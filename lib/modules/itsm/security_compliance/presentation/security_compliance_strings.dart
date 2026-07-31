import 'package:arptc_connect/generated/l10n.dart';
import 'package:flutter/widgets.dart';

import '../application/security_compliance_commands.dart';
import '../domain/security_compliance_domain.dart';

/// Typed presentation adapter backed by the application's ARB localizations.
class SecurityComplianceStrings {
  const SecurityComplianceStrings._(this._l10n);

  factory SecurityComplianceStrings.of(BuildContext context) =>
      SecurityComplianceStrings._(S.of(context));

  final S _l10n;

  String value(String key) {
    final namespacedKey =
        'itsmSc${key.substring(0, 1).toUpperCase()}${key.substring(1)}';
    return _l10n.lookup(namespacedKey);
  }

  String findingSeverity(SecurityFindingSeverity severity) => value(
        switch (severity) {
          SecurityFindingSeverity.low => 'severityLow',
          SecurityFindingSeverity.medium => 'severityMedium',
          SecurityFindingSeverity.high => 'severityHigh',
          SecurityFindingSeverity.critical => 'severityCritical',
        },
      );

  String findingRisk(SecurityFindingRisk risk) => value(
        switch (risk) {
          SecurityFindingRisk.low => 'severityLow',
          SecurityFindingRisk.medium => 'severityMedium',
          SecurityFindingRisk.high => 'severityHigh',
          SecurityFindingRisk.critical => 'severityCritical',
        },
      );

  String findingCommand(SecurityComplianceCommandType command) => value(
        switch (command) {
          SecurityComplianceCommandType.triageFinding => 'actionTriageFinding',
          SecurityComplianceCommandType.assignFinding => 'actionAssignFinding',
          SecurityComplianceCommandType.planRemediation =>
            'actionPlanRemediation',
          SecurityComplianceCommandType.submitFindingValidation =>
            'actionSubmitValidation',
          SecurityComplianceCommandType.validateFinding =>
            'actionValidateFinding',
          SecurityComplianceCommandType.acceptFindingRisk => 'actionAcceptRisk',
          SecurityComplianceCommandType.closeFinding => 'actionCloseFinding',
          SecurityComplianceCommandType.cancelFinding => 'actionCancelFinding',
          _ => command.command,
        },
      );

  String exceptionCommand(SecurityComplianceCommandType command) => value(
        switch (command) {
          SecurityComplianceCommandType.submitException =>
            'actionSubmitException',
          SecurityComplianceCommandType.requestExceptionApproval =>
            'actionRequestExceptionApproval',
          SecurityComplianceCommandType.decideExceptionApproval =>
            'actionDecideExceptionApproval',
          SecurityComplianceCommandType.activateException =>
            'actionActivateException',
          SecurityComplianceCommandType.renewException =>
            'actionRenewException',
          SecurityComplianceCommandType.closeException =>
            'actionCloseException',
          _ => command.command,
        },
      );

  String findingStatus(SecurityFindingStatus status) => value(
        switch (status) {
          SecurityFindingStatus.detected => 'findingStatusDetected',
          SecurityFindingStatus.triaged => 'findingStatusTriaged',
          SecurityFindingStatus.assigned => 'findingStatusAssigned',
          SecurityFindingStatus.remediation => 'findingStatusRemediation',
          SecurityFindingStatus.validation => 'findingStatusValidation',
          SecurityFindingStatus.closed => 'findingStatusClosed',
          SecurityFindingStatus.riskAccepted => 'findingStatusRiskAccepted',
          SecurityFindingStatus.cancelled => 'findingStatusCancelled',
        },
      );
  String exceptionStatus(SecurityExceptionStatus status) => value(
        switch (status) {
          SecurityExceptionStatus.draft => 'exceptionStatusDraft',
          SecurityExceptionStatus.submitted => 'exceptionStatusSubmitted',
          SecurityExceptionStatus.underReview => 'exceptionStatusUnderReview',
          SecurityExceptionStatus.awaitingApproval =>
            'exceptionStatusAwaitingApproval',
          SecurityExceptionStatus.approved => 'exceptionStatusApproved',
          SecurityExceptionStatus.rejected => 'exceptionStatusRejected',
          SecurityExceptionStatus.active => 'exceptionStatusActive',
          SecurityExceptionStatus.expired => 'exceptionStatusExpired',
          SecurityExceptionStatus.closed => 'exceptionStatusClosed',
          SecurityExceptionStatus.cancelled => 'exceptionStatusCancelled',
        },
      );
  String campaignStatus(AccessReviewCampaignStatus status) => value(
        switch (status) {
          AccessReviewCampaignStatus.draft => 'campaignStatusDraft',
          AccessReviewCampaignStatus.active => 'campaignStatusActive',
          AccessReviewCampaignStatus.completed => 'campaignStatusCompleted',
          AccessReviewCampaignStatus.cancelled => 'campaignStatusCancelled',
        },
      );
  String reviewStatus(AccessReviewCompletionStatus status) => value(
        switch (status) {
          AccessReviewCompletionStatus.pending => 'reviewStatusPending',
          AccessReviewCompletionStatus.decided => 'reviewStatusDecided',
          AccessReviewCompletionStatus.revocationPending =>
            'reviewStatusRevocationPending',
          AccessReviewCompletionStatus.completed => 'reviewStatusCompleted',
        },
      );
  String correctionStatus(AccessCorrectionRequestStatus status) => value(
        switch (status) {
          AccessCorrectionRequestStatus.submitted =>
            'correctionStatusSubmitted',
          AccessCorrectionRequestStatus.inReview => 'correctionStatusInReview',
          AccessCorrectionRequestStatus.completed =>
            'correctionStatusCompleted',
          AccessCorrectionRequestStatus.rejected => 'correctionStatusRejected',
          AccessCorrectionRequestStatus.cancelled =>
            'correctionStatusCancelled',
        },
      );
  String correctionType(AccessCorrectionRequestType type) =>
      type == AccessCorrectionRequestType.revocation
          ? value('requestRevocation')
          : value('requestCorrection');

  String complianceStatus(OwnDeviceComplianceStatus status) => value(
        switch (status) {
          OwnDeviceComplianceStatus.compliant => 'complianceCompliant',
          OwnDeviceComplianceStatus.actionRequired =>
            'complianceActionRequired',
          OwnDeviceComplianceStatus.assessmentPending =>
            'complianceAssessmentPending',
        },
      );

  String assessmentResult(AssetComplianceResult result) => value(
        switch (result) {
          AssetComplianceResult.compliant => 'complianceCompliant',
          AssetComplianceResult.nonCompliant => 'complianceActionRequired',
          AssetComplianceResult.assessmentPending =>
            'complianceAssessmentPending',
        },
      );
}
