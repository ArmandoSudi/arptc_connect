'use strict';

const crypto = require('node:crypto');

const MAX_ATTACHMENT_SIZE_BYTES = 20 * 1024 * 1024;
const SUPPORTED_CONTENT_TYPES = new Set([
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

function parseInventoryAttachmentPath(path) {
  const match = normalizeString(path).match(
    /^inventory\/requests\/([^/]+)\/attachments\/([^/]+)\/([^/]+)$/,
  );
  if (!match) return null;
  return {
    requestId: match[1],
    attachmentId: match[2],
    fileName: match[3],
    storagePath: normalizeString(path),
  };
}

function buildInventoryAttachmentMetadata(object, fieldValue) {
  const parsed = parseInventoryAttachmentPath(object?.name);
  if (!parsed) return null;
  const metadata = object.metadata && typeof object.metadata === 'object'
    ? object.metadata
    : {};
  if (
    normalizeString(metadata.requestId) !== parsed.requestId ||
    normalizeString(metadata.attachmentId) !== parsed.attachmentId ||
    !normalizeString(metadata.uploadedByUserId)
  ) {
    return null;
  }
  const contentType = normalizeString(object.contentType).toLowerCase();
  const sizeBytes = Number(object.size);
  if (
    (!contentType.startsWith('image/') && !SUPPORTED_CONTENT_TYPES.has(contentType)) ||
    !Number.isSafeInteger(sizeBytes) ||
    sizeBytes <= 0 ||
    sizeBytes > MAX_ATTACHMENT_SIZE_BYTES
  ) {
    return null;
  }
  return {
    ...parsed,
    contentType,
    sizeBytes,
    uploadedByUserId: normalizeString(metadata.uploadedByUserId),
    storageBucket: normalizeString(object.bucket),
    storageGeneration: normalizeString(object.generation),
    checksum: normalizeString(object.md5Hash || object.crc32c),
    createdAt: fieldValue.serverTimestamp(),
  };
}

async function registerInventoryAttachment({ db, fieldValue, object }) {
  const attachment = buildInventoryAttachmentMetadata(object, fieldValue);
  if (!attachment) return { registered: false, reason: 'invalid_metadata' };
  const requestRef = db.collection('materialRequests').doc(attachment.requestId);
  const agentRef = db.collection('agents').doc(attachment.uploadedByUserId);
  const destinationRef = db
    .collection('inventorySupportingDocuments')
    .doc(attachment.attachmentId);
  return db.runTransaction(async (transaction) => {
    const [requestSnapshot, agentSnapshot, destinationSnapshot] = await Promise.all([
      transaction.get(requestRef),
      transaction.get(agentRef),
      transaction.get(destinationRef),
    ]);
    if (!requestSnapshot.exists || !agentSnapshot.exists) {
      return { registered: false, reason: 'missing_parent_or_agent' };
    }
    const request = requestSnapshot.data() || {};
    const agent = agentSnapshot.data() || {};
    const role = inventoryRole(agent);
    const ownsRequest = normalizeString(request.requestedFor?.userId) ===
      attachment.uploadedByUserId;
    if (agent.isActive !== true || (!ownsRequest && role !== 'MANAGER')) {
      return { registered: false, reason: 'forbidden_uploader' };
    }
    const registrationKey = stableKey(
      `${attachment.storagePath}|${attachment.storageGeneration}`,
    );
    if (destinationSnapshot.exists) {
      return destinationSnapshot.data()?.registrationKey === registrationKey
        ? { registered: false, reason: 'already_registered' }
        : { registered: false, reason: 'metadata_conflict' };
    }
    transaction.create(destinationRef, {
      ...attachment,
      uploadedBy: {
        userId: attachment.uploadedByUserId,
        name: displayName(agent),
        email: normalizeString(agent.email).toLowerCase(),
      },
      registrationKey,
    });
    return {
      registered: true,
      attachmentId: attachment.attachmentId,
      requestId: attachment.requestId,
    };
  });
}

function inventoryRole(agent) {
  const permissions = agent.modulePermissions &&
    typeof agent.modulePermissions === 'object'
    ? agent.modulePermissions
    : {};
  return normalizeString(permissions.inventory || permissions.inventaire)
    .toUpperCase();
}

function displayName(agent) {
  return normalizeString(
    agent.displayName ||
      [agent.firstName, agent.postName || agent.name]
        .map(normalizeString)
        .filter(Boolean)
        .join(' '),
  );
}

function stableKey(value) {
  return crypto.createHash('sha256').update(value).digest('hex');
}

function normalizeString(value) {
  return value == null ? '' : String(value).trim();
}

module.exports = {
  buildInventoryAttachmentMetadata,
  parseInventoryAttachmentPath,
  registerInventoryAttachment,
};
