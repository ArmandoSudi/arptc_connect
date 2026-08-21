'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');

const {
  buildInventoryAttachmentMetadata,
  parseInventoryAttachmentPath,
} = require('../src/inventory_attachment_registration');

const fieldValue = { serverTimestamp: () => 'server-time' };
const maxAttachmentSizeBytes = 20 * 1024 * 1024;

test('parses only the canonical Inventory request attachment shape', () => {
  assert.deepEqual(parseInventoryAttachmentPath(
    'inventory/requests/request-1/attachments/attachment-1/invoice.pdf',
  ), {
    requestId: 'request-1',
    attachmentId: 'attachment-1',
    fileName: 'invoice.pdf',
    storagePath:
      'inventory/requests/request-1/attachments/attachment-1/invoice.pdf',
  });
  assert.equal(parseInventoryAttachmentPath(
    'inventory/requests/request-1/documents/attachment-1/invoice.pdf',
  ), null);
  assert.equal(parseInventoryAttachmentPath(
    'inventory/requests/request-1/attachments/attachment-1/folder/invoice.pdf',
  ), null);
  assert.equal(parseInventoryAttachmentPath(
    'inventory/requests/request-1/attachments/attachment-1/',
  ), null);
  assert.equal(parseInventoryAttachmentPath(null), null);
});

test('builds trusted metadata from canonical finalized-object facts', () => {
  const result = buildInventoryAttachmentMetadata(
    attachmentObject(),
    fieldValue,
  );

  assert.deepEqual(result, {
    requestId: 'request-1',
    attachmentId: 'attachment-1',
    fileName: 'invoice.pdf',
    storagePath:
      'inventory/requests/request-1/attachments/attachment-1/invoice.pdf',
    contentType: 'application/pdf',
    sizeBytes: 2048,
    uploadedByUserId: 'user-1',
    storageBucket: 'test.appspot.com',
    storageGeneration: '7',
    checksum: 'md5-checksum',
    createdAt: 'server-time',
  });
});

test('accepts supported office documents and images with CRC fallback', () => {
  const spreadsheet = build({
    contentType:
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    md5Hash: '',
    crc32c: 'crc-checksum',
  });
  assert.equal(spreadsheet.contentType,
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  assert.equal(spreadsheet.checksum, 'crc-checksum');

  const image = build({ contentType: 'image/png' });
  assert.equal(image.contentType, 'image/png');
});

test('rejects path metadata mismatch and missing uploader identity', () => {
  const object = attachmentObject();
  assert.equal(build({
    metadata: { ...object.metadata, requestId: 'other-request' },
  }), null);
  assert.equal(build({
    metadata: { ...object.metadata, attachmentId: 'other-attachment' },
  }), null);
  assert.equal(build({
    metadata: { ...object.metadata, uploadedByUserId: ' ' },
  }), null);
  assert.equal(build({ name: 'inventory/requests/invalid.pdf' }), null);
});

test('rejects unsupported, empty, oversized, and fractional objects', () => {
  assert.equal(build({ contentType: 'application/octet-stream' }), null);
  assert.equal(build({ size: '0' }), null);
  assert.equal(build({ size: String(maxAttachmentSizeBytes + 1) }), null);
  assert.equal(build({ size: '1.5' }), null);
  assert.equal(build({ size: 'not-a-number' }), null);
});

function build(overrides) {
  return buildInventoryAttachmentMetadata(
    { ...attachmentObject(), ...overrides },
    fieldValue,
  );
}

function attachmentObject() {
  return {
    name:
      'inventory/requests/request-1/attachments/attachment-1/invoice.pdf',
    bucket: 'test.appspot.com',
    generation: '7',
    contentType: 'application/pdf',
    size: '2048',
    md5Hash: 'md5-checksum',
    crc32c: 'crc-checksum',
    metadata: {
      requestId: 'request-1',
      attachmentId: 'attachment-1',
      uploadedByUserId: 'user-1',
    },
  };
}
