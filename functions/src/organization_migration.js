'use strict';

const MAX_PAGE_SIZE = 100;

class OrganizationMigrationError extends Error {
  constructor(code, message) {
    super(message);
    this.code = code;
  }
}

async function listUnplacedAgentsPage({
  db,
  fieldPath,
  limit = 100,
  afterId = '',
}) {
  const pageSize = normalizePageSize(limit);
  const cursor = normalizeString(afterId);
  let query = db.collection('agents')
    .orderBy(fieldPath.documentId())
    .limit(pageSize);
  if (cursor) query = query.startAfter(cursor);

  const snapshot = await query.get();
  const items = snapshot.docs
    .filter((document) => isUnplacedAgent(document.data() || {}))
    .map((document) => unplacedAgentSummary(document.id, document.data() || {}));
  const lastDocument = snapshot.docs.at(-1);

  return {
    items,
    nextCursor: snapshot.size === pageSize && lastDocument
      ? lastDocument.id
      : null,
    scannedCount: snapshot.size,
  };
}

function isUnplacedAgent(data) {
  if (!data || data.isActive !== true) return false;
  return Number(data.organizationSchemaVersion) !== 2 ||
    !normalizeString(data.organizationId) ||
    !normalizeString(data.primaryOrganizationUnitId) ||
    !normalizeString(data.primaryAssignmentId);
}

function unplacedAgentSummary(id, data) {
  const displayName = [data.firstName, data.name, data.postName]
    .map(normalizeString)
    .filter(Boolean)
    .join(' ');
  return {
    id: normalizeString(id),
    displayName: displayName || normalizeString(data.email),
    email: normalizeString(data.emailLower || data.email).toLowerCase(),
    isActive: data.isActive === true,
  };
}

function normalizePageSize(value) {
  const pageSize = Number(value);
  if (!Number.isInteger(pageSize) || pageSize < 1 || pageSize > MAX_PAGE_SIZE) {
    throw new OrganizationMigrationError(
      'invalid-argument',
      `The page limit must be between 1 and ${MAX_PAGE_SIZE}.`,
    );
  }
  return pageSize;
}

function normalizeString(value) {
  return typeof value === 'string' ? value.trim() : '';
}

module.exports = {
  MAX_PAGE_SIZE,
  OrganizationMigrationError,
  isUnplacedAgent,
  listUnplacedAgentsPage,
  normalizePageSize,
  unplacedAgentSummary,
};
