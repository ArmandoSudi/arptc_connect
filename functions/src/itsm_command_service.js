const {
  ITSM_COMMANDS,
  deepFreeze,
} = require('./itsm_command_validation');
const {
  ITSM_ROLES,
  ItsmCommandError,
  normalizeRole,
  normalizeString,
} = require('./itsm_permissions');
const {
  buildIdempotencyDocumentId,
  runIdempotentCommand,
} = require('./itsm_idempotency');

const COLLECTION_BY_ENTITY_TYPE = Object.freeze({
  incident: 'incidentTickets',
  service_request: 'serviceRequests',
  change_request: 'changeRequests',
  security_finding: 'securityFindings',
  security_exception: 'securityExceptions',
  asset: 'assets',
  configuration_item: 'configurationItems',
});

async function executeItsmCommand({
  db,
  fieldValue,
  actor,
  envelope,
}) {
  return runIdempotentCommand({
    db,
    fieldValue,
    actorUid: actor.uid,
    command: envelope.command,
    idempotencyKey: envelope.idempotencyKey,
    execute: async (transaction, receiptId) => {
      switch (envelope.command) {
        case ITSM_COMMANDS.transitionWorkItem:
          return transitionWorkItem({
            db,
            fieldValue,
            transaction,
            actor,
            envelope,
            receiptId,
          });
        case ITSM_COMMANDS.decideApproval:
          return decideApproval({
            db,
            fieldValue,
            transaction,
            actor,
            envelope,
            receiptId,
          });
        case ITSM_COMMANDS.indexAuditEvent:
          return indexAuditEvent({
            db,
            fieldValue,
            transaction,
            actor,
            envelope,
            receiptId,
          });
        case ITSM_COMMANDS.maintainWorkItemIndex:
          return maintainWorkItemIndex({
            db,
            fieldValue,
            transaction,
            actor,
            envelope,
          });
        case ITSM_COMMANDS.processSla:
          return processSlaHook({
            db,
            fieldValue,
            transaction,
            actor,
            envelope,
          });
        case ITSM_COMMANDS.createNotificationEvent:
          return createNotificationEvent({
            db,
            fieldValue,
            transaction,
            actor,
            envelope,
            receiptId,
          });
        default:
          throw new ItsmCommandError(
            'invalid-argument',
            `Unknown ITSM command: ${envelope.command}.`,
          );
      }
    },
  });
}

async function transitionWorkItem({
  db,
  fieldValue,
  transaction,
  actor,
  envelope,
  receiptId,
}) {
  const workItemRef = workItemReference(db, envelope);
  const workItemSnapshot = await transaction.get(workItemRef);
  requireExisting(workItemSnapshot, envelope);
  const workItem = workItemSnapshot.data() || {};

  if (
    actor.role === ITSM_ROLES.user &&
    !isSelfServiceOwner(workItem, actor)
  ) {
    throw new ItsmCommandError(
      'permission-denied',
      'A USER can transition only their own ITSM work item.',
    );
  }
  if (
    actor.role === ITSM_ROLES.admin &&
    (
      envelope.entityType !== 'service_request' ||
      !isSelfServiceOwner(workItem, actor)
    )
  ) {
    throw new ItsmCommandError(
      'permission-denied',
      'An ADMIN can transition only their own self-service request.',
    );
  }

  const currentRevision = Number.isInteger(workItem.workflowRevision)
    ? workItem.workflowRevision
    : 0;
  if (currentRevision !== envelope.payload.expectedRevision) {
    throw new ItsmCommandError(
      'aborted',
      'The work item changed after it was loaded. Refresh and try again.',
      { currentRevision },
    );
  }

  const workflowId = safeStoredIdentifier(
    workItem.workflowDefinitionId,
    'workflowDefinitionId',
  );
  const workflowVersion = safeStoredIdentifier(
    workItem.workflowVersionDocumentId || workItem.workflowVersion,
    'workflowVersion',
  );
  const workflowRef = db
    .collection('workflowDefinitions')
    .doc(workflowId)
    .collection('versions')
    .doc(workflowVersion);
  const workflowSnapshot = await transaction.get(workflowRef);
  if (!workflowSnapshot.exists) {
    throw new ItsmCommandError(
      'failed-precondition',
      'The pinned workflow version does not exist.',
    );
  }

  const currentState = normalizeString(workItem.workflowState || workItem.status);
  const transition = findTransition(
    workflowSnapshot.data() || {},
    envelope.payload.transitionId,
  );
  validateTransition({
    transition,
    currentState,
    requestedState: envelope.payload.toState,
    actorRole: actor.role,
    workItem,
  });
  if (actor.role === ITSM_ROLES.admin && !transition.selfServiceAllowed) {
    throw new ItsmCommandError(
      'permission-denied',
      'This transition is not available through self-service.',
    );
  }
  if (
    ['rejected', 'cancelled'].includes(
      normalizeString(transition.toState).toLowerCase(),
    ) &&
    !normalizeString(envelope.payload.reason)
  ) {
    throw new ItsmCommandError(
      'failed-precondition',
      'A reason is required for this terminal transition.',
    );
  }

  const timestamp = fieldValue.serverTimestamp();
  const nextRevision = currentRevision + 1;
  const patch = buildTransitionPatch({
    toState: transition.toState,
    reason: envelope.payload.reason,
    actor,
    timestamp,
    nextRevision,
  });
  transaction.update(workItemRef, patch);
  transaction.set(
    workItemRef.collection('workflowInstances').doc(
      normalizeString(workItem.workflowInstanceId) || 'current',
    ),
    {
      definitionId: workflowId,
      version: workItem.workflowVersion || null,
      versionDocumentId: workflowVersion,
      state: transition.toState,
      revision: nextRevision,
      updatedAt: timestamp,
      updatedByUserId: actor.uid,
    },
    { merge: true },
  );
  const updatedWorkItem = { ...workItem, ...patch };
  transaction.set(
    db.collection('itsmWorkItemIndex').doc(
      `${envelope.entityType}:${envelope.entityId}`,
    ),
    buildTrustedWorkItemSummary({
      actor,
      envelope,
      workItem: updatedWorkItem,
      sourcePath: workItemRef.path,
      updatedAt: timestamp,
    }),
    { merge: false },
  );

  const auditEvent = buildImmutableAuditEvent({
    actor,
    envelope,
    eventType: 'workflow.transitioned',
    action: transition.id,
    summary:
      envelope.payload.reason ||
      `Transitioned from ${currentState} to ${transition.toState}.`,
    before: { status: currentState, workflowRevision: currentRevision },
    after: {
      status: transition.toState,
      workflowRevision: nextRevision,
    },
    createdAt: timestamp,
  });
  writeAuditEvent({
    db,
    transaction,
    workItemRef,
    auditId: receiptId,
    event: auditEvent,
  });

  return {
    entityType: envelope.entityType,
    entityId: envelope.entityId,
    status: transition.toState,
    workflowRevision: nextRevision,
  };
}

async function decideApproval({
  db,
  fieldValue,
  transaction,
  actor,
  envelope,
  receiptId,
}) {
  const workItemRef = workItemReference(db, envelope);
  const workItemSnapshot = await transaction.get(workItemRef);
  requireExisting(workItemSnapshot, envelope);

  const approvalRef = workItemRef
    .collection('approvals')
    .doc(envelope.payload.approvalId);
  const approvalSnapshot = await transaction.get(approvalRef);
  if (!approvalSnapshot.exists) {
    throw new ItsmCommandError('not-found', 'The approval does not exist.');
  }
  const approval = approvalSnapshot.data() || {};
  if (normalizeString(approval.status).toLowerCase() !== 'pending') {
    throw new ItsmCommandError(
      'failed-precondition',
      'Only a pending approval can be decided.',
    );
  }

  const workItem = workItemSnapshot.data() || {};
  const requesterId = normalizeString(
    approval.requestedByUserId ||
      approval.requesterUserId ||
      workItem.requesterId ||
      workItem.requesterUserId ||
      workItem.requestedByUserId ||
      workItem.createdBy ||
      workItem.createdByUserId,
  );
  if (requesterId && requesterId === actor.uid) {
    throw new ItsmCommandError(
      'permission-denied',
      'A requester cannot approve their own work item.',
    );
  }

  const approverUserId = normalizeString(approval.approverUserId);
  const assignedApproverIds = Array.isArray(approval.approverUserIds)
    ? approval.approverUserIds.map(normalizeString)
    : [];
  if (
    (approverUserId && approverUserId !== actor.uid) ||
    (!approverUserId && assignedApproverIds.length > 0 &&
      !assignedApproverIds.includes(actor.uid))
  ) {
    throw new ItsmCommandError(
      'permission-denied',
      'This approval is assigned to another approver.',
    );
  }
  const approverGroupId = normalizeString(approval.approverGroupId);
  if (!approverUserId && assignedApproverIds.length === 0) {
    if (!approverGroupId) {
      throw new ItsmCommandError(
        'failed-precondition',
        'The approval has no configured approver.',
      );
    }
    const actorGroupIds = await readActorGroupIds({
      db,
      transaction,
      actor,
    });
    if (!actorGroupIds.has(approverGroupId)) {
      throw new ItsmCommandError(
        'permission-denied',
        'This approval is assigned to another approval group.',
      );
    }
  }

  const timestamp = fieldValue.serverTimestamp();
  transaction.update(approvalRef, {
    status: envelope.payload.decision,
    decision: envelope.payload.decision,
    decisionComment: envelope.payload.comment,
    decidedByUserId: actor.uid,
    decidedByName: actor.displayName,
    decidedByEmail: actor.email,
    decidedAt: timestamp,
    updatedAt: timestamp,
  });

  const auditEvent = buildImmutableAuditEvent({
    actor,
    envelope,
    eventType: 'approval.decided',
    action: envelope.payload.decision,
    summary:
      envelope.payload.comment ||
      `Approval ${envelope.payload.decision}.`,
    before: { approvalId: approvalRef.id, status: approval.status },
    after: {
      approvalId: approvalRef.id,
      status: envelope.payload.decision,
    },
    createdAt: timestamp,
  });
  writeAuditEvent({
    db,
    transaction,
    workItemRef,
    auditId: receiptId,
    event: auditEvent,
  });

  return {
    entityType: envelope.entityType,
    entityId: envelope.entityId,
    approvalId: approvalRef.id,
    decision: envelope.payload.decision,
  };
}

async function indexAuditEvent({
  db,
  fieldValue,
  transaction,
  envelope,
}) {
  const workItemRef = workItemReference(db, envelope);
  const workItemSnapshot = await transaction.get(workItemRef);
  requireExisting(workItemSnapshot, envelope);

  const auditEventRef = workItemRef
    .collection('auditLogs')
    .doc(envelope.payload.auditEventId);
  const auditEventSnapshot = await transaction.get(auditEventRef);
  if (!auditEventSnapshot.exists) {
    throw new ItsmCommandError(
      'not-found',
      'The authoritative audit event does not exist.',
    );
  }

  const globalAuditId = buildIdempotencyDocumentId(
    'system',
    'audit.index',
    `${envelope.entityType}:${envelope.entityId}:${auditEventRef.id}`,
  );
  const globalAuditRef = db.collection('itsmAuditEvents').doc(globalAuditId);
  const globalAuditSnapshot = await transaction.get(globalAuditRef);
  if (!globalAuditSnapshot.exists) {
    transaction.create(globalAuditRef, {
      ...(auditEventSnapshot.data() || {}),
      entityType: envelope.entityType,
      entityId: envelope.entityId,
      sourceAuditEventId: auditEventRef.id,
      sourcePath: workItemRef.path,
      indexedAt: fieldValue.serverTimestamp(),
    });
  }

  return {
    entityType: envelope.entityType,
    entityId: envelope.entityId,
    auditEventId: auditEventRef.id,
    globalAuditEventId: globalAuditId,
    alreadyIndexed: globalAuditSnapshot.exists,
  };
}

async function maintainWorkItemIndex({
  db,
  fieldValue,
  transaction,
  actor,
  envelope,
}) {
  const workItemRef = workItemReference(db, envelope);
  const workItemSnapshot = await transaction.get(workItemRef);
  requireExisting(workItemSnapshot, envelope);
  const workItem = workItemSnapshot.data() || {};
  const indexId = `${envelope.entityType}:${envelope.entityId}`;
  const indexRef = db.collection('itsmWorkItemIndex').doc(indexId);

  const summary = buildTrustedWorkItemSummary({
    actor,
    envelope,
    workItem,
    sourcePath: workItemRef.path,
    updatedAt: fieldValue.serverTimestamp(),
  });
  transaction.set(indexRef, summary, { merge: false });

  return {
    entityType: envelope.entityType,
    entityId: envelope.entityId,
    indexId,
  };
}

async function processSlaHook({
  db,
  fieldValue,
  transaction,
  actor,
  envelope,
}) {
  const workItemRef = workItemReference(db, envelope);
  const workItemSnapshot = await transaction.get(workItemRef);
  requireExisting(workItemSnapshot, envelope);
  const workItem = workItemSnapshot.data() || {};
  const slaStateId = `${envelope.entityType}:${envelope.entityId}`;
  const slaStateRef = db.collection('itsmSlaStates').doc(slaStateId);
  const timestamp = fieldValue.serverTimestamp();

  const patch = {
    entityType: envelope.entityType,
    entityId: envelope.entityId,
    sourcePath: workItemRef.path,
    policyId: normalizeString(workItem.slaPolicyId),
    policyVersion: workItem.slaPolicyVersion || null,
    requestedAction: envelope.payload.action,
    requestedReason: envelope.payload.reason,
    processingStatus: 'pending',
    requestedByUserId: actor.uid,
    requestedAt: timestamp,
    updatedAt: timestamp,
  };
  if (envelope.payload.action === 'pause') {
    patch.pauseRequestedAt = timestamp;
  } else if (envelope.payload.action === 'resume') {
    patch.resumeRequestedAt = timestamp;
  }
  transaction.set(slaStateRef, patch, { merge: true });

  return {
    entityType: envelope.entityType,
    entityId: envelope.entityId,
    slaStateId,
    processingStatus: 'pending',
  };
}

async function createNotificationEvent({
  db,
  fieldValue,
  transaction,
  actor,
  envelope,
  receiptId,
}) {
  const workItemRef = workItemReference(db, envelope);
  const workItemSnapshot = await transaction.get(workItemRef);
  requireExisting(workItemSnapshot, envelope);

  const eventId = buildIdempotencyDocumentId(
    actor.uid,
    'notification.event',
    receiptId,
  );
  const eventRef = db.collection('notificationEvents').doc(eventId);
  validateNotificationRecipients(
    envelope.payload.target,
    workItemSnapshot.data() || {},
  );
  transaction.create(eventRef, {
    eventType: envelope.payload.eventType,
    moduleKey: 'ticketing',
    title: envelope.payload.title,
    body: envelope.payload.body,
    entityType: envelope.entityType,
    entityId: envelope.entityId,
    route: envelope.payload.route,
    target: envelope.payload.target,
    sourceCommandId: receiptId,
    createdByUserId: actor.uid,
    createdByName: actor.displayName,
    createdByEmail: actor.email,
    createdAt: fieldValue.serverTimestamp(),
    status: 'PENDING',
  });

  return {
    entityType: envelope.entityType,
    entityId: envelope.entityId,
    notificationEventId: eventId,
  };
}

function workItemReference(db, envelope) {
  const collection = COLLECTION_BY_ENTITY_TYPE[envelope.entityType];
  if (!collection) {
    throw new ItsmCommandError(
      'invalid-argument',
      `Unsupported ITSM entity type: ${envelope.entityType}.`,
    );
  }
  return db.collection(collection).doc(envelope.entityId);
}

function requireExisting(snapshot, envelope) {
  if (!snapshot.exists) {
    throw new ItsmCommandError(
      'not-found',
      `${envelope.entityType} ${envelope.entityId} does not exist.`,
    );
  }
}

function findTransition(workflow, transitionId) {
  const transitions = Array.isArray(workflow.transitions)
    ? workflow.transitions
    : [];
  const transition = transitions.find(
    (candidate) => normalizeString(candidate.id) === transitionId,
  );
  if (!transition) {
    throw new ItsmCommandError(
      'failed-precondition',
      'The requested transition is not present in the pinned workflow.',
    );
  }
  return {
    id: normalizeString(transition.id),
    fromState: normalizeString(
      transition.fromState || transition.fromStateId,
    ),
    toState: normalizeString(transition.toState || transition.toStateId),
    allowedRoles: Array.isArray(
      transition.allowedRoles || transition.permittedRoles,
    )
      ? (transition.allowedRoles || transition.permittedRoles).map(normalizeRole)
      : [],
    mandatoryFields: Array.isArray(transition.mandatoryFields)
      ? transition.mandatoryFields.map(normalizeString).filter(Boolean)
      : [],
    isAuditable: transition.isAuditable !== false,
    selfServiceAllowed:
      transition.selfServiceAllowed === true ||
      transition.isSelfService === true ||
      transition.selfService === true,
  };
}

function validateTransition({
  transition,
  currentState,
  requestedState,
  actorRole,
  workItem = {},
}) {
  if (
    transition.fromState !== currentState ||
    transition.toState !== requestedState
  ) {
    throw new ItsmCommandError(
      'failed-precondition',
      'The transition does not match the current or requested state.',
    );
  }
  if (!transition.allowedRoles.includes(actorRole)) {
    throw new ItsmCommandError(
      'permission-denied',
      'The pinned workflow does not allow this role to use the transition.',
    );
  }
  if (!transition.isAuditable) {
    throw new ItsmCommandError(
      'failed-precondition',
      'The transition is not auditable and cannot be executed.',
    );
  }

  const missingFields = transition.mandatoryFields.filter(
    (field) => !hasStoredValue(workItem, field),
  );
  if (missingFields.length > 0) {
    throw new ItsmCommandError(
      'failed-precondition',
      'Required workflow fields are missing.',
      { missingFields },
    );
  }
}

function validateNotificationRecipients(target, workItem) {
  if (target.type === 'MODULE_ROLE') {
    return;
  }
  if (target.type !== 'USERS') {
    throw new ItsmCommandError(
      'permission-denied',
      'The notification target is not permitted.',
    );
  }

  const allowedUserIds = new Set(
    [
      workItem.requesterUserId,
      workItem.requestedByUserId,
      workItem.createdByUserId,
      workItem.affectedUserId,
      workItem.assignedToUserId,
      workItem.ownerUserId,
    ].map(normalizeString).filter(Boolean),
  );
  const allowedEmails = new Set(
    [
      workItem.requesterEmail,
      workItem.requestedByEmail,
      workItem.createdByEmail,
      workItem.affectedUserEmail,
      workItem.assignedToEmail,
      workItem.ownerEmail,
    ].map((value) => normalizeString(value).toLowerCase()).filter(Boolean),
  );

  const userIds = target.userIds || [];
  const userEmails = target.userEmails || [];
  if (
    userIds.some((userId) => !allowedUserIds.has(userId)) ||
    userEmails.some((email) => !allowedEmails.has(email))
  ) {
    throw new ItsmCommandError(
      'permission-denied',
      'Notifications may target only users linked to the work item.',
    );
  }
}

function isSelfServiceOwner(record, actor) {
  const identifiers = [
    record.requesterId,
    record.requesterUserId,
    record.requestedByUserId,
    record.requestedForUserId,
    record.createdBy,
    record.createdByUserId,
    record.affectedUserId,
    record.ownerUserId,
  ].map(normalizeString).filter(Boolean);
  if (identifiers.includes(actor.uid)) return true;
  const emails = [
    record.requesterEmail,
    record.requestedByEmail,
    record.requestedForEmail,
    record.createdByEmail,
    record.affectedUserEmail,
    record.ownerEmail,
  ].map((value) => normalizeString(value).toLowerCase()).filter(Boolean);
  return Boolean(actor.email) && emails.includes(actor.email);
}

function buildTransitionPatch({
  toState,
  reason,
  actor,
  timestamp,
  nextRevision,
}) {
  const normalizedState = normalizeString(toState).toLowerCase();
  const patch = {
    workflowState: toState,
    status: toState,
    workflowRevision: nextRevision,
    updatedAt: timestamp,
    updatedBy: actor.uid,
    lastStatusChangedAt: timestamp,
  };
  const normalizedReason = normalizeString(reason);
  if (normalizedReason) patch.transitionReason = normalizedReason;
  if (normalizedState === 'fulfilled') {
    patch.fulfilledAt = timestamp;
  } else if (normalizedState === 'archived') {
    patch.lifecycleState = 'archived';
    patch.archivedAt = timestamp;
    if (normalizedReason) patch.archiveReason = normalizedReason;
  } else if (['closed', 'rejected', 'cancelled'].includes(normalizedState)) {
    patch.lifecycleState = 'closed';
    patch.closedAt = timestamp;
    if (normalizedState === 'rejected' && normalizedReason) {
      patch.rejectionReason = normalizedReason;
    } else if (normalizedState === 'cancelled' && normalizedReason) {
      patch.cancellationReason = normalizedReason;
    } else if (normalizedReason) {
      patch.closureReason = normalizedReason;
    }
  } else {
    patch.lifecycleState = 'active';
  }
  return patch;
}

async function readActorGroupIds({ db, transaction, actor }) {
  const paths = [
    db.collection('agents').doc(actor.uid),
    db.collection('users').doc(actor.uid),
  ];
  const groups = new Set();
  for (const reference of paths) {
    const snapshot = await transaction.get(reference);
    if (!snapshot.exists) continue;
    const data = snapshot.data() || {};
    for (const field of [
      'itsmGroupIds',
      'assignmentGroupIds',
      'approvalGroupIds',
      'groupIds',
    ]) {
      if (!Array.isArray(data[field])) continue;
      data[field].map(normalizeString).filter(Boolean).forEach(
        (groupId) => groups.add(groupId),
      );
    }
    for (const field of ['itsmGroupId', 'assignmentGroupId', 'approvalGroupId']) {
      const groupId = normalizeString(data[field]);
      if (groupId) groups.add(groupId);
    }
  }
  return groups;
}

function hasStoredValue(record, fieldPath) {
  let value = record;
  for (const segment of fieldPath.split('.')) {
    if (!value || typeof value !== 'object') {
      return false;
    }
    value = value[segment];
  }
  if (value === null || value === undefined) {
    return false;
  }
  if (typeof value === 'string') {
    return value.trim().length > 0;
  }
  if (Array.isArray(value)) {
    return value.length > 0;
  }
  return true;
}

function buildImmutableAuditEvent({
  actor,
  envelope,
  eventType,
  action,
  summary,
  before = {},
  after = {},
  metadata = {},
  createdAt,
}) {
  const immutablePayload = deepFreeze({
    eventType: normalizeString(eventType),
    action: normalizeString(action),
    summary: normalizeString(summary),
    entityType: envelope.entityType,
    entityId: envelope.entityId,
    actorUserId: actor.uid,
    actorName: actor.displayName,
    actorEmail: actor.email,
    actorRole: actor.role,
    before: cloneValue(before),
    after: cloneValue(after),
    metadata: cloneValue(metadata),
    sourceCommand: envelope.command,
    sourceIdempotencyKey: envelope.idempotencyKey,
  });
  // Do not recursively freeze Firestore FieldValue sentinels.
  return Object.freeze({ ...immutablePayload, createdAt });
}

function writeAuditEvent({
  db,
  transaction,
  workItemRef,
  auditId,
  event,
}) {
  transaction.create(workItemRef.collection('auditLogs').doc(auditId), event);
  transaction.create(db.collection('itsmAuditEvents').doc(auditId), {
    ...event,
    sourcePath: workItemRef.path,
  });
}

function buildTrustedWorkItemSummary({
  actor,
  envelope,
  workItem,
  sourcePath,
  updatedAt,
}) {
  const requesterId = normalizeString(
    workItem.requesterId ||
      workItem.requesterUserId ||
      workItem.createdByUserId ||
      workItem.affectedUserId,
  );
  const reference = normalizeString(
    workItem.reference ||
      workItem.ticketNumber ||
      workItem.requestNumber ||
      workItem.changeNumber ||
      workItem.findingNumber,
  );
  return {
    id: envelope.entityId,
    type: envelope.entityType,
    entityType: envelope.entityType,
    entityId: envelope.entityId,
    sourcePath,
    reference,
    referenceNumber: reference,
    title: normalizeString(workItem.title),
    description: normalizeString(workItem.description),
    status: normalizeString(workItem.status),
    lifecycleState: normalizeString(workItem.lifecycleState),
    priority: normalizeString(workItem.priority),
    requesterId,
    requesterUserId: requesterId,
    requesterName: normalizeString(
      workItem.requesterName ||
        workItem.createdByName ||
        workItem.affectedUserName,
    ),
    requesterEmail: normalizeString(
      workItem.requesterEmail ||
        workItem.createdByEmail ||
        workItem.affectedUserEmail,
    ).toLowerCase(),
    affectedUserId: normalizeString(workItem.affectedUserId),
    departmentId: normalizeString(
      workItem.departmentId || workItem.createdByDepartmentId,
    ),
    serviceId: normalizeString(
      workItem.serviceId || workItem.affectedServiceId,
    ),
    assignedUserId: normalizeString(
      workItem.assignedUserId || workItem.assignedToUserId,
    ),
    assignedToUserId: normalizeString(
      workItem.assignedUserId || workItem.assignedToUserId,
    ),
    assignedToName: normalizeString(workItem.assignedToName),
    confidentiality: normalizeString(
      workItem.confidentiality || 'internal',
    ).toLowerCase(),
    selfServiceVisible: workItem.selfServiceVisible !== false,
    slaStatus: normalizeString(workItem.slaStatus),
    dueAt: workItem.dueAt || null,
    createdAt: workItem.createdAt || null,
    sourceCreatedAt: workItem.createdAt || null,
    sourceUpdatedAt: workItem.updatedAt || null,
    indexedByUserId: actor.uid,
    updatedAt,
  };
}

function safeStoredIdentifier(value, field) {
  const identifier = normalizeString(value);
  if (!/^[A-Za-z0-9][A-Za-z0-9._:-]{0,199}$/.test(identifier)) {
    throw new ItsmCommandError(
      'failed-precondition',
      `The work item has no valid ${field}.`,
    );
  }
  return identifier;
}

function cloneValue(value) {
  return JSON.parse(JSON.stringify(value || {}));
}

module.exports = {
  COLLECTION_BY_ENTITY_TYPE,
  buildImmutableAuditEvent,
  buildTrustedWorkItemSummary,
  executeItsmCommand,
  validateNotificationRecipients,
  validateTransition,
};
