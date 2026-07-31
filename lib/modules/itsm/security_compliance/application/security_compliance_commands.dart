import 'dart:collection';

import '../../shared/data/trusted_command_gateways.dart';

enum SecurityComplianceCommandType {
  createFinding('security.finding.create', 'itsmCreateSecurityFinding'),
  triageFinding('security.finding.triage', 'itsmTriageSecurityFinding'),
  assignFinding('security.finding.assign', 'itsmAssignSecurityFinding'),
  planRemediation(
    'security.finding.remediation.plan',
    'itsmPlanSecurityFindingRemediation',
  ),
  submitFindingValidation(
    'security.finding.validation.submit',
    'itsmSubmitSecurityFindingValidation',
  ),
  validateFinding(
    'security.finding.validation.decide',
    'itsmValidateSecurityFinding',
  ),
  acceptFindingRisk(
    'security.finding.risk.accept',
    'itsmAcceptSecurityFindingRisk',
  ),
  closeFinding('security.finding.close', 'itsmCloseSecurityFinding'),
  cancelFinding('security.finding.cancel', 'itsmCancelSecurityFinding'),
  createException('security.exception.create', 'itsmCreateSecurityException'),
  submitException(
    'security.exception.submit',
    'itsmSubmitSecurityException',
  ),
  requestExceptionApproval(
    'security.exception.approval.request',
    'itsmRequestSecurityExceptionApproval',
  ),
  decideExceptionApproval(
    'security.exception.approval.decide',
    'itsmDecideSecurityExceptionApproval',
  ),
  activateException(
    'security.exception.activate',
    'itsmActivateSecurityException',
  ),
  renewException('security.exception.renew', 'itsmRenewSecurityException'),
  closeException('security.exception.close', 'itsmCloseSecurityException'),
  assessCompliance(
    'security.compliance.assess',
    'itsmAssessAssetCompliance',
  ),
  createReviewCampaign(
    'security.access_review.campaign.create',
    'itsmCreateAccessReviewCampaign',
  ),
  activateReviewCampaign(
    'security.access_review.campaign.activate',
    'itsmActivateAccessReviewCampaign',
  ),
  completeReviewCampaign(
    'security.access_review.campaign.complete',
    'itsmCompleteAccessReviewCampaign',
  ),
  createReviewItem(
    'security.access_review.item.create',
    'itsmCreateAccessReviewItem',
  ),
  decideReviewItem(
    'security.access_review.item.decide',
    'itsmDecideAccessReviewItem',
  ),
  requestAccessCorrection(
    'security.access_review.correction.request',
    'itsmRequestAccessCorrection',
  ),
  completeRevocationTask(
    'security.access_review.revocation.complete',
    'itsmCompleteAccessRevocationTask',
  );

  const SecurityComplianceCommandType(this.command, this.functionName);

  final String command;
  final String functionName;

  bool get isCorrection => this == requestAccessCorrection;
  bool get isSelfServiceException => const {
        createException,
        submitException,
        renewException,
        closeException,
      }.contains(this);
  bool get isOperational => !isCorrection && !isSelfServiceException;
}

class SecurityComplianceCommand {
  SecurityComplianceCommand({
    required this.context,
    required this.type,
    Map<String, Object?> payload = const {},
  }) : payload = UnmodifiableMapView(Map<String, Object?>.from(payload));

  final ItsmCommandContext context;
  final SecurityComplianceCommandType type;
  final Map<String, Object?> payload;
}

abstract interface class SecurityComplianceCommandGateway {
  Future<ItsmCommandReceipt> execute(SecurityComplianceCommand command);
}
