'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');

test('index registers every Phase 5 callable and attachment finalizer', () => {
  const source = fs.readFileSync(
    path.join(__dirname, '..', 'index.js'),
    'utf8',
  );
  for (const exportName of [
    'itsmCreateSecurityFinding',
    'itsmTriageSecurityFinding',
    'itsmAssignSecurityFinding',
    'itsmPlanSecurityFindingRemediation',
    'itsmSubmitSecurityFindingValidation',
    'itsmValidateSecurityFinding',
    'itsmAcceptSecurityFindingRisk',
    'itsmCloseSecurityFinding',
    'itsmCancelSecurityFinding',
    'itsmCreateSecurityException',
    'itsmSubmitSecurityException',
    'itsmRequestSecurityExceptionApproval',
    'itsmDecideSecurityExceptionApproval',
    'itsmActivateSecurityException',
    'itsmRenewSecurityException',
    'itsmCloseSecurityException',
    'itsmAssessAssetCompliance',
    'itsmCreateAccessReviewCampaign',
    'itsmActivateAccessReviewCampaign',
    'itsmCompleteAccessReviewCampaign',
    'itsmCreateAccessReviewItem',
    'itsmDecideAccessReviewItem',
    'itsmRequestAccessCorrection',
    'itsmCompleteAccessRevocationTask',
  ]) {
    assert.match(source, new RegExp(`\\b${exportName}\\b`));
  }
  assert.match(
    source,
    /exports\.itsmRegisterSecurityComplianceAttachment\s*=\s*onObjectFinalized/,
  );
});
