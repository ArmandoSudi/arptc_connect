import 'package:arptc_connect/generated/l10n.dart';

import '../domain/changes_domain.dart';

extension ChangePresentationStrings on S {
  String changeTypeLabel(ChangeType type) => switch (type) {
        ChangeType.standard => changeStandard,
        ChangeType.normal => changeNormal,
        ChangeType.emergency => changeEmergency,
      };

  String changeStatusLabel(ChangeStatus status) => switch (status) {
        ChangeStatus.draft => changeStatusDraft,
        ChangeStatus.submitted => changeStatusSubmitted,
        ChangeStatus.assessment => changeStatusAssessment,
        ChangeStatus.awaitingApproval => changeStatusAwaitingApproval,
        ChangeStatus.approved => changeStatusApproved,
        ChangeStatus.scheduled => changeStatusScheduled,
        ChangeStatus.implementation => changeStatusImplementation,
        ChangeStatus.review => changeStatusReview,
        ChangeStatus.closed => changeStatusClosed,
        ChangeStatus.rejected => changeStatusRejected,
        ChangeStatus.cancelled => changeStatusCancelled,
        ChangeStatus.failed => changeStatusFailed,
        ChangeStatus.rolledBack => changeStatusRolledBack,
      };

  String changeRiskLabel(ChangeRiskLevel risk) => switch (risk) {
        ChangeRiskLevel.low => changeRiskLow,
        ChangeRiskLevel.medium => changeRiskMedium,
        ChangeRiskLevel.high => changeRiskHigh,
        ChangeRiskLevel.critical => changeRiskCritical,
      };

  String changeImplementationOutcomeLabel(ChangeImplementationOutcome value) =>
      switch (value) {
        ChangeImplementationOutcome.successful => changeOutcomeSuccessful,
        ChangeImplementationOutcome.successfulWithIssues =>
          changeOutcomePartial,
        ChangeImplementationOutcome.failed => changeOutcomeFailed,
        ChangeImplementationOutcome.rolledBack => changeOutcomeRolledBack,
      };

  String changeReviewOutcomeLabel(PostImplementationReviewOutcome value) =>
      switch (value) {
        PostImplementationReviewOutcome.successful => changeOutcomeSuccessful,
        PostImplementationReviewOutcome.partiallySuccessful =>
          changeOutcomePartial,
        PostImplementationReviewOutcome.unsuccessful => changeOutcomeFailed,
      };
}
