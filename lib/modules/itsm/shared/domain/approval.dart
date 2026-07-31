import 'itsm_common.dart';

enum ApprovalMode { sequential, parallel }

enum ApprovalStatus {
  pending,
  approved,
  rejected,
  clarificationRequested,
  cancelled,
  expired,
}

enum ApprovalDecision { approve, reject, requestClarification }

enum ApprovalDecisionIssue {
  approvalNotPending,
  requesterCannotApprove,
  actorNotAssigned,
  actorNotInApproverGroup,
  rejectionCommentRequired,
  clarificationCommentRequired,
}

class ApprovalDecisionValidation {
  ApprovalDecisionValidation(Iterable<ApprovalDecisionIssue> issues)
      : issues = List<ApprovalDecisionIssue>.unmodifiable(issues);

  final List<ApprovalDecisionIssue> issues;

  bool get isValid => issues.isEmpty;
}

class ApprovalPolicy {
  ApprovalPolicy({
    required this.id,
    required this.mode,
    this.enforceSeparationOfDuties = true,
    this.allowDelegation = true,
    this.requireRejectionComment = true,
    this.requireClarificationComment = true,
  }) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'An approval policy ID is required.');
    }
  }

  final String id;
  final ApprovalMode mode;
  final bool enforceSeparationOfDuties;
  final bool allowDelegation;
  final bool requireRejectionComment;
  final bool requireClarificationComment;
}

class ApprovalDecisionRecord {
  const ApprovalDecisionRecord({
    required this.decision,
    required this.decidedBy,
    required this.decidedAt,
    required this.comment,
  });

  final ApprovalDecision decision;
  final String decidedBy;
  final DateTime decidedAt;
  final String comment;
}

class Approval {
  Approval({
    required this.id,
    required this.workItemType,
    required this.workItemId,
    required this.step,
    required this.status,
    required this.requestedAt,
    this.approverUserId,
    this.approverGroupId,
    this.delegatedToUserId,
    this.delegatedByUserId,
    this.decision,
    this.comment = '',
    this.dueAt,
    this.decidedAt,
    this.decidedBy,
    Iterable<ApprovalDecisionRecord> decisionHistory = const [],
  }) : decisionHistory =
            List<ApprovalDecisionRecord>.unmodifiable(decisionHistory) {
    if (id.trim().isEmpty || workItemId.trim().isEmpty) {
      throw ArgumentError('Approval and work-item IDs are required.');
    }
    if (step < 1) throw RangeError.value(step, 'step');
    if ((approverUserId?.trim().isEmpty ?? true) &&
        (approverGroupId?.trim().isEmpty ?? true)) {
      throw ArgumentError(
        'An approval requires an approver user or approver group.',
      );
    }
  }

  final String id;
  final ItsmWorkItemType workItemType;
  final String workItemId;
  final int step;
  final String? approverUserId;
  final String? approverGroupId;
  final String? delegatedToUserId;
  final String? delegatedByUserId;
  final ApprovalStatus status;
  final ApprovalDecision? decision;
  final String comment;
  final DateTime requestedAt;
  final DateTime? dueAt;
  final DateTime? decidedAt;
  final String? decidedBy;
  final List<ApprovalDecisionRecord> decisionHistory;

  Approval applyDecision({
    required ApprovalPolicy policy,
    required String actorUserId,
    required String requesterUserId,
    required ApprovalDecision decision,
    required DateTime decidedAt,
    String comment = '',
    Set<String> actorGroupIds = const {},
  }) {
    final validation = ApprovalDecisionPolicy.validate(
      approval: this,
      policy: policy,
      actorUserId: actorUserId,
      requesterUserId: requesterUserId,
      decision: decision,
      comment: comment,
      actorGroupIds: actorGroupIds,
    );
    if (!validation.isValid) {
      throw ApprovalDecisionException(validation);
    }

    final nextStatus = switch (decision) {
      ApprovalDecision.approve => ApprovalStatus.approved,
      ApprovalDecision.reject => ApprovalStatus.rejected,
      ApprovalDecision.requestClarification =>
        ApprovalStatus.clarificationRequested,
    };
    final historyEntry = ApprovalDecisionRecord(
      decision: decision,
      decidedBy: actorUserId,
      decidedAt: decidedAt,
      comment: comment.trim(),
    );

    return Approval(
      id: id,
      workItemType: workItemType,
      workItemId: workItemId,
      step: step,
      approverUserId: approverUserId,
      approverGroupId: approverGroupId,
      delegatedToUserId: delegatedToUserId,
      delegatedByUserId: delegatedByUserId,
      status: nextStatus,
      decision: decision,
      comment: comment.trim(),
      requestedAt: requestedAt,
      dueAt: dueAt,
      decidedAt: decidedAt,
      decidedBy: actorUserId,
      decisionHistory: [...decisionHistory, historyEntry],
    );
  }
}

abstract final class ApprovalDecisionPolicy {
  static ApprovalDecisionValidation validate({
    required Approval approval,
    required ApprovalPolicy policy,
    required String actorUserId,
    required String requesterUserId,
    required ApprovalDecision decision,
    required String comment,
    Set<String> actorGroupIds = const {},
  }) {
    final issues = <ApprovalDecisionIssue>[];
    final actor = actorUserId.trim();

    if (approval.status != ApprovalStatus.pending) {
      issues.add(ApprovalDecisionIssue.approvalNotPending);
    }
    if (policy.enforceSeparationOfDuties &&
        actor.isNotEmpty &&
        actor == requesterUserId.trim()) {
      issues.add(ApprovalDecisionIssue.requesterCannotApprove);
    }

    final assignedUser = approval.approverUserId?.trim();
    final delegatedUser = approval.delegatedToUserId?.trim();
    if (assignedUser != null && assignedUser.isNotEmpty) {
      final actorIsAssigned = actor == assignedUser;
      final actorIsDelegate = policy.allowDelegation &&
          delegatedUser != null &&
          delegatedUser.isNotEmpty &&
          actor == delegatedUser;
      if (!actorIsAssigned && !actorIsDelegate) {
        issues.add(ApprovalDecisionIssue.actorNotAssigned);
      }
    } else {
      final groupId = approval.approverGroupId?.trim();
      if (groupId == null ||
          groupId.isEmpty ||
          !actorGroupIds.contains(groupId)) {
        issues.add(ApprovalDecisionIssue.actorNotInApproverGroup);
      }
    }

    if (decision == ApprovalDecision.reject &&
        policy.requireRejectionComment &&
        comment.trim().isEmpty) {
      issues.add(ApprovalDecisionIssue.rejectionCommentRequired);
    }
    if (decision == ApprovalDecision.requestClarification &&
        policy.requireClarificationComment &&
        comment.trim().isEmpty) {
      issues.add(ApprovalDecisionIssue.clarificationCommentRequired);
    }

    return ApprovalDecisionValidation(issues);
  }
}

class ApprovalDecisionException implements Exception {
  const ApprovalDecisionException(this.validation);

  final ApprovalDecisionValidation validation;
}
