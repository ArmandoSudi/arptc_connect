'use strict';

const {
  ITSM_ROLES,
  ItsmCommandError,
  normalizeString,
  resolveItsmRole,
} = require('./itsm_permissions');
const { runIdempotentCommand } = require('./itsm_idempotency');
const {
  SECURITY_COMPLIANCE_ALLOWED_ROLES,
  SECURITY_COMPLIANCE_COMMANDS: COMMANDS,
} = require('./itsm_security_compliance_validation');
const {
  buildOwnDeviceComplianceProjection,
  buildSecurityWorkItemIndex,
  complianceResult,
  deterministicId,
} = require('./itsm_security_compliance_projections');
const {
  canonicalRoute,
  notificationForAction,
} = require('./itsm_security_compliance_notifications');

async function executeSecurityComplianceCommand({
  db,
  fieldValue,
  timestamp,
  actor,
  command,
  dependencies = {},
}) {
  requireCommandRole(actor, command.command);
  const services = {
    resolveAgent,
    resolveAsset,
    resolveSecurityApprovalGroup,
    ...dependencies,
  };
  return runIdempotentCommand({
    db,
    fieldValue,
    actorUid: actor.uid,
    command: command.command,
    idempotencyKey: command.idempotencyKey,
    execute: async (transaction, receiptId) => {
      const context = {
        db, fieldValue, timestamp, transaction, actor, command, receiptId, services,
      };
      switch (command.command) {
        case COMMANDS.createFinding: return createFinding(context);
        case COMMANDS.triageFinding: return triageFinding(context);
        case COMMANDS.assignFinding: return assignFinding(context);
        case COMMANDS.planRemediation: return planRemediation(context);
        case COMMANDS.submitFindingValidation: return submitFindingValidation(context);
        case COMMANDS.validateFinding: return validateFinding(context);
        case COMMANDS.acceptFindingRisk: return acceptFindingRisk(context);
        case COMMANDS.closeFinding: return closeFinding(context);
        case COMMANDS.cancelFinding: return cancelFinding(context);
        case COMMANDS.createException: return createException(context);
        case COMMANDS.submitException: return submitException(context);
        case COMMANDS.requestExceptionApproval: return requestExceptionApproval(context);
        case COMMANDS.decideExceptionApproval: return decideExceptionApproval(context);
        case COMMANDS.activateException: return activateException(context);
        case COMMANDS.renewException: return renewException(context);
        case COMMANDS.closeException: return closeException(context);
        case COMMANDS.assessCompliance: return assessCompliance(context);
        case COMMANDS.createReviewCampaign: return createReviewCampaign(context);
        case COMMANDS.activateReviewCampaign: return transitionCampaign(context, 'draft', 'active');
        case COMMANDS.completeReviewCampaign: return completeReviewCampaign(context);
        case COMMANDS.createReviewItem: return createReviewItem(context);
        case COMMANDS.decideReviewItem: return decideReviewItem(context);
        case COMMANDS.requestAccessCorrection: return requestAccessCorrection(context);
        case COMMANDS.completeRevocationTask: return completeRevocationTask(context);
        default: throw invalid('Unsupported security command.');
      }
    },
  });
}

function createFinding(context) {
  const { db, fieldValue, transaction, actor, command, receiptId } = context;
  const p = command.payload;
  const id = p.findingId || generatedId('finding', receiptId);
  const ref = db.collection('securityFindings').doc(id);
  const time = fieldValue.serverTimestamp();
  const doc = {
    id,
    reference: reference('SECF', receiptId),
    title: p.title,
    description: p.description,
    source: p.source,
    severity: p.severity,
    risk: p.risk,
    status: 'detected',
    lifecycleState: 'active',
    confidentiality: p.confidentiality,
    affectedAssetIds: p.affectedAssetIds,
    affectedCiIds: p.affectedCiIds,
    affectedServiceIds: p.affectedServiceIds,
    relatedIncidentId: p.relatedIncidentId,
    relatedChangeId: p.relatedChangeId,
    dueAt: serverDate(context, p.dueAt),
    ownerUserId: null,
    remediationPlan: '',
    remediationLinks: [],
    validationResult: 'not_assessed',
    revision: 0,
    createdAt: time,
    createdByUserId: actor.uid,
    updatedAt: time,
    updatedByUserId: actor.uid,
  };
  transaction.create(ref, doc);
  writeIndex(context, 'security_finding', id, doc);
  writeAudit(context, ref, 'security_finding', id, 'created', {}, auditView(doc));
  return result('findingId', id, doc.status, 0, doc.reference);
}

async function triageFinding(context) {
  return updateFinding(context, ['detected', 'triaged'], 'triaged', 'triaged', (p) => ({
    severity: p.severity,
    risk: p.risk,
    dueAt: serverDate(context, p.dueAt),
  }));
}

async function assignFinding(context) {
  const owner = await context.services.resolveAgent({
    db: context.db,
    transaction: context.transaction,
    userId: context.command.payload.ownerUserId,
    requireManager: true,
  });
  return updateFinding(context, ['triaged'], 'assigned', 'assigned', () => ({
    ownerUserId: owner.uid,
    ownerName: owner.displayName,
    ownerEmail: owner.email,
    assignedAt: context.fieldValue.serverTimestamp(),
  }), { notify: true });
}

async function planRemediation(context) {
  const finding = await read(
    context,
    'securityFindings',
    context.command.payload.findingId,
  );
  if (!finding.data.ownerUserId || !finding.data.dueAt) {
    throw failed('Remediation requires an assigned owner and due date.');
  }
  return updateFinding(context, ['assigned', 'remediation'], 'remediation', 'remediation_planned', (p) => ({
    remediationPlan: p.remediationPlan,
    remediationLinks: p.remediationLinks,
  }));
}

async function submitFindingValidation(context) {
  return updateFinding(context, ['remediation'], 'validation', 'validation_requested', (p) => ({
    remediationSubmissionComment: p.comment,
    validationResult: 'not_assessed',
  }), { notify: true });
}

async function validateFinding(context) {
  const p = context.command.payload;
  const next = p.result === 'passed' ? 'closed' : 'remediation';
  return updateFinding(context, ['validation'], next, p.result === 'passed' ? 'closed' : 'validation_failed', () => ({
    validationResult: p.result,
    validationComment: p.comment,
    validatedAt: context.fieldValue.serverTimestamp(),
    validatedByUserId: context.actor.uid,
    closedAt: p.result === 'passed' ? context.fieldValue.serverTimestamp() : null,
    lifecycleState: p.result === 'passed' ? 'closed' : 'active',
  }), { notify: true });
}

async function acceptFindingRisk(context) {
  return updateFinding(context, ['triaged', 'assigned', 'remediation'], 'risk_accepted', 'risk_accepted', (p) => ({
    riskAcceptanceReason: p.reason,
    riskAcceptanceExpiresAt: serverDate(context, p.expiresAt),
    riskAcceptedAt: context.fieldValue.serverTimestamp(),
    riskAcceptedByUserId: context.actor.uid,
  }));
}

async function closeFinding(context) {
  return updateFinding(context, ['risk_accepted'], 'closed', 'closed', (p) => ({
    closureComment: p.comment,
    closedAt: context.fieldValue.serverTimestamp(),
    lifecycleState: 'closed',
  }), { notify: true });
}

async function cancelFinding(context) {
  return updateFinding(context, ['detected', 'triaged', 'assigned', 'remediation'], 'cancelled', 'cancelled', (p) => ({
    cancellationReason: p.reason,
    cancelledAt: context.fieldValue.serverTimestamp(),
    lifecycleState: 'cancelled',
  }));
}

async function updateFinding(context, allowed, nextStatus, action, patchBuilder, options = {}) {
  const p = context.command.payload;
  const { ref, data } = await read(context, 'securityFindings', p.findingId);
  revision(data, p.expectedRevision);
  status(data, allowed);
  const patch = revisionPatch(context, p.expectedRevision, {
    ...patchBuilder(p, data),
    status: nextStatus,
  });
  context.transaction.update(ref, patch);
  const updated = { ...data, ...patch };
  writeIndex(context, 'security_finding', p.findingId, updated);
  writeAudit(context, ref, 'security_finding', p.findingId, action, auditView(data), auditView(updated));
  if (options.notify) writeNotification(context, action, 'security_finding', p.findingId, updated);
  return result('findingId', p.findingId, nextStatus, patch.revision, data.reference);
}

function createException(context) {
  const { db, fieldValue, transaction, actor, command, receiptId } = context;
  const p = command.payload;
  validateDateWindow(p.requestedStartAt, p.requestedEndAt, p.reviewAt);
  const id = p.exceptionId || generatedId('exception', receiptId);
  const ref = db.collection('securityExceptions').doc(id);
  const time = fieldValue.serverTimestamp();
  const doc = {
    id,
    reference: reference('SECX', receiptId),
    title: p.title,
    requirementOrControl: p.requirementOrControl,
    businessJustification: p.businessJustification,
    scope: p.scope,
    affectedAssetId: p.affectedAssetId,
    affectedServiceId: p.affectedServiceId,
    affectedUserId: p.affectedUserId,
    riskDescription: p.riskDescription,
    compensatingControls: p.compensatingControls,
    requesterId: actor.uid,
    requesterName: actor.displayName,
    requesterEmail: actor.email,
    requester: {
      userId: actor.uid,
      name: actor.displayName,
      email: actor.email,
    },
    selfServiceVisible: true,
    status: 'draft',
    lifecycleState: 'active',
    requestedStartAt: serverDate(context, p.requestedStartAt),
    requestedEndAt: serverDate(context, p.requestedEndAt),
    reviewAt: serverDate(context, p.reviewAt),
    confidentiality: p.confidentiality,
    renewalNumber: 0,
    revision: 0,
    createdAt: time,
    createdByUserId: actor.uid,
    updatedAt: time,
    updatedByUserId: actor.uid,
  };
  transaction.create(ref, doc);
  writeIndex(context, 'security_exception', id, doc);
  writeAudit(context, ref, 'security_exception', id, 'created', {}, auditView(doc));
  return result('exceptionId', id, 'draft', 0, doc.reference);
}

async function submitException(context) {
  const p = context.command.payload;
  const record = await read(context, 'securityExceptions', p.exceptionId);
  requireOwnerOrManager(record.data, context.actor);
  return updateException(context, record, ['draft'], 'submitted', 'submitted', {
    submittedAt: context.fieldValue.serverTimestamp(),
  }, true);
}

async function requestExceptionApproval(context) {
  const p = context.command.payload;
  const record = await read(context, 'securityExceptions', p.exceptionId);
  const group = p.approverGroupId
    ? await context.services.resolveSecurityApprovalGroup({
        db: context.db,
        transaction: context.transaction,
        groupId: p.approverGroupId,
      })
    : null;
  const expandedApprovers = [...new Set([
    ...p.approverUserIds,
    ...((group && group.memberUserIds) || []),
  ])];
  const approvers = expandedApprovers.filter(
    (userId) => userId !== record.data.requesterId,
  );
  if (approvers.length === 0) {
    throw failed(expandedApprovers.includes(record.data.requesterId)
      ? 'The requester cannot be the sole exception approver.'
      : 'At least one independent approver is required.');
  }
  for (const userId of approvers) {
    await context.services.resolveAgent({ db: context.db, transaction: context.transaction, userId, requireManager: true });
  }
  const approvalId = p.approvalId || generatedId('approval', context.receiptId);
  const approvalRef = record.ref.collection('approvals').doc(approvalId);
  const approval = {
    id: approvalId,
    exceptionId: p.exceptionId,
    status: 'pending',
    approverUserIds: approvers,
    approverGroupId: p.approverGroupId,
    requestedAt: context.fieldValue.serverTimestamp(),
    requestedByUserId: context.actor.uid,
  };
  context.transaction.create(approvalRef, approval);
  return updateException(context, record, ['submitted', 'under_review'], 'awaiting_approval', 'approval_requested', {
    currentApprovalId: approvalId,
    approvalRequestedAt: context.fieldValue.serverTimestamp(),
  }, true);
}

async function decideExceptionApproval(context) {
  const p = context.command.payload;
  const record = await read(context, 'securityExceptions', p.exceptionId);
  revision(record.data, p.expectedRevision);
  status(record.data, ['awaiting_approval']);
  if (record.data.requesterId === context.actor.uid) {
    throw denied('The requester cannot approve their own security exception.');
  }
  const approvalRef = record.ref.collection('approvals').doc(p.approvalId);
  const snapshot = await context.transaction.get(approvalRef);
  const approval = requireDocument(snapshot, 'The exception approval does not exist.');
  if (approval.status !== 'pending') throw failed('The approval was already decided.');
  if (!(approval.approverUserIds || []).includes(context.actor.uid)) {
    throw denied('Only a designated independent approver can decide this approval.');
  }
  context.transaction.update(approvalRef, {
    status: p.decision,
    comment: p.comment,
    decidedAt: context.fieldValue.serverTimestamp(),
    decidedByUserId: context.actor.uid,
  });
  writeApprovalHistory(context, record.ref, p.exceptionId, p.approvalId, p.decision, p.comment);
  return updateException(context, record, ['awaiting_approval'], p.decision, p.decision, {
    approvalDecision: p.decision,
    approvalComment: p.comment,
    approvalDecidedAt: context.fieldValue.serverTimestamp(),
    approvalDecidedByUserId: context.actor.uid,
  }, true);
}

async function activateException(context) {
  const p = context.command.payload;
  const record = await read(context, 'securityExceptions', p.exceptionId);
  return updateException(context, record, ['approved'], 'active', 'activated', {
    activatedAt: context.fieldValue.serverTimestamp(),
  }, true);
}

async function renewException(context) {
  const p = context.command.payload;
  const record = await read(context, 'securityExceptions', p.exceptionId);
  revision(record.data, p.expectedRevision);
  status(record.data, ['approved', 'active', 'expired']);
  requireOwnerOrManager(record.data, context.actor);
  validateDateWindow(p.requestedStartAt, p.requestedEndAt, p.reviewAt);
  const previousEnd = toDate(record.data.requestedEndAt);
  if (previousEnd && p.requestedEndAt <= previousEnd) {
    throw failed('A renewal must extend the current exception end date.');
  }
  if (previousEnd && p.reviewAt < previousEnd) {
    throw failed('A renewal review date cannot precede the current end date.');
  }
  const id = p.newExceptionId || generatedId('exception', context.receiptId);
  const ref = context.db.collection('securityExceptions').doc(id);
  const time = context.fieldValue.serverTimestamp();
  const doc = {
    ...copyExceptionForRenewal(record.data),
    id,
    reference: reference('SECX', context.receiptId),
    businessJustification: p.businessJustification,
    requestedStartAt: serverDate(context, p.requestedStartAt),
    requestedEndAt: serverDate(context, p.requestedEndAt),
    reviewAt: serverDate(context, p.reviewAt),
    status: 'draft',
    lifecycleState: 'active',
    selfServiceVisible: true,
    requester: record.data.requester || {
      userId: record.data.requesterId,
      name: normalizeString(record.data.requesterName),
      email: normalizeString(record.data.requesterEmail).toLowerCase(),
    },
    renewedFromExceptionId: p.exceptionId,
    renewalNumber: Number(record.data.renewalNumber || 0) + 1,
    revision: 0,
    createdAt: time,
    createdByUserId: context.actor.uid,
    updatedAt: time,
    updatedByUserId: context.actor.uid,
  };
  context.transaction.create(ref, doc);
  writeIndex(context, 'security_exception', id, doc);
  writeAudit(context, ref, 'security_exception', id, 'renewal_created', {}, auditView(doc));
  writeAudit(context, record.ref, 'security_exception', p.exceptionId, 'renewed', {}, { renewedAsExceptionId: id });
  return result('exceptionId', id, 'draft', 0, doc.reference);
}

async function closeException(context) {
  const p = context.command.payload;
  const record = await read(context, 'securityExceptions', p.exceptionId);
  requireOwnerOrManager(record.data, context.actor);
  const allowed = context.actor.role === ITSM_ROLES.manager
    ? ['draft', 'submitted', 'under_review', 'awaiting_approval', 'approved', 'rejected', 'active', 'expired']
    : ['draft', 'submitted'];
  return updateException(context, record, allowed, 'closed', 'closed', {
    closureReason: p.reason,
    closedAt: context.fieldValue.serverTimestamp(),
    lifecycleState: 'closed',
  }, true);
}

function updateException(context, record, allowed, next, action, extra, notify) {
  const p = context.command.payload;
  revision(record.data, p.expectedRevision);
  status(record.data, allowed);
  const patch = revisionPatch(context, p.expectedRevision, { ...extra, status: next });
  context.transaction.update(record.ref, patch);
  const updated = { ...record.data, ...patch };
  writeIndex(context, 'security_exception', p.exceptionId, updated);
  writeAudit(context, record.ref, 'security_exception', p.exceptionId, action, auditView(record.data), auditView(updated));
  if (notify) writeNotification(context, action, 'security_exception', p.exceptionId, updated);
  return result('exceptionId', p.exceptionId, next, patch.revision, record.data.reference);
}

async function assessCompliance(context) {
  const p = context.command.payload;
  const asset = await context.services.resolveAsset({ db: context.db, transaction: context.transaction, assetId: p.assetId });
  const resultValue = complianceResult(p.checks);
  if (resultValue === 'non_compliant' && !p.remediationRequestId &&
      !p.remediationChangeId && !p.remediationSummary) {
    throw failed('A non-compliant assessment requires remediation tracking.');
  }
  const id = p.assessmentId || generatedId('assessment', context.receiptId);
  const ref = context.db.collection('assetComplianceAssessments').doc(id);
  const time = context.fieldValue.serverTimestamp();
  const assignedUserId = normalizeString(asset.assignedUserId);
  const document = {
    id,
    assetId: p.assetId,
    assetTag: normalizeString(asset.assetTag || p.assetTag),
    assetName: normalizeString(asset.name || asset.assetName || p.assetName),
    assignedUserId: assignedUserId || null,
    assignedUserName: assignedUserId ? normalizeString(asset.assignedUserName || p.assignedUserName) : '',
    assessedByUserId: context.actor.uid,
    assessedAt: time,
    nextAssessmentAt: serverDate(context, p.nextAssessmentAt),
    result: resultValue,
    checks: p.checks.map((check) => ({ ...check, assessedAt: time, assessedByUserId: context.actor.uid })),
    evidenceIds: p.evidenceIds,
    remediationRequestId: p.remediationRequestId,
    remediationChangeId: p.remediationChangeId,
    remediationSummary: p.remediationSummary,
    createdAt: time,
    updatedAt: time,
    updatedByUserId: context.actor.uid,
  };
  context.transaction.create(ref, document);
  const projection = buildOwnDeviceComplianceProjection(document, time);
  if (projection) {
    context.transaction.set(
      context.db.collection('assetComplianceSelfService').doc(projection.id),
      projection.data,
      { merge: false },
    );
  }
  writeAudit(context, ref, 'compliance_assessment', id, 'assessed', {}, {
    assetId: p.assetId,
    result: resultValue,
    projectionId: projection && projection.id,
  });
  return { assessmentId: id, assetId: p.assetId, result: resultValue, projectionId: projection && projection.id };
}

async function createReviewCampaign(context) {
  const p = context.command.payload;
  if (p.dueAt <= p.startsAt) throw failed('Campaign dueAt must be after startsAt.');
  await context.services.resolveAgent({ db: context.db, transaction: context.transaction, userId: p.ownerUserId, requireManager: true });
  for (const userId of p.reviewerUserIds) {
    await context.services.resolveAgent({ db: context.db, transaction: context.transaction, userId, requireManager: true });
  }
  const id = p.campaignId || generatedId('campaign', context.receiptId);
  const ref = context.db.collection('accessReviewCampaigns').doc(id);
  const time = context.fieldValue.serverTimestamp();
  const document = {
    id,
    reference: reference('ARCV', context.receiptId),
    title: p.title,
    scope: p.scope,
    systemId: p.systemId,
    systemName: p.systemName,
    ownerUserId: p.ownerUserId,
    status: 'draft',
    startsAt: serverDate(context, p.startsAt),
    dueAt: serverDate(context, p.dueAt),
    allowSelfServiceCorrection: p.allowSelfServiceCorrection,
    reviewerUserIds: p.reviewerUserIds,
    departmentIds: p.departmentIds,
    revision: 0,
    createdAt: time,
    createdByUserId: context.actor.uid,
    updatedAt: time,
    updatedByUserId: context.actor.uid,
  };
  context.transaction.create(ref, document);
  writeAudit(context, ref, 'access_review_campaign', id, 'created', {}, auditView(document));
  return result('campaignId', id, 'draft', 0, document.reference);
}

async function transitionCampaign(context, from, to) {
  const p = context.command.payload;
  const record = await read(context, 'accessReviewCampaigns', p.campaignId);
  revision(record.data, p.expectedRevision);
  status(record.data, [from]);
  if (to === 'active' && !(record.data.reviewerUserIds || []).length) {
    throw failed('An active campaign requires at least one reviewer.');
  }
  const patch = revisionPatch(context, p.expectedRevision, {
    status: to,
    [`${to}At`]: context.fieldValue.serverTimestamp(),
  });
  context.transaction.update(record.ref, patch);
  writeAudit(context, record.ref, 'access_review_campaign', p.campaignId, to, auditView(record.data), auditView({ ...record.data, ...patch }));
  return result('campaignId', p.campaignId, to, patch.revision, record.data.reference);
}

async function completeReviewCampaign(context) {
  const p = context.command.payload;
  const record = await read(context, 'accessReviewCampaigns', p.campaignId);
  revision(record.data, p.expectedRevision);
  status(record.data, ['active']);
  const pending = await context.transaction.get(
    record.ref.collection('items').where('completionStatus', '!=', 'completed').limit(1),
  );
  if (pending.docs && pending.docs.length > 0) {
    throw failed('All access review items must be completed first.');
  }
  return transitionCampaignWithRecord(context, record, 'completed');
}

function transitionCampaignWithRecord(context, record, to) {
  const p = context.command.payload;
  const patch = revisionPatch(context, p.expectedRevision, { status: to, completedAt: context.fieldValue.serverTimestamp() });
  context.transaction.update(record.ref, patch);
  writeAudit(context, record.ref, 'access_review_campaign', p.campaignId, to, auditView(record.data), auditView({ ...record.data, ...patch }));
  return result('campaignId', p.campaignId, to, patch.revision, record.data.reference);
}

async function createReviewItem(context) {
  const p = context.command.payload;
  const campaign = await read(context, 'accessReviewCampaigns', p.campaignId);
  status(campaign.data, ['draft', 'active']);
  if (!(campaign.data.reviewerUserIds || []).includes(p.reviewerUserId)) {
    throw failed('The reviewer must belong to the campaign reviewer list.');
  }
  const subject = await context.services.resolveAgent({ db: context.db, transaction: context.transaction, userId: p.subjectUserId });
  const reviewer = await context.services.resolveAgent({ db: context.db, transaction: context.transaction, userId: p.reviewerUserId, requireManager: true });
  const id = p.itemId || generatedId('review_item', context.receiptId);
  const ref = context.db.collection('accessReviewItems').doc(id);
  const time = context.fieldValue.serverTimestamp();
  const document = {
    id,
    reference: `${campaign.data.reference || p.campaignId}-${id.slice(-6).toUpperCase()}`,
    campaignId: p.campaignId,
    systemId: campaign.data.systemId,
    systemName: campaign.data.systemName,
    subjectUserId: subject.uid,
    subjectUserName: subject.displayName,
    subjectUserEmail: subject.email,
    subjectUser: {
      userId: subject.uid,
      name: subject.displayName,
      email: subject.email,
    },
    currentAccess: p.currentAccess,
    currentRole: p.currentRole,
    departmentId: p.departmentId,
    departmentName: p.departmentName,
    reviewerUserId: reviewer.uid,
    reviewerName: reviewer.displayName,
    decision: 'pending',
    status: 'pending',
    lifecycleState: 'active',
    selfServiceVisible: true,
    completionStatus: 'pending',
    dueAt: serverDate(context, p.dueAt),
    revision: 0,
    createdAt: time,
    createdByUserId: context.actor.uid,
    updatedAt: time,
    updatedByUserId: context.actor.uid,
  };
  context.transaction.create(ref, document);
  context.transaction.create(campaign.ref.collection('items').doc(id), {
    itemId: id,
    completionStatus: 'pending',
    createdAt: time,
  });
  writeAudit(context, ref, 'access_review_item', id, 'created', {}, auditView(document));
  return result('itemId', id, 'pending', 0, document.reference);
}

async function decideReviewItem(context) {
  const p = context.command.payload;
  const record = await read(context, 'accessReviewItems', p.itemId);
  revision(record.data, p.expectedRevision);
  if (record.data.decision !== 'pending') throw failed('The access review item was already decided.');
  if (record.data.reviewerUserId !== context.actor.uid) {
    throw denied('Only the assigned MANAGER reviewer can decide this item.');
  }
  const needsTask = ['revoke', 'modify'].includes(p.decision);
  if (needsTask && (!p.assignedToUserId || !p.taskDueAt)) {
    throw failed('Revoke and modify decisions require an assigned revocation task.');
  }
  if (p.decision === 'modify' && !p.targetAccess) {
    throw failed('A modify decision requires targetAccess.');
  }
  let taskId = null;
  if (needsTask) {
    const assignee = await context.services.resolveAgent({ db: context.db, transaction: context.transaction, userId: p.assignedToUserId, requireManager: true });
    taskId = generatedId('revocation', context.receiptId);
    context.transaction.create(context.db.collection('accessRevocationTasks').doc(taskId), {
      id: taskId,
      accessReviewItemId: p.itemId,
      campaignId: record.data.campaignId,
      subjectUserId: record.data.subjectUserId,
      action: p.decision,
      targetAccess: p.targetAccess,
      status: 'pending',
      assignedToUserId: assignee.uid,
      assignedToName: assignee.displayName,
      dueAt: serverDate(context, p.taskDueAt),
      revision: 0,
      createdAt: context.fieldValue.serverTimestamp(),
      createdByUserId: context.actor.uid,
    });
  }
  const completionStatus = needsTask ? 'revocation_pending' : 'completed';
  const patch = revisionPatch(context, p.expectedRevision, {
    decision: p.decision,
    status: 'decided',
    justification: p.justification,
    decidedAt: context.fieldValue.serverTimestamp(),
    decidedByUserId: context.actor.uid,
    revocationTaskId: taskId,
    completionStatus,
  });
  context.transaction.update(record.ref, patch);
  context.transaction.set(
    context.db.collection('accessReviewCampaigns').doc(record.data.campaignId).collection('items').doc(p.itemId),
    { completionStatus, updatedAt: context.fieldValue.serverTimestamp() },
    { merge: true },
  );
  writeAudit(context, record.ref, 'access_review_item', p.itemId, 'decided', auditView(record.data), auditView({ ...record.data, ...patch }));
  if (needsTask) writeNotification(context, 'revocation_assigned', 'access_review_item', p.itemId, { ...record.data, ...patch, ownerUserId: p.assignedToUserId });
  return { itemId: p.itemId, decision: p.decision, completionStatus, revision: patch.revision, revocationTaskId: taskId };
}

async function requestAccessCorrection(context) {
  const p = context.command.payload;
  const item = await read(context, 'accessReviewItems', p.itemId);
  if (item.data.subjectUserId !== context.actor.uid) {
    throw denied('Only the access subject can request a correction.');
  }
  const campaign = await read(context, 'accessReviewCampaigns', item.data.campaignId);
  if (campaign.data.allowSelfServiceCorrection !== true || campaign.data.status !== 'active') {
    throw failed('Self-service correction is not available for this campaign.');
  }
  const id = generatedId('correction', context.receiptId);
  const ref = item.ref.collection('correctionRequests').doc(id);
  const document = {
    id,
    accessReviewItemId: p.itemId,
    campaignId: item.data.campaignId,
    subjectUserId: item.data.subjectUserId,
    subjectUser: item.data.subjectUser,
    requestedBy: context.actor.uid,
    requestedByUserId: context.actor.uid,
    requesterId: context.actor.uid,
    type: p.type,
    reason: p.reason,
    status: 'submitted',
    lifecycleState: 'active',
    selfServiceVisible: true,
    revision: 0,
    createdAt: context.fieldValue.serverTimestamp(),
    updatedAt: context.fieldValue.serverTimestamp(),
  };
  context.transaction.create(ref, document);
  writeAudit(context, item.ref, 'access_review_item', p.itemId, 'correction_requested', {}, { correctionRequestId: id, type: p.type });
  writeNotification(context, 'correction_requested', 'access_review_item', p.itemId, item.data);
  return { correctionRequestId: id, itemId: p.itemId, status: 'submitted' };
}

async function completeRevocationTask(context) {
  const p = context.command.payload;
  const task = await read(context, 'accessRevocationTasks', p.taskId);
  revision(task.data, p.expectedRevision);
  status(task.data, ['pending', 'in_progress']);
  if (task.data.assignedToUserId !== context.actor.uid) {
    throw denied('Only the assigned MANAGER can complete this revocation task.');
  }
  const patch = revisionPatch(context, p.expectedRevision, {
    status: 'completed',
    completionEvidenceId: p.completionEvidenceId,
    completionComment: p.comment,
    completedAt: context.fieldValue.serverTimestamp(),
    completedByUserId: context.actor.uid,
  });
  const item = await read(context, 'accessReviewItems', task.data.accessReviewItemId);
  context.transaction.update(task.ref, patch);
  context.transaction.update(item.ref, {
    completionStatus: 'completed',
    revision: Number(item.data.revision || 0) + 1,
    updatedAt: context.fieldValue.serverTimestamp(),
    updatedByUserId: context.actor.uid,
  });
  context.transaction.set(
    context.db.collection('accessReviewCampaigns').doc(task.data.campaignId).collection('items').doc(task.data.accessReviewItemId),
    { completionStatus: 'completed', updatedAt: context.fieldValue.serverTimestamp() },
    { merge: true },
  );
  writeAudit(context, task.ref, 'access_revocation_task', p.taskId, 'completed', auditView(task.data), auditView({ ...task.data, ...patch }));
  writeNotification(context, 'closed', 'access_review_item', task.data.accessReviewItemId, item.data);
  return { taskId: p.taskId, itemId: task.data.accessReviewItemId, status: 'completed', revision: patch.revision };
}

async function resolveAgent({ db, transaction, userId, requireManager = false }) {
  const snapshot = await transaction.get(db.collection('agents').doc(userId));
  const agent = requireDocument(snapshot, 'The selected agent does not exist.');
  if (agent.isActive === false) throw failed('The selected agent is inactive.');
  if (requireManager && resolveItsmRole(agent) !== ITSM_ROLES.manager) {
    throw failed('The selected agent must be an active ITSM MANAGER.');
  }
  return {
    uid: userId,
    displayName: [agent.firstName, agent.name, agent.postName].map(normalizeString).filter(Boolean).join(' '),
    email: normalizeString(agent.email).toLowerCase(),
  };
}

async function resolveAsset({ db, transaction, assetId }) {
  const snapshot = await transaction.get(db.collection('assets').doc(assetId));
  return requireDocument(snapshot, 'The selected asset does not exist.');
}

async function resolveSecurityApprovalGroup({ db, transaction, groupId }) {
  const snapshot = await transaction.get(
    db.collection('securityApprovalGroups').doc(groupId),
  );
  const group = requireDocument(
    snapshot,
    'The security approval group does not exist.',
  );
  if (group.isActive === false ||
      ['inactive', 'retired'].includes(
        normalizeString(group.status).toLowerCase(),
      )) {
    throw failed('The security approval group is inactive.');
  }
  const memberUserIds = [...new Set((group.memberUserIds || [])
    .map(normalizeString)
    .filter(Boolean))];
  if (memberUserIds.length === 0 || memberUserIds.length > 50) {
    throw failed(
      'The security approval group must contain 1-50 MANAGER users.',
    );
  }
  for (const userId of memberUserIds) {
    await resolveAgent({
      db,
      transaction,
      userId,
      requireManager: true,
    });
  }
  return { id: groupId, memberUserIds };
}

async function read(context, collection, id) {
  const ref = context.db.collection(collection).doc(id);
  const snapshot = await context.transaction.get(ref);
  return { ref, data: requireDocument(snapshot, `The ${collection} record does not exist.`) };
}

function writeAudit(context, parentRef, entityType, entityId, action, before = {}, after = {}) {
  const id = deterministicId('security_audit', context.receiptId, action, entityType, entityId);
  const requesterVisible = entityType === 'security_exception';
  const event = {
    eventType: `${entityType}.${action}`,
    action,
    entityType,
    entityId,
    actor: actorMap(context.actor),
    actorUserId: context.actor.uid,
    actorRole: context.actor.role,
    before,
    after,
    sourceCommand: context.command.command,
    sourceIdempotencyKey: context.command.idempotencyKey,
    correlationId: context.command.idempotencyKey,
    confidentiality: requesterVisible ? 'internal' : 'restricted',
    requesterVisible,
    isInternal: !requesterVisible,
    createdAt: context.fieldValue.serverTimestamp(),
  };
  context.transaction.create(parentRef.collection('auditLogs').doc(id), event);
  context.transaction.create(context.db.collection('itsmAuditEvents').doc(id), {
    ...event,
    sourcePath: parentRef.path,
  });
}

function writeApprovalHistory(context, parentRef, exceptionId, approvalId, decision, comment) {
  const id = deterministicId('security_approval_history', context.receiptId, decision);
  context.transaction.create(parentRef.collection('approvalHistory').doc(id), {
    id,
    exceptionId,
    approvalId,
    decision,
    comment,
    actor: actorMap(context.actor),
    sourceCommand: context.command.command,
    correlationId: context.command.idempotencyKey,
    occurredAt: context.fieldValue.serverTimestamp(),
  });
}

function writeIndex(context, type, id, document) {
  const projection = buildSecurityWorkItemIndex({
    type,
    id,
    document,
    route: canonicalRoute(type, id),
  });
  context.transaction.set(
    context.db.collection('itsmWorkItemIndex').doc(projection.id),
    projection.data,
    { merge: false },
  );
}

function writeNotification(context, action, type, id, document) {
  const notification = notificationForAction({
    action,
    entityType: type,
    entityId: id,
    document,
    actor: context.actor,
    sourceId: context.receiptId,
    createdAt: context.fieldValue.serverTimestamp(),
  });
  context.transaction.create(
    context.db.collection('notificationEvents').doc(notification.id),
    notification.data,
  );
}

function requireCommandRole(actor, command) {
  const allowed = SECURITY_COMPLIANCE_ALLOWED_ROLES[command] || [];
  if (!actor || !normalizeString(actor.uid) || !allowed.includes(actor.role)) {
    throw denied('Your ITSM role does not allow this security command.');
  }
}

function requireOwnerOrManager(document, actor) {
  if (actor.role !== ITSM_ROLES.manager && document.requesterId !== actor.uid) {
    throw denied('Only the requester or an ITSM MANAGER can perform this command.');
  }
}

function revision(document, expected) {
  if (Number(document.revision || 0) !== expected) {
    throw new ItsmCommandError('aborted', 'The record changed. Reload it and retry.', {
      expectedRevision: expected,
      actualRevision: Number(document.revision || 0),
    });
  }
}

function status(document, allowed) {
  const current = normalizeString(document.status).toLowerCase();
  if (!allowed.includes(current)) throw failed(`A record in ${current || 'unknown'} cannot perform this transition.`);
}

function revisionPatch(context, expected, patch) {
  return {
    ...patch,
    revision: expected + 1,
    updatedAt: context.fieldValue.serverTimestamp(),
    updatedByUserId: context.actor.uid,
  };
}

function validateDateWindow(start, end, review) {
  if (end <= start) throw failed('requestedEndAt must be after requestedStartAt.');
  if (review < start || review > end) throw failed('reviewAt must fall inside the requested period.');
}

function copyExceptionForRenewal(value) {
  return Object.fromEntries([
    'title', 'requirementOrControl', 'scope', 'affectedAssetId',
    'affectedServiceId', 'affectedUserId', 'riskDescription',
    'compensatingControls', 'requesterId', 'requesterName', 'requesterEmail',
    'confidentiality', 'requester', 'selfServiceVisible',
  ].map((key) => [key, value[key]])
    .filter((entry) => entry[1] !== undefined));
}

function auditView(document) {
  return {
    status: document.status || null,
    revision: Number(document.revision || 0),
    ownerUserId: document.ownerUserId || null,
    result: document.result || null,
    decision: document.decision || null,
  };
}

function actorMap(actor) {
  return { uid: actor.uid, email: actor.email, displayName: actor.displayName, role: actor.role };
}

function requireDocument(snapshot, message) {
  if (!snapshot || !snapshot.exists) throw new ItsmCommandError('not-found', message);
  return snapshot.data() || {};
}

function result(key, id, statusValue, revisionValue, referenceValue) {
  return { [key]: id, status: statusValue, revision: revisionValue, reference: referenceValue };
}

function serverDate(context, value) {
  if (!value) return null;
  return context.timestamp && typeof context.timestamp.fromDate === 'function'
    ? context.timestamp.fromDate(value)
    : value;
}

function toDate(value) {
  if (!value) return null;
  if (value instanceof Date) return value;
  if (typeof value.toDate === 'function') return value.toDate();
  const result = new Date(value);
  return Number.isNaN(result.getTime()) ? null : result;
}

function generatedId(prefix, receiptId) { return `${prefix}_${receiptId.slice(0, 24)}`; }
function reference(prefix, receiptId) { return `${prefix}-${receiptId.slice(0, 10).toUpperCase()}`; }
function invalid(message) { return new ItsmCommandError('invalid-argument', message); }
function failed(message) { return new ItsmCommandError('failed-precondition', message); }
function denied(message) { return new ItsmCommandError('permission-denied', message); }

module.exports = {
  executeSecurityComplianceCommand,
  resolveAgent,
  resolveAsset,
  resolveSecurityApprovalGroup,
};
