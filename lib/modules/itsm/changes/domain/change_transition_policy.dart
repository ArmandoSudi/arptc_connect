import 'change_request.dart';

enum ChangeTransitionIssue {
  sameStatus,
  transitionNotAllowed,
  approvalRequired,
  plannedWindowRequired,
  completePlansRequired,
  implementationResultRequired,
  reviewRequired,
  rejectionReasonRequired,
  cancellationReasonRequired,
}

class ChangeTransitionValidation {
  ChangeTransitionValidation(Iterable<ChangeTransitionIssue> issues)
      : issues = List<ChangeTransitionIssue>.unmodifiable(issues);

  final List<ChangeTransitionIssue> issues;

  bool get isValid => issues.isEmpty;
}

class ChangeTransitionContext {
  const ChangeTransitionContext({
    this.approvalSatisfied = false,
    this.rejectionReason = '',
    this.cancellationReason = '',
  });

  final bool approvalSatisfied;
  final String rejectionReason;
  final String cancellationReason;
}

abstract final class ChangeTransitionPolicy {
  static const Map<ChangeStatus, Set<ChangeStatus>> _allowed = {
    ChangeStatus.draft: {ChangeStatus.submitted, ChangeStatus.cancelled},
    ChangeStatus.submitted: {
      ChangeStatus.assessment,
      ChangeStatus.cancelled,
    },
    ChangeStatus.assessment: {
      ChangeStatus.awaitingApproval,
      ChangeStatus.approved,
      ChangeStatus.rejected,
      ChangeStatus.cancelled,
    },
    ChangeStatus.awaitingApproval: {
      ChangeStatus.assessment,
      ChangeStatus.approved,
      ChangeStatus.rejected,
      ChangeStatus.cancelled,
    },
    ChangeStatus.approved: {
      ChangeStatus.scheduled,
      ChangeStatus.cancelled,
    },
    ChangeStatus.scheduled: {
      ChangeStatus.implementation,
      ChangeStatus.cancelled,
    },
    ChangeStatus.implementation: {
      ChangeStatus.review,
      ChangeStatus.failed,
      ChangeStatus.rolledBack,
    },
    ChangeStatus.failed: {
      ChangeStatus.review,
      ChangeStatus.rolledBack,
    },
    ChangeStatus.rolledBack: {ChangeStatus.review},
    ChangeStatus.review: {ChangeStatus.closed},
    ChangeStatus.closed: {},
    ChangeStatus.rejected: {},
    ChangeStatus.cancelled: {},
  };

  static Set<ChangeStatus> validNextStatuses(ChangeStatus current) =>
      Set<ChangeStatus>.unmodifiable(_allowed[current] ?? const {});

  static ChangeTransitionValidation validate({
    required ChangeRequest change,
    required ChangeStatus next,
    ChangeTransitionContext context = const ChangeTransitionContext(),
  }) {
    final issues = <ChangeTransitionIssue>[];
    if (next == change.status) {
      issues.add(ChangeTransitionIssue.sameStatus);
    } else if (!(_allowed[change.status]?.contains(next) ?? false)) {
      issues.add(ChangeTransitionIssue.transitionNotAllowed);
    }

    if (next == ChangeStatus.approved &&
        change.type != ChangeType.standard &&
        !context.approvalSatisfied) {
      issues.add(ChangeTransitionIssue.approvalRequired);
    }
    if (next == ChangeStatus.scheduled && change.plannedWindow == null) {
      issues.add(ChangeTransitionIssue.plannedWindowRequired);
    }
    if ((next == ChangeStatus.awaitingApproval ||
            next == ChangeStatus.approved) &&
        !change.plans.isComplete) {
      issues.add(ChangeTransitionIssue.completePlansRequired);
    }
    if ((next == ChangeStatus.review || next == ChangeStatus.failed) &&
        change.implementationResult == null) {
      issues.add(ChangeTransitionIssue.implementationResultRequired);
    }
    if (next == ChangeStatus.closed &&
        change.postImplementationReview == null) {
      issues.add(ChangeTransitionIssue.reviewRequired);
    }
    if (next == ChangeStatus.rejected &&
        context.rejectionReason.trim().isEmpty) {
      issues.add(ChangeTransitionIssue.rejectionReasonRequired);
    }
    if (next == ChangeStatus.cancelled &&
        context.cancellationReason.trim().isEmpty) {
      issues.add(ChangeTransitionIssue.cancellationReasonRequired);
    }

    return ChangeTransitionValidation(issues);
  }
}
