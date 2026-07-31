'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');

const {
  ITSM_SUPPORT_COMMANDS,
  SUPPORT_COMMAND_ALLOWED_ROLES,
  validateSupportCommand,
} = require('../src/itsm_support_validation');

test('service request commands enforce canonical two-stage payloads', () => {
  const initialize = validateSupportCommand({
    command: ITSM_SUPPORT_COMMANDS.initializeServiceRequestDraft,
    idempotencyKey: 'request-initialize-1234',
    payload: {
      catalogueItemId: 'computer-request',
      requestedForUserId: '',
      responses: { quantity: 1, encrypted: true },
    },
  });
  const submit = validateSupportCommand({
    command: ITSM_SUPPORT_COMMANDS.submitServiceRequest,
    idempotencyKey: 'request-submit-1234',
    payload: {
      requestId: 'request-1',
      attachmentIds: ['approval-file'],
    },
  });
  assert.equal(initialize.payload.catalogueItemId, 'computer-request');
  assert.deepEqual(submit.payload.attachmentIds, ['approval-file']);
  assert.equal(Object.isFrozen(initialize.payload.responses), true);
});

test('legacy catalogItem names and forged identity fields are rejected', () => {
  for (const payload of [
    { catalogItemId: 'computer-request' },
    { catalogueItemId: 'computer-request', requesterEmail: 'forged@arptc.cd' },
  ]) {
    assert.throws(
      () => validateSupportCommand({
        command: ITSM_SUPPORT_COMMANDS.initializeServiceRequestDraft,
        idempotencyKey: 'request-initialize-1234',
        payload,
      }),
      (error) => error.code === 'invalid-argument',
    );
  }
});

test('knowledge commands validate state transition requirements', () => {
  const draft = validateSupportCommand({
    command: ITSM_SUPPORT_COMMANDS.saveKnowledgeDraft,
    idempotencyKey: 'knowledge-save-1234',
    payload: {
      categoryId: 'general',
      title: 'Reset a password',
      content: 'Use the official portal.',
      visibility: 'employee',
    },
  });
  assert.equal(draft.payload.languageCode, 'en');
  assert.equal(draft.payload.visibility, 'employee');

  assert.throws(
    () => validateSupportCommand({
      command: ITSM_SUPPORT_COMMANDS.rejectKnowledgeReview,
      idempotencyKey: 'knowledge-reject-1234',
      payload: { articleId: 'article-1', reason: '' },
    }),
    (error) => error.code === 'invalid-argument',
  );
});

test('ADMIN remains self-service/read-only while Knowledge operations are MANAGER-only', () => {
  assert.equal(
    SUPPORT_COMMAND_ALLOWED_ROLES[
      ITSM_SUPPORT_COMMANDS.initializeServiceRequestDraft
    ].includes('ADMIN'),
    true,
  );
  assert.deepEqual(
    SUPPORT_COMMAND_ALLOWED_ROLES[ITSM_SUPPORT_COMMANDS.saveKnowledgeDraft],
    ['MANAGER'],
  );
  assert.deepEqual(
    SUPPORT_COMMAND_ALLOWED_ROLES[
      ITSM_SUPPORT_COMMANDS.updateServiceRequestTask
    ],
    ['MANAGER'],
  );
});
