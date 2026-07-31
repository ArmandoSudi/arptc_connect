'use strict';

const {
  ITSM_ROLES,
  ItsmCommandError,
  normalizeRole,
  normalizeString,
} = require('./itsm_permissions');
const { runIdempotentCommand } = require('./itsm_idempotency');
const {
  buildSupportWorkItemIndex,
  deterministicId,
} = require('./itsm_support_triggers');
const { ITSM_SUPPORT_COMMANDS } = require('./itsm_support_validation');

async function executeSupportCommand({
  db,
  fieldValue,
  timestamp,
  actor,
  agent,
  command,
}) {
  return runIdempotentCommand({
    db,
    fieldValue,
    actorUid: actor.uid,
    command: command.command,
    idempotencyKey: command.idempotencyKey,
    execute: async (transaction, receiptId) => {
      const common = {
        db,
        fieldValue,
        timestamp,
        transaction,
        actor,
        agent,
        command,
        receiptId,
      };
      switch (command.command) {
        case ITSM_SUPPORT_COMMANDS.initializeServiceRequestDraft:
          return initializeServiceRequestDraft(common);
        case ITSM_SUPPORT_COMMANDS.submitServiceRequest:
          return submitServiceRequest(common);
        case ITSM_SUPPORT_COMMANDS.updateServiceRequestTask:
          return updateServiceRequestTask(common);
        case ITSM_SUPPORT_COMMANDS.saveKnowledgeDraft:
          return saveKnowledgeDraft(common);
        case ITSM_SUPPORT_COMMANDS.submitKnowledgeReview:
          return transitionKnowledge(common, 'review');
        case ITSM_SUPPORT_COMMANDS.rejectKnowledgeReview:
          return transitionKnowledge(common, 'draft');
        case ITSM_SUPPORT_COMMANDS.publishKnowledgeArticle:
          return transitionKnowledge(common, 'published');
        case ITSM_SUPPORT_COMMANDS.retireKnowledgeArticle:
          return transitionKnowledge(common, 'retired');
        case ITSM_SUPPORT_COMMANDS.archiveKnowledgeArticle:
          return transitionKnowledge(common, 'archived');
        case ITSM_SUPPORT_COMMANDS.recordKnowledgeView:
          return recordKnowledgeView(common);
        case ITSM_SUPPORT_COMMANDS.recordKnowledgeFeedback:
          return recordKnowledgeFeedback(common);
        default:
          throw invalid(`Unknown support command: ${command.command}.`);
      }
    },
  });
}

async function initializeServiceRequestDraft({
  db,
  fieldValue,
  timestamp,
  transaction,
  actor,
  agent,
  command,
  receiptId,
}) {
  const payload = command.payload;
  const catalogueRef = db
    .collection('serviceCatalogItems')
    .doc(payload.catalogueItemId);
  const catalogueSnapshot = await transaction.get(catalogueRef);
  requireExisting(catalogueSnapshot, 'The catalogue item does not exist.');
  const catalogueVersion = await resolvePublishedCatalogueVersion({
    transaction,
    parentRef: catalogueRef,
    parentSnapshot: catalogueSnapshot,
  });
  const catalogue = catalogueVersion.data;
  const now = trustedNow(timestamp);
  validatePublishedCatalogueItem(catalogue, actor, agent, now);

  const requestedFor = await resolveRequestedFor({
    db,
    transaction,
    actor,
    agent,
    requestedForUserId: payload.requestedForUserId,
    allowOnBehalf: catalogue.allowManagerRequestOnBehalf !== false,
  });
  validateEligibility(catalogue.eligibility || {}, requestedFor);

  const workflowReference = configurationReference(catalogue.workflow, 'workflow');
  const slaReference = configurationReference(catalogue.slaPolicy, 'SLA policy');
  const workflow = await resolvePublishedVersion({
    db,
    transaction,
    parentCollection: 'workflowDefinitions',
    reference: workflowReference,
    label: 'workflow',
  });
  const sla = await resolvePublishedVersion({
    db,
    transaction,
    parentCollection: 'slaPolicies',
    reference: slaReference,
    label: 'SLA policy',
  });

  const requestId = `req_${receiptId.substring(0, 24)}`;
  const requestRef = db.collection('serviceRequests').doc(requestId);
  const requestNumber = buildReference('REQ', now, receiptId);
  const timestampValue = fieldValue.serverTimestamp();
  const responseDueAt = dueAt(timestamp, now, sla.data.responseTargetMinutes);
  const fulfilmentDueAt = dueAt(
    timestamp,
    now,
    sla.data.fulfilmentTargetMinutes || sla.data.resolutionTargetMinutes,
  );
  const slaWarningAt = warningAt({
    timestamp,
    now,
    due: fulfilmentDueAt || responseDueAt,
    targetMinutes:
      sla.data.fulfilmentTargetMinutes || sla.data.resolutionTargetMinutes,
    warningThresholdMinutes: sla.data.warningThresholdMinutes,
    warningThresholdPercent: sla.data.warningThresholdPercent,
  });
  const catalogueName = localizedText(catalogue.name);
  const request = {
    requestNumber,
    reference: requestNumber,
    catalogueItemId: catalogueSnapshot.id,
    catalogueItemCode: normalizeString(catalogue.code || catalogueSnapshot.id),
    catalogueItemVersion: catalogueVersion.version,
    catalogueItemVersionDocumentId: catalogueVersion.documentId,
    catalogueItemName: catalogueName,
    title: payload.title || catalogueName,
    description: payload.description || localizedText(catalogue.description),
    responses: payload.responses,
    requesterId: actor.uid,
    requesterName: actor.displayName,
    requesterEmail: actor.email,
    requestedForUserId: requestedFor.uid,
    requestedForName: requestedFor.displayName,
    requestedForEmail: requestedFor.email,
    affectedUserId: requestedFor.uid,
    affectedUserName: requestedFor.displayName,
    affectedUserEmail: requestedFor.email,
    departmentId: requestedFor.departmentId,
    departmentName: requestedFor.departmentName,
    serviceId: requestedFor.serviceId,
    serviceName: requestedFor.serviceName,
    requestedOnBehalf: requestedFor.uid !== actor.uid,
    workflowDefinitionId: workflowReference.id,
    workflowVersion: workflowReference.version,
    workflowVersionDocumentId: workflow.documentId,
    workflowInstanceId: 'current',
    workflowRevision: 0,
    approvalPolicyId: nullableString(catalogue.approvalPolicyId),
    fulfilmentGroupId: normalizeString(catalogue.fulfilmentGroupId),
    assignedGroupId: null,
    assignedUserId: null,
    assignedUserName: null,
    slaPolicyId: slaReference.id,
    slaPolicyVersion: slaReference.version,
    slaPolicyVersionDocumentId: sla.documentId,
    slaSummary: {
      policyId: slaReference.id,
      policyVersion: slaReference.version,
      status: 'on_track',
      responseDueAt,
      fulfilmentDueAt: fulfilmentDueAt || responseDueAt,
      warningAt: slaWarningAt,
    },
    slaStatus: 'on_track',
    slaWarningAt,
    slaNextCheckAt: slaWarningAt || fulfilmentDueAt || responseDueAt,
    status: 'draft',
    lifecycleState: 'active',
    workflowAllowsCancellation: catalogue.workflowAllowsCancellation !== false,
    selfServiceVisible: true,
    confidentiality: 'internal',
    commentCount: 0,
    attachmentCount: 0,
    taskCount: 0,
    completedTaskCount: 0,
    pendingApprovalCount: 0,
    relatedRecords: [],
    createdAt: timestampValue,
    createdBy: actor.uid,
    updatedAt: timestampValue,
    updatedBy: actor.uid,
  };
  transaction.create(requestRef, request);
  writeIndex(transaction, db, requestId, request);
  writeAudit({
    transaction,
    db,
    fieldValue,
    actor,
    command,
    receiptId,
    entityType: 'service_request',
    entityId: requestId,
    parentRef: requestRef,
    action: 'draft_initialized',
    after: { status: 'draft' },
  });
  return {
    requestId,
    requestNumber,
    status: 'draft',
    uploadPath: `itsm/serviceRequests/${requestId}/attachments`,
    wasDuplicate: false,
  };
}

async function submitServiceRequest({
  db,
  fieldValue,
  transaction,
  actor,
  command,
  receiptId,
}) {
  const payload = command.payload;
  const requestRef = db.collection('serviceRequests').doc(payload.requestId);
  const requestSnapshot = await transaction.get(requestRef);
  requireExisting(requestSnapshot, 'The service request does not exist.');
  const request = { id: payload.requestId, ...(requestSnapshot.data() || {}) };
  requireDraftOwner(request, actor);
  if (normalizeString(request.status).toLowerCase() !== 'draft') {
    throw failed('Only a draft service request can be submitted.');
  }

  const catalogue = await getPinnedCatalogueVersion({
    db,
    transaction,
    catalogueItemId: request.catalogueItemId,
    versionDocumentId: request.catalogueItemVersionDocumentId,
    version: request.catalogueItemVersion,
  });
  const responses = { ...(request.responses || {}), ...payload.responses };
  validateDynamicResponses(catalogue, responses);
  const attachments = [];
  for (const attachmentId of payload.attachmentIds) {
    const attachmentSnapshot = await transaction.get(
      requestRef.collection('attachments').doc(attachmentId),
    );
    requireExisting(
      attachmentSnapshot,
      `Attachment ${attachmentId} has not finished uploading.`,
    );
    attachments.push({
      id: attachmentSnapshot.id,
      ...(attachmentSnapshot.data() || {}),
    });
  }
  validateRequiredDocuments(catalogue, attachments, request, actor);

  const workflow = await getPinnedVersion({
    db,
    transaction,
    parentCollection: 'workflowDefinitions',
    definitionId: request.workflowDefinitionId,
    versionDocumentId: request.workflowVersionDocumentId,
    version: request.workflowVersion,
  });
  const approvals = workflowEntries(workflow, 'approvalSteps');
  const tasks = workflowEntries(workflow, 'fulfilmentTasks');
  const status = approvals.length > 0 ? 'awaiting_approval' : 'submitted';
  const approvalStepIds = approvals.map((approval, index) =>
    normalizeString(approval.id) || `approval_${index + 1}`,
  );
  const mandatoryTaskCount = tasks.filter(
    (task) => task.isMandatory !== false && task.mandatory !== false,
  ).length;
  const timestampValue = fieldValue.serverTimestamp();
  const patch = {
    responses,
    status,
    lifecycleState: 'active',
    submittedAt: timestampValue,
    attachmentCount: attachments.length,
    taskCount: tasks.length,
    completedTaskCount: 0,
    mandatoryTaskCount,
    completedMandatoryTaskCount: 0,
    pendingApprovalCount: approvals.length,
    approvalStepIds,
    currentApprovalStep: approvals.length > 0 ? 1 : null,
    approvalState: approvals.length > 0 ? 'pending' : 'not_required',
    workflowRevision: Number(request.workflowRevision || 0) + 1,
    updatedAt: timestampValue,
    updatedBy: actor.uid,
  };
  transaction.update(requestRef, patch);
  transaction.set(requestRef.collection('workflowInstances').doc('current'), {
    definitionId: request.workflowDefinitionId,
    version: request.workflowVersion,
    versionDocumentId: request.workflowVersionDocumentId,
    state: status,
    revision: patch.workflowRevision,
    startedAt: timestampValue,
    updatedAt: timestampValue,
  });
  approvals.forEach((approval, index) => {
    const id = approvalStepIds[index];
    transaction.create(requestRef.collection('approvals').doc(id), {
      step: index + 1,
      name: localizedText(approval.name) || id,
      status: index === 0 ? 'pending' : 'queued',
      approverUserId: nullableString(approval.approverUserId),
      approverGroupId: normalizeString(
        approval.approverGroupId || approval.groupId || request.fulfilmentGroupId,
      ),
      requestedAt: index === 0 ? timestampValue : null,
      dueAt: index === 0 && Number(approval.dueMinutes) > 0
        ? dueAt(timestamp, trustedNow(timestamp), approval.dueMinutes)
        : null,
      createdAt: timestampValue,
    });
  });
  tasks.forEach((task, index) => {
    const id = normalizeString(task.id) || `task_${index + 1}`;
    transaction.create(requestRef.collection('tasks').doc(id), {
      title: localizedText(task.title || task.name) || id,
      description: localizedText(task.description),
      status: 'pending',
      assignedGroupId: normalizeString(
        task.assignedGroupId || task.groupId || request.fulfilmentGroupId,
      ),
      assignedUserId: null,
      isInternal: task.isInternal !== false,
      isMandatory: task.isMandatory !== false && task.mandatory !== false,
      createdAt: timestampValue,
      createdByUserId: actor.uid,
    });
  });
  writeIndex(transaction, db, payload.requestId, { ...request, ...patch });
  writeAudit({
    transaction,
    db,
    fieldValue,
    actor,
    command,
    receiptId,
    entityType: 'service_request',
    entityId: payload.requestId,
    parentRef: requestRef,
    action: 'submitted',
    before: { status: 'draft' },
    after: { status },
  });
  return {
    requestId: payload.requestId,
    requestNumber: request.requestNumber,
    status,
    wasDuplicate: false,
  };
}

async function updateServiceRequestTask({
  db,
  fieldValue,
  transaction,
  actor,
  command,
  receiptId,
}) {
  const { requestId, taskId, status, comment } = command.payload;
  const requestRef = db.collection('serviceRequests').doc(requestId);
  const taskRef = requestRef.collection('tasks').doc(taskId);
  const [requestSnapshot, taskSnapshot] = await Promise.all([
    transaction.get(requestRef),
    transaction.get(taskRef),
  ]);
  requireExisting(requestSnapshot, 'The service request does not exist.');
  requireExisting(taskSnapshot, 'The fulfilment task does not exist.');
  const task = taskSnapshot.data() || {};
  const request = requestSnapshot.data() || {};
  if (['closed', 'rejected', 'cancelled', 'archived'].includes(
    normalizeString(request.status).toLowerCase(),
  )) {
    throw failed('A task on a terminal service request cannot be changed.');
  }
  const timestampValue = fieldValue.serverTimestamp();
  const completedBefore = normalizeString(task.status) === 'completed';
  const completedAfter = status === 'completed';
  transaction.update(taskRef, {
    status,
    comment,
    updatedAt: timestampValue,
    updatedByUserId: actor.uid,
    updatedByName: actor.displayName,
    updatedByEmail: actor.email,
    ...(completedAfter ? { completedAt: timestampValue } : {}),
  });
  const requestPatch = {
    updatedAt: timestampValue,
    updatedBy: actor.uid,
    ...(status === 'in_progress' ? { status: 'in_fulfilment' } : {}),
  };
  if (completedBefore !== completedAfter) {
    requestPatch.completedTaskCount = fieldValue.increment(completedAfter ? 1 : -1);
    if (task.isMandatory !== false) {
      requestPatch.completedMandatoryTaskCount = fieldValue.increment(
        completedAfter ? 1 : -1,
      );
    }
  }
  transaction.update(requestRef, requestPatch);
  writeAudit({
    transaction,
    db,
    fieldValue,
    actor,
    command,
    receiptId,
    entityType: 'service_request',
    entityId: requestId,
    parentRef: requestRef,
    action: 'task_updated',
    before: { taskId, status: task.status },
    after: { taskId, status },
  });
  return { requestId, taskId, status, wasDuplicate: false };
}

async function saveKnowledgeDraft({
  db,
  fieldValue,
  transaction,
  actor,
  command,
  receiptId,
}) {
  const payload = command.payload;
  const categorySnapshot = await transaction.get(
    db.collection('knowledgeCategories').doc(payload.categoryId),
  );
  requireExisting(categorySnapshot, 'The knowledge category does not exist.');
  if ((categorySnapshot.data() || {}).isActive === false) {
    throw failed('The knowledge category is inactive.');
  }
  const articleId = payload.articleId || `kb_${receiptId.substring(0, 24)}`;
  const articleRef = db.collection('knowledgeArticles').doc(articleId);
  const articleSnapshot = await transaction.get(articleRef);
  const existing = articleSnapshot.exists ? articleSnapshot.data() || {} : null;
  const existingState = normalizeString(existing && existing.state).toLowerCase();
  if (existing && !['draft', 'published', 'retired'].includes(existingState)) {
    throw failed(`An article in ${existingState} cannot be edited.`);
  }
  const currentVersion = existing ? positiveInteger(existing.currentVersionNumber, 1) : 0;
  if (payload.expectedVersionNumber && currentVersion !== payload.expectedVersionNumber) {
    throw conflict('The knowledge article version has changed.');
  }
  const versionNumber = !existing
    ? 1
    : ['published', 'retired'].includes(existingState)
      ? currentVersion + 1
      : currentVersion;
  const versionRef = articleRef
    .collection('versions')
    .doc(versionDocumentId(versionNumber));
  let existingDraftAttachmentIds = [];
  if (existingState === 'draft') {
    const versionSnapshot = await transaction.get(versionRef);
    if (versionSnapshot.exists) {
      const versionData = versionSnapshot.data() || {};
      if (normalizeString(versionData.state) !== 'draft') {
        throw failed('Published knowledge versions are immutable.');
      }
      existingDraftAttachmentIds = Array.isArray(versionData.attachmentIds)
        ? versionData.attachmentIds.map(normalizeString).filter(Boolean)
        : [];
    }
  }
  const timestampValue = fieldValue.serverTimestamp();
  const author = actorMap(actor);
  const related = {
    relatedServiceIds: payload.relatedServiceIds,
    relatedCatalogueItemIds: payload.relatedCatalogueItemIds,
    relatedIncidentCategoryIds: payload.relatedIncidentCategoryIds,
  };
  const suggestionCriteria = {
    serviceIds: payload.relatedServiceIds,
    catalogueItemIds: payload.relatedCatalogueItemIds,
    incidentCategoryIds: payload.relatedIncidentCategoryIds,
  };
  const article = {
    reference: existing && existing.reference || buildReference('KB', trustedNow(), receiptId),
    categoryId: payload.categoryId,
    title: payload.title,
    summary: payload.summary,
    languageCode: payload.languageCode,
    state: 'draft',
    visibility: payload.visibility,
    isFeatured: payload.isFeatured,
    currentVersionNumber: versionNumber,
    currentVersionId: versionDocumentId(versionNumber),
    publishedVersionNumber: existing && existing.publishedVersionNumber || null,
    author: existing && existing.author || author,
    authorId: existing && existing.authorId || actor.uid,
    reviewer: null,
    reviewerId: null,
    reviewComment: '',
    reviewDueAt: null,
    expiresAt: existing && existing.expiresAt || null,
    submittedAt: null,
    reviewedAt: existing && existing.reviewedAt || null,
    publishedAt: existing && existing.publishedAt || null,
    retiredAt: existing && existing.retiredAt || null,
    archivedAt: null,
    createdAt: existing && existing.createdAt || timestampValue,
    updatedAt: timestampValue,
    helpfulCount: Number(existing && existing.helpfulCount || 0),
    notHelpfulCount: Number(existing && existing.notHelpfulCount || 0),
    viewCount: Number(existing && existing.viewCount || 0),
    usageCount: Number(existing && existing.usageCount || 0),
    ...related,
    suggestionCriteria,
    suggestionKeys: buildSuggestionKeys(suggestionCriteria),
    searchTokens: buildSearchTokens([
      payload.title,
      payload.summary,
      existing && existing.reference,
    ]),
  };
  transaction.set(articleRef, article, { merge: false });
  transaction.set(versionRef, {
    versionNumber,
    title: payload.title,
    summary: payload.summary,
    content: payload.content,
    languageCode: payload.languageCode,
    state: 'draft',
    author,
    reviewer: null,
    reviewComment: '',
    createdAt: timestampValue,
    submittedAt: null,
    reviewedAt: null,
    publishedAt: null,
    attachments: [],
    attachmentIds: existingDraftAttachmentIds,
  }, { merge: false });
  writeAudit({
    transaction,
    db,
    fieldValue,
    actor,
    command,
    receiptId,
    entityType: 'knowledge_article',
    entityId: articleId,
    parentRef: articleRef,
    action: existing ? 'draft_saved' : 'draft_created',
    after: { state: 'draft', versionNumber },
  });
  return { articleId, versionNumber, state: 'draft', wasDuplicate: false };
}

async function transitionKnowledge({
  db,
  fieldValue,
  transaction,
  actor,
  command,
  receiptId,
}, targetState) {
  const payload = command.payload;
  const articleRef = db.collection('knowledgeArticles').doc(payload.articleId);
  const articleSnapshot = await transaction.get(articleRef);
  requireExisting(articleSnapshot, 'The knowledge article does not exist.');
  const article = articleSnapshot.data() || {};
  const currentState = normalizeString(article.state).toLowerCase();
  const allowed = {
    review: 'draft',
    draft: 'review',
    published: 'review',
    retired: 'published',
    archived: 'retired',
  };
  if (allowed[targetState] !== currentState) {
    throw failed(`Cannot transition knowledge from ${currentState} to ${targetState}.`);
  }
  const versionNumber = positiveInteger(article.currentVersionNumber, 1);
  if (payload.expectedVersionNumber && versionNumber !== payload.expectedVersionNumber) {
    throw conflict('The knowledge article version has changed.');
  }
  const versionRef = articleRef
    .collection('versions')
    .doc(versionDocumentId(versionNumber));
  const versionSnapshot = await transaction.get(versionRef);
  requireExisting(versionSnapshot, 'The current knowledge version does not exist.');
  const version = versionSnapshot.data() || {};
  if (normalizeString(version.state).toLowerCase() !== currentState) {
    throw failed('The article and current version states are inconsistent.');
  }
  if (targetState === 'published' &&
      (!normalizeString(version.title) || !normalizeString(version.content))) {
    throw failed('A title and content are required before publication.');
  }
  const timestampValue = fieldValue.serverTimestamp();
  const reviewer = ['draft', 'published'].includes(targetState)
    ? actorMap(actor)
    : article.reviewer || null;
  const reason = normalizeString(payload.reason);
  const articlePatch = {
    state: targetState,
    reviewer,
    reviewerId: reviewer && reviewer.userId || null,
    reviewComment: targetState === 'draft' ? reason : '',
    updatedAt: timestampValue,
    ...(targetState === 'review' ? { submittedAt: timestampValue } : {}),
    ...(['draft', 'published'].includes(targetState)
      ? { reviewedAt: timestampValue }
      : {}),
    ...(targetState === 'published'
      ? { publishedAt: timestampValue, publishedVersionNumber: versionNumber }
      : {}),
    ...(targetState === 'retired' ? { retiredAt: timestampValue } : {}),
    ...(targetState === 'archived' ? { archivedAt: timestampValue } : {}),
  };
  const versionPatch = {
    state: targetState,
    reviewer,
    reviewComment: targetState === 'draft' ? reason : '',
    ...(targetState === 'review' ? { submittedAt: timestampValue } : {}),
    ...(['draft', 'published'].includes(targetState)
      ? { reviewedAt: timestampValue }
      : {}),
    ...(targetState === 'published' ? { publishedAt: timestampValue } : {}),
  };
  transaction.update(articleRef, articlePatch);
  transaction.update(versionRef, versionPatch);
  writeAudit({
    transaction,
    db,
    fieldValue,
    actor,
    command,
    receiptId,
    entityType: 'knowledge_article',
    entityId: payload.articleId,
    parentRef: articleRef,
    action: `transitioned_to_${targetState}`,
    before: { state: currentState },
    after: { state: targetState, reason },
  });
  return {
    articleId: payload.articleId,
    versionNumber,
    state: targetState,
    wasDuplicate: false,
  };
}

async function recordKnowledgeView({
  db,
  fieldValue,
  transaction,
  actor,
  command,
}) {
  const articleRef = db.collection('knowledgeArticles').doc(command.payload.articleId);
  const snapshot = await transaction.get(articleRef);
  requirePublishedKnowledge(snapshot, actor);
  transaction.update(articleRef, {
    viewCount: fieldValue.increment(1),
    usageCount: fieldValue.increment(1),
  });
  return { articleId: command.payload.articleId, recorded: true };
}

async function recordKnowledgeFeedback({
  db,
  fieldValue,
  transaction,
  actor,
  command,
}) {
  const { articleId, helpful, comment } = command.payload;
  const articleRef = db.collection('knowledgeArticles').doc(articleId);
  const articleSnapshot = await transaction.get(articleRef);
  requirePublishedKnowledge(articleSnapshot, actor);
  const feedbackRef = articleRef.collection('feedback').doc(actor.uid);
  const feedbackSnapshot = await transaction.get(feedbackRef);
  const previous = feedbackSnapshot.exists ? feedbackSnapshot.data() || {} : null;
  let helpfulDelta = helpful ? 1 : 0;
  let notHelpfulDelta = helpful ? 0 : 1;
  if (previous) {
    helpfulDelta -= previous.helpful === true ? 1 : 0;
    notHelpfulDelta -= previous.helpful === true ? 0 : 1;
  }
  transaction.set(feedbackRef, {
    userId: actor.uid,
    helpful,
    comment,
    createdAt: previous && previous.createdAt || fieldValue.serverTimestamp(),
    updatedAt: fieldValue.serverTimestamp(),
  }, { merge: false });
  transaction.update(articleRef, {
    helpfulCount: fieldValue.increment(helpfulDelta),
    notHelpfulCount: fieldValue.increment(notHelpfulDelta),
  });
  return { articleId, helpful, recorded: true };
}

function validatePublishedCatalogueItem(catalogue, actor, agent, now) {
  if (normalizeString(catalogue.status).toLowerCase() !== 'published') {
    throw failed('The catalogue item is not published.');
  }
  const roles = Array.isArray(catalogue.visibleRoles)
    ? catalogue.visibleRoles.map(normalizeRole)
    : [];
  if (!roles.includes(actor.role)) {
    throw denied('The catalogue item is not visible to this role.');
  }
  const activeFrom = dateValue(catalogue.activeFrom);
  const activeUntil = dateValue(catalogue.activeUntil);
  if ((activeFrom && now < activeFrom) || (activeUntil && now > activeUntil)) {
    throw failed('The catalogue item is not currently available.');
  }
  if (agent.isActive === false) throw denied('The agent profile is disabled.');
}

async function resolveRequestedFor({
  db,
  transaction,
  actor,
  agent,
  requestedForUserId,
  allowOnBehalf,
}) {
  const targetId = requestedForUserId || actor.uid;
  if (targetId !== actor.uid && actor.role !== ITSM_ROLES.manager) {
    throw denied('Only a MANAGER can create a request for another agent.');
  }
  if (targetId !== actor.uid && !allowOnBehalf) {
    throw failed('This catalogue item does not allow requests on behalf.');
  }
  let target = agent;
  if (targetId !== actor.uid) {
    const snapshot = await transaction.get(db.collection('agents').doc(targetId));
    requireExisting(snapshot, 'The requested-for agent does not exist.');
    target = snapshot.data() || {};
  }
  if (target.isActive === false) throw failed('The requested-for agent is inactive.');
  return {
    uid: targetId,
    displayName: agentName(target),
    email: normalizeString(target.email).toLowerCase(),
    departmentId: nullableString(target.departmentId),
    departmentName: nullableString(target.departmentName || target.directionName),
    serviceId: nullableString(target.serviceId),
    serviceName: nullableString(target.serviceName),
  };
}

function validateEligibility(eligibility, principal) {
  const excluded = stringList(eligibility.excludedUserIds);
  if (excluded.includes(principal.uid)) throw denied('The agent is not eligible.');
  if (eligibility.allEmployees !== false) return;
  const eligible = stringList(eligibility.userIds).includes(principal.uid) ||
    stringList(eligibility.departmentIds).includes(principal.departmentId) ||
    stringList(eligibility.serviceIds).includes(principal.serviceId);
  if (!eligible) throw denied('The agent is not eligible for this catalogue item.');
}

function validateDynamicResponses(catalogue, responses) {
  const missingFields = [];
  for (const field of Array.isArray(catalogue.formFields) ? catalogue.formFields : []) {
    const key = normalizeString(field.key);
    if (!key) continue;
    const value = responses[key];
    if (field.required === true && isEmpty(value)) missingFields.push(key);
    validateFieldValue(field, value, key);
  }
  if (missingFields.length > 0) {
    throw new ItsmCommandError(
      'failed-precondition',
      'Required catalogue responses are missing.',
      { missingFields },
    );
  }
}

function validateFieldValue(field, value, key) {
  if (isEmpty(value)) return;
  const type = normalizeString(field.type).toLowerCase();
  if (['integer', 'decimal'].includes(type) && typeof value !== 'number') {
    throw invalid(`${key} must be a number.`);
  }
  if (type === 'boolean' && typeof value !== 'boolean') {
    throw invalid(`${key} must be a boolean.`);
  }
  const options = Array.isArray(field.options)
    ? field.options.map((option) => normalizeString(option && option.value))
    : [];
  if (type === 'single_select' && !options.includes(normalizeString(value))) {
    throw invalid(`${key} contains an unsupported option.`);
  }
  if (type === 'multi_select' &&
      (!Array.isArray(value) || value.some((item) => !options.includes(item)))) {
    throw invalid(`${key} contains unsupported options.`);
  }
}

function validateRequiredDocuments(catalogue, attachments, request, actor) {
  for (const attachment of attachments) {
    if (normalizeString(attachment.requestId) !== normalizeString(request.id) &&
        normalizeString(attachment.workItemId) !== normalizeString(request.id)) {
      // Older trusted metadata may not repeat the parent ID; path validation below remains authoritative.
    }
    if (normalizeString(attachment.uploadedByUserId) !== actor.uid &&
        actor.role !== ITSM_ROLES.manager) {
      throw denied('An attachment was uploaded by another agent.');
    }
    const expectedPrefix = `itsm/serviceRequests/${request.id}/attachments/`;
    if (!normalizeString(attachment.storagePath).startsWith(expectedPrefix)) {
      throw failed('An attachment has an invalid storage path.');
    }
  }
  const missingDocuments = [];
  for (const requirement of Array.isArray(catalogue.requiredDocuments)
    ? catalogue.requiredDocuments
    : []) {
    const key = normalizeString(requirement.key);
    const matching = attachments.filter((attachment) =>
      normalizeString(attachment.documentRequirementKey) === key,
    );
    if (requirement.required !== false && matching.length === 0) {
      missingDocuments.push(key);
    }
    const maximum = positiveInteger(requirement.maximumFiles, 1);
    if (matching.length > maximum) {
      throw failed(`Too many files were uploaded for ${key}.`);
    }
    const allowed = stringList(requirement.allowedContentTypes)
      .map((type) => type.toLowerCase());
    if (allowed.length > 0 && matching.some((attachment) =>
      !allowed.includes(normalizeString(attachment.contentType).toLowerCase()),
    )) {
      throw failed(`A file uploaded for ${key} has an unsupported type.`);
    }
  }
  if (missingDocuments.length > 0) {
    throw new ItsmCommandError(
      'failed-precondition',
      'Required catalogue documents are missing.',
      { missingDocuments },
    );
  }
}

function requireDraftOwner(request, actor) {
  if (actor.role === ITSM_ROLES.manager) return;
  if (normalizeString(request.requesterId) !== actor.uid) {
    throw denied('Only the requester can submit this draft.');
  }
}

async function resolvePublishedVersion({
  db,
  transaction,
  parentCollection,
  reference,
  label,
}) {
  const parentRef = db.collection(parentCollection).doc(reference.id);
  const parentSnapshot = await transaction.get(parentRef);
  requireExisting(parentSnapshot, `The configured ${label} does not exist.`);
  if (normalizeString((parentSnapshot.data() || {}).status).toLowerCase() !== 'published') {
    throw failed(`The configured ${label} is not published.`);
  }
  const ids = [versionDocumentId(reference.version), String(reference.version)];
  for (const id of ids) {
    const snapshot = await transaction.get(parentRef.collection('versions').doc(id));
    if (snapshot.exists) {
      const data = snapshot.data() || {};
      if (normalizeString(data.status || data.state).toLowerCase() !== 'published') {
        throw failed(`The configured ${label} version is not published.`);
      }
      return { data, documentId: id };
    }
  }
  throw failed(`The configured ${label} version does not exist.`);
}

async function resolvePublishedCatalogueVersion({
  transaction,
  parentRef,
  parentSnapshot,
}) {
  const parent = parentSnapshot.data() || {};
  const version = positiveInteger(
    parent.currentPublishedVersion || parent.publishedVersion || parent.version,
    1,
  );
  const explicitDocumentId = normalizeString(
    parent.currentPublishedVersionId ||
      parent.currentPublishedVersionDocumentId,
  );
  const candidates = [
    explicitDocumentId,
    versionDocumentId(version),
    String(version),
  ].filter(Boolean);
  for (const documentId of [...new Set(candidates)]) {
    const snapshot = await transaction.get(
      parentRef.collection('versions').doc(documentId),
    );
    if (!snapshot.exists) continue;
    const data = snapshot.data() || {};
    if (normalizeString(data.status || data.state).toLowerCase() !== 'published') {
      throw failed('The configured catalogue item version is not published.');
    }
    return {
      data,
      documentId,
      version: positiveInteger(data.version, version),
    };
  }
  if (explicitDocumentId) {
    throw failed('The configured catalogue item version does not exist.');
  }

  // Existing parent-only catalogue records remain readable until explicitly
  // versioned; all newly administered records carry a published-version ID.
  return { data: parent, documentId: null, version };
}

async function getPinnedCatalogueVersion({
  db,
  transaction,
  catalogueItemId,
  versionDocumentId: storedDocumentId,
  version,
}) {
  const parentRef = db
    .collection('serviceCatalogItems')
    .doc(normalizeString(catalogueItemId));
  const documentId = normalizeString(storedDocumentId);
  if (documentId) {
    const snapshot = await transaction.get(
      parentRef.collection('versions').doc(documentId),
    );
    requireExisting(snapshot, 'The pinned catalogue item version does not exist.');
    return snapshot.data() || {};
  }

  const parentSnapshot = await transaction.get(parentRef);
  requireExisting(parentSnapshot, 'The catalogue item no longer exists.');
  const parent = parentSnapshot.data() || {};
  if (positiveInteger(parent.version, 1) !== positiveInteger(version, 1)) {
    throw failed(
      'The legacy catalogue item changed before this draft was submitted.',
    );
  }
  return parent;
}

async function getPinnedVersion({
  db,
  transaction,
  parentCollection,
  definitionId,
  versionDocumentId: storedDocumentId,
  version,
}) {
  const parent = db.collection(parentCollection).doc(normalizeString(definitionId));
  const ids = [normalizeString(storedDocumentId), versionDocumentId(version)]
    .filter(Boolean);
  for (const id of [...new Set(ids)]) {
    const snapshot = await transaction.get(parent.collection('versions').doc(id));
    if (snapshot.exists) return snapshot.data() || {};
  }
  throw failed('The pinned workflow version does not exist.');
}

function configurationReference(value, label) {
  const map = value && typeof value === 'object' && !Array.isArray(value)
    ? value
    : {};
  const id = normalizeString(map.id);
  const version = positiveInteger(map.version, 0);
  if (!id || version < 1) throw failed(`The catalogue ${label} is invalid.`);
  return { id, version };
}

function requirePublishedKnowledge(snapshot, actor) {
  requireExisting(snapshot, 'The knowledge article does not exist.');
  const article = snapshot.data() || {};
  if (normalizeString(article.state).toLowerCase() !== 'published') {
    throw failed('The knowledge article is not published.');
  }
  if (actor.role !== ITSM_ROLES.manager &&
      normalizeString(article.visibility).toLowerCase() !== 'employee') {
    throw denied('The knowledge article is restricted.');
  }
}

function writeIndex(transaction, db, requestId, request) {
  const summary = buildSupportWorkItemIndex({
    collectionName: 'serviceRequests',
    workItemId: requestId,
    data: { ...request, id: requestId },
  });
  transaction.set(
    db.collection('itsmWorkItemIndex').doc(`service_request:${requestId}`),
    summary,
    { merge: false },
  );
}

function writeAudit({
  transaction,
  db,
  fieldValue,
  actor,
  command,
  receiptId,
  entityType,
  entityId,
  parentRef,
  action,
  before = {},
  after = {},
}) {
  const id = deterministicId('audit', receiptId, entityType, entityId, action);
  const event = {
    eventType: `${entityType}.${action}`,
    action,
    summary: `${entityType} ${action}`,
    entityType,
    entityId,
    actorUserId: actor.uid,
    actorName: actor.displayName,
    actorEmail: actor.email,
    actorRole: actor.role,
    before,
    after,
    sourceCommand: command.command,
    sourceIdempotencyKey: command.idempotencyKey,
    createdAt: fieldValue.serverTimestamp(),
  };
  transaction.set(parentRef.collection('auditLogs').doc(id), event);
  transaction.set(db.collection('itsmAuditEvents').doc(id), {
    ...event,
    sourcePath: parentRef.path,
  });
}

function buildReference(prefix, date, receiptId) {
  const iso = date.toISOString().replace(/\D/g, '').substring(0, 14);
  return `${prefix}-${iso}-${receiptId.substring(0, 6).toUpperCase()}`;
}

function workflowEntries(workflow, key) {
  return Array.isArray(workflow[key]) ? workflow[key] : [];
}

function buildSearchTokens(values) {
  const tokens = new Set();
  for (const value of values) {
    const normalized = normalizeString(value)
      .toLowerCase()
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .replace(/[^a-z0-9]+/g, ' ')
      .trim();
    if (!normalized) continue;
    for (const word of normalized.split(/\s+/)) {
      for (let length = 1; length <= Math.min(word.length, 30); length += 1) {
        tokens.add(word.substring(0, length));
      }
    }
  }
  return [...tokens].sort().slice(0, 500);
}

function buildSuggestionKeys(criteria) {
  return [
    ...stringList(criteria.serviceIds).map((id) => `service:${id}`),
    ...stringList(criteria.catalogueItemIds).map((id) => `catalogue:${id}`),
    ...stringList(criteria.incidentCategoryIds).map((id) => `incident_category:${id}`),
  ];
}

function actorMap(actor) {
  return { userId: actor.uid, name: actor.displayName, email: actor.email };
}

function agentName(agent) {
  return [agent.firstName, agent.name, agent.postName]
    .map(normalizeString)
    .filter(Boolean)
    .join(' ');
}

function localizedText(value) {
  if (typeof value === 'string') return normalizeString(value);
  if (!value || typeof value !== 'object' || Array.isArray(value)) return '';
  return normalizeString(value.en || value.fr || Object.values(value)[0]);
}

function trustedNow(timestamp = {}) {
  const value = typeof timestamp.now === 'function' ? timestamp.now() : new Date();
  return dateValue(value) || new Date();
}

function dueAt(timestamp, now, minutes) {
  const amount = Number(minutes);
  if (!Number.isFinite(amount) || amount < 0) return now;
  const millis = now.getTime() + amount * 60 * 1000;
  return typeof timestamp.fromMillis === 'function'
    ? timestamp.fromMillis(millis)
    : new Date(millis);
}

function warningAt({
  timestamp,
  now,
  due,
  targetMinutes,
  warningThresholdMinutes,
  warningThresholdPercent,
}) {
  const dueDate = dateValue(due);
  if (!dueDate) return null;
  const explicitMinutes = Number(warningThresholdMinutes);
  let millis;
  if (Number.isFinite(explicitMinutes) && explicitMinutes > 0) {
    millis = dueDate.getTime() - explicitMinutes * 60 * 1000;
  } else {
    const target = Number(targetMinutes);
    const configuredPercent = Number(warningThresholdPercent);
    const percent = Number.isFinite(configuredPercent) &&
      configuredPercent > 0 && configuredPercent < 100
      ? configuredPercent
      : 80;
    millis = Number.isFinite(target) && target > 0
      ? now.getTime() + target * (percent / 100) * 60 * 1000
      : dueDate.getTime();
  }
  const bounded = Math.min(dueDate.getTime(), Math.max(now.getTime(), millis));
  return typeof timestamp.fromMillis === 'function'
    ? timestamp.fromMillis(bounded)
    : new Date(bounded);
}

function dateValue(value) {
  if (!value) return null;
  if (value instanceof Date) return value;
  if (typeof value.toDate === 'function') return value.toDate();
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}

function versionDocumentId(version) {
  return String(positiveInteger(version, 1)).padStart(6, '0');
}

function stringList(value) {
  return Array.isArray(value) ? value.map(normalizeString).filter(Boolean) : [];
}

function positiveInteger(value, fallback) {
  const number = Number(value);
  return Number.isSafeInteger(number) && number > 0 ? number : fallback;
}

function nullableString(value) {
  const normalized = normalizeString(value);
  return normalized || null;
}

function isEmpty(value) {
  return value === undefined || value === null ||
    (typeof value === 'string' && !value.trim()) ||
    (Array.isArray(value) && value.length === 0);
}

function requireExisting(snapshot, message) {
  if (!snapshot || !snapshot.exists) throw new ItsmCommandError('not-found', message);
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

function conflict(message) {
  return new ItsmCommandError('aborted', message);
}

module.exports = {
  executeSupportCommand,
  initializeServiceRequestDraft,
  recordKnowledgeFeedback,
  recordKnowledgeView,
  saveKnowledgeDraft,
  submitServiceRequest,
  transitionKnowledge,
  updateServiceRequestTask,
};
