import 'dart:io';

import 'package:arptc_connect/modules/itsm/security_compliance/application/security_compliance_commands.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Flutter commands match the trusted Functions command/callable map', () {
    const expected = {
      'createFinding': ('security.finding.create', 'itsmCreateSecurityFinding'),
      'triageFinding': ('security.finding.triage', 'itsmTriageSecurityFinding'),
      'assignFinding': ('security.finding.assign', 'itsmAssignSecurityFinding'),
      'planRemediation': (
        'security.finding.remediation.plan',
        'itsmPlanSecurityFindingRemediation',
      ),
      'submitFindingValidation': (
        'security.finding.validation.submit',
        'itsmSubmitSecurityFindingValidation',
      ),
      'validateFinding': (
        'security.finding.validation.decide',
        'itsmValidateSecurityFinding',
      ),
      'acceptFindingRisk': (
        'security.finding.risk.accept',
        'itsmAcceptSecurityFindingRisk',
      ),
      'closeFinding': ('security.finding.close', 'itsmCloseSecurityFinding'),
      'cancelFinding': ('security.finding.cancel', 'itsmCancelSecurityFinding'),
      'createException': (
        'security.exception.create',
        'itsmCreateSecurityException',
      ),
      'submitException': (
        'security.exception.submit',
        'itsmSubmitSecurityException',
      ),
      'requestExceptionApproval': (
        'security.exception.approval.request',
        'itsmRequestSecurityExceptionApproval',
      ),
      'decideExceptionApproval': (
        'security.exception.approval.decide',
        'itsmDecideSecurityExceptionApproval',
      ),
      'activateException': (
        'security.exception.activate',
        'itsmActivateSecurityException',
      ),
      'renewException': (
        'security.exception.renew',
        'itsmRenewSecurityException',
      ),
      'closeException': (
        'security.exception.close',
        'itsmCloseSecurityException',
      ),
      'assessCompliance': (
        'security.compliance.assess',
        'itsmAssessAssetCompliance',
      ),
      'createReviewCampaign': (
        'security.access_review.campaign.create',
        'itsmCreateAccessReviewCampaign',
      ),
      'activateReviewCampaign': (
        'security.access_review.campaign.activate',
        'itsmActivateAccessReviewCampaign',
      ),
      'completeReviewCampaign': (
        'security.access_review.campaign.complete',
        'itsmCompleteAccessReviewCampaign',
      ),
      'createReviewItem': (
        'security.access_review.item.create',
        'itsmCreateAccessReviewItem',
      ),
      'decideReviewItem': (
        'security.access_review.item.decide',
        'itsmDecideAccessReviewItem',
      ),
      'requestAccessCorrection': (
        'security.access_review.correction.request',
        'itsmRequestAccessCorrection',
      ),
      'completeRevocationTask': (
        'security.access_review.revocation.complete',
        'itsmCompleteAccessRevocationTask',
      ),
    };

    final actual = {
      for (final value in SecurityComplianceCommandType.values)
        value.name: (value.command, value.functionName),
    };
    expect(actual, expected);
    expect(actual.values.map((value) => value.$1).toSet(), hasLength(24));
    expect(actual.values.map((value) => value.$2).toSet(), hasLength(24));

    final validator = File(
      'functions/src/itsm_security_compliance_validation.js',
    ).readAsStringSync();
    final functionsIndex = File('functions/index.js').readAsStringSync();
    for (final entry in expected.entries) {
      expect(
        validator,
        contains("${entry.key}: '${entry.value.$1}'"),
        reason: '${entry.key} must remain aligned with Functions validation.',
      );
      expect(
        functionsIndex,
        contains(entry.value.$2),
        reason: '${entry.value.$2} must be exported server-side.',
      );
    }
    expect(functionsIndex, contains('exports[exportName]'));
  });
}
