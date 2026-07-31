'use strict';

const crypto = require('node:crypto');
const {
  ITSM_ROLES,
  normalizeString,
  resolveItsmRole,
} = require('./itsm_permissions');

const MAX_SECURITY_EVIDENCE_SIZE_BYTES = 20 * 1024 * 1024;
const IDENTIFIER = /^[A-Za-z0-9][A-Za-z0-9._:@-]{0,127}$/;
const CONTENT_TYPES = new Set([
  'application/pdf',
  'application/msword',
  'application/vnd.ms-excel',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'text/plain',
  'text/csv',
]);
const PARENTS = Object.freeze({
  securityFindings: Object.freeze({
    entityType: 'security_finding',
  }),
  securityExceptions: Object.freeze({
    entityType: 'security_exception',
  }),
  assetComplianceAssessments: Object.freeze({
    entityType: 'compliance_assessment',
  }),
  accessReviewItems: Object.freeze({
    entityType: 'access_review_item',
  }),
});

function parseItsmSecurityComplianceAttachmentPath(path) {
  const normalized = normalizeString(path);
  const match = normalized.match(
    /^itsm\/(securityFindings|securityExceptions|assetComplianceAssessments|accessReviewItems)\/([^/]+)\/attachments\/([^/]+)\/([^/]+)$/,
  );
  if (!match) return null;
  const config = PARENTS[match[1]];
  if (!config || !validIdentifier(match[2]) || !validIdentifier(match[3]) ||
      !validFileName(match[4])) {
    return null;
  }
  return Object.freeze({
    entityType: config.entityType,
    parentCollection: match[1],
    parentId: match[2],
    childCollection: 'attachments',
    attachmentId: match[3],
    fileName: match[4],
    storagePath: normalized,
  });
}

function buildItsmSecurityComplianceAttachmentMetadata({ object, fieldValue }) {
  const parsed = parseItsmSecurityComplianceAttachmentPath(object && object.name);
  if (!parsed) return invalid('unsupported_path');
  const custom = object.metadata && typeof object.metadata === 'object'
    ? object.metadata
    : {};
  if (normalizeString(custom.parentCollection) !== parsed.parentCollection ||
      normalizeString(custom.parentId) !== parsed.parentId ||
      normalizeString(custom.attachmentId) !== parsed.attachmentId) {
    return invalid('path_metadata_mismatch');
  }
  const uploadedByUserId = normalizeString(custom.uploadedByUserId);
  if (!validIdentifier(uploadedByUserId)) return invalid('invalid_uploader');
  const confidentiality = normalizeString(custom.confidentiality).toLowerCase();
  if (!['internal', 'confidential', 'restricted'].includes(confidentiality)) {
    return invalid('invalid_confidentiality');
  }
  const requesterVisible = parseBoolean(custom.requesterVisible);
  const isInternal = parseBoolean(custom.isInternal);
  if (requesterVisible === null || isInternal === null ||
      requesterVisible === isInternal) {
    return invalid('invalid_visibility');
  }
  if (requesterVisible && confidentiality !== 'internal') {
    return invalid('invalid_visibility');
  }
  const authorizedManagerId = normalizeString(custom.authorizedManagerId);
  if (confidentiality === 'restricted' &&
      (authorizedManagerId !== uploadedByUserId || requesterVisible || !isInternal)) {
    return invalid('invalid_authorized_managers');
  }
  if (confidentiality !== 'restricted' && authorizedManagerId) {
    return invalid('invalid_authorized_managers');
  }
  const authorizedManagerIds = confidentiality === 'restricted'
    ? [uploadedByUserId]
    : [];
  const contentType = normalizeString(object.contentType).toLowerCase();
  if (!supportedContentType(contentType)) return invalid('unsupported_content_type');
  const sizeBytes = Number(object.size);
  if (!Number.isSafeInteger(sizeBytes) || sizeBytes <= 0 ||
      sizeBytes > MAX_SECURITY_EVIDENCE_SIZE_BYTES) {
    return invalid('invalid_size');
  }
  const registeredAt = fieldValue.serverTimestamp();
  return Object.freeze({
    valid: true,
    parsed,
    metadata: {
      id: parsed.attachmentId,
      attachmentId: parsed.attachmentId,
      entityType: parsed.entityType,
      parentCollection: parsed.parentCollection,
      parentId: parsed.parentId,
      fileName: parsed.fileName,
      storagePath: parsed.storagePath,
      storageBucket: normalizeString(object.bucket),
      storageGeneration: normalizeString(object.generation),
      contentType,
      sizeBytes,
      checksum: normalizeString(object.md5Hash || object.crc32c),
      confidentiality,
      authorizedManagerIds,
      uploadedByUserId,
      createdBy: uploadedByUserId,
      requesterVisible,
      isInternal,
      createdAt: registeredAt,
      registeredAt,
    },
  });
}

async function registerItsmSecurityComplianceAttachment({
  db,
  fieldValue,
  object,
}) {
  const built = buildItsmSecurityComplianceAttachmentMetadata({
    object,
    fieldValue,
  });
  if (!built.valid) return { registered: false, reason: built.reason };
  const { parsed, metadata } = built;
  const parentRef = db.collection(parsed.parentCollection).doc(parsed.parentId);
  const uploaderRef = db.collection('agents').doc(metadata.uploadedByUserId);
  const destinationRef = parentRef
    .collection(parsed.childCollection)
    .doc(parsed.attachmentId);
  return db.runTransaction(async (transaction) => {
    const [parentSnapshot, uploaderSnapshot, destinationSnapshot] =
      await Promise.all([
        transaction.get(parentRef),
        transaction.get(uploaderRef),
        transaction.get(destinationRef),
      ]);
    if (!parentSnapshot.exists) return rejected('missing_parent');
    if (!uploaderSnapshot.exists) return rejected('forbidden_uploader');
    const parent = parentSnapshot.data() || {};
    const uploader = uploaderSnapshot.data() || {};
    const role = enabledItsmRole(uploader);
    if (!canUpload(parsed, parent, metadata, role)) {
      return rejected('forbidden_uploader');
    }
    if (metadata.confidentiality === 'restricted' &&
        role !== ITSM_ROLES.manager) {
      return rejected('invalid_authorized_managers');
    }
    const trusted = {
      ...metadata,
      uploadedBy: {
        userId: metadata.uploadedByUserId,
        name: agentName(uploader),
        email: normalizeString(uploader.email).toLowerCase(),
      },
      registrationKey: registrationKey(metadata),
    };
    if (destinationSnapshot.exists) {
      const existing = destinationSnapshot.data() || {};
      return sameObject(existing, trusted)
        ? rejected('already_registered', destinationRef.id)
        : rejected('metadata_conflict', destinationRef.id);
    }
    transaction.create(destinationRef, trusted);
    return {
      registered: true,
      attachmentId: destinationRef.id,
      destinationPath: destinationRef.path,
    };
  });
}

function canUpload(parsed, parent, metadata, role) {
  const uploaderId = metadata.uploadedByUserId;
  const ownsVisibleException = parsed.entityType === 'security_exception' &&
    parent.selfServiceVisible === true &&
    (normalizeString(parent.requesterId) === uploaderId ||
      normalizeString(parent.requester && parent.requester.userId) === uploaderId);
  if (metadata.requesterVisible) {
    return ownsVisibleException && metadata.confidentiality === 'internal' &&
      metadata.isInternal === false &&
      [ITSM_ROLES.user, ITSM_ROLES.manager, ITSM_ROLES.admin].includes(role);
  }
  return metadata.isInternal === true && role === ITSM_ROLES.manager;
}

function enabledItsmRole(agent) {
  const status = normalizeString(agent.status).toLowerCase();
  if (agent.isActive === false || ['disabled', 'inactive', 'suspended'].includes(status)) {
    return ITSM_ROLES.none;
  }
  return resolveItsmRole(agent);
}

function supportedContentType(value) {
  return value.startsWith('image/') || CONTENT_TYPES.has(value);
}

function registrationKey(metadata) {
  return crypto.createHash('sha256').update([
    metadata.storageBucket,
    metadata.storagePath,
    metadata.storageGeneration,
    metadata.attachmentId,
  ].map(normalizeString).join('\u0000')).digest('hex');
}

function sameObject(existing, expected) {
  return normalizeString(existing.storagePath) === expected.storagePath &&
    normalizeString(existing.storageGeneration) === expected.storageGeneration &&
    normalizeString(existing.checksum) === expected.checksum &&
    Number(existing.sizeBytes) === expected.sizeBytes &&
    normalizeString(existing.uploadedByUserId) === expected.uploadedByUserId &&
    normalizeString(existing.registrationKey) === expected.registrationKey;
}

function validIdentifier(value) { return IDENTIFIER.test(normalizeString(value)); }
function validFileName(value) { const text = normalizeString(value); return Boolean(text) && text.length <= 240 && !text.includes('..'); }
function parseBoolean(value) { const text = normalizeString(value).toLowerCase(); return text === 'true' ? true : text === 'false' ? false : null; }
function agentName(agent) { return normalizeString(agent.displayName) || [agent.firstName, agent.postName || agent.name].map(normalizeString).filter(Boolean).join(' '); }
function invalid(reason) { return Object.freeze({ valid: false, reason }); }
function rejected(reason, attachmentId) { return { registered: false, reason, ...(attachmentId && { attachmentId }) }; }

module.exports = {
  MAX_SECURITY_EVIDENCE_SIZE_BYTES,
  buildItsmSecurityComplianceAttachmentMetadata,
  parseItsmSecurityComplianceAttachmentPath,
  registerItsmSecurityComplianceAttachment,
};
