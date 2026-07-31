'use strict';

const crypto = require('node:crypto');
const {
  normalizeString,
  resolveItsmRole,
} = require('./itsm_permissions');

const MAX_ATTACHMENT_SIZE_BYTES = 20 * 1024 * 1024;
const ASSET_RESOURCE_KINDS = new Set(['attachments', 'photographs']);
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
const IDENTIFIER_PATTERN = /^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$/;

function parseItsmAssetAttachmentPath(path) {
  const match = normalizeString(path).match(
    /^itsm\/assets\/([^/]+)\/(attachments|photographs)\/([^/]+)\/([^/]+)$/,
  );
  if (!match || !validIdentifier(match[1]) || !validIdentifier(match[3])) {
    return null;
  }
  return Object.freeze({
    type: 'asset',
    assetId: match[1],
    resourceKind: match[2],
    resourceId: match[3],
    fileName: match[4],
    storagePath: normalizeString(path),
  });
}

function parseItsmStockAttachmentPath(path) {
  const match = normalizeString(path).match(
    /^itsm\/stock\/([^/]+)\/supportingDocuments\/([^/]+)\/([^/]+)$/,
  );
  if (!match || !validIdentifier(match[1]) || !validIdentifier(match[2])) {
    return null;
  }
  return Object.freeze({
    type: 'stock',
    stockItemId: match[1],
    attachmentId: match[2],
    fileName: match[3],
    storagePath: normalizeString(path),
  });
}

function parseItsmContractAttachmentPath(path) {
  return parseParentAttachmentPath({
    path,
    pattern: /^itsm\/contracts\/([^/]+)\/attachments\/([^/]+)\/([^/]+)$/,
    type: 'contract',
    parentIdKey: 'contractId',
  });
}

function parseItsmWarrantyAttachmentPath(path) {
  return parseParentAttachmentPath({
    path,
    pattern: /^itsm\/warranties\/([^/]+)\/attachments\/([^/]+)\/([^/]+)$/,
    type: 'warranty',
    parentIdKey: 'warrantyId',
  });
}

function parseParentAttachmentPath({ path, pattern, type, parentIdKey }) {
  const normalizedPath = normalizeString(path);
  const match = normalizedPath.match(pattern);
  if (!match || !validIdentifier(match[1]) || !validIdentifier(match[2])) {
    return null;
  }
  return Object.freeze({
    type,
    [parentIdKey]: match[1],
    attachmentId: match[2],
    fileName: match[3],
    storagePath: normalizedPath,
  });
}

function parseItsmAssetsStoragePath(path) {
  return parseItsmAssetAttachmentPath(path) ||
    parseItsmStockAttachmentPath(path) ||
    parseItsmContractAttachmentPath(path) ||
    parseItsmWarrantyAttachmentPath(path);
}

function buildItsmAssetsAttachmentMetadata({ object, fieldValue }) {
  const parsed = parseItsmAssetsStoragePath(object && object.name);
  if (!parsed) return invalidMetadata('unsupported_path');

  const custom = object.metadata && typeof object.metadata === 'object'
    ? object.metadata
    : {};
  const uploadedByUserId = normalizeString(custom.uploadedByUserId);
  if (!validIdentifier(uploadedByUserId)) {
    return invalidMetadata('invalid_uploader');
  }

  const contentType = normalizeString(object.contentType).toLowerCase();
  if (!isSupportedContentType(contentType)) {
    return invalidMetadata('unsupported_content_type');
  }
  if (parsed.resourceKind === 'photographs' && !contentType.startsWith('image/')) {
    return invalidMetadata('photograph_must_be_image');
  }

  const sizeBytes = Number(object.size);
  if (
    !Number.isSafeInteger(sizeBytes) ||
    sizeBytes <= 0 ||
    sizeBytes > MAX_ATTACHMENT_SIZE_BYTES
  ) {
    return invalidMetadata('invalid_size');
  }

  if (parsed.type === 'asset') {
    if (
      normalizeString(custom.assetId) !== parsed.assetId ||
      normalizeString(custom.resourceKind) !== parsed.resourceKind ||
      normalizeString(custom.resourceId) !== parsed.resourceId
    ) {
      return invalidMetadata('path_metadata_mismatch');
    }
  } else {
    const parentMetadataMatches = parsed.type === 'stock'
      ? normalizeString(custom.stockItemId) === parsed.stockItemId
      : parsed.type === 'contract'
        ? normalizeString(custom.contractId) === parsed.contractId
        : normalizeString(custom.warrantyId) === parsed.warrantyId;
    if (
      normalizeString(custom.attachmentId) !== parsed.attachmentId ||
      !parentMetadataMatches
    ) {
      return invalidMetadata('path_metadata_mismatch');
    }
  }

  const registeredAt = fieldValue.serverTimestamp();
  const common = {
    id: parsed.type === 'asset' ? parsed.resourceId : parsed.attachmentId,
    fileName: parsed.fileName,
    storagePath: parsed.storagePath,
    storageBucket: normalizeString(object.bucket),
    storageGeneration: normalizeString(object.generation),
    contentType,
    sizeBytes,
    checksum: normalizeString(object.md5Hash || object.crc32c),
    uploadedByUserId,
    isInternal: normalizeString(custom.isInternal).toLowerCase() === 'true',
    createdAt: registeredAt,
    registeredAt,
  };

  const metadata = buildResourceMetadata(parsed, common);
  return Object.freeze({ valid: true, parsed, metadata });
}

function buildResourceMetadata(parsed, common) {
  if (parsed.type === 'asset') {
    return {
      ...common,
      assetId: parsed.assetId,
      resourceKind: parsed.resourceKind,
      resourceId: parsed.resourceId,
    };
  }
  return {
    ...common,
    attachmentId: parsed.attachmentId,
    ...(parsed.type === 'stock' && { stockItemId: parsed.stockItemId }),
    ...(parsed.type === 'contract' && { contractId: parsed.contractId }),
    ...(parsed.type === 'warranty' && { warrantyId: parsed.warrantyId }),
  };
}

async function registerItsmAssetsAttachment({ db, fieldValue, object }) {
  const built = buildItsmAssetsAttachmentMetadata({ object, fieldValue });
  if (!built.valid) {
    return { registered: false, reason: built.reason };
  }

  const { parsed, metadata } = built;
  const agentRef = db.collection('agents').doc(metadata.uploadedByUserId);
  const { parentRef, destinationRef } = registrationReferences(db, parsed);

  return db.runTransaction(async (transaction) => {
    const [parentSnapshot, agentSnapshot, destinationSnapshot] = await Promise.all([
      transaction.get(parentRef),
      transaction.get(agentRef),
      transaction.get(destinationRef),
    ]);
    if (!parentSnapshot.exists) {
      return { registered: false, reason: 'missing_parent' };
    }
    if (!isEnabledItsmManager(agentSnapshot)) {
      return { registered: false, reason: 'forbidden_uploader' };
    }

    const agent = agentSnapshot.data() || {};
    const trustedMetadata = {
      ...metadata,
      uploadedBy: {
        userId: metadata.uploadedByUserId,
        name: agentDisplayName(agent),
        email: normalizeString(agent.email).toLowerCase(),
      },
      registrationKey: deterministicRegistrationKey(metadata),
    };

    if (destinationSnapshot.exists) {
      const existing = destinationSnapshot.data() || {};
      if (sameImmutableObject(existing, trustedMetadata)) {
        return {
          registered: false,
          reason: 'already_registered',
          attachmentId: destinationRef.id,
        };
      }
      return {
        registered: false,
        reason: 'metadata_conflict',
        attachmentId: destinationRef.id,
      };
    }

    transaction.create(destinationRef, trustedMetadata);
    return {
      registered: true,
      attachmentId: destinationRef.id,
      destinationPath: destinationRef.path,
    };
  });
}

function registrationReferences(db, parsed) {
  if (parsed.type === 'asset') {
    const parentRef = db.collection('assets').doc(parsed.assetId);
    return {
      parentRef,
      destinationRef: parentRef
        .collection(parsed.resourceKind)
        .doc(parsed.resourceId),
    };
  }
  if (parsed.type === 'stock') {
    return {
      parentRef: db.collection('stockItems').doc(parsed.stockItemId),
      destinationRef: db
        .collection('stockSupportingDocuments')
        .doc(parsed.attachmentId),
    };
  }
  const collectionName = parsed.type === 'contract'
    ? 'supplierContracts'
    : 'warranties';
  const parentId = parsed.type === 'contract'
    ? parsed.contractId
    : parsed.warrantyId;
  const parentRef = db.collection(collectionName).doc(parentId);
  return {
    parentRef,
    destinationRef: parentRef
      .collection('attachments')
      .doc(parsed.attachmentId),
  };
}

function isEnabledItsmManager(snapshot) {
  if (!snapshot || !snapshot.exists) return false;
  const agent = snapshot.data() || {};
  const status = normalizeString(agent.status).toLowerCase();
  return agent.isActive !== false &&
    !['disabled', 'inactive', 'suspended'].includes(status) &&
    resolveItsmRole(agent) === 'MANAGER';
}

function isSupportedContentType(contentType) {
  const normalized = normalizeString(contentType).toLowerCase();
  return normalized.startsWith('image/') ||
    SUPPORTED_ATTACHMENT_CONTENT_TYPES.has(normalized);
}

function validIdentifier(value) {
  return IDENTIFIER_PATTERN.test(normalizeString(value));
}

function deterministicRegistrationKey(metadata) {
  return crypto
    .createHash('sha256')
    .update([
      metadata.storageBucket,
      metadata.storagePath,
      metadata.storageGeneration,
      metadata.id,
    ].map(normalizeString).join('\u0000'))
    .digest('hex');
}

function sameImmutableObject(existing, expected) {
  return normalizeString(existing.storagePath) === expected.storagePath &&
    normalizeString(existing.storageGeneration) === expected.storageGeneration &&
    normalizeString(existing.contentType).toLowerCase() === expected.contentType &&
    Number(existing.sizeBytes) === expected.sizeBytes &&
    normalizeString(existing.uploadedByUserId) === expected.uploadedByUserId &&
    normalizeString(existing.registrationKey) === expected.registrationKey;
}

function agentDisplayName(agent) {
  return normalizeString(agent.displayName) ||
    [agent.firstName, agent.postName || agent.name]
      .map(normalizeString)
      .filter(Boolean)
      .join(' ');
}

function invalidMetadata(reason) {
  return Object.freeze({ valid: false, reason });
}

module.exports = {
  ASSET_RESOURCE_KINDS,
  MAX_ATTACHMENT_SIZE_BYTES,
  SUPPORTED_ATTACHMENT_CONTENT_TYPES,
  buildItsmAssetsAttachmentMetadata,
  deterministicRegistrationKey,
  isEnabledItsmManager,
  isSupportedContentType,
  parseItsmAssetAttachmentPath,
  parseItsmAssetsStoragePath,
  parseItsmContractAttachmentPath,
  parseItsmStockAttachmentPath,
  parseItsmWarrantyAttachmentPath,
  registerItsmAssetsAttachment,
};
