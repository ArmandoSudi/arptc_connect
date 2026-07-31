'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');

const functions = require('../index');

const CHANGE_CALLABLE_EXPORTS = Object.freeze([
  'itsmInitializeChangeDraft',
  'itsmSaveChangeDraft',
  'itsmSubmitChange',
  'itsmCancelChange',
  'itsmAssessChange',
  'itsmRequestChangeApproval',
  'itsmDecideChangeApproval',
  'itsmSaveChangeCabMeeting',
  'itsmScheduleChange',
  'itsmStartChangeImplementation',
  'itsmRecordChangeImplementationResult',
  'itsmRecordChangePostImplementationReview',
  'itsmCloseChange',
]);

test('index registers every Phase 4 change callable', () => {
  assert.equal(CHANGE_CALLABLE_EXPORTS.length, 13);
  for (const exportName of CHANGE_CALLABLE_EXPORTS) {
    assert.equal(
      typeof functions[exportName],
      'function',
      `${exportName} must be exported as a Cloud Function`,
    );
  }
});
