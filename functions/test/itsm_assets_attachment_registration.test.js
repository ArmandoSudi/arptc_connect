'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');

const {
  MAX_ATTACHMENT_SIZE_BYTES,
  buildItsmAssetsAttachmentMetadata,
  parseItsmAssetAttachmentPath,
  parseItsmAssetsStoragePath,
  parseItsmContractAttachmentPath,
  parseItsmStockAttachmentPath,
  parseItsmWarrantyAttachmentPath,
  registerItsmAssetsAttachment,
} = require('../src/itsm_assets_attachment_registration');

const fieldValue = { serverTimestamp: () => 'server-time' };

test('parses only canonical governed finalization paths', () => {
  assert.deepEqual(
    parseItsmAssetAttachmentPath(
      'itsm/assets/asset-1/attachments/attachment-1/invoice.pdf',
    ),
    {
      type: 'asset',
      assetId: 'asset-1',
      resourceKind: 'attachments',
      resourceId: 'attachment-1',
      fileName: 'invoice.pdf',
      storagePath: 'itsm/assets/asset-1/attachments/attachment-1/invoice.pdf',
    },
  );
  assert.deepEqual(
    parseItsmContractAttachmentPath(
      'itsm/contracts/contract-1/attachments/contract-file-1/terms.pdf',
    ),
    {
      type: 'contract',
      contractId: 'contract-1',
      attachmentId: 'contract-file-1',
      fileName: 'terms.pdf',
      storagePath:
        'itsm/contracts/contract-1/attachments/contract-file-1/terms.pdf',
    },
  );
  assert.deepEqual(
    parseItsmWarrantyAttachmentPath(
      'itsm/warranties/warranty-1/attachments/warranty-file-1/proof.pdf',
    ),
    {
      type: 'warranty',
      warrantyId: 'warranty-1',
      attachmentId: 'warranty-file-1',
      fileName: 'proof.pdf',
      storagePath:
        'itsm/warranties/warranty-1/attachments/warranty-file-1/proof.pdf',
    },
  );
  assert.equal(
    parseItsmAssetsStoragePath(
      'itsm/contracts/../attachments/file-1/file.pdf',
    ),
    null,
  );
  assert.equal(
    parseItsmAssetsStoragePath(
      'itsm/assets/asset-1/unsupported/file-1/file.pdf',
    ),
    null,
  );
  assert.equal(
    parseItsmAssetAttachmentPath(
      'itsm/assets/../attachments/file-1/file.pdf',
    ),
    null,
  );
  assert.deepEqual(
    parseItsmStockAttachmentPath(
      'itsm/stock/stock-1/supportingDocuments/evidence-1/count.csv',
    ),
    {
      type: 'stock',
      stockItemId: 'stock-1',
      attachmentId: 'evidence-1',
      fileName: 'count.csv',
      storagePath:
          'itsm/stock/stock-1/supportingDocuments/evidence-1/count.csv',
    },
  );
});

test('builds asset metadata only when path IDs and object facts are valid', () => {
  const object = assetObject();
  const result = buildItsmAssetsAttachmentMetadata({ object, fieldValue });
  assert.equal(result.valid, true);
  assert.equal(result.metadata.assetId, 'asset-1');
  assert.equal(result.metadata.resourceId, 'attachment-1');
  assert.equal(result.metadata.sizeBytes, 1024);
  assert.equal(result.metadata.createdAt, 'server-time');

  assert.equal(build(object, {
    metadata: { ...object.metadata, assetId: 'other' },
  }).reason, 'path_metadata_mismatch');
  assert.equal(build(object, { contentType: 'application/octet-stream' }).reason,
    'unsupported_content_type');
  assert.equal(build(object, { size: '0' }).reason, 'invalid_size');
  assert.equal(build(object, { size: String(MAX_ATTACHMENT_SIZE_BYTES + 1) }).reason,
    'invalid_size');
  assert.equal(build(object, {
    metadata: { ...object.metadata, uploadedByUserId: '../manager' },
  }).reason, 'invalid_uploader');
});

test('photographs must use an image content type', () => {
  const object = assetObject({ resourceKind: 'photographs' });
  assert.equal(build(object, { contentType: 'application/pdf' }).reason,
    'photograph_must_be_image');
  assert.equal(build(object, { contentType: 'image/jpeg' }).valid, true);
});

test('builds stock evidence with a validated parent stock item ID', () => {
  const result = buildItsmAssetsAttachmentMetadata({
    object: stockObject(),
    fieldValue,
  });
  assert.equal(result.valid, true);
  assert.equal(result.metadata.attachmentId, 'evidence-1');
  assert.equal(result.metadata.stockItemId, 'stock-1');
  assert.equal(build(stockObject(), {
    metadata: { ...stockObject().metadata, attachmentId: 'other' },
  }).reason, 'path_metadata_mismatch');
  assert.equal(build(stockObject(), {
    metadata: { ...stockObject().metadata, stockItemId: '../stock' },
  }).reason, 'path_metadata_mismatch');
});

test('builds contract and warranty metadata only for matching parents', () => {
  const contract = buildItsmAssetsAttachmentMetadata({
    object: contractObject(),
    fieldValue,
  });
  assert.equal(contract.valid, true);
  assert.equal(contract.metadata.contractId, 'contract-1');
  assert.equal(contract.metadata.attachmentId, 'contract-file-1');
  assert.equal(build(contractObject(), {
    metadata: { ...contractObject().metadata, contractId: 'contract-2' },
  }).reason, 'path_metadata_mismatch');

  const warranty = buildItsmAssetsAttachmentMetadata({
    object: warrantyObject(),
    fieldValue,
  });
  assert.equal(warranty.valid, true);
  assert.equal(warranty.metadata.warrantyId, 'warranty-1');
  assert.equal(warranty.metadata.attachmentId, 'warranty-file-1');
  assert.equal(build(warrantyObject(), {
    metadata: { ...warrantyObject().metadata, attachmentId: 'forged' },
  }).reason, 'path_metadata_mismatch');
});

test('registers authoritative asset metadata with a trusted MANAGER identity', async () => {
  const db = fakeDatabase({
    'assets/asset-1': { assetTag: 'ARPTC-001' },
    'agents/manager-1': managerAgent(),
  });
  const result = await registerItsmAssetsAttachment({
    db,
    fieldValue,
    object: assetObject(),
  });
  assert.equal(result.registered, true);
  assert.equal(
    result.destinationPath,
    'assets/asset-1/attachments/attachment-1',
  );
  const stored = db.document(result.destinationPath);
  assert.deepEqual(stored.uploadedBy, {
    userId: 'manager-1',
    name: 'Marie Manager',
    email: 'marie.manager@arptc.cd',
  });
  assert.equal(stored.registeredAt, 'server-time');
  assert.match(stored.registrationKey, /^[a-f0-9]{64}$/);
});

test('registers stock evidence only when its stock item parent exists', async () => {
  const db = fakeDatabase({
    'stockItems/stock-1': { name: 'Laptop charger' },
    'agents/manager-1': managerAgent(),
  });
  const result = await registerItsmAssetsAttachment({
    db,
    fieldValue,
    object: stockObject(),
  });
  assert.equal(result.registered, true);
  assert.equal(result.destinationPath, 'stockSupportingDocuments/evidence-1');
  assert.equal(db.document(result.destinationPath).stockItemId, 'stock-1');

  const missing = fakeDatabase({ 'agents/manager-1': managerAgent() });
  assert.equal((await registerItsmAssetsAttachment({
    db: missing,
    fieldValue,
    object: stockObject(),
  })).reason, 'missing_parent');
});

test('registers contract and warranty metadata in parent subcollections', async () => {
  const db = fakeDatabase({
    'supplierContracts/contract-1': { contractNumber: 'CON-1' },
    'warranties/warranty-1': { warrantyNumber: 'WAR-1' },
    'agents/manager-1': managerAgent(),
  });

  const contract = await registerItsmAssetsAttachment({
    db,
    fieldValue,
    object: contractObject(),
  });
  assert.equal(contract.registered, true);
  assert.equal(
    contract.destinationPath,
    'supplierContracts/contract-1/attachments/contract-file-1',
  );
  assert.equal(db.document(contract.destinationPath).contractId, 'contract-1');

  const warranty = await registerItsmAssetsAttachment({
    db,
    fieldValue,
    object: warrantyObject(),
  });
  assert.equal(warranty.registered, true);
  assert.equal(
    warranty.destinationPath,
    'warranties/warranty-1/attachments/warranty-file-1',
  );
  assert.equal(db.document(warranty.destinationPath).warrantyId, 'warranty-1');

  const missingParent = fakeDatabase({
    'agents/manager-1': managerAgent(),
  });
  assert.equal((await registerItsmAssetsAttachment({
    db: missingParent,
    fieldValue,
    object: contractObject(),
  })).reason, 'missing_parent');
});

test('rejects missing, disabled, USER, and ADMIN uploader profiles', async () => {
  const profiles = [
    null,
    managerAgent({ isActive: false }),
    managerAgent({ role: 'USER' }),
    managerAgent({ role: 'ADMIN' }),
  ];
  for (const profile of profiles) {
    const seed = { 'assets/asset-1': { assetTag: 'ARPTC-001' } };
    if (profile) seed['agents/manager-1'] = profile;
    const result = await registerItsmAssetsAttachment({
      db: fakeDatabase(seed),
      fieldValue,
      object: assetObject(),
    });
    assert.equal(result.reason, 'forbidden_uploader');
  }
});

test('is idempotent and never overwrites immutable metadata', async () => {
  const db = fakeDatabase({
    'assets/asset-1': { assetTag: 'ARPTC-001' },
    'agents/manager-1': managerAgent(),
  });
  const object = assetObject();
  const first = await registerItsmAssetsAttachment({ db, fieldValue, object });
  const original = structuredClone(db.document(first.destinationPath));
  const replay = await registerItsmAssetsAttachment({ db, fieldValue, object });
  assert.equal(replay.reason, 'already_registered');
  assert.deepEqual(db.document(first.destinationPath), original);

  const conflictObject = { ...object, generation: '2', size: '2048' };
  const conflict = await registerItsmAssetsAttachment({
    db,
    fieldValue,
    object: conflictObject,
  });
  assert.equal(conflict.reason, 'metadata_conflict');
  assert.deepEqual(db.document(first.destinationPath), original);
  assert.equal(db.createCount(), 1);
});

function build(object, overrides) {
  return buildItsmAssetsAttachmentMetadata({
    object: { ...object, ...overrides },
    fieldValue,
  });
}

function assetObject({ resourceKind = 'attachments' } = {}) {
  return {
    name: `itsm/assets/asset-1/${resourceKind}/attachment-1/invoice.pdf`,
    bucket: 'test.appspot.com',
    generation: '1',
    contentType: resourceKind === 'photographs' ? 'image/jpeg' : 'application/pdf',
    size: '1024',
    md5Hash: 'asset-checksum',
    metadata: {
      assetId: 'asset-1',
      resourceKind,
      resourceId: 'attachment-1',
      uploadedByUserId: 'manager-1',
      isInternal: 'false',
    },
  };
}

function stockObject() {
  return {
    name: 'itsm/stock/stock-1/supportingDocuments/evidence-1/count.csv',
    bucket: 'test.appspot.com',
    generation: '7',
    contentType: 'text/csv',
    size: '512',
    crc32c: 'stock-checksum',
    metadata: {
      attachmentId: 'evidence-1',
      stockItemId: 'stock-1',
      uploadedByUserId: 'manager-1',
      isInternal: 'true',
    },
  };
}

function contractObject() {
  return {
    name:
      'itsm/contracts/contract-1/attachments/contract-file-1/terms.pdf',
    bucket: 'test.appspot.com',
    generation: '11',
    contentType: 'application/pdf',
    size: '768',
    md5Hash: 'contract-checksum',
    metadata: {
      contractId: 'contract-1',
      attachmentId: 'contract-file-1',
      uploadedByUserId: 'manager-1',
      isInternal: 'true',
    },
  };
}

function warrantyObject() {
  return {
    name:
      'itsm/warranties/warranty-1/attachments/warranty-file-1/proof.pdf',
    bucket: 'test.appspot.com',
    generation: '13',
    contentType: 'application/pdf',
    size: '640',
    crc32c: 'warranty-checksum',
    metadata: {
      warrantyId: 'warranty-1',
      attachmentId: 'warranty-file-1',
      uploadedByUserId: 'manager-1',
      isInternal: 'true',
    },
  };
}

function managerAgent({ role = 'MANAGER', isActive = true } = {}) {
  return {
    firstName: 'Marie',
    name: 'Manager',
    email: 'MARIE.MANAGER@ARPTC.CD',
    isActive,
    modulePermissions: { ticketing: role },
  };
}

function fakeDatabase(seed) {
  const documents = new Map(Object.entries(seed).map(([path, value]) => [
    path,
    structuredClone(value),
  ]));
  let creates = 0;
  class Ref {
    constructor(path) {
      this.path = path;
      this.id = path.split('/').at(-1);
    }
    collection(name) { return new Collection(`${this.path}/${name}`); }
  }
  class Collection {
    constructor(path) { this.path = path; }
    doc(id) { return new Ref(`${this.path}/${id}`); }
  }
  const snapshot = (ref) => ({
    exists: documents.has(ref.path),
    data: () => structuredClone(documents.get(ref.path)),
  });
  return {
    collection(name) { return new Collection(name); },
    document(path) { return structuredClone(documents.get(path)); },
    createCount() { return creates; },
    async runTransaction(callback) {
      const writes = [];
      const transaction = {
        get: async (ref) => snapshot(ref),
        create: (ref, value) => writes.push([ref, structuredClone(value)]),
      };
      const result = await callback(transaction);
      for (const [ref, value] of writes) {
        if (documents.has(ref.path)) throw new Error('already-exists');
        documents.set(ref.path, value);
        creates += 1;
      }
      return result;
    },
  };
}
