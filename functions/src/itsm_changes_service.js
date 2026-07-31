'use strict';

const crypto = require('node:crypto');

const {
  ITSM_ROLES,
  ItsmCommandError,
  normalizeString,
  resolveItsmRole,
} = require('./itsm_permissions');
const { runIdempotentCommand } = require('./itsm_idempotency');
const {
  CHANGES_COMMAND_ALLOWED_ROLES,
  ITSM_CHANGES_COMMANDS,
} = require('./itsm_changes_validation');
const {
  buildCabMeetingNotificationEvent,
  buildChangeApprovalDecisionNotificationEvent,
  buildChangeApprovalRequestedNotificationEvent,
  buildChangeOwnerAssignedNotificationEvent,
  buildChangeStatusNotificationEvent,
  buildChangeSubmittedNotificationEvent,
  canonicalCalendarRoute,
  canonicalChangeRoute,
} = require('./itsm_changes_notifications');

const TERMINAL_STATUSES = Object.freeze([
  'closed',
  'rejected',
  'cancelled',
  'failed',
  'rolled_back',
]);
const SELF_SERVICE_CANCELLABLE_STATUSES = Object.freeze(['draft', 'submitted']);
const MANAGER_CANCELLABLE_STATUSES = Object.freeze([
  'draft',
  'submitted',
  'assessment',
  'awaiting_approval',
  'approved',
  'scheduled',
]);
const REFERENCE_COLLECTIONS = Object.freeze({
  affectedServiceIds: 'itServices',
  affectedCiIds: 'configurationItems',
  affectedAssetIds: 'assets',
  relatedIncidentIds: 'incidentTickets',
  relatedRequestIds: 'serviceRequests',
});

async function executeChangesCommand({
  db,
  fieldValue,
  timestamp,
  actor,
  command,
  dependencies = {},
}) {
  requireCommandRole(actor, command.command);
  const services = createServiceDependencies(dependencies);
  return runIdempotentCommand({
    db,
    fieldValue,
    actorUid: actor.uid,
    command: command.command,
    idempotencyKey: command.idempotencyKey,
    execute: async (transaction, receiptId) => {
      const context = {
        db,
        fieldValue,
        timestamp,
        transaction,
        actor,
        command,
        receiptId,
        services,
      };
      switch (command.command) {
        case ITSM_CHANGES_COMMANDS.initializeDraft:
          return initializeDraft(context);
        case ITSM_CHANGES_COMMANDS.saveDraft:
          return saveDraft(context);
        case ITSM_CHANGES_COMMANDS.submit:
          return submitChange(context);
        case ITSM_CHANGES_COMMANDS.cancel:
          return cancelChange(context);
        case ITSM_CHANGES_COMMANDS.assess:
          return assessChange(context);
        case ITSM_CHANGES_COMMANDS.requestApproval:
          return requestApproval(context);
        case ITSM_CHANGES_COMMANDS.decideApproval:
          return decideApproval(context);
        case ITSM_CHANGES_COMMANDS.saveCabMeeting:
          return saveCabMeeting(context);
        case ITSM_CHANGES_COMMANDS.schedule:
          return scheduleChange(context);
        case ITSM_CHANGES_COMMANDS.startImplementation:
          return startImplementation(context);
        case ITSM_CHANGES_COMMANDS.recordImplementationResult:
          return recordImplementationResult(context);
        case ITSM_CHANGES_COMMANDS.recordPostImplementationReview:
          return recordPostImplementationReview(context);
        case ITSM_CHANGES_COMMANDS.close:
          return closeChange(context);
        default:
          throw invalid(`Unknown change command: ${command.command}.`);
      }
    },
  });
}

async function initializeDraft(context) {
  const {
    db,
    fieldValue,
    timestamp,
    transaction,
    actor,
    command,
    receiptId,
    services,
  } = context;
  const payload = command.payload;
  const workflow = await services.resolvePublishedWorkflowVersion({
    db,
    transaction,
    workflowDefinitionId: payload.workflowDefinitionId,
    changeType: payload.changeType,
  });
  const changeId = payload.changeId || `change_${receiptId.slice(0, 24)}`;
  const ref = db.collection('changeRequests').doc(changeId);
  const serverTime = fieldValue.serverTimestamp();
  const now = trustedNow(timestamp);
  const change = {
    id: changeId,
    changeNumber: buildChangeNumber(now, receiptId),
    title: payload.title,
    description: payload.description,
    justification: payload.justification,
    changeType: payload.changeType,
    status: 'draft',
    lifecycleState: 'active',
    requesterId: actor.uid,
    requesterName: actor.displayName,
    requesterEmail: actor.email,
    ownerUserId: null,
    ownerName: null,
    ownerEmail: null,
    workflowDefinitionId: workflow.definitionId,
    workflowVersion: workflow.version,
    workflowVersionDocumentId: workflow.documentId,
    standardPreAuthorized: payload.changeType === 'standard' &&
      workflow.data.standardPreAuthorized === true,
    risk: 'unassessed',
    riskScore: null,
    revision: 0,
    createdAt: serverTime,
    createdByUserId: actor.uid,
    updatedAt: serverTime,
    updatedByUserId: actor.uid,
  };
  transaction.create(ref, change);
  writeWorkItemIndex({ transaction, db, changeId, change });
  writeAudit({
    ...context,
    parentRef: ref,
    changeId,
    action: 'draft_initialized',
    after: auditSnapshot(change),
  });
  return {
    changeId,
    changeNumber: change.changeNumber,
    status: change.status,
    revision: 0,
  };
}

async function saveDraft(context) {
  const { db, fieldValue, transaction, actor, command } = context;
  const payload = command.payload;
  const { ref, change } = await readChange(transaction, db, payload.changeId);
  requireRevision(change, payload.expectedRevision);
  requireStatus(change, ['draft']);
  requireRequester(change, actor);
  const patch = revisionPatch(fieldValue, actor, payload.expectedRevision, {
    title: payload.title,
    description: payload.description,
    justification: payload.justification,
  });
  transaction.update(ref, patch);
  writeWorkItemIndex({
    transaction,
    db,
    changeId: payload.changeId,
    change: { ...change, ...patch },
  });
  writeAudit({
    ...context,
    parentRef: ref,
    changeId: payload.changeId,
    action: 'draft_updated',
    before: auditSnapshot(change),
    after: auditSnapshot({ ...change, ...patch }),
  });
  return result(payload.changeId, change.changeNumber, 'draft', patch.revision);
}

async function submitChange(context) {
  const {
    db,
    fieldValue,
    transaction,
    actor,
    command,
    receiptId,
    services,
  } = context;
  const payload = command.payload;
  const { ref, change } = await readChange(transaction, db, payload.changeId);
  requireRevision(change, payload.expectedRevision);
  requireStatus(change, ['draft']);
  requireRequester(change, actor);
  requireDraftFields(change);
  await services.getPinnedWorkflowVersion({ db, transaction, change });
  const patch = revisionPatch(fieldValue, actor, payload.expectedRevision, {
    status: 'submitted',
    submittedAt: fieldValue.serverTimestamp(),
  });
  transaction.update(ref, patch);
  const updated = { ...change, ...patch };
  writeWorkItemIndex({ transaction, db, changeId: payload.changeId, change: updated });
  writeAudit({
    ...context,
    parentRef: ref,
    changeId: payload.changeId,
    action: 'submitted',
    before: { status: change.status },
    after: { status: patch.status, revision: patch.revision },
  });
  writeNotification(transaction, db, buildChangeSubmittedNotificationEvent({
    change: updated,
    changeId: payload.changeId,
    actor,
    sourceId: receiptId,
    createdAt: fieldValue.serverTimestamp(),
  }));
  return result(payload.changeId, change.changeNumber, patch.status, patch.revision);
}

async function cancelChange(context) {
  const { db, fieldValue, transaction, actor, command, receiptId } = context;
  const payload = command.payload;
  const { ref, change } = await readChange(transaction, db, payload.changeId);
  requireRevision(change, payload.expectedRevision);
  const currentStatus = statusOf(change);
  if (actor.role === ITSM_ROLES.manager) {
    if (!MANAGER_CANCELLABLE_STATUSES.includes(currentStatus)) {
      throw failed(`A change in ${currentStatus} cannot be cancelled.`);
    }
  } else {
    requireRequester(change, actor);
    if (!SELF_SERVICE_CANCELLABLE_STATUSES.includes(currentStatus)) {
      throw denied('Only a MANAGER can cancel this change at its current stage.');
    }
  }
  const patch = revisionPatch(fieldValue, actor, payload.expectedRevision, {
    status: 'cancelled',
    lifecycleState: 'closed',
    cancellationReason: payload.reason,
    cancelledAt: fieldValue.serverTimestamp(),
    cancelledByUserId: actor.uid,
  });
  transaction.update(ref, patch);
  const updated = { ...change, ...patch };
  writeWorkItemIndex({ transaction, db, changeId: payload.changeId, change: updated });
  writeCalendarProjection({ transaction, db, changeId: payload.changeId, change: updated });
  writeAudit({
    ...context,
    parentRef: ref,
    changeId: payload.changeId,
    action: 'cancelled',
    before: { status: currentStatus },
    after: { status: 'cancelled', reason: payload.reason },
  });
  writeNotification(transaction, db, buildChangeStatusNotificationEvent({
    change: updated,
    changeId: payload.changeId,
    status: 'cancelled',
    actor,
    sourceId: receiptId,
    createdAt: fieldValue.serverTimestamp(),
  }));
  return result(payload.changeId, change.changeNumber, patch.status, patch.revision);
}

async function assessChange(context) {
  const {
    db,
    fieldValue,
    transaction,
    actor,
    command,
    receiptId,
    services,
  } = context;
  const payload = command.payload;
  const { ref, change } = await readChange(transaction, db, payload.changeId);
  requireRevision(change, payload.expectedRevision);
  requireStatus(change, ['submitted', 'assessment']);
  const owner = await services.resolveManagerAgent({
    db,
    transaction,
    userId: payload.ownerUserId,
  });
  await services.validateReferences({ db, transaction, payload });
  const risk = calculateChangeRisk(payload);
  const patch = revisionPatch(fieldValue, actor, payload.expectedRevision, {
    status: 'assessment',
    ownerUserId: owner.uid,
    ownerName: owner.displayName,
    ownerEmail: owner.email,
    affectedServiceIds: payload.affectedServiceIds,
    affectedCiIds: payload.affectedCiIds,
    affectedAssetIds: payload.affectedAssetIds,
    relatedIncidentIds: payload.relatedIncidentIds,
    relatedRequestIds: payload.relatedRequestIds,
    impact: payload.impact,
    urgency: payload.urgency,
    complexity: payload.complexity,
    risk: risk.level,
    riskScore: risk.score,
    expectedDowntimeMinutes: payload.expectedDowntimeMinutes,
    implementationPlan: payload.implementationPlan,
    testPlan: payload.testPlan,
    testEvidenceAttachmentIds: payload.testEvidenceAttachmentIds,
    communicationPlan: payload.communicationPlan,
    rollbackPlan: payload.rollbackPlan,
    approvalGroupId: payload.approvalGroupId || null,
    assessedAt: fieldValue.serverTimestamp(),
    assessedByUserId: actor.uid,
  });
  transaction.update(ref, patch);
  const updated = { ...change, ...patch };
  writeWorkItemIndex({ transaction, db, changeId: payload.changeId, change: updated });
  writeAudit({
    ...context,
    parentRef: ref,
    changeId: payload.changeId,
    action: 'assessed',
    before: auditSnapshot(change),
    after: auditSnapshot(updated),
  });
  if (normalizeString(change.ownerUserId) !== owner.uid) {
    writeNotification(transaction, db, buildChangeOwnerAssignedNotificationEvent({
      change: updated,
      changeId: payload.changeId,
      actor,
      sourceId: receiptId,
      createdAt: fieldValue.serverTimestamp(),
    }));
  }
  return {
    ...result(payload.changeId, change.changeNumber, patch.status, patch.revision),
    risk: risk.level,
    riskScore: risk.score,
  };
}

async function requestApproval(context) {
  const {
    db,
    fieldValue,
    timestamp,
    transaction,
    actor,
    command,
    receiptId,
    services,
  } = context;
  const payload = command.payload;
  const { ref, change } = await readChange(transaction, db, payload.changeId);
  requireRevision(change, payload.expectedRevision);
  requireStatus(change, ['assessment']);
  requireAssessment(change);
  const workflow = await services.getPinnedWorkflowVersion({ db, transaction, change });
  if (change.changeType === 'standard' && change.standardPreAuthorized === true) {
    const patch = revisionPatch(fieldValue, actor, payload.expectedRevision, {
      status: 'approved',
      approvalState: 'pre_authorized',
      approvedAt: fieldValue.serverTimestamp(),
      approvedByUserId: 'workflow',
    });
    transaction.update(ref, patch);
    const updated = { ...change, ...patch };
    writeWorkItemIndex({ transaction, db, changeId: payload.changeId, change: updated });
    writeAudit({
      ...context,
      parentRef: ref,
      changeId: payload.changeId,
      action: 'pre_authorized',
      before: { status: change.status },
      after: { status: patch.status, workflowVersion: change.workflowVersion },
    });
    writeNotification(transaction, db, buildChangeStatusNotificationEvent({
      change: updated,
      changeId: payload.changeId,
      status: patch.status,
      actor,
      sourceId: receiptId,
      createdAt: fieldValue.serverTimestamp(),
    }));
    return result(payload.changeId, change.changeNumber, patch.status, patch.revision);
  }

  const groupId = normalizeString(
    change.approvalGroupId || workflow.defaultApprovalGroupId,
  );
  if (!groupId) throw failed('An approval group is required for this change.');
  const group = await services.resolveApprovalGroup({
    db,
    transaction,
    groupId,
  });
  const approverUserIds = group.members
    .map((member) => member.uid)
    .filter((uid) => uid !== normalizeString(change.requesterId));
  if (approverUserIds.length === 0) {
    throw failed('The approval group has no independent MANAGER approver.');
  }
  const approvalId = `approval_${receiptId.slice(0, 24)}`;
  const approvalRef = ref.collection('approvals').doc(approvalId);
  const requestedAt = fieldValue.serverTimestamp();
  const deadlineHours = boundedHours(
    group.approvalDeadlineHours ||
      workflow.approvalDeadlineHours ||
      (change.changeType === 'emergency' ? 4 : 72),
    1,
    720,
  );
  const dueAt = serverDate(timestamp, addHours(trustedNow(timestamp), deadlineHours));
  const approval = {
    approvalId,
    changeId: payload.changeId,
    changeType: change.changeType,
    assignedGroupId: groupId,
    assignedGroupName: group.name,
    approverUserIds,
    status: 'pending',
    emergency: change.changeType === 'emergency',
    requestedAt,
    requestedByUserId: actor.uid,
    dueAt,
    revision: 0,
  };
  transaction.create(approvalRef, approval);
  writeApprovalHistory({
    ...context,
    parentRef: ref,
    changeId: payload.changeId,
    approvalId,
    action: 'requested',
    decision: 'pending',
    comment: '',
    conditions: [],
    groupId,
    emergencyDecision: change.changeType === 'emergency',
  });
  const patch = revisionPatch(fieldValue, actor, payload.expectedRevision, {
    status: 'awaiting_approval',
    approvalState: 'pending',
    activeApprovalId: approvalId,
    approvalGroupId: groupId,
    approvalDueAt: dueAt,
  });
  transaction.update(ref, patch);
  const updated = { ...change, ...patch };
  writeWorkItemIndex({ transaction, db, changeId: payload.changeId, change: updated });
  writeAudit({
    ...context,
    parentRef: ref,
    changeId: payload.changeId,
    action: 'approval_requested',
    before: { status: change.status },
    after: { status: patch.status, approvalId, groupId, dueAt },
  });
  writeNotification(transaction, db, buildChangeApprovalRequestedNotificationEvent({
    change: updated,
    changeId: payload.changeId,
    approvalId,
    approverUserIds,
    actor,
    sourceId: receiptId,
    createdAt: fieldValue.serverTimestamp(),
  }));
  return {
    ...result(payload.changeId, change.changeNumber, patch.status, patch.revision),
    approvalId,
    approvalDueAt: dueAt,
  };
}

async function decideApproval(context) {
  const {
    db,
    fieldValue,
    transaction,
    actor,
    command,
    receiptId,
    services,
  } = context;
  const payload = command.payload;
  const { ref, change } = await readChange(transaction, db, payload.changeId);
  requireRevision(change, payload.expectedRevision);
  requireStatus(change, ['awaiting_approval']);
  if (normalizeString(change.activeApprovalId) !== payload.approvalId) {
    throw failed('This approval is not the active approval for the change.');
  }
  const approvalRef = ref.collection('approvals').doc(payload.approvalId);
  const approvalSnapshot = await transaction.get(approvalRef);
  const approval = requireDocument(approvalSnapshot, 'The approval does not exist.');
  if (normalizeString(approval.status).toLowerCase() !== 'pending') {
    throw failed('The approval has already received a decision.');
  }
  const group = await services.resolveApprovalGroup({
    db,
    transaction,
    groupId: approval.assignedGroupId,
  });
  if (!group.members.some((member) => member.uid === actor.uid)) {
    throw denied('You are not a member of the assigned CAB group.');
  }
  if (['normal', 'emergency'].includes(change.changeType) &&
      normalizeString(change.requesterId) === actor.uid) {
    throw denied('The requester cannot approve their own normal or emergency change.');
  }
  if (payload.decision !== 'approved' && payload.conditions.length > 0) {
    throw failed('Conditions can be attached only to an approval.');
  }
  const nextStatus = ({
    approved: 'approved',
    rejected: 'rejected',
    clarification_requested: 'assessment',
  })[payload.decision];
  const decidedAt = fieldValue.serverTimestamp();
  transaction.update(approvalRef, {
    status: payload.decision,
    decision: payload.decision,
    decisionComment: payload.comment,
    conditions: payload.conditions,
    decidedAt,
    decidedByUserId: actor.uid,
    decidedByName: actor.displayName,
    decidedByEmail: actor.email,
    revision: Number(approval.revision || 0) + 1,
  });
  writeApprovalHistory({
    ...context,
    parentRef: ref,
    changeId: payload.changeId,
    approvalId: payload.approvalId,
    action: 'decided',
    decision: payload.decision,
    comment: payload.comment,
    conditions: payload.conditions,
    groupId: approval.assignedGroupId,
    emergencyDecision: change.changeType === 'emergency',
  });
  const patch = revisionPatch(fieldValue, actor, payload.expectedRevision, {
    status: nextStatus,
    lifecycleState: payload.decision === 'rejected' ? 'closed' : 'active',
    approvalState: payload.decision,
    approvalConditions: payload.conditions,
    activeApprovalId: null,
    approvalDecidedAt: decidedAt,
    approvalDecidedByUserId: actor.uid,
  });
  transaction.update(ref, patch);
  const updated = { ...change, ...patch };
  writeWorkItemIndex({ transaction, db, changeId: payload.changeId, change: updated });
  writeCalendarProjection({ transaction, db, changeId: payload.changeId, change: updated });
  writeAudit({
    ...context,
    parentRef: ref,
    changeId: payload.changeId,
    action: `approval_${payload.decision}`,
    before: { status: change.status, approvalState: change.approvalState },
    after: { status: nextStatus, approvalState: payload.decision },
  });
  writeNotification(transaction, db, buildChangeApprovalDecisionNotificationEvent({
    change: updated,
    changeId: payload.changeId,
    approvalId: payload.approvalId,
    decision: payload.decision,
    comment: payload.comment,
    actor,
    sourceId: receiptId,
    createdAt: fieldValue.serverTimestamp(),
  }));
  return result(payload.changeId, change.changeNumber, patch.status, patch.revision);
}

async function saveCabMeeting(context) {
  const {
    db,
    fieldValue,
    timestamp,
    transaction,
    actor,
    command,
    receiptId,
    services,
  } = context;
  const payload = command.payload;
  const { ref, change } = await readChange(transaction, db, payload.changeId);
  requireRevision(change, payload.expectedRevision);
  if (TERMINAL_STATUSES.includes(statusOf(change))) {
    throw failed('A CAB meeting cannot be added to a terminal change.');
  }
  const group = await services.resolveApprovalGroup({
    db,
    transaction,
    groupId: payload.approvalGroupId,
  });
  const memberIds = new Set(group.members.map((member) => member.uid));
  if (!memberIds.has(actor.uid)) {
    throw denied('Only a member of the CAB group can manage its meeting.');
  }
  if (payload.participantUserIds.some((userId) => !memberIds.has(userId))) {
    throw failed('Every CAB participant must be a MANAGER in the assigned group.');
  }
  const participants = payload.participantUserIds.map((userId) => {
    const member = group.members.find((candidate) => candidate.uid === userId);
    return {
      userId: member.uid,
      name: member.displayName,
      email: member.email,
    };
  });
  const meetingId = payload.meetingId || `meeting_${receiptId.slice(0, 24)}`;
  const meetingRef = ref.collection('cabMeetings').doc(meetingId);
  const existing = await transaction.get(meetingRef);
  const startAt = serverDate(timestamp, new Date(payload.scheduledStartAt));
  const endAt = serverDate(timestamp, new Date(payload.scheduledEndAt));
  const decisionDeadlineAt = serverDate(
    timestamp,
    addHours(
      new Date(payload.scheduledEndAt),
      boundedHours(group.decisionDeadlineHours || 24, 1, 720),
    ),
  );
  const meeting = {
    meetingId,
    changeId: payload.changeId,
    approvalGroupId: payload.approvalGroupId,
    approvalGroupName: group.name,
    title: payload.title,
    agenda: payload.agenda,
    participants,
    participantUserIds: participants.map((participant) => participant.userId),
    scheduledStartAt: startAt,
    scheduledEndAt: endAt,
    decisionDeadlineAt,
    notes: payload.notes,
    updatedAt: fieldValue.serverTimestamp(),
    updatedByUserId: actor.uid,
    ...(existing.exists ? {} : {
      createdAt: fieldValue.serverTimestamp(),
      createdByUserId: actor.uid,
    }),
  };
  transaction.set(meetingRef, meeting, { merge: existing.exists });
  const patch = revisionPatch(fieldValue, actor, payload.expectedRevision, {
    cabMeetingId: meetingId,
    cabMeetingAt: startAt,
    cabDecisionDeadlineAt: decisionDeadlineAt,
  });
  transaction.update(ref, patch);
  writeAudit({
    ...context,
    parentRef: ref,
    changeId: payload.changeId,
    action: existing.exists ? 'cab_meeting_updated' : 'cab_meeting_created',
    before: existing.exists ? meetingAudit(existing.data() || {}) : {},
    after: meetingAudit(meeting),
  });
  writeNotification(transaction, db, buildCabMeetingNotificationEvent({
    change: { ...change, ...patch },
    changeId: payload.changeId,
    meetingId,
    participantUserIds: payload.participantUserIds,
    actor,
    sourceId: receiptId,
    createdAt: fieldValue.serverTimestamp(),
  }));
  return {
    ...result(payload.changeId, change.changeNumber, statusOf(change), patch.revision),
    meetingId,
    decisionDeadlineAt,
  };
}

async function scheduleChange(context) {
  const {
    db,
    fieldValue,
    timestamp,
    transaction,
    actor,
    command,
    receiptId,
    services,
  } = context;
  const payload = command.payload;
  const { ref, change } = await readChange(transaction, db, payload.changeId);
  requireRevision(change, payload.expectedRevision);
  requireStatus(change, ['approved']);
  const start = new Date(payload.plannedStartAt);
  const end = new Date(payload.plannedEndAt);
  if (start <= trustedNow(timestamp)) {
    throw failed('The planned implementation start must be in the future.');
  }
  if (payload.maintenanceWindowId) {
    await services.validateMaintenanceWindow({
      db,
      transaction,
      maintenanceWindowId: payload.maintenanceWindowId,
      start,
      end,
    });
  }
  const conflicts = await services.findCalendarConflicts({
    db,
    transaction,
    timestamp,
    changeId: payload.changeId,
    start,
    end,
    affectedServiceIds: change.affectedServiceIds || [],
    affectedCiIds: change.affectedCiIds || [],
    limit: 50,
  });
  const patch = revisionPatch(fieldValue, actor, payload.expectedRevision, {
    status: 'scheduled',
    plannedStartAt: serverDate(timestamp, start),
    plannedEndAt: serverDate(timestamp, end),
    expectedDowntimeMinutes: payload.expectedDowntimeMinutes,
    maintenanceWindowId: payload.maintenanceWindowId || null,
    publishMaintenance: payload.publishMaintenance,
    conflictChangeIds: conflicts.map((conflict) => conflict.changeId).slice(0, 50),
    conflictCount: Math.min(conflicts.length, 50),
    hasConflict: conflicts.length > 0,
    scheduledAt: fieldValue.serverTimestamp(),
    scheduledByUserId: actor.uid,
  });
  transaction.update(ref, patch);
  const updated = { ...change, ...patch };
  writeWorkItemIndex({ transaction, db, changeId: payload.changeId, change: updated });
  writeCalendarProjection({ transaction, db, changeId: payload.changeId, change: updated });
  writeAudit({
    ...context,
    parentRef: ref,
    changeId: payload.changeId,
    action: 'scheduled',
    before: { status: change.status },
    after: {
      status: patch.status,
      plannedStartAt: patch.plannedStartAt,
      plannedEndAt: patch.plannedEndAt,
      conflictCount: patch.conflictCount,
    },
  });
  writeNotification(transaction, db, buildChangeStatusNotificationEvent({
    change: updated,
    changeId: payload.changeId,
    status: patch.status,
    actor,
    sourceId: receiptId,
    createdAt: fieldValue.serverTimestamp(),
    route: canonicalCalendarRoute(payload.changeId),
  }));
  return {
    ...result(payload.changeId, change.changeNumber, patch.status, patch.revision),
    hasConflict: patch.hasConflict,
    conflictCount: patch.conflictCount,
  };
}

async function startImplementation(context) {
  return transitionOperationalChange(context, {
    allowedStatuses: ['scheduled'],
    nextStatus: 'implementation',
    action: 'implementation_started',
    extraPatch: ({ fieldValue, actor, payload }) => ({
      implementationStartedAt: fieldValue.serverTimestamp(),
      implementationStartedByUserId: actor.uid,
      implementationStartComment: payload.comment,
    }),
  });
}

async function recordImplementationResult(context) {
  const outcome = context.command.payload.outcome;
  const nextStatus = ({
    succeeded: 'review',
    failed: 'failed',
    rolled_back: 'rolled_back',
  })[outcome];
  return transitionOperationalChange(context, {
    allowedStatuses: ['implementation'],
    nextStatus,
    action: `implementation_${outcome}`,
    lifecycleState: outcome === 'succeeded' ? 'active' : 'closed',
    extraPatch: ({ fieldValue, actor, payload }) => ({
      implementationOutcome: outcome,
      implementationResult: payload.summary,
      implementationEvidenceAttachmentIds: payload.evidenceAttachmentIds,
      implementationCompletedAt: fieldValue.serverTimestamp(),
      implementationCompletedByUserId: actor.uid,
    }),
  });
}

async function recordPostImplementationReview(context) {
  const { db, fieldValue, transaction, actor, command } = context;
  const payload = command.payload;
  const { ref, change } = await readChange(transaction, db, payload.changeId);
  requireRevision(change, payload.expectedRevision);
  requireStatus(change, ['review']);
  const pir = {
    outcome: payload.outcome,
    summary: payload.summary,
    lessonsLearned: payload.lessonsLearned,
    followUpActions: payload.followUpActions,
    evidenceAttachmentIds: payload.evidenceAttachmentIds,
    reviewedAt: fieldValue.serverTimestamp(),
    reviewedByUserId: actor.uid,
    reviewedByName: actor.displayName,
    reviewedByEmail: actor.email,
  };
  const patch = revisionPatch(fieldValue, actor, payload.expectedRevision, {
    postImplementationReview: pir,
    pirCompletedAt: fieldValue.serverTimestamp(),
  });
  transaction.update(ref, patch);
  const updated = { ...change, ...patch };
  writeWorkItemIndex({ transaction, db, changeId: payload.changeId, change: updated });
  writeAudit({
    ...context,
    parentRef: ref,
    changeId: payload.changeId,
    action: 'post_implementation_review_recorded',
    before: { pirCompletedAt: change.pirCompletedAt || null },
    after: { outcome: payload.outcome, pirCompletedAt: patch.pirCompletedAt },
  });
  return result(payload.changeId, change.changeNumber, statusOf(change), patch.revision);
}

async function closeChange(context) {
  const { change } = await readChange(
    context.transaction,
    context.db,
    context.command.payload.changeId,
  );
  if (!change.postImplementationReview || !change.pirCompletedAt) {
    throw failed('A post-implementation review is required before closure.');
  }
  return transitionOperationalChange(context, {
    allowedStatuses: ['review'],
    nextStatus: 'closed',
    action: 'closed',
    lifecycleState: 'closed',
    preloadedChange: change,
    extraPatch: ({ fieldValue, actor, payload }) => ({
      closureComment: payload.comment,
      closedAt: fieldValue.serverTimestamp(),
      closedByUserId: actor.uid,
    }),
  });
}

async function transitionOperationalChange(context, options) {
  const {
    db,
    fieldValue,
    transaction,
    actor,
    command,
    receiptId,
  } = context;
  const payload = command.payload;
  let ref;
  let change = options.preloadedChange;
  if (change) {
    ref = db.collection('changeRequests').doc(payload.changeId);
  } else {
    ({ ref, change } = await readChange(transaction, db, payload.changeId));
  }
  requireRevision(change, payload.expectedRevision);
  requireStatus(change, options.allowedStatuses);
  const patch = revisionPatch(fieldValue, actor, payload.expectedRevision, {
    status: options.nextStatus,
    lifecycleState: options.lifecycleState || change.lifecycleState || 'active',
    ...options.extraPatch({ fieldValue, actor, payload, change }),
  });
  transaction.update(ref, patch);
  const updated = { ...change, ...patch };
  writeWorkItemIndex({ transaction, db, changeId: payload.changeId, change: updated });
  writeCalendarProjection({ transaction, db, changeId: payload.changeId, change: updated });
  writeAudit({
    ...context,
    parentRef: ref,
    changeId: payload.changeId,
    action: options.action,
    before: { status: change.status },
    after: { status: options.nextStatus, revision: patch.revision },
  });
  writeNotification(transaction, db, buildChangeStatusNotificationEvent({
    change: updated,
    changeId: payload.changeId,
    status: options.nextStatus,
    actor,
    sourceId: receiptId,
    createdAt: fieldValue.serverTimestamp(),
  }));
  return result(payload.changeId, change.changeNumber, patch.status, patch.revision);
}

function createServiceDependencies(overrides) {
  return {
    resolvePublishedWorkflowVersion,
    getPinnedWorkflowVersion,
    resolveManagerAgent,
    resolveApprovalGroup,
    validateReferences,
    validateMaintenanceWindow,
    findCalendarConflicts,
    ...overrides,
  };
}

async function resolvePublishedWorkflowVersion({
  db,
  transaction,
  workflowDefinitionId,
  changeType,
}) {
  const parentRef = db.collection('workflowDefinitions').doc(workflowDefinitionId);
  const parentSnapshot = await transaction.get(parentRef);
  const parent = requireDocument(parentSnapshot, 'The change workflow does not exist.');
  if (normalizeString(parent.status).toLowerCase() !== 'published') {
    throw failed('The change workflow is not published.');
  }
  const version = positiveInteger(
    parent.publishedVersion || parent.currentVersion || parent.version,
  );
  if (!version) throw failed('The change workflow has no published version.');
  const candidates = [`version_${version}`, String(version)];
  for (const documentId of candidates) {
    const snapshot = await transaction.get(parentRef.collection('versions').doc(documentId));
    if (!snapshot.exists) continue;
    const data = snapshot.data() || {};
    if (normalizeString(data.status || data.state).toLowerCase() !== 'published') {
      throw failed('The selected change workflow version is not published.');
    }
    const supportedTypes = stringList(data.supportedChangeTypes || parent.supportedChangeTypes);
    if (supportedTypes.length > 0 && !supportedTypes.includes(changeType)) {
      throw failed('The workflow does not support this change type.');
    }
    return { definitionId: workflowDefinitionId, version, documentId, data };
  }
  throw failed('The published change workflow version does not exist.');
}

async function getPinnedWorkflowVersion({ db, transaction, change }) {
  const definitionId = normalizeString(change.workflowDefinitionId);
  const documentId = normalizeString(change.workflowVersionDocumentId);
  if (!definitionId || !documentId) throw failed('The pinned workflow is invalid.');
  const snapshot = await transaction.get(
    db.collection('workflowDefinitions')
      .doc(definitionId)
      .collection('versions')
      .doc(documentId),
  );
  const data = requireDocument(snapshot, 'The pinned workflow version does not exist.');
  return data;
}

async function resolveManagerAgent({ db, transaction, userId }) {
  const snapshot = await transaction.get(db.collection('agents').doc(userId));
  const agent = requireDocument(snapshot, 'The selected MANAGER does not exist.');
  if (agent.isActive === false || resolveItsmRole(agent) !== ITSM_ROLES.manager) {
    throw failed('The selected agent is not an active ITSM MANAGER.');
  }
  return {
    uid: userId,
    displayName: agentName(agent),
    email: normalizeString(agent.email).toLowerCase(),
  };
}

async function resolveApprovalGroup({ db, transaction, groupId }) {
  const snapshot = await transaction.get(db.collection('changeApprovalGroups').doc(groupId));
  const group = requireDocument(snapshot, 'The CAB approval group does not exist.');
  if (group.isActive === false || normalizeString(group.status).toLowerCase() === 'retired') {
    throw failed('The CAB approval group is inactive.');
  }
  const memberUserIds = stringList(group.memberUserIds);
  if (memberUserIds.length === 0 || memberUserIds.length > 50) {
    throw failed('The CAB approval group must contain 1-50 MANAGER users.');
  }
  const members = [];
  for (const userId of memberUserIds) {
    members.push(await resolveManagerAgent({ db, transaction, userId }));
  }
  return {
    id: groupId,
    name: normalizeString(group.name) || groupId,
    members,
    approvalDeadlineHours: group.approvalDeadlineHours,
    decisionDeadlineHours: group.decisionDeadlineHours,
  };
}

async function validateReferences({ db, transaction, payload }) {
  for (const [field, collection] of Object.entries(REFERENCE_COLLECTIONS)) {
    for (const id of payload[field] || []) {
      const snapshot = await transaction.get(db.collection(collection).doc(id));
      if (!snapshot.exists) throw failed(`${field} contains an unknown reference.`);
    }
  }
}

async function validateMaintenanceWindow({
  db,
  transaction,
  maintenanceWindowId,
  start,
  end,
}) {
  const snapshot = await transaction.get(
    db.collection('maintenanceWindows').doc(maintenanceWindowId),
  );
  const window = requireDocument(snapshot, 'The maintenance window does not exist.');
  if (window.isActive === false) throw failed('The maintenance window is inactive.');
  const windowStart = toDate(window.startAt);
  const windowEnd = toDate(window.endAt);
  if (!windowStart || !windowEnd || start < windowStart || end > windowEnd) {
    throw failed('The change schedule is outside the maintenance window.');
  }
}

async function findCalendarConflicts({
  db,
  transaction,
  timestamp,
  changeId,
  start,
  end,
  affectedServiceIds,
  affectedCiIds,
  limit,
}) {
  const safeLimit = Math.min(50, Math.max(1, Number(limit) || 50));
  // A change window is capped at 90 days. Therefore any overlapping entry
  // must start after this lower bound, keeping the query bounded on one field.
  const overlapFloor = new Date(start.getTime() - 90 * 24 * 60 * 60 * 1000);
  const query = db.collection('changeCalendarEntries')
    .where('plannedStartAt', '>=', serverDate(timestamp, overlapFloor))
    .where('plannedStartAt', '<', serverDate(timestamp, end))
    .orderBy('plannedStartAt')
    .limit(safeLimit);
  const snapshot = await transaction.get(query);
  const services = new Set(affectedServiceIds);
  const cis = new Set(affectedCiIds);
  return (snapshot.docs || [])
    .filter((document) => document.id !== changeId)
    .map((document) => ({ changeId: document.id, ...(document.data() || {}) }))
    .filter((entry) => entry.isActive !== false)
    .filter((entry) => {
      const plannedEnd = toDate(entry.plannedEndAt);
      return plannedEnd && plannedEnd > start;
    })
    .filter((entry) => intersects(services, entry.affectedServiceIds) ||
      intersects(cis, entry.affectedCiIds))
    .slice(0, safeLimit);
}

function calculateChangeRisk({ impact, urgency, complexity }) {
  const impactScore = ({ low: 1, medium: 2, high: 3, critical: 4 })[impact];
  const urgencyScore = ({ low: 1, medium: 2, high: 3, critical: 4 })[urgency];
  const complexityScore = ({ low: 1, medium: 2, high: 3 })[complexity];
  if (!impactScore || !urgencyScore || !complexityScore) {
    throw invalid('Impact, urgency, and complexity are required to calculate risk.');
  }
  const score = impactScore * urgencyScore + complexityScore;
  const level = score <= 4 ? 'low' : score <= 8 ? 'medium' : score <= 13 ? 'high' : 'critical';
  return { level, score };
}

function writeApprovalHistory({
  transaction,
  fieldValue,
  actor,
  command,
  receiptId,
  parentRef,
  changeId,
  approvalId,
  action,
  decision,
  comment,
  conditions,
  groupId,
  emergencyDecision = false,
}) {
  const historyId = deterministicId('approval_history', receiptId, action);
  transaction.create(parentRef.collection('approvalHistory').doc(historyId), {
    historyId,
    changeId,
    approvalId,
    action,
    decision,
    comment,
    conditions,
    approvalGroupId: normalizeString(groupId),
    emergencyDecision,
    actor: actorMap(actor),
    sourceCommand: command.command,
    correlationId: command.idempotencyKey,
    occurredAt: fieldValue.serverTimestamp(),
  });
}

function writeAudit({
  transaction,
  db,
  fieldValue,
  actor,
  command,
  receiptId,
  parentRef,
  changeId,
  action,
  before = {},
  after = {},
}) {
  const auditId = deterministicId('audit', receiptId, action);
  const requesterVisible = !action.startsWith('cab_meeting');
  const event = {
    eventType: `change_request.${action}`,
    action,
    entityType: 'change_request',
    entityId: changeId,
    actor: actorMap(actor),
    actorUserId: actor.uid,
    actorRole: actor.role,
    before,
    after,
    sourceCommand: command.command,
    sourceIdempotencyKey: command.idempotencyKey,
    correlationId: command.idempotencyKey,
    requesterVisible,
    isInternal: !requesterVisible,
    createdAt: fieldValue.serverTimestamp(),
  };
  transaction.create(parentRef.collection('auditLogs').doc(auditId), event);
  transaction.create(db.collection('itsmAuditEvents').doc(auditId), {
    ...event,
    sourcePath: parentRef.path,
  });
}

function writeWorkItemIndex({ transaction, db, changeId, change }) {
  transaction.set(db.collection('itsmWorkItemIndex').doc(`change_request:${changeId}`), {
    id: changeId,
    type: 'change_request',
    reference: normalizeString(change.changeNumber),
    title: normalizeString(change.title),
    requesterId: normalizeString(change.requesterId),
    assignedUserId: normalizeString(change.ownerUserId),
    status: statusOf(change),
    lifecycleState: normalizeString(change.lifecycleState || 'active'),
    priority: normalizeString(change.risk || 'unassessed'),
    risk: normalizeString(change.risk || 'unassessed'),
    changeType: normalizeString(change.changeType),
    serviceIds: stringList(change.affectedServiceIds),
    linkedCiIds: stringList(change.affectedCiIds),
    linkedAssetIds: stringList(change.affectedAssetIds),
    workflowDefinitionId: normalizeString(change.workflowDefinitionId),
    workflowVersion: positiveInteger(change.workflowVersion),
    createdAt: change.createdAt || null,
    updatedAt: change.updatedAt || change.createdAt || null,
    updatedBy: normalizeString(change.updatedByUserId || change.createdByUserId),
    dueAt: change.approvalDueAt || change.plannedEndAt || null,
    closedAt: change.closedAt || change.cancelledAt || null,
    confidentiality: 'internal',
    selfServiceVisible: true,
    route: canonicalChangeRoute(changeId),
  }, { merge: false });
}

function writeCalendarProjection({ transaction, db, changeId, change }) {
  if (!change.plannedStartAt || !change.plannedEndAt) return;
  const status = statusOf(change);
  transaction.set(db.collection('changeCalendarEntries').doc(changeId), {
    changeId,
    changeNumber: normalizeString(change.changeNumber),
    title: normalizeString(change.title),
    requesterId: normalizeString(change.requesterId),
    ownerUserId: normalizeString(change.ownerUserId),
    changeType: normalizeString(change.changeType),
    status,
    risk: normalizeString(change.risk),
    plannedStartAt: change.plannedStartAt,
    plannedEndAt: change.plannedEndAt,
    expectedDowntimeMinutes: Number(change.expectedDowntimeMinutes || 0),
    affectedServiceIds: stringList(change.affectedServiceIds),
    affectedCiIds: stringList(change.affectedCiIds),
    maintenanceWindowId: normalizeString(change.maintenanceWindowId),
    publishMaintenance: change.publishMaintenance === true,
    hasConflict: change.hasConflict === true,
    conflictCount: Number(change.conflictCount || 0),
    isActive: !TERMINAL_STATUSES.includes(status),
    route: canonicalChangeRoute(changeId),
    calendarRoute: canonicalCalendarRoute(changeId),
    updatedAt: change.updatedAt || null,
  }, { merge: false });
}

function writeNotification(transaction, db, event) {
  if (!event) return;
  transaction.create(db.collection('notificationEvents').doc(event.id), event.data);
}

async function readChange(transaction, db, changeId) {
  const ref = db.collection('changeRequests').doc(changeId);
  const snapshot = await transaction.get(ref);
  return {
    ref,
    change: requireDocument(snapshot, 'The change request does not exist.'),
  };
}

function requireCommandRole(actor, command) {
  const allowed = CHANGES_COMMAND_ALLOWED_ROLES[command] || [];
  if (!actor || !normalizeString(actor.uid) || !allowed.includes(actor.role)) {
    throw denied('Your ITSM role does not allow this change command.');
  }
}

function requireRequester(change, actor) {
  if (normalizeString(change.requesterId) !== actor.uid) {
    throw denied('Only the requester can modify this self-service change.');
  }
}

function requireStatus(change, allowedStatuses) {
  const status = statusOf(change);
  if (!allowedStatuses.includes(status)) {
    throw failed(`A change in ${status || 'an unknown state'} cannot perform this action.`);
  }
}

function requireRevision(change, expectedRevision) {
  if (Number(change.revision) !== expectedRevision) {
    throw new ItsmCommandError(
      'aborted',
      'The change was updated after it was loaded. Refresh and try again.',
    );
  }
}

function requireDraftFields(change) {
  for (const field of ['title', 'description', 'justification', 'changeType']) {
    if (!normalizeString(change[field])) throw failed(`${field} is required before submission.`);
  }
}

function requireAssessment(change) {
  const required = [
    'ownerUserId',
    'impact',
    'urgency',
    'complexity',
    'risk',
    'implementationPlan',
    'testPlan',
    'communicationPlan',
    'rollbackPlan',
  ];
  const missing = required.filter((field) => !normalizeString(change[field]));
  if (stringList(change.affectedServiceIds).length === 0) missing.push('affectedServiceIds');
  if (missing.length > 0) {
    throw new ItsmCommandError(
      'failed-precondition',
      'The change assessment is incomplete.',
      { missingFields: missing },
    );
  }
}

function revisionPatch(fieldValue, actor, expectedRevision, values) {
  return {
    ...values,
    revision: expectedRevision + 1,
    updatedAt: fieldValue.serverTimestamp(),
    updatedByUserId: actor.uid,
  };
}

function auditSnapshot(change) {
  return {
    status: statusOf(change),
    revision: Number(change.revision || 0),
    changeType: normalizeString(change.changeType),
    ownerUserId: normalizeString(change.ownerUserId),
    impact: normalizeString(change.impact),
    urgency: normalizeString(change.urgency),
    complexity: normalizeString(change.complexity),
    risk: normalizeString(change.risk),
    riskScore: change.riskScore === null || change.riskScore === undefined
      ? null
      : Number(change.riskScore),
    affectedServiceIds: stringList(change.affectedServiceIds),
    affectedCiIds: stringList(change.affectedCiIds),
    affectedAssetIds: stringList(change.affectedAssetIds),
  };
}

function meetingAudit(meeting) {
  return {
    meetingId: normalizeString(meeting.meetingId),
    approvalGroupId: normalizeString(meeting.approvalGroupId),
    participantUserIds: stringList(meeting.participantUserIds),
    scheduledStartAt: meeting.scheduledStartAt || null,
    scheduledEndAt: meeting.scheduledEndAt || null,
    decisionDeadlineAt: meeting.decisionDeadlineAt || null,
  };
}

function result(changeId, changeNumber, status, revision) {
  return { changeId, changeNumber, status, revision };
}

function statusOf(change) {
  return normalizeString(change && change.status).toLowerCase();
}

function buildChangeNumber(now, receiptId) {
  const date = now.toISOString().slice(0, 10).replaceAll('-', '');
  return `CHG-${date}-${receiptId.slice(0, 6).toUpperCase()}`;
}

function deterministicId(prefix, ...parts) {
  const hash = crypto.createHash('sha256')
    .update(parts.map(normalizeString).join('|'))
    .digest('hex');
  return `${prefix}_${hash}`;
}

function actorMap(actor) {
  return {
    userId: actor.uid,
    name: actor.displayName || '',
    email: actor.email || '',
    role: actor.role,
  };
}

function agentName(agent) {
  return [agent.firstName, agent.name, agent.postName]
    .map(normalizeString)
    .filter(Boolean)
    .join(' ');
}

function trustedNow(timestamp) {
  if (!timestamp || typeof timestamp.now !== 'function') {
    throw new TypeError('A trusted timestamp dependency is required.');
  }
  const value = timestamp.now();
  const date = toDate(value);
  if (!date) throw new TypeError('timestamp.now() returned an invalid value.');
  return date;
}

function serverDate(timestamp, date) {
  if (typeof timestamp.fromDate === 'function') return timestamp.fromDate(date);
  return new Date(date.getTime());
}

function toDate(value) {
  if (!value) return null;
  if (value instanceof Date) return Number.isNaN(value.getTime()) ? null : new Date(value);
  if (typeof value.toDate === 'function') return toDate(value.toDate());
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date;
}

function addHours(date, hours) {
  return new Date(date.getTime() + hours * 60 * 60 * 1000);
}

function boundedHours(value, minimum, maximum) {
  const number = Number(value);
  if (!Number.isFinite(number)) return minimum;
  return Math.min(maximum, Math.max(minimum, Math.floor(number)));
}

function positiveInteger(value) {
  const number = Number(value);
  return Number.isSafeInteger(number) && number > 0 ? number : null;
}

function stringList(value) {
  return [...new Set((Array.isArray(value) ? value : [])
    .map(normalizeString)
    .filter(Boolean))];
}

function intersects(values, candidateValues) {
  return stringList(candidateValues).some((value) => values.has(value));
}

function requireDocument(snapshot, message) {
  if (!snapshot || !snapshot.exists) throw new ItsmCommandError('not-found', message);
  return snapshot.data() || {};
}

function invalid(message) {
  return new ItsmCommandError('invalid-argument', message);
}

function failed(message) {
  return new ItsmCommandError('failed-precondition', message);
}

function denied(message) {
  return new ItsmCommandError('permission-denied', message);
}

module.exports = {
  MANAGER_CANCELLABLE_STATUSES,
  SELF_SERVICE_CANCELLABLE_STATUSES,
  TERMINAL_STATUSES,
  calculateChangeRisk,
  createServiceDependencies,
  executeChangesCommand,
  findCalendarConflicts,
  getPinnedWorkflowVersion,
  resolveApprovalGroup,
  resolveManagerAgent,
  resolvePublishedWorkflowVersion,
};
