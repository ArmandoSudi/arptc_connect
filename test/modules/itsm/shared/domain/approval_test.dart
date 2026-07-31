import 'package:arptc_connect/modules/itsm/shared/domain/itsm_shared_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApprovalDecisionPolicy', () {
    test('prevents a requester from approving their own work item', () {
      final validation = ApprovalDecisionPolicy.validate(
        approval: _approval(approverUserId: 'user-1'),
        policy: _policy(),
        actorUserId: 'user-1',
        requesterUserId: 'user-1',
        decision: ApprovalDecision.approve,
        comment: '',
      );

      expect(validation.isValid, isFalse);
      expect(
        validation.issues,
        contains(ApprovalDecisionIssue.requesterCannotApprove),
      );
    });

    test('requires comments for rejection and clarification', () {
      final rejection = ApprovalDecisionPolicy.validate(
        approval: _approval(),
        policy: _policy(),
        actorUserId: 'manager-1',
        requesterUserId: 'user-1',
        decision: ApprovalDecision.reject,
        comment: '',
      );
      final clarification = ApprovalDecisionPolicy.validate(
        approval: _approval(),
        policy: _policy(),
        actorUserId: 'manager-1',
        requesterUserId: 'user-1',
        decision: ApprovalDecision.requestClarification,
        comment: '',
      );

      expect(
        rejection.issues,
        contains(ApprovalDecisionIssue.rejectionCommentRequired),
      );
      expect(
        clarification.issues,
        contains(ApprovalDecisionIssue.clarificationCommentRequired),
      );
    });

    test('supports delegated and group approvers', () {
      final delegated = ApprovalDecisionPolicy.validate(
        approval: _approval(delegatedToUserId: 'manager-2'),
        policy: _policy(),
        actorUserId: 'manager-2',
        requesterUserId: 'user-1',
        decision: ApprovalDecision.approve,
        comment: '',
      );
      final group = ApprovalDecisionPolicy.validate(
        approval: _approval(
          approverUserId: null,
          approverGroupId: 'cab',
        ),
        policy: _policy(),
        actorUserId: 'manager-3',
        requesterUserId: 'user-1',
        decision: ApprovalDecision.approve,
        comment: '',
        actorGroupIds: const {'cab'},
      );

      expect(delegated.isValid, isTrue);
      expect(group.isValid, isTrue);
    });
  });

  group('Approval', () {
    test('applies a valid decision and appends immutable history', () {
      final decided = _approval().applyDecision(
        policy: _policy(),
        actorUserId: 'manager-1',
        requesterUserId: 'user-1',
        decision: ApprovalDecision.reject,
        decidedAt: DateTime.utc(2026, 8, 1, 10),
        comment: 'Insufficient business justification',
      );

      expect(decided.status, ApprovalStatus.rejected);
      expect(decided.decidedBy, 'manager-1');
      expect(decided.decisionHistory, hasLength(1));
      expect(
        decided.decisionHistory.single.comment,
        'Insufficient business justification',
      );
      expect(
        () => decided.decisionHistory.add(
          ApprovalDecisionRecord(
            decision: ApprovalDecision.approve,
            decidedBy: 'manager-2',
            decidedAt: DateTime.utc(2026, 8, 1),
            comment: '',
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('does not allow a second decision on a completed approval', () {
      final decided = _approval().applyDecision(
        policy: _policy(),
        actorUserId: 'manager-1',
        requesterUserId: 'user-1',
        decision: ApprovalDecision.approve,
        decidedAt: DateTime.utc(2026, 8, 1, 10),
      );

      expect(
        () => decided.applyDecision(
          policy: _policy(),
          actorUserId: 'manager-1',
          requesterUserId: 'user-1',
          decision: ApprovalDecision.approve,
          decidedAt: DateTime.utc(2026, 8, 1, 11),
        ),
        throwsA(isA<ApprovalDecisionException>()),
      );
    });
  });
}

ApprovalPolicy _policy() {
  return ApprovalPolicy(
    id: 'manager-approval',
    mode: ApprovalMode.sequential,
  );
}

Approval _approval({
  String? approverUserId = 'manager-1',
  String? approverGroupId,
  String? delegatedToUserId,
}) {
  return Approval(
    id: 'approval-1',
    workItemType: ItsmWorkItemType.changeRequest,
    workItemId: 'change-1',
    step: 1,
    approverUserId: approverUserId,
    approverGroupId: approverGroupId,
    delegatedToUserId: delegatedToUserId,
    delegatedByUserId: delegatedToUserId == null ? null : approverUserId,
    status: ApprovalStatus.pending,
    requestedAt: DateTime.utc(2026, 7, 31),
  );
}
