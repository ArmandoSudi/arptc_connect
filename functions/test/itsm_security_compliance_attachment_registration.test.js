'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');

const {
  MAX_SECURITY_EVIDENCE_SIZE_BYTES,
  buildItsmSecurityComplianceAttachmentMetadata,
  parseItsmSecurityComplianceAttachmentPath,
  registerItsmSecurityComplianceAttachment,
} = require('../src/itsm_security_compliance_attachment_registration');

const fieldValue = { serverTimestamp: () => 'server-time' };

test('parses only canonical parent-aware security attachment paths', () => {
  assert.deepEqual(parseItsmSecurityComplianceAttachmentPath(
    'itsm/securityFindings/finding-1/attachments/evidence-1/report.pdf',
  ), {
    entityType: 'security_finding',
    parentCollection: 'securityFindings', parentId: 'finding-1',
    childCollection: 'attachments', attachmentId: 'evidence-1',
    fileName: 'report.pdf',
    storagePath: 'itsm/securityFindings/finding-1/attachments/evidence-1/report.pdf',
  });
  assert.equal(parseItsmSecurityComplianceAttachmentPath(
    'itsm/securityFindings/../attachments/evidence-1/report.pdf',
  ), null);
  assert.equal(parseItsmSecurityComplianceAttachmentPath(
    'itsm/assetComplianceAssessments/a-1/evidence/e-1/report.pdf',
  ), null);
  assert.equal(parseItsmSecurityComplianceAttachmentPath(
    'itsm/accessReviewItems/i-1/attachments/e-1/../report.pdf',
  ), null);
  for (const collection of [
    'securityExceptions',
    'assetComplianceAssessments',
    'accessReviewItems',
  ]) {
    assert.equal(
      parseItsmSecurityComplianceAttachmentPath(
        `itsm/${collection}/parent-1/attachments/file-1/report.pdf`,
      ).parentCollection,
      collection,
    );
  }
});

test('builds metadata from finalized object facts and preserves authorization', () => {
  const result = buildItsmSecurityComplianceAttachmentMetadata({
    object: findingObject(), fieldValue,
  });
  assert.equal(result.valid, true);
  assert.equal(result.metadata.sizeBytes, 2048);
  assert.equal(result.metadata.createdAt, 'server-time');
  assert.deepEqual(result.metadata.authorizedManagerIds, ['manager-1']);
  assert.equal(result.metadata.confidentiality, 'restricted');
  assert.equal(Object.hasOwn(result.metadata, 'actorRole'), false);
});

test('rejects metadata mismatch, unsafe content, size, and missing restricted ACL', () => {
  assert.equal(build({ metadata: { ...findingObject().metadata, parentId: 'forged' } }).reason, 'path_metadata_mismatch');
  assert.equal(build({ contentType: 'application/octet-stream' }).reason, 'unsupported_content_type');
  assert.equal(build({ size: String(MAX_SECURITY_EVIDENCE_SIZE_BYTES + 1) }).reason, 'invalid_size');
  assert.equal(build({ metadata: { ...findingObject().metadata, authorizedManagerId: '' } }).reason, 'invalid_authorized_managers');
});

test('registers immutable restricted finding evidence for authorized MANAGERs', async () => {
  const db = fakeDatabase({
    'securityFindings/finding-1': { status: 'remediation', confidentiality: 'restricted' },
    'agents/manager-1': agent('MANAGER'),
    'agents/manager-2': agent('MANAGER'),
  });
  const first = await registerItsmSecurityComplianceAttachment({
    db, fieldValue, object: findingObject(),
  });
  assert.equal(first.registered, true);
  assert.equal(first.destinationPath, 'securityFindings/finding-1/attachments/evidence-1');
  const stored = db.document(first.destinationPath);
  assert.deepEqual(stored.authorizedManagerIds, ['manager-1']);
  assert.equal(stored.createdBy, 'manager-1');
  assert.equal(stored.requesterVisible, false);
  assert.equal(stored.isInternal, true);
  assert.equal(stored.uploadedBy.userId, 'manager-1');
  assert.match(stored.registrationKey, /^[a-f0-9]{64}$/);

  const replay = await registerItsmSecurityComplianceAttachment({
    db, fieldValue, object: findingObject(),
  });
  assert.equal(replay.reason, 'already_registered');
  const conflict = await registerItsmSecurityComplianceAttachment({
    db, fieldValue, object: { ...findingObject(), generation: '2' },
  });
  assert.equal(conflict.reason, 'metadata_conflict');
  assert.equal(db.createCount(), 1);
});

test('exception owner can register own evidence but cannot forge another parent', async () => {
  const db = fakeDatabase({
    'securityExceptions/exception-1': {
      requesterId: 'user-1', requester: { userId: 'user-1' },
      selfServiceVisible: true,
    },
    'securityExceptions/exception-2': {
      requesterId: 'user-2', requester: { userId: 'user-2' },
      selfServiceVisible: true,
    },
    'agents/user-1': agent('USER'),
  });
  const allowed = await registerItsmSecurityComplianceAttachment({
    db, fieldValue, object: exceptionObject('exception-1'),
  });
  assert.equal(allowed.registered, true);
  const denied = await registerItsmSecurityComplianceAttachment({
    db, fieldValue, object: exceptionObject('exception-2'),
  });
  assert.equal(denied.reason, 'forbidden_uploader');
});

test('restricted uploader must resolve to an active ITSM MANAGER profile', async () => {
  const db = fakeDatabase({
    'securityFindings/finding-1': { status: 'detected' },
    'agents/manager-1': agent('ADMIN'),
  });
  const result = await registerItsmSecurityComplianceAttachment({
    db, fieldValue, object: findingObject(),
  });
  assert.equal(result.reason, 'forbidden_uploader');
});

function build(overrides) {
  return buildItsmSecurityComplianceAttachmentMetadata({
    object: { ...findingObject(), ...overrides }, fieldValue,
  });
}

function findingObject() {
  return {
    name: 'itsm/securityFindings/finding-1/attachments/evidence-1/report.pdf',
    bucket: 'test.appspot.com', generation: '1',
    contentType: 'application/pdf', size: '2048', md5Hash: 'checksum',
    metadata: {
      parentCollection: 'securityFindings', parentId: 'finding-1',
      attachmentId: 'evidence-1', uploadedByUserId: 'manager-1',
      confidentiality: 'restricted', requesterVisible: 'false',
      isInternal: 'true', authorizedManagerId: 'manager-1',
    },
  };
}

function exceptionObject(exceptionId) {
  return {
    name: `itsm/securityExceptions/${exceptionId}/attachments/evidence-user/report.pdf`,
    bucket: 'test.appspot.com', generation: '1',
    contentType: 'application/pdf', size: '1024', crc32c: 'checksum',
    metadata: {
      parentCollection: 'securityExceptions', parentId: exceptionId,
      attachmentId: 'evidence-user', uploadedByUserId: 'user-1',
      confidentiality: 'internal', requesterVisible: 'true',
      isInternal: 'false', authorizedManagerId: '',
    },
  };
}

function agent(role) {
  return {
    firstName: role, email: `${role.toLowerCase()}@arptc.cd`, isActive: true,
    modulePermissions: { ticketing: role },
  };
}

function fakeDatabase(seed) {
  const documents = new Map(Object.entries(seed).map(([path, value]) => [path, structuredClone(value)]));
  let creates = 0;
  class Ref {
    constructor(path) { this.path = path; this.id = path.split('/').at(-1); }
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
    collection: (name) => new Collection(name),
    document: (path) => structuredClone(documents.get(path)),
    createCount: () => creates,
    runTransaction: async (callback) => {
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
