'use strict';

const {
  ITSM_ROLES,
  ItsmCommandError,
  normalizeString,
} = require('./itsm_permissions');
const { runIdempotentCommand } = require('./itsm_idempotency');
const {
  REPORTING_ADMINISTRATION_COMMANDS: C,
  validateCatalogueDefinition,
  validateSlaPolicyDefinition,
  validateWorkflowDefinition,
  workflowValidationIssues,
} = require('./itsm_reporting_administration_validation');

const CONFIGURATION_TYPES = Object.freeze({
  sla: Object.freeze({
    collection: 'slaPolicies',
    entityType: 'sla_policy',
    commandFragment: '.sla.',
  }),
  catalogue: Object.freeze({
    collection: 'serviceCatalogItems',
    entityType: 'service_catalogue_item',
    commandFragment: '.catalogue.',
  }),
  workflow: Object.freeze({
    collection: 'workflowDefinitions',
    entityType: 'workflow_definition',
    commandFragment: '.workflow.',
  }),
});

async function executeReportingAdministrationCommand({
  db,
  fieldValue,
  timestamp,
  actor,
  command,
}) {
  enforceCommandRole(actor, command.command);
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
      };
      let result;
      if (command.command === C.requestAuditExport) {
        result = await requestAuditExport(context);
      } else if (command.command === C.recalculateSla) {
        result = await requestSlaRecalculation(context);
      } else if (command.command.includes('.create_draft')) {
        result = await createConfigurationDraft(context);
      } else if (command.command.includes('.update_draft')) {
        result = await updateConfigurationDraft(context);
      } else if (command.command.includes('.validate_draft')) {
        result = await validateConfigurationDraft(context);
      } else if (command.command.includes('.publish_version')) {
        result = await publishConfigurationVersion(context);
      } else if (command.command.includes('.retire_version')) {
        result = await retireConfigurationVersion(context);
      } else {
        throw invalid(
          `Unsupported Reporting & Administration command ${command.command}.`,
        );
      }
      return commandReceipt(result, receiptId, timestamp);
    },
  });
}

async function createConfigurationDraft(context) {
  const {
    db,
    fieldValue,
    transaction,
    actor,
    command,
    receiptId,
  } = context;
  const type = configurationType(command.command);
  const definitionId = command.payload.definitionId ||
    `${type.entityType}_${receiptId.slice(0, 24)}`;
  const parentRef = db.collection(type.collection).doc(definitionId);
  const parentSnapshot = await transaction.get(parentRef);
  const parent = parentSnapshot.exists ? parentSnapshot.data() || {} : {};
  if (normalizeString(parent.currentDraftVersionDocumentId)) {
    throw precondition('Complete or publish the current draft before creating another.');
  }
  const latestVersion = Math.max(0, Number(parent.latestVersion || 0));
  const version = latestVersion + 1;
  const versionDocumentId = `v${version}`;
  const versionRef = parentRef.collection('versions').doc(versionDocumentId);
  let sourceDefinition = {};
  if (command.payload.sourceVersionDocumentId) {
    if (!parentSnapshot.exists) {
      throw precondition('A source version requires an existing definition.');
    }
    const sourceSnapshot = await transaction.get(
      parentRef.collection('versions').doc(command.payload.sourceVersionDocumentId),
    );
    if (!sourceSnapshot.exists) throw notFound('The source version does not exist.');
    sourceDefinition = sourceSnapshot.get('definition') || {};
  }
  const definition = validateDefinitionForType(type, {
    ...sourceDefinition,
    ...command.payload.draft,
  });
  const serverTime = fieldValue.serverTimestamp();
  const versionData = {
    schemaVersion: 1,
    definitionId,
    version,
    versionDocumentId,
    status: 'draft',
    definition,
    revision: 0,
    validation: null,
    createdAt: serverTime,
    createdBy: actor.uid,
    updatedAt: serverTime,
    updatedBy: actor.uid,
  };
  transaction.create(versionRef, versionData);
  if (parentSnapshot.exists) {
    transaction.update(parentRef, {
      latestVersion: version,
      currentDraftVersion: version,
      currentDraftVersionDocumentId: versionDocumentId,
      revision: Number(parent.revision || 0) + 1,
      updatedAt: serverTime,
      updatedBy: actor.uid,
    });
  } else {
    transaction.create(parentRef, {
      schemaVersion: 1,
      id: definitionId,
      status: 'draft',
      latestVersion: version,
      currentDraftVersion: version,
      currentDraftVersionDocumentId: versionDocumentId,
      currentPublishedVersion: null,
      currentPublishedVersionDocumentId: null,
      revision: 0,
      createdAt: serverTime,
      createdBy: actor.uid,
      updatedAt: serverTime,
      updatedBy: actor.uid,
    });
  }
  writeConfigurationAudit({
    ...context,
    type,
    parentRef,
    definitionId,
    action: 'draft_created',
    after: { version, versionDocumentId, status: 'draft' },
  });
  return { definitionId, version, versionDocumentId, status: 'draft', revision: 0 };
}

async function updateConfigurationDraft(context) {
  const { db, fieldValue, transaction, actor, command } = context;
  const type = configurationType(command.command);
  const payload = command.payload;
  const parentRef = db.collection(type.collection).doc(payload.definitionId);
  const versionRef = parentRef.collection('versions').doc(payload.versionDocumentId);
  const versionSnapshot = await transaction.get(versionRef);
  const versionData = requireDraftVersion(versionSnapshot, payload.expectedRevision);
  const definition = validateDefinitionForType(type, payload.draft);
  const revision = payload.expectedRevision + 1;
  transaction.update(versionRef, {
    definition,
    revision,
    validation: null,
    updatedAt: fieldValue.serverTimestamp(),
    updatedBy: actor.uid,
  });
  writeConfigurationAudit({
    ...context,
    type,
    parentRef,
    definitionId: payload.definitionId,
    action: 'draft_updated',
    before: { version: versionData.version, revision: payload.expectedRevision },
    after: { version: versionData.version, revision },
  });
  return {
    definitionId: payload.definitionId,
    version: versionData.version,
    versionDocumentId: payload.versionDocumentId,
    status: 'draft',
    revision,
  };
}

async function validateConfigurationDraft(context) {
  const { db, fieldValue, transaction, actor, command } = context;
  const type = configurationType(command.command);
  const payload = command.payload;
  const parentRef = db.collection(type.collection).doc(payload.definitionId);
  const versionRef = parentRef.collection('versions').doc(payload.versionDocumentId);
  const versionSnapshot = await transaction.get(versionRef);
  const versionData = requireDraftVersion(versionSnapshot, payload.expectedRevision);
  const result = await validateConfigurationReferences({
    db,
    transaction,
    type,
    definition: versionData.definition,
  });
  const revision = payload.expectedRevision + 1;
  transaction.update(versionRef, {
    validation: {
      isValid: result.issues.length === 0,
      issues: result.issues,
      validatedAt: fieldValue.serverTimestamp(),
      validatedBy: actor.uid,
    },
    revision,
    updatedAt: fieldValue.serverTimestamp(),
    updatedBy: actor.uid,
  });
  writeConfigurationAudit({
    ...context,
    type,
    parentRef,
    definitionId: payload.definitionId,
    action: 'draft_validated',
    after: { version: versionData.version, isValid: result.issues.length === 0 },
  });
  return {
    definitionId: payload.definitionId,
    version: versionData.version,
    versionDocumentId: payload.versionDocumentId,
    revision,
    isValid: result.issues.length === 0,
    issues: result.issues,
  };
}

async function publishConfigurationVersion(context) {
  const { db, fieldValue, transaction, actor, command } = context;
  const type = configurationType(command.command);
  const payload = command.payload;
  const parentRef = db.collection(type.collection).doc(payload.definitionId);
  const versionRef = parentRef.collection('versions').doc(payload.versionDocumentId);
  const parentSnapshot = await transaction.get(parentRef);
  if (!parentSnapshot.exists) throw notFound('The configuration definition does not exist.');
  const parent = parentSnapshot.data() || {};
  if (normalizeString(parent.currentDraftVersionDocumentId) !==
      payload.versionDocumentId) {
    throw precondition('Only the current draft version can be published.');
  }
  const versionSnapshot = await transaction.get(versionRef);
  const versionData = requireDraftVersion(versionSnapshot, payload.expectedRevision);
  const validation = await validateConfigurationReferences({
    db,
    transaction,
    type,
    definition: versionData.definition,
  });
  if (validation.issues.length > 0) {
    throw new ItsmCommandError(
      'failed-precondition',
      'The configuration cannot be published until validation succeeds.',
      { issues: validation.issues },
    );
  }
  const serverTime = fieldValue.serverTimestamp();
  const publishedDefinition = type === CONFIGURATION_TYPES.sla
    ? { ...versionData.definition, calendarSnapshot: calendarSnapshot(versionData.definition) }
    : versionData.definition;
  transaction.update(versionRef, {
    definition: publishedDefinition,
    status: 'published',
    publishedAt: serverTime,
    publishedBy: actor.uid,
    revision: payload.expectedRevision + 1,
    validation: {
      isValid: true,
      issues: [],
      validatedAt: serverTime,
      validatedBy: actor.uid,
    },
    updatedAt: serverTime,
    updatedBy: actor.uid,
  });
  transaction.update(parentRef, {
    ...materializedParent(type, publishedDefinition, versionData),
    status: 'published',
    currentPublishedVersion: versionData.version,
    currentPublishedVersionDocumentId: payload.versionDocumentId,
    currentDraftVersion: null,
    currentDraftVersionDocumentId: null,
    revision: Number(parent.revision || 0) + 1,
    publishedAt: serverTime,
    publishedBy: actor.uid,
    updatedAt: serverTime,
    updatedBy: actor.uid,
  });
  writeConfigurationAudit({
    ...context,
    type,
    parentRef,
    definitionId: payload.definitionId,
    action: 'version_published',
    before: {
      currentPublishedVersion: parent.currentPublishedVersion || null,
      currentPublishedVersionDocumentId:
        parent.currentPublishedVersionDocumentId || null,
    },
    after: {
      currentPublishedVersion: versionData.version,
      currentPublishedVersionDocumentId: payload.versionDocumentId,
    },
  });
  return {
    definitionId: payload.definitionId,
    version: versionData.version,
    versionDocumentId: payload.versionDocumentId,
    status: 'published',
    revision: payload.expectedRevision + 1,
  };
}

async function retireConfigurationVersion(context) {
  const { db, fieldValue, transaction, actor, command } = context;
  const type = configurationType(command.command);
  const payload = command.payload;
  const parentRef = db.collection(type.collection).doc(payload.definitionId);
  const snapshot = await transaction.get(parentRef);
  if (!snapshot.exists) throw notFound('The configuration definition does not exist.');
  const parent = snapshot.data() || {};
  requireRevision(parent, payload.expectedRevision);
  if (parent.status !== 'published') {
    throw precondition('Only a published configuration can be retired.');
  }
  const revision = payload.expectedRevision + 1;
  transaction.update(parentRef, {
    status: 'retired',
    retirementReason: payload.reason,
    retiredAt: fieldValue.serverTimestamp(),
    retiredBy: actor.uid,
    revision,
    updatedAt: fieldValue.serverTimestamp(),
    updatedBy: actor.uid,
  });
  writeConfigurationAudit({
    ...context,
    type,
    parentRef,
    definitionId: payload.definitionId,
    action: 'definition_retired',
    before: { status: parent.status },
    after: { status: 'retired', reason: payload.reason },
  });
  return {
    definitionId: payload.definitionId,
    status: 'retired',
    revision,
    pinnedVersionRetained: parent.currentPublishedVersionDocumentId || null,
  };
}

async function requestSlaRecalculation(context) {
  const { db, fieldValue, timestamp, transaction, actor, command } = context;
  const payload = command.payload;
  const ref = db.collection(payload.collectionName).doc(payload.workItemId);
  const snapshot = await transaction.get(ref);
  if (!snapshot.exists) throw notFound('The SLA work item does not exist.');
  const item = snapshot.data() || {};
  const policyId = payload.policyId || normalizeString(item.slaPolicyId);
  if (!policyId) throw precondition('The work item has no SLA policy.');
  const policyRef = db.collection('slaPolicies').doc(policyId);
  const policySnapshot = await transaction.get(policyRef);
  if (!policySnapshot.exists || policySnapshot.get('status') !== 'published') {
    throw precondition('The selected SLA policy is not published.');
  }
  const versionDocumentId = normalizeString(
    policySnapshot.get('currentPublishedVersionDocumentId'),
  );
  if (!versionDocumentId) throw precondition('The SLA policy has no published version.');
  transaction.update(ref, {
    slaPolicyId: policyId,
    slaPolicyVersion: policySnapshot.get('currentPublishedVersion'),
    slaPolicyVersionDocumentId: versionDocumentId,
    slaNextCheckAt: timestamp.now(),
    slaRecalculationRequestedAt: fieldValue.serverTimestamp(),
    slaRecalculationRequestedBy: actor.uid,
  });
  writeConfigurationAudit({
    ...context,
    type: CONFIGURATION_TYPES.sla,
    parentRef: ref,
    definitionId: payload.workItemId,
    entityType: collectionEntityType(payload.collectionName),
    action: 'sla_recalculation_requested',
    after: { policyId, versionDocumentId },
  });
  return {
    collectionName: payload.collectionName,
    workItemId: payload.workItemId,
    policyId,
    versionDocumentId,
    status: 'queued',
  };
}

async function requestAuditExport(context) {
  const { db, fieldValue, timestamp, transaction, actor, command, receiptId } = context;
  const exportId = `audit_export_${receiptId.slice(0, 32)}`;
  const exportRef = db.collection('itsmAuditExports').doc(exportId);
  const payload = command.payload;
  const { maxRows, ...filters } = payload;
  transaction.create(exportRef, {
    schemaVersion: 1,
    requester: {
      userId: actor.uid,
      displayName: actor.displayName,
      email: actor.email,
      role: actor.role,
      departmentId: actor.departmentId || null,
    },
    filters: {
      ...filters,
      startAt: fromDate(timestamp, payload.startAt),
      endAt: fromDate(timestamp, payload.endAt),
    },
    maxRows,
    authorizationScope: actor.role === ITSM_ROLES.admin
      ? 'non_restricted_only'
      : 'manager_authorized',
    status: 'queued',
    rowCount: null,
    expiresAt: null,
    createdAt: fieldValue.serverTimestamp(),
    updatedAt: fieldValue.serverTimestamp(),
  });
  return { exportId, status: 'queued', maxRows: payload.maxRows };
}

async function validateConfigurationReferences({ db, transaction, type, definition }) {
  const issues = type === CONFIGURATION_TYPES.workflow
    ? [...workflowValidationIssues(definition)]
    : [];
  const references = [];
  if (type === CONFIGURATION_TYPES.sla) {
    for (const target of definition.escalationTargets) {
      if (target.assignmentGroupId) {
        references.push(reference('assignment_group', target.assignmentGroupId));
      }
    }
  } else if (type === CONFIGURATION_TYPES.catalogue) {
    references.push(publishedVersionReference(
      'workflowDefinitions',
      definition.workflow,
      'workflow',
    ));
    references.push(publishedVersionReference(
      'slaPolicies',
      definition.slaPolicy,
      'sla_policy',
    ));
    references.push(reference('assignment_group', definition.fulfilmentGroupId));
    if (definition.approvalPolicyId) {
      references.push(reference('approval_policy', definition.approvalPolicyId));
    }
  } else if (type === CONFIGURATION_TYPES.workflow) {
    for (const transition of definition.transitions) {
      if (transition.approvalPolicyId) {
        references.push(reference('approval_policy', transition.approvalPolicyId));
      }
      if (transition.assignmentGroupId) {
        references.push(reference('assignment_group', transition.assignmentGroupId));
      }
    }
  }
  for (const value of deduplicateReferences(references)) {
    const ref = value.collection
      ? db.collection(value.collection).doc(value.definitionId)
        .collection('versions').doc(value.versionDocumentId)
      : db.collection('itsmReferenceData').doc(value.id);
    const snapshot = await transaction.get(ref);
    if (!snapshot.exists) {
      issues.push({ code: 'missing_reference', subjectId: value.subjectId });
      continue;
    }
    const data = snapshot.data() || {};
    if (value.collection && (data.status !== 'published' ||
        Number(data.version) !== value.version)) {
      issues.push({ code: 'reference_not_published', subjectId: value.subjectId });
    }
    if (!value.collection && (data.active === false ||
        normalizeString(data.type) !== value.type)) {
      issues.push({ code: 'inactive_reference', subjectId: value.subjectId });
    }
  }
  return { issues };
}

function writeConfigurationAudit({
  db,
  fieldValue,
  transaction,
  actor,
  command,
  receiptId,
  type,
  parentRef,
  definitionId,
  entityType,
  action,
  before = {},
  after = {},
}) {
  const eventId = `${receiptId}_${action}`.slice(0, 180);
  const createdAt = fieldValue.serverTimestamp();
  const resolvedEntityType = entityType || type.entityType;
  const event = {
    schemaVersion: 1,
    eventType: `itsm.${resolvedEntityType}.${action}`,
    action,
    module: 'ticketing',
    entityType: resolvedEntityType,
    entityId: definitionId,
    entityReference: definitionId,
    sourcePath: parentRef.path,
    actor: {
      userId: actor.uid,
      displayName: actor.displayName,
      email: actor.email,
      role: actor.role,
      departmentId: actor.departmentId || null,
    },
    actorUserId: actor.uid,
    before,
    after,
    correlationId: receiptId,
    sourceCommand: command.command,
    sourceIdempotencyKey: command.idempotencyKey,
    confidentiality: 'internal',
    isRestricted: false,
    authorizedManagerIds: [],
    createdAt,
    occurredAt: createdAt,
  };
  transaction.create(parentRef.collection('auditLogs').doc(eventId), event);
  transaction.create(db.collection('itsmAuditEvents').doc(eventId), event);
}

function configurationType(command) {
  const type = Object.values(CONFIGURATION_TYPES).find(
    (entry) => command.includes(entry.commandFragment),
  );
  if (!type) throw invalid(`No configuration type for ${command}.`);
  return type;
}

function validateDefinitionForType(type, definition) {
  if (type === CONFIGURATION_TYPES.sla) return validateSlaPolicyDefinition(definition);
  if (type === CONFIGURATION_TYPES.catalogue) {
    return validateCatalogueDefinition(definition);
  }
  return validateWorkflowDefinition(definition);
}

function requireDraftVersion(snapshot, expectedRevision) {
  if (!snapshot.exists) throw notFound('The configuration version does not exist.');
  const value = snapshot.data() || {};
  if (value.status !== 'draft') {
    throw precondition('Published and retired versions are immutable.');
  }
  requireRevision(value, expectedRevision);
  return value;
}

function requireRevision(value, expectedRevision) {
  if (Number(value.revision || 0) !== expectedRevision) {
    throw new ItsmCommandError(
      'aborted',
      'The configuration changed. Reload it before trying again.',
      { expectedRevision, actualRevision: Number(value.revision || 0) },
    );
  }
}

function materializedParent(type, definition, versionData) {
  if (type === CONFIGURATION_TYPES.catalogue) {
    return {
      ...definition,
      id: versionData.definitionId,
      version: versionData.version,
      catalogueVersionDocumentId: versionData.versionDocumentId,
      pinnedWorkflowVersionDocumentId: definition.workflow.versionDocumentId,
      pinnedSlaPolicyVersionDocumentId: definition.slaPolicy.versionDocumentId,
    };
  }
  if (type === CONFIGURATION_TYPES.workflow) {
    return {
      ...definition,
      id: versionData.definitionId,
      version: versionData.version,
      workflowVersionDocumentId: versionData.versionDocumentId,
    };
  }
  return {
    ...definition,
    id: versionData.definitionId,
    version: versionData.version,
    slaPolicyVersionDocumentId: versionData.versionDocumentId,
  };
}

function calendarSnapshot(definition) {
  return {
    timeZone: definition.timeZone,
    weeklyWindows: definition.weeklyWindows,
    holidays: definition.holidays,
  };
}

function publishedVersionReference(collection, value, type) {
  return {
    collection,
    definitionId: value.definitionId,
    version: value.version,
    versionDocumentId: value.versionDocumentId,
    subjectId: `${type}:${value.definitionId}:${value.versionDocumentId}`,
  };
}

function reference(type, id) {
  return { type, id, subjectId: `${type}:${id}` };
}

function deduplicateReferences(values) {
  return [...new Map(values.map((value) => [JSON.stringify(value), value])).values()];
}

function collectionEntityType(collectionName) {
  return ({
    incidentTickets: 'incident',
    serviceRequests: 'service_request',
    changeRequests: 'change_request',
    securityFindings: 'security_finding',
    securityExceptions: 'security_exception',
    assetComplianceAssessments: 'asset_compliance_assessment',
    accessReviewItems: 'access_review_item',
  })[collectionName];
}

function fromDate(timestamp, date) {
  return typeof timestamp.fromDate === 'function' ? timestamp.fromDate(date) : date;
}

function commandReceipt(result, receiptId, timestamp) {
  return {
    ...result,
    commandId: receiptId,
    receiptId,
    entityId: result.definitionId || result.workItemId || result.exportId || null,
    versionId: result.versionDocumentId || null,
    acceptedAt: timestamp.now(),
    wasDuplicate: false,
  };
}

function enforceCommandRole(actor, command) {
  if (command === C.requestAuditExport) {
    if (![ITSM_ROLES.manager, ITSM_ROLES.admin].includes(actor.role)) {
      throw denied('Only MANAGER and ADMIN can request an audit export.');
    }
    return;
  }
  if (actor.role !== ITSM_ROLES.manager) {
    throw denied('Only MANAGER can modify ITSM configuration.');
  }
}

function invalid(message) {
  return new ItsmCommandError('invalid-argument', message);
}

function denied(message) {
  return new ItsmCommandError('permission-denied', message);
}

function precondition(message) {
  return new ItsmCommandError('failed-precondition', message);
}

function notFound(message) {
  return new ItsmCommandError('not-found', message);
}

module.exports = {
  CONFIGURATION_TYPES,
  calendarSnapshot,
  enforceCommandRole,
  executeReportingAdministrationCommand,
  materializedParent,
  validateConfigurationReferences,
  writeConfigurationAudit,
};
