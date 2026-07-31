'use strict';

const crypto = require('node:crypto');
const { normalizeString } = require('./itsm_permissions');

const SUPPORT_COLLECTION_TYPES = Object.freeze({
  incidentTickets: 'incident',
  serviceRequests: 'service_request',
});

const SUPPORTED_ATTACHMENT_CONTENT_TYPES = new Set([
  'application/pdf',
  'application/msword',
  'application/vnd.ms-excel',
  'application/vnd.ms-powerpoint',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  'text/plain',
  'text/csv',
]);

function buildSupportWorkItemIndex({
  collectionName,
  workItemId,
  data,
}) {
  const type = SUPPORT_COLLECTION_TYPES[collectionName];
  if (!type) {
    throw new Error(`Unsupported support work-item collection: ${collectionName}.`);
  }
  // The shared index is a self-service projection. Its requester is the
  // requested-for/affected owner, while the authoritative document retains
  // the submitting actor in requesterId and createdBy.
  const requesterId = normalizeString(
    data.requestedForUserId ||
      data.affectedUserId ||
      data.requesterId ||
      data.requesterUserId ||
      data.createdByUserId,
  );
  const slaSummary = data.slaSummary && typeof data.slaSummary === 'object'
    ? data.slaSummary
    : {};
  return {
    id: workItemId,
    type,
    reference: normalizeString(
      data.reference ||
        data.requestNumber ||
        data.ticketNumber,
    ),
    title: normalizeString(data.title),
    description: normalizeString(data.description),
    requesterId,
    affectedUserId: normalizeString(
      data.affectedUserId || data.requestedForUserId,
    ),
    departmentId: normalizeString(
      data.departmentId || data.createdByDepartmentId,
    ),
    serviceId: normalizeString(
      data.serviceId || data.affectedServiceId || data.createdByServiceId,
    ),
    locationId: normalizeString(data.locationId || data.location),
    assignedGroupId: normalizeString(data.assignedGroupId),
    assignedUserId: normalizeString(
      data.assignedUserId || data.assignedToUserId,
    ),
    priority: normalizeString(data.priority || 'unprioritized'),
    impact: normalizeString(data.impact),
    urgency: normalizeString(data.urgency),
    status: normalizeString(data.status),
    lifecycleState: normalizeString(data.lifecycleState || 'active'),
    workflowDefinitionId: normalizeString(data.workflowDefinitionId),
    workflowVersion: positiveIntegerOrNull(data.workflowVersion),
    createdAt: data.createdAt || null,
    createdBy: normalizeString(data.createdBy || data.createdByUserId),
    updatedAt: data.updatedAt || data.createdAt || null,
    updatedBy: normalizeString(
      data.updatedBy || data.updatedByUserId || data.createdBy ||
        data.createdByUserId,
    ),
    dueAt: data.dueAt || slaSummary.fulfilmentDueAt || null,
    closedAt: data.closedAt || null,
    confidentiality: normalizeString(
      data.confidentiality || 'internal',
    ).toLowerCase(),
    linkedAssetIds: normalizedArray(data.linkedAssetIds || assetIds(data)),
    linkedCiIds: normalizedArray(data.linkedCiIds),
    selfServiceVisible: data.selfServiceVisible !== false,
    slaStatus: normalizeString(data.slaStatus || slaSummary.status),
    submittedByUserId: normalizeString(
      data.requesterId || data.createdBy || data.createdByUserId,
    ),
  };
}

async function maintainSupportWorkItemIndex({
  db,
  collectionName,
  workItemId,
  after,
}) {
  const type = SUPPORT_COLLECTION_TYPES[collectionName];
  if (!type) {
    throw new Error(`Unsupported support work-item collection: ${collectionName}.`);
  }
  const indexRef = db
    .collection('itsmWorkItemIndex')
    .doc(`${type}:${workItemId}`);
  if (!after || after.exists === false) {
    await indexRef.delete();
    return { deleted: true, indexId: indexRef.id };
  }
  const summary = buildSupportWorkItemIndex({
    collectionName,
    workItemId,
    data: after.data() || {},
  });
  await indexRef.set(summary, { merge: false });
  return { deleted: false, indexId: indexRef.id };
}

function notificationEventsForSupportChange({
  collectionName,
  workItemId,
  before,
  after,
  sourceEventId,
  fieldValue,
}) {
  if (!after || after.exists === false) {
    return [];
  }
  const current = after.data() || {};
  const previous = before && before.exists !== false ? before.data() || {} : null;
  const type = SUPPORT_COLLECTION_TYPES[collectionName];
  const route = canonicalSupportRoute(type, workItemId);
  const timestamp = fieldValue.serverTimestamp();
  const events = [];

  if (
    type === 'service_request' &&
    ((!previous && normalizeString(current.status) !== 'draft') ||
      (previous && normalizeString(previous.status) === 'draft' &&
        normalizeString(current.status) !== 'draft'))
  ) {
    events.push(buildNotificationEvent({
      type,
      workItemId,
      sourceEventId,
      eventKind: 'submitted',
      eventType: 'service_request.submitted',
      title: 'New service request',
      body: `${displayReference(current, workItemId)} requires attention.`,
      route,
      target: {
        type: 'MODULE_ROLE',
        moduleKey: 'ticketing',
        roles: ['MANAGER'],
      },
      current,
      timestamp,
    }));
  }

  const assignedUserId = normalizeString(
    current.assignedUserId || current.assignedToUserId,
  );
  const previousAssignedUserId = normalizeString(
    previous && (previous.assignedUserId || previous.assignedToUserId),
  );
  if (previous && assignedUserId && assignedUserId !== previousAssignedUserId) {
    events.push(buildNotificationEvent({
      type,
      workItemId,
      sourceEventId,
      eventKind: `assigned:${assignedUserId}`,
      eventType: type === 'incident'
        ? 'incident.assigned'
        : 'service_request.assigned',
      title: type === 'incident' ? 'Incident assigned' : 'Service request assigned',
      body: `${displayReference(current, workItemId)} was assigned to you.`,
      route,
      target: {
        type: 'USERS',
        userIds: [assignedUserId],
        userEmails: [],
      },
      current,
      timestamp,
    }));
  }

  const status = normalizeString(current.status).toLowerCase();
  const previousStatus = normalizeString(previous && previous.status).toLowerCase();
  if (
    previous &&
    status &&
    status !== previousStatus &&
    !(type === 'service_request' && previousStatus === 'draft')
  ) {
    if (type === 'service_request') {
      const requesterRecipients = requesterNotificationRecipients(current);
      if (
        requesterRecipients.userIds.length > 0 ||
        requesterRecipients.userEmails.length > 0
      ) {
        events.push(buildNotificationEvent({
          type,
          workItemId,
          sourceEventId,
          eventKind: `status:${status}:requester`,
          eventType: 'service_request.status_changed',
          title: 'Service request updated',
          body: `${displayReference(current, workItemId)} is now ${status}.`,
          route: selfServiceSupportRoute(type, workItemId),
          target: { type: 'USERS', ...requesterRecipients },
          current,
          timestamp,
        }));
      }
      const operationalRecipients = operationalNotificationRecipients(current);
      if (
        operationalRecipients.userIds.length > 0 ||
        operationalRecipients.userEmails.length > 0
      ) {
        events.push(buildNotificationEvent({
          type,
          workItemId,
          sourceEventId,
          eventKind: `status:${status}:operational`,
          eventType: 'service_request.status_changed',
          title: 'Service request updated',
          body: `${displayReference(current, workItemId)} is now ${status}.`,
          route,
          target: { type: 'USERS', ...operationalRecipients },
          current,
          timestamp,
        }));
      }
    } else {
      const recipients = statusNotificationRecipients(current);
      if (recipients.userIds.length === 0 && recipients.userEmails.length === 0) {
        return events;
      }
      events.push(buildNotificationEvent({
        type,
        workItemId,
        sourceEventId,
        eventKind: `status:${status}`,
        eventType: type === 'incident'
          ? 'incident.status_changed'
          : 'service_request.status_changed',
        title: type === 'incident' ? 'Incident updated' : 'Service request updated',
        body: `${displayReference(current, workItemId)} is now ${status}.`,
        route,
        target: { type: 'USERS', ...recipients },
        current,
        timestamp,
      }));
    }
  }

  return events;
}

async function writeSupportNotificationEvents({ db, events }) {
  if (events.length === 0) {
    return 0;
  }
  const batch = db.batch();
  for (const event of events) {
    batch.set(
      db.collection('notificationEvents').doc(event.id),
      event.data,
      { merge: false },
    );
  }
  await batch.commit();
  return events.length;
}

async function synchronizeServiceRequestApproval({
  db,
  fieldValue,
  requestId,
  approvalId,
  before,
  after,
  sourceEventId,
}) {
  if (!after || after.exists === false) {
    return { changed: false };
  }
  const current = after.data() || {};
  const previous = before && before.exists !== false ? before.data() || {} : {};
  const decision = normalizeString(current.decision || current.status).toLowerCase();
  const previousDecision = normalizeString(
    previous.decision || previous.status,
  ).toLowerCase();
  if (
    !['approved', 'rejected', 'clarification_requested'].includes(decision) ||
    decision === previousDecision
  ) {
    return { changed: false };
  }

  const requestRef = db.collection('serviceRequests').doc(requestId);
  const timestamp = fieldValue.serverTimestamp();
  await db.runTransaction(async (transaction) => {
    const requestSnapshot = await transaction.get(requestRef);
    if (!requestSnapshot.exists) return;
    const request = requestSnapshot.data() || {};
    const currentStep = Number(current.step || request.currentApprovalStep || 1);
    const stepIds = normalizedArray(request.approvalStepIds);
    const remainingApprovals = Math.max(
      0,
      Number(request.pendingApprovalCount || stepIds.length || 1) - 1,
    );
    const patch = {
      approvalState: decision,
      pendingApprovalCount: remainingApprovals,
      updatedAt: timestamp,
      updatedBy: normalizeString(current.decidedByUserId),
      workflowRevision: Number(request.workflowRevision || 0) + 1,
      lastStatusChangedAt: timestamp,
    };
    if (decision === 'rejected') {
      patch.status = 'rejected';
      patch.workflowState = 'rejected';
      patch.lifecycleState = 'closed';
      patch.rejectionReason = normalizeString(current.decisionComment);
      patch.closedAt = timestamp;
    } else if (decision === 'clarification_requested') {
      patch.pendingApprovalCount = Number(
        request.pendingApprovalCount || stepIds.length || 1,
      );
      patch.status = 'awaiting_user';
      patch.workflowState = 'awaiting_user';
      patch.lifecycleState = 'active';
      patch.clarificationReason = normalizeString(current.decisionComment);
    } else {
      const nextApprovalId = stepIds[currentStep] || '';
      if (nextApprovalId) {
        const nextApprovalRef = requestRef
          .collection('approvals')
          .doc(nextApprovalId);
        const nextApprovalSnapshot = await transaction.get(nextApprovalRef);
        if (!nextApprovalSnapshot.exists) {
          throw new Error(
            `Configured approval step ${nextApprovalId} does not exist.`,
          );
        }
        const nextApproval = nextApprovalSnapshot.data() || {};
        if (normalizeString(nextApproval.status).toLowerCase() !== 'queued') {
          throw new Error(
            `Configured approval step ${nextApprovalId} is not queued.`,
          );
        }
        transaction.update(nextApprovalRef, {
          status: 'pending',
          requestedAt: timestamp,
          updatedAt: timestamp,
        });
        writeApprovalRequestedNotification({
          db,
          transaction,
          requestId,
          request,
          approvalId: nextApprovalId,
          approval: nextApproval,
          sourceEventId,
          timestamp,
        });
        patch.status = 'awaiting_approval';
        patch.workflowState = 'awaiting_approval';
        patch.lifecycleState = 'active';
        patch.approvalState = 'pending';
        patch.currentApprovalStep = currentStep + 1;
      } else if (remainingApprovals > 0) {
        patch.status = 'awaiting_approval';
        patch.workflowState = 'awaiting_approval';
        patch.lifecycleState = 'active';
        patch.approvalState = 'pending';
      } else {
        patch.status = Number(request.taskCount || 0) > 0
          ? 'approved'
          : 'fulfilled';
        patch.workflowState = patch.status;
        patch.lifecycleState = 'active';
        patch.approvedAt = timestamp;
        if (patch.status === 'fulfilled') patch.fulfilledAt = timestamp;
      }
    }
    transaction.update(requestRef, patch);
    synchronizeWorkflowAndIndex({
      db,
      transaction,
      requestRef,
      requestId,
      request,
      patch,
      timestamp,
    });

    const auditId = deterministicId(
      'approval',
      requestId,
      approvalId,
      sourceEventId,
    );
    const audit = {
      eventType: 'approval.state_synchronized',
      action: decision,
      summary: `Approval ${approvalId} changed to ${decision}.`,
      entityType: 'service_request',
      entityId: requestId,
      actorUserId: normalizeString(current.decidedByUserId),
      actorName: normalizeString(current.decidedByName),
      actorEmail: normalizeString(current.decidedByEmail).toLowerCase(),
      actorRole: 'MANAGER',
      before: { approvalState: normalizeString(request.approvalState) },
      after: { approvalState: decision, status: patch.status },
      sourceCommand: 'approval.decide',
      sourceIdempotencyKey: sourceEventId,
      createdAt: timestamp,
    };
    transaction.set(requestRef.collection('auditLogs').doc(auditId), audit);
    transaction.set(db.collection('itsmAuditEvents').doc(auditId), {
      ...audit,
      sourcePath: requestRef.path,
    });
  });

  return { changed: true, decision };
}

function writeApprovalRequestedNotification({
  db,
  transaction,
  requestId,
  request,
  approvalId,
  approval,
  sourceEventId,
  timestamp,
}) {
  const approverUserId = normalizeString(approval.approverUserId);
  const approverGroupId = normalizeString(approval.approverGroupId);
  const route = canonicalSupportRoute('service_request', requestId);
  const event = buildNotificationEvent({
    type: 'service_request',
    workItemId: requestId,
    sourceEventId,
    eventKind: `approval_requested:${approvalId}`,
    eventType: 'approval.requested',
    title: 'Approval requested',
    body: `${displayReference(request, requestId)} requires approval.`,
    route,
    target: approverUserId
      ? { type: 'USERS', userIds: [approverUserId], userEmails: [] }
      : {
          type: 'MODULE_ROLE',
          moduleKey: 'ticketing',
          roles: ['MANAGER'],
          approvalGroupId: approverGroupId,
        },
    current: request,
    timestamp,
  });
  transaction.set(
    db.collection('notificationEvents').doc(event.id),
    event.data,
    { merge: false },
  );
}

async function synchronizeServiceRequestTask({
  db,
  fieldValue,
  requestId,
  taskId,
  before,
  after,
  sourceEventId,
}) {
  if (!after || after.exists === false) {
    return { changed: false };
  }
  const current = after.data() || {};
  const previous = before && before.exists !== false ? before.data() || {} : {};
  const status = normalizeString(current.status).toLowerCase();
  const previousStatus = normalizeString(previous.status).toLowerCase();
  if (!status || status === previousStatus) {
    return { changed: false };
  }

  const requestRef = db.collection('serviceRequests').doc(requestId);
  const timestamp = fieldValue.serverTimestamp();
  await db.runTransaction(async (transaction) => {
    const requestSnapshot = await transaction.get(requestRef);
    if (!requestSnapshot.exists) {
      return;
    }
    const request = requestSnapshot.data() || {};
    const patch = {
      lastTaskChangedAt: timestamp,
      updatedAt: timestamp,
      updatedBy: normalizeString(current.updatedByUserId),
    };
    const mandatoryTaskCount = Number(request.mandatoryTaskCount || 0);
    const completedMandatoryTaskCount = Number(
      request.completedMandatoryTaskCount || 0,
    );
    const completesMandatoryWork =
      current.isMandatory !== false &&
      status === 'completed' &&
      mandatoryTaskCount > 0 &&
      completedMandatoryTaskCount >= mandatoryTaskCount;
    if (completesMandatoryWork) {
      patch.status = 'fulfilled';
      patch.workflowState = 'fulfilled';
      patch.lifecycleState = 'active';
      patch.fulfilledAt = timestamp;
      patch.lastStatusChangedAt = timestamp;
      patch.workflowRevision = Number(request.workflowRevision || 0) + 1;
    } else if (
      ['in_progress', 'completed'].includes(status) &&
      !['awaiting_approval', 'awaiting_user'].includes(
        normalizeString(request.status).toLowerCase(),
      )
    ) {
      patch.status = 'in_fulfilment';
      patch.workflowState = 'in_fulfilment';
      patch.lifecycleState = 'active';
      patch.lastStatusChangedAt = timestamp;
      patch.workflowRevision = Number(request.workflowRevision || 0) + 1;
    }
    transaction.update(requestRef, patch);
    if (patch.status) {
      synchronizeWorkflowAndIndex({
        db,
        transaction,
        requestRef,
        requestId,
        request,
        patch,
        timestamp,
      });
    }

    const auditId = deterministicId('task', requestId, taskId, sourceEventId);
    const audit = {
      eventType: 'service_request.task_updated',
      action: status,
      summary: `Task ${taskId} changed to ${status}.`,
      entityType: 'service_request',
      entityId: requestId,
      actorUserId: normalizeString(current.updatedByUserId),
      actorName: normalizeString(current.updatedByName),
      actorEmail: normalizeString(current.updatedByEmail).toLowerCase(),
      actorRole: 'MANAGER',
      before: { taskStatus: previousStatus },
      after: { taskStatus: status },
      sourceCommand: 'service_request.task.update',
      sourceIdempotencyKey: sourceEventId,
      createdAt: timestamp,
    };
    transaction.set(requestRef.collection('auditLogs').doc(auditId), audit);
    transaction.set(db.collection('itsmAuditEvents').doc(auditId), {
      ...audit,
      sourcePath: requestRef.path,
    });
  });
  return { changed: true, status };
}

function synchronizeWorkflowAndIndex({
  db,
  transaction,
  requestRef,
  requestId,
  request,
  patch,
  timestamp,
}) {
  const revision = Number(
    patch.workflowRevision === undefined
      ? request.workflowRevision || 0
      : patch.workflowRevision,
  );
  transaction.set(
    requestRef.collection('workflowInstances').doc(
      normalizeString(request.workflowInstanceId) || 'current',
    ),
    {
      definitionId: normalizeString(request.workflowDefinitionId),
      version: request.workflowVersion || null,
      versionDocumentId: normalizeString(request.workflowVersionDocumentId),
      state: normalizeString(patch.workflowState || patch.status || request.status),
      revision,
      updatedAt: timestamp,
    },
    { merge: true },
  );
  transaction.set(
    db.collection('itsmWorkItemIndex').doc(`service_request:${requestId}`),
    buildSupportWorkItemIndex({
      collectionName: 'serviceRequests',
      workItemId: requestId,
      data: { ...request, ...patch },
    }),
    { merge: false },
  );
}

function buildNotificationEvent({
  type,
  workItemId,
  sourceEventId,
  eventKind,
  eventType,
  title,
  body,
  route,
  target,
  current,
  timestamp,
}) {
  const deduplicationId = deterministicId(
    'notification',
    type,
    workItemId,
    eventKind,
    sourceEventId,
  );
  return {
    id: deduplicationId,
    data: {
      eventType,
      moduleKey: 'ticketing',
      title,
      body,
      entityType: type,
      entityId: workItemId,
      route,
      deepLink: route,
      deduplicationId,
      target,
      sourceEventId,
      createdByUserId: normalizeString(
        current.updatedByUserId ||
          current.createdByUserId ||
          current.requestedByUserId,
      ),
      createdByName: normalizeString(
        current.updatedByName ||
          current.createdByName ||
          current.requestedByName,
      ),
      createdByEmail: normalizeString(
        current.updatedByEmail ||
          current.createdByEmail ||
          current.requestedByEmail,
      ).toLowerCase(),
      createdAt: timestamp,
      status: 'PENDING',
    },
  };
}

function canonicalSupportRoute(type, workItemId) {
  return type === 'incident'
    ? `/services/itsm/support/incidents/${encodeURIComponent(workItemId)}`
    : `/services/itsm/support/service-requests/${encodeURIComponent(workItemId)}`;
}

function selfServiceSupportRoute(type, workItemId) {
  return type === 'service_request'
    ? `/services/itsm/support/my-requests/${encodeURIComponent(workItemId)}`
    : canonicalSupportRoute(type, workItemId);
}

function requesterNotificationRecipients(data) {
  return uniqueRecipients(
    [
      data.requestedForUserId,
      data.affectedUserId,
      data.requesterId,
      data.requesterUserId,
    ],
    [
      data.requestedForEmail,
      data.affectedUserEmail,
      data.requesterEmail,
    ],
  );
}

function operationalNotificationRecipients(data) {
  return uniqueRecipients(
    [data.assignedUserId, data.assignedToUserId],
    [data.assignedToEmail],
  );
}

function statusNotificationRecipients(data) {
  return uniqueRecipients([
    data.assignedUserId,
    data.assignedToUserId,
    data.requestedForUserId,
    data.affectedUserId,
    data.requesterId,
    data.requesterUserId,
  ], [
    data.assignedToEmail,
    data.requestedForEmail,
    data.affectedUserEmail,
    data.requesterEmail,
  ]);
}

function uniqueRecipients(userIds, userEmails) {
  return {
    userIds: [...new Set(userIds.map(normalizeString).filter(Boolean))],
    userEmails: [...new Set(
      userEmails
        .map((value) => normalizeString(value).toLowerCase())
        .filter(Boolean),
    )],
  };
}

function displayReference(data, fallback) {
  return normalizeString(
    data.reference || data.requestNumber || data.ticketNumber,
  ) || fallback;
}

function deterministicId(...parts) {
  return crypto
    .createHash('sha256')
    .update(parts.map(normalizeString).join('\u0000'))
    .digest('hex');
}

function buildServiceRequestAttachmentMetadata(object, fieldValue) {
  const parsed = parseServiceRequestAttachmentPath(object && object.name);
  if (!parsed) return null;
  const metadata = object.metadata || {};
  if (
    normalizeString(metadata.workItemCollection) !== 'serviceRequests' ||
    normalizeString(metadata.workItemId) !== parsed.requestId ||
    normalizeString(metadata.attachmentId) !== parsed.attachmentId
  ) {
    return null;
  }
  const contentType = normalizeString(object.contentType).toLowerCase();
  if (!isSupportedAttachmentContentType(contentType)) return null;
  if (normalizeString(metadata.isInternal).toLowerCase() !== 'false') return null;
  return {
    requestId: parsed.requestId,
    workItemCollection: 'serviceRequests',
    workItemId: parsed.requestId,
    fileName: parsed.fileName,
    storagePath: object.name,
    contentType,
    sizeBytes: Number(object.size || 0),
    documentRequirementKey: normalizeString(
      metadata.documentRequirementKey || metadata.requirementKey,
    ),
    uploadedByUserId: normalizeString(metadata.uploadedByUserId),
    visibility: 'requester_visible',
    isInternal: false,
    createdAt: fieldValue.serverTimestamp(),
  };
}

function buildKnowledgeAttachmentMetadata(object, fieldValue) {
  const parsed = parseKnowledgeAttachmentPath(object && object.name);
  if (!parsed) return null;
  const metadata = object.metadata || {};
  if (
    normalizeString(metadata.articleId) !== parsed.articleId ||
    normalizeString(metadata.versionId) !== parsed.versionId ||
    normalizeString(metadata.attachmentId) !== parsed.attachmentId
  ) {
    return null;
  }
  const contentType = normalizeString(object.contentType).toLowerCase();
  if (!isSupportedAttachmentContentType(contentType)) return null;
  return {
    articleId: parsed.articleId,
    versionId: parsed.versionId,
    attachmentId: parsed.attachmentId,
    fileName: parsed.fileName,
    storagePath: object.name,
    contentType,
    sizeBytes: Number(object.size || 0),
    uploadedByUserId: normalizeString(metadata.uploadedByUserId),
    visibility: normalizeString(metadata.isInternal).toLowerCase() === 'true'
      ? 'dsi_only'
      : 'employee',
    isInternal: normalizeString(metadata.isInternal).toLowerCase() === 'true',
    createdAt: fieldValue.serverTimestamp(),
  };
}

async function registerServiceRequestAttachment({ db, fieldValue, object }) {
  const attachment = buildServiceRequestAttachmentMetadata(object, fieldValue);
  if (!attachment || !attachment.uploadedByUserId || attachment.sizeBytes <= 0) {
    return { registered: false, reason: 'invalid_metadata' };
  }
  const requestRef = db.collection('serviceRequests').doc(attachment.requestId);
  const attachmentRef = requestRef
    .collection('attachments')
    .doc(parseServiceRequestAttachmentPath(object.name).attachmentId);
  return db.runTransaction(async (transaction) => {
    const requestSnapshot = await transaction.get(requestRef);
    if (!requestSnapshot.exists) {
      return { registered: false, reason: 'missing_parent' };
    }
    const request = requestSnapshot.data() || {};
    const ownerIds = new Set([
      request.requesterId,
      request.requestedForUserId,
      request.affectedUserId,
    ].map(normalizeString).filter(Boolean));
    if (!ownerIds.has(attachment.uploadedByUserId) ||
        normalizeString(request.status).toLowerCase() !== 'draft') {
      return { registered: false, reason: 'forbidden_parent' };
    }
    transaction.set(attachmentRef, attachment, { merge: false });
    return { registered: true, attachmentId: attachmentRef.id };
  });
}

async function registerKnowledgeAttachment({ db, fieldValue, object }) {
  const attachment = buildKnowledgeAttachmentMetadata(object, fieldValue);
  if (!attachment || !attachment.uploadedByUserId || attachment.sizeBytes <= 0) {
    return { registered: false, reason: 'invalid_metadata' };
  }
  const articleRef = db.collection('knowledgeArticles').doc(attachment.articleId);
  const versionRef = articleRef.collection('versions').doc(attachment.versionId);
  const attachmentRef = versionRef
    .collection('attachments')
    .doc(attachment.attachmentId);
  return db.runTransaction(async (transaction) => {
    const articleSnapshot = await transaction.get(articleRef);
    const versionSnapshot = await transaction.get(versionRef);
    const agentSnapshot = await transaction.get(
      db.collection('agents').doc(attachment.uploadedByUserId),
    );
    if (!articleSnapshot.exists || !versionSnapshot.exists) {
      return { registered: false, reason: 'missing_parent' };
    }
    const article = articleSnapshot.data() || {};
    const version = versionSnapshot.data() || {};
    const agent = agentSnapshot.exists ? agentSnapshot.data() || {} : {};
    const permissions = agent.modulePermissions &&
      typeof agent.modulePermissions === 'object'
      ? agent.modulePermissions
      : {};
    const role = normalizeString(
      permissions.ticketing ||
        permissions.itsm ||
        permissions.support,
    ).toUpperCase();
    const expectedVersionId = String(
      Number(article.currentVersionNumber || 0),
    ).padStart(6, '0');
    if (
      role !== 'MANAGER' ||
      expectedVersionId !== attachment.versionId ||
      normalizeString(article.state).toLowerCase() !== 'draft' ||
      normalizeString(version.state).toLowerCase() !== 'draft'
    ) {
      return { registered: false, reason: 'forbidden_parent' };
    }
    const uploadedBy = {
      userId: attachment.uploadedByUserId,
      name: normalizeString(
        agent.displayName ||
          [agent.firstName, agent.postName || agent.name]
            .map(normalizeString)
            .filter(Boolean)
            .join(' '),
      ),
      email: normalizeString(agent.email).toLowerCase(),
    };
    transaction.set(attachmentRef, {
      ...attachment,
      id: attachment.attachmentId,
      uploadedBy,
      uploadedAt: fieldValue.serverTimestamp(),
    }, { merge: false });
    transaction.update(versionRef, {
      attachmentIds: fieldValue.arrayUnion(attachment.attachmentId),
    });
    return {
      registered: true,
      articleId: attachment.articleId,
      versionId: attachment.versionId,
      attachmentId: attachment.attachmentId,
    };
  });
}

function parseServiceRequestAttachmentPath(path) {
  const match = normalizeString(path).match(
    /^itsm\/serviceRequests\/([^/]+)\/attachments\/([^/]+)\/([^/]+)$/,
  );
  return match ? {
    requestId: match[1],
    attachmentId: match[2],
    fileName: match[3],
  } : null;
}

function parseKnowledgeAttachmentPath(path) {
  const match = normalizeString(path).match(
    /^itsm\/knowledgeArticles\/([^/]+)\/versions\/([^/]+)\/attachments\/([^/]+)\/([^/]+)$/,
  );
  return match ? {
    articleId: match[1],
    versionId: match[2],
    attachmentId: match[3],
    fileName: match[4],
  } : null;
}

function isSupportedAttachmentContentType(contentType) {
  const normalized = normalizeString(contentType).toLowerCase();
  return normalized.startsWith('image/') ||
    SUPPORTED_ATTACHMENT_CONTENT_TYPES.has(normalized);
}

function positiveIntegerOrNull(value) {
  const number = Number(value);
  return Number.isSafeInteger(number) && number > 0 ? number : null;
}

function normalizedArray(value) {
  return Array.isArray(value)
    ? [...new Set(value.map(normalizeString).filter(Boolean))]
    : [];
}

function assetIds(data) {
  const assetId = normalizeString(data.assetId);
  return assetId ? [assetId] : [];
}

module.exports = {
  SUPPORT_COLLECTION_TYPES,
  SUPPORTED_ATTACHMENT_CONTENT_TYPES,
  buildKnowledgeAttachmentMetadata,
  buildSupportWorkItemIndex,
  buildServiceRequestAttachmentMetadata,
  canonicalSupportRoute,
  deterministicId,
  maintainSupportWorkItemIndex,
  notificationEventsForSupportChange,
  parseServiceRequestAttachmentPath,
  parseKnowledgeAttachmentPath,
  registerKnowledgeAttachment,
  registerServiceRequestAttachment,
  selfServiceSupportRoute,
  synchronizeServiceRequestApproval,
  synchronizeServiceRequestTask,
  writeSupportNotificationEvents,
};
