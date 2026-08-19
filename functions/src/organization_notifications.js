'use strict';

const crypto = require('node:crypto');
const { FieldPath } = require('firebase-admin/firestore');

const ORGANIZATION_SCOPE_TARGET_TYPE = 'ORG_SCOPE';
const MAX_RECIPIENT_PAGE_SIZE = 400;
const MAX_FIRESTORE_BATCH_WRITES = 400;
const MAX_TARGET_ROLES = 10;
const ORGANIZATION_NOTIFICATION_COMMAND = 'sendOrganizationNotification';
const ORGANIZATION_NOTIFICATION_EVENT_POLICIES = Object.freeze({
  'organization.announcement.published': Object.freeze({
    entityType: 'organization',
    scopeKind: 'org',
    sourceCollection: 'organizations',
  }),
  'organization_unit.announcement.published': Object.freeze({
    entityType: 'organizationUnit',
    scopeKind: 'unit',
    sourceCollection: 'organizationUnits',
  }),
});

class OrganizationNotificationError extends Error {
  constructor(code, message) {
    super(message);
    this.name = 'OrganizationNotificationError';
    this.code = code;
  }
}

function validateOrganizationNotificationPayload(value) {
  const payload = object(value, 'notification payload');
  const source = validateNotificationSource(payload.source);
  return {
    commandId: safeIdentifier(
      payload.commandId,
      'commandId',
      180,
    ),
    title: requiredText(payload.title, 'title', 160),
    body: requiredText(payload.body, 'body', 1000),
    source,
    target: validateOrganizationNotificationTarget(payload.target),
  };
}

function validateNotificationSource(value) {
  const source = object(value, 'notification source');
  const route = requiredText(source.route, 'source.route', 500);
  if (!route.startsWith('/') || route.startsWith('//')) {
    throw invalid('source.route must be an internal application route.');
  }
  return {
    id: safeIdentifier(
      source.id || source.sourceId || source.eventId,
      'source.id',
      180,
    ),
    eventType: safeIdentifier(source.eventType, 'source.eventType', 100),
    moduleKey: normalizeModuleKey(source.moduleKey, 'source.moduleKey'),
    entityType: safeIdentifier(source.entityType, 'source.entityType', 80),
    entityId: safeIdentifier(source.entityId, 'source.entityId', 200),
    route,
  };
}

function validateOrganizationNotificationTarget(value) {
  const target = object(value, 'notification target');
  const type = normalizeString(target.type).toUpperCase();
  if (type !== ORGANIZATION_SCOPE_TARGET_TYPE) {
    throw invalid(`target.type must be ${ORGANIZATION_SCOPE_TARGET_TYPE}.`);
  }

  const organizationId = safeIdentifier(
    target.organizationId,
    'target.organizationId',
    200,
  );
  const scopeKey = validateScopeKey(target.scopeKey, organizationId);
  const hasModuleKey = Boolean(normalizeString(target.moduleKey));
  const roles = normalizeRoles(target.roles);
  if (hasModuleKey !== (roles.length > 0)) {
    throw invalid('target.moduleKey and target.roles must be provided together.');
  }

  return {
    type: ORGANIZATION_SCOPE_TARGET_TYPE,
    organizationId,
    scopeKey,
    ...(hasModuleKey ? {
      moduleKey: normalizeModuleKey(target.moduleKey, 'target.moduleKey'),
      roles,
    } : {}),
  };
}

function validateScopeKey(value, organizationId) {
  const scopeKey = requiredText(value, 'target.scopeKey', 260);
  const separatorIndex = scopeKey.indexOf(':');
  if (separatorIndex <= 0) {
    throw invalid('target.scopeKey must use the org:<id> or unit:<id> format.');
  }
  const kind = scopeKey.substring(0, separatorIndex).toLowerCase();
  const id = safeIdentifier(
    scopeKey.substring(separatorIndex + 1),
    'target.scopeKey identifier',
    200,
  );
  if (kind === 'org') {
    if (id !== organizationId) {
      throw invalid('The organization scope must match target.organizationId.');
    }
    return `org:${id}`;
  }
  if (kind === 'unit') return `unit:${id}`;
  throw invalid('target.scopeKey must use the org:<id> or unit:<id> format.');
}

function normalizeRoles(value) {
  if (value === undefined || value === null) return [];
  if (!Array.isArray(value)) throw invalid('target.roles must be an array.');
  const roles = [...new Set(value.map((entry) => {
    const role = normalizeString(entry).toUpperCase();
    if (!/^[A-Z][A-Z0-9_]{0,31}$/.test(role) || role === 'NONE') {
      throw invalid('target.roles contains an invalid role.');
    }
    return role;
  }))].sort();
  if (roles.length === 0 || roles.length > MAX_TARGET_ROLES) {
    throw invalid(`target.roles must contain between 1 and ${MAX_TARGET_ROLES} roles.`);
  }
  return roles;
}

function buildAuthorizationQueryPlans(targetValue) {
  const target = validateOrganizationNotificationTarget(targetValue);
  if (!target.moduleKey) {
    return [{ field: 'scopeKeys', key: target.scopeKey }];
  }
  return target.roles.map((role) => ({
    field: 'scopeRoleKeys',
    key: `${target.scopeKey}|${target.moduleKey}:${role}`,
  }));
}

function isAuthorizationProjectionRecipient(projectionValue, targetValue) {
  const projection = projectionValue && typeof projectionValue === 'object'
    ? projectionValue
    : {};
  const target = validateOrganizationNotificationTarget(targetValue);
  if (
    projection.isActive !== true ||
    normalizeString(projection.organizationId) !== target.organizationId
  ) {
    return false;
  }
  return buildAuthorizationQueryPlans(target).some(({ field, key }) =>
    normalizeStringArray(projection[field]).includes(key));
}

function validateSameOrganization(actorOrganizationIdValue, targetValue) {
  const actorOrganizationId = normalizeString(actorOrganizationIdValue);
  const target = validateOrganizationNotificationTarget(targetValue);
  if (!actorOrganizationId || actorOrganizationId !== target.organizationId) {
    throw new OrganizationNotificationError(
      'permission-denied',
      'Organization notifications may only target the caller\'s organization.',
    );
  }
  return target;
}

async function assertSameOrganizationScope({ db, actorOrganizationId, target }) {
  const normalizedTarget = validateSameOrganization(
    actorOrganizationId,
    target,
  );
  const organizationSnapshot = await db.collection('organizations')
    .doc(normalizedTarget.organizationId).get();
  if (!organizationSnapshot.exists || !isActiveDocument(organizationSnapshot.data())) {
    throw failedPrecondition('The target organization is not active.');
  }

  const scope = parseScopeKey(normalizedTarget.scopeKey);
  if (scope.kind === 'unit') {
    const unitSnapshot = await db.collection('organizationUnits').doc(scope.id).get();
    const unit = unitSnapshot.exists ? unitSnapshot.data() || {} : {};
    if (!unitSnapshot.exists || !isActiveDocument(unit)) {
      throw failedPrecondition('The target organization unit is not active.');
    }
    if (normalizeString(unit.organizationId) !== normalizedTarget.organizationId) {
      throw new OrganizationNotificationError(
        'permission-denied',
        'The target organization unit belongs to another organization.',
      );
    }
  }
  return normalizedTarget;
}

async function createOrganizationNotificationEvent({
  db,
  fieldValue,
  payload,
  actor,
}) {
  const normalizedPayload = validateOrganizationNotificationPayload(payload);
  const target = await assertSameOrganizationScope({
    db,
    actorOrganizationId: actor && actor.organizationId,
    target: normalizedPayload.target,
  });
  const canonicalPayload = { ...normalizedPayload, target };
  await assertAuthorizedOrganizationNotification({
    db,
    actor,
    payload: canonicalPayload,
  });
  const eventId = deterministicOrganizationNotificationId(canonicalPayload);
  const payloadHash = hash(canonicalJson(canonicalPayload));
  const eventRef = db.collection('notificationEvents').doc(eventId);
  const auditRef = db.collection('organizationAuditEvents').doc(eventId);
  const receiptRef = db.collection('organizationCommandReceipts')
    .doc(canonicalPayload.commandId);
  const eventData = {
    eventType: canonicalPayload.source.eventType,
    moduleKey: canonicalPayload.source.moduleKey,
    title: canonicalPayload.title,
    body: canonicalPayload.body,
    entityType: canonicalPayload.source.entityType,
    entityId: canonicalPayload.source.entityId,
    route: canonicalPayload.source.route,
    sourceId: canonicalPayload.source.id,
    target,
    organizationId: target.organizationId,
    createdByUserId: normalizeString(actor && actor.uid),
    createdByName: agentDisplayName(actor),
    createdByEmail: normalizeString(actor && actor.email).toLowerCase(),
    createdAt: fieldValue.serverTimestamp(),
    status: 'PENDING',
    payloadHash,
  };

  return db.runTransaction(async (transaction) => {
    const receipt = await transaction.get(receiptRef);
    if (receipt.exists) {
      assertMatchingNotificationReceipt({
        receipt,
        actor,
        payloadHash,
      });
      return {
        eventId: normalizeString(receipt.get('result.eventId')) || eventId,
        created: false,
        replayed: true,
      };
    }
    const existing = await transaction.get(eventRef);
    if (existing.exists) {
      if (normalizeString(existing.get('payloadHash')) !== payloadHash) {
        throw new OrganizationNotificationError(
          'already-exists',
          'This notification source was already used with different content.',
        );
      }
    } else {
      transaction.create(eventRef, eventData);
      const scope = parseScopeKey(target.scopeKey);
      transaction.create(auditRef, {
        eventType: 'ORGANIZATION_NOTIFICATION_CREATED',
        command: ORGANIZATION_NOTIFICATION_COMMAND,
        commandId: canonicalPayload.commandId,
        actorUid: normalizeString(actor && actor.uid),
        organizationId: target.organizationId,
        unitId: scope.kind === 'unit' ? scope.id : null,
        reason: canonicalPayload.title,
        before: null,
        after: {
          notificationEventId: eventId,
          sourceEventType: canonicalPayload.source.eventType,
          sourceEntityType: canonicalPayload.source.entityType,
          sourceEntityId: canonicalPayload.source.entityId,
          scopeKey: target.scopeKey,
          moduleKey: target.moduleKey || null,
          roles: target.roles || [],
        },
        createdAt: fieldValue.serverTimestamp(),
        schemaVersion: 2,
      });
    }
    const result = { eventId, created: !existing.exists };
    transaction.create(receiptRef, {
      command: ORGANIZATION_NOTIFICATION_COMMAND,
      commandId: canonicalPayload.commandId,
      actorUid: normalizeString(actor && actor.uid),
      payloadHash,
      result,
      createdAt: fieldValue.serverTimestamp(),
    });
    return result;
  });
}

async function assertAuthorizedOrganizationNotification({ db, actor, payload }) {
  const normalized = validateOrganizationNotificationPayload(payload);
  const actorRole = normalizeString(
    actor && actor.modulePermissions &&
      (actor.modulePermissions.usermanagement ||
       actor.modulePermissions.user_management),
  ).toUpperCase();
  if (actorRole !== 'MANAGER') {
    throw new OrganizationNotificationError(
      'permission-denied',
      'Only a User Management manager can publish organization announcements.',
    );
  }

  const policy = ORGANIZATION_NOTIFICATION_EVENT_POLICIES[
    normalized.source.eventType
  ];
  if (!policy || normalized.source.moduleKey !== 'usermanagement') {
    throw new OrganizationNotificationError(
      'permission-denied',
      'This organization notification event type is not authorized.',
    );
  }
  if (normalized.source.entityType !== policy.entityType) {
    throw invalid(
      `source.entityType must be ${policy.entityType} for this event.`,
    );
  }

  const scope = parseScopeKey(normalized.target.scopeKey);
  if (
    scope.kind !== policy.scopeKind ||
    scope.id !== normalized.source.entityId
  ) {
    throw invalid('The notification source must match the target scope.');
  }

  const snapshot = await db.collection(policy.sourceCollection)
    .doc(normalized.source.entityId).get();
  const sourceData = snapshot.exists ? snapshot.data() || {} : {};
  if (!snapshot.exists || !isActiveDocument(sourceData)) {
    throw failedPrecondition('The notification source is not active.');
  }
  const sourceOrganizationId = policy.scopeKind === 'org'
    ? snapshot.id
    : normalizeString(sourceData.organizationId);
  if (sourceOrganizationId !== normalized.target.organizationId) {
    throw new OrganizationNotificationError(
      'permission-denied',
      'The notification source belongs to another organization.',
    );
  }

  assertCanonicalOrganizationRoute({
    source: normalized.source,
    organizationId: normalized.target.organizationId,
    scopeKind: policy.scopeKind,
  });
  return normalized;
}

function assertCanonicalOrganizationRoute({ source, organizationId, scopeKind }) {
  const parsed = new URL(source.route, 'https://app.arptc.invalid');
  const expectedPath = scopeKind === 'org'
    ? `/service/usermanagement/organizations/${encodeURIComponent(source.entityId)}`
    : `/service/usermanagement/structure/${encodeURIComponent(source.entityId)}`;
  const validUnitOrganization = scopeKind !== 'unit' ||
    parsed.searchParams.get('organizationId') === organizationId;
  const onlyExpectedQuery = scopeKind === 'unit'
    ? [...parsed.searchParams.keys()].every((key) => key === 'organizationId')
    : parsed.search === '';
  if (
    parsed.pathname !== expectedPath ||
    !validUnitOrganization ||
    !onlyExpectedQuery ||
    parsed.hash
  ) {
    throw invalid('source.route does not match the canonical source route.');
  }
}

function assertMatchingNotificationReceipt({ receipt, actor, payloadHash }) {
  if (
    normalizeString(receipt.get('command')) !==
      ORGANIZATION_NOTIFICATION_COMMAND ||
    normalizeString(receipt.get('actorUid')) !==
      normalizeString(actor && actor.uid) ||
    normalizeString(receipt.get('payloadHash')) !== payloadHash
  ) {
    throw new OrganizationNotificationError(
      'already-exists',
      'This command ID has already been used for a different operation.',
    );
  }
}

async function resolveOrganizationRecipientsPage({
  db,
  target: targetValue,
  cursor = '',
  pageSize = MAX_RECIPIENT_PAGE_SIZE,
}) {
  const target = validateOrganizationNotificationTarget(targetValue);
  const limit = validateRecipientPageSize(pageSize);
  const normalizedCursor = normalizeString(cursor);
  const plans = buildAuthorizationQueryPlans(target);
  const snapshots = await Promise.all(plans.map(async ({ field, key }) => {
    let query = db.collection('agentAuthorizationIndex')
      .where('organizationId', '==', target.organizationId)
      .where('isActive', '==', true)
      .where(field, 'array-contains', key)
      .orderBy(FieldPath.documentId());
    if (normalizedCursor) query = query.startAfter(normalizedCursor);
    return query.limit(limit).get();
  }));

  const candidates = snapshots.flatMap((snapshot) => snapshot.docs)
    .filter((document) => isAuthorizationProjectionRecipient(
      document.data() || {},
      target,
    ));
  const deduplicated = deduplicateRecipients(candidates)
    .sort((left, right) => recipientId(left).localeCompare(recipientId(right)));
  const page = deduplicated.slice(0, limit);
  const recipientIds = page.map(recipientId);
  const mayHaveMore = deduplicated.length > limit ||
    snapshots.some((snapshot) => snapshot.size === limit);
  return {
    recipientIds,
    nextCursor: mayHaveMore && recipientIds.length > 0
      ? recipientIds.at(-1)
      : null,
    hasMore: mayHaveMore && recipientIds.length > 0,
  };
}

async function writeOrganizationInboxDocuments({
  db,
  recipientIds,
  eventId,
  notification,
  batchSize = MAX_FIRESTORE_BATCH_WRITES,
}) {
  const normalizedEventId = safeIdentifier(eventId, 'eventId', 500);
  const recipients = deduplicateRecipients(recipientIds).map(recipientId);
  const batches = splitIntoSafeBatches(recipients, batchSize);
  for (const recipientsBatch of batches) {
    const writeBatch = db.batch();
    for (const recipientIdValue of recipientsBatch) {
      const notificationRef = db.collection('agents').doc(recipientIdValue)
        .collection('notifications').doc(normalizedEventId);
      writeBatch.set(notificationRef, notification, { merge: true });
    }
    await writeBatch.commit();
  }
  return recipients.length;
}

function deterministicOrganizationNotificationId(payloadValue) {
  const payload = validateOrganizationNotificationPayload(payloadValue);
  const identity = {
    commandId: payload.commandId,
    organizationId: payload.target.organizationId,
    scopeKey: payload.target.scopeKey,
    moduleKey: payload.target.moduleKey || '',
    roles: payload.target.roles || [],
    sourceId: payload.source.id,
  };
  return `org_scope_${hash(canonicalJson(identity)).substring(0, 48)}`;
}

function validateRecipientPageSize(value) {
  const size = Number(value);
  if (!Number.isInteger(size) || size < 1 || size > MAX_RECIPIENT_PAGE_SIZE) {
    throw invalid(
      `Recipient page size must be between 1 and ${MAX_RECIPIENT_PAGE_SIZE}.`,
    );
  }
  return size;
}

function deduplicateRecipients(values) {
  const unique = new Map();
  for (const value of Array.isArray(values) ? values : []) {
    const id = recipientId(value);
    if (id && !unique.has(id)) unique.set(id, value);
  }
  return [...unique.values()];
}

function splitIntoSafeBatches(values, batchSize = MAX_FIRESTORE_BATCH_WRITES) {
  const size = Number(batchSize);
  if (!Number.isInteger(size) || size < 1 || size > MAX_FIRESTORE_BATCH_WRITES) {
    throw invalid(
      `Firestore batch size must be between 1 and ${MAX_FIRESTORE_BATCH_WRITES}.`,
    );
  }
  const batches = [];
  for (let index = 0; index < values.length; index += size) {
    batches.push(values.slice(index, index + size));
  }
  return batches;
}

function recipientId(value) {
  if (typeof value === 'string') return normalizeString(value);
  return normalizeString(value && (value.id || value.uid));
}

function parseScopeKey(value) {
  const scopeKey = normalizeString(value);
  const separatorIndex = scopeKey.indexOf(':');
  return {
    kind: scopeKey.substring(0, separatorIndex),
    id: scopeKey.substring(separatorIndex + 1),
  };
}

function isActiveDocument(value) {
  const data = value && typeof value === 'object' ? value : {};
  return data.isActive === true || normalizeString(data.status).toUpperCase() === 'ACTIVE';
}

function agentDisplayName(agent) {
  const explicit = normalizeString(agent && (agent.displayName || agent.fullName));
  if (explicit) return explicit;
  return [agent && agent.firstName, agent && agent.name, agent && agent.postName]
    .map(normalizeString)
    .filter(Boolean)
    .join(' ');
}

function normalizeModuleKey(value, fieldName) {
  const sanitized = normalizeString(value)
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '');
  const aliases = {
    support: 'ticketing',
    incident: 'ticketing',
    incidents: 'ticketing',
    incident_management: 'ticketing',
    user_management: 'usermanagement',
  };
  const normalized = aliases[sanitized] || sanitized;
  if (!normalized || normalized.length > 80) {
    throw invalid(`${fieldName} is invalid.`);
  }
  return normalized;
}

function safeIdentifier(value, fieldName, maxLength) {
  const normalized = requiredText(value, fieldName, maxLength);
  if (!/^[A-Za-z0-9][A-Za-z0-9_.:@-]*$/.test(normalized)) {
    throw invalid(`${fieldName} contains unsupported characters.`);
  }
  return normalized;
}

function requiredText(value, fieldName, maxLength) {
  const normalized = normalizeString(value);
  if (!normalized) throw invalid(`${fieldName} is required.`);
  if (normalized.length > maxLength) {
    throw invalid(`${fieldName} must not exceed ${maxLength} characters.`);
  }
  return normalized;
}

function object(value, fieldName) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw invalid(`${fieldName} must be an object.`);
  }
  return value;
}

function normalizeString(value) {
  return value === null || value === undefined ? '' : String(value).trim();
}

function normalizeStringArray(value) {
  if (!Array.isArray(value)) return [];
  return value.map(normalizeString).filter(Boolean);
}

function canonicalJson(value) {
  if (Array.isArray(value)) return `[${value.map(canonicalJson).join(',')}]`;
  if (value && typeof value === 'object') {
    return `{${Object.keys(value).sort().map((key) =>
      `${JSON.stringify(key)}:${canonicalJson(value[key])}`).join(',')}}`;
  }
  return JSON.stringify(value);
}

function hash(value) {
  return crypto.createHash('sha256').update(value).digest('hex');
}

function invalid(message) {
  return new OrganizationNotificationError('invalid-argument', message);
}

function failedPrecondition(message) {
  return new OrganizationNotificationError('failed-precondition', message);
}

module.exports = {
  MAX_FIRESTORE_BATCH_WRITES,
  MAX_RECIPIENT_PAGE_SIZE,
  ORGANIZATION_SCOPE_TARGET_TYPE,
  OrganizationNotificationError,
  assertAuthorizedOrganizationNotification,
  assertSameOrganizationScope,
  buildAuthorizationQueryPlans,
  createOrganizationNotificationEvent,
  deduplicateRecipients,
  deterministicOrganizationNotificationId,
  isAuthorizationProjectionRecipient,
  resolveOrganizationRecipientsPage,
  splitIntoSafeBatches,
  validateOrganizationNotificationPayload,
  validateOrganizationNotificationTarget,
  validateRecipientPageSize,
  validateSameOrganization,
  writeOrganizationInboxDocuments,
};
