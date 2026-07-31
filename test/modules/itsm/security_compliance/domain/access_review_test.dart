import 'package:arptc_connect/modules/itsm/security_compliance/domain/security_compliance_domain.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_common.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AccessReviewCampaign', () {
    test('round-trips bounded campaign scope and immutable reviewers', () {
      final source = _campaign();

      final parsed = AccessReviewCampaign.fromMap(source.id, source.toMap());

      expect(parsed.systemId, 'directory-1');
      expect(parsed.reviewerUserIds, ['manager-1']);
      expect(
        () => parsed.reviewerUserIds.add('manager-2'),
        throwsUnsupportedError,
      );
    });

    test('requires reviewers before activating a campaign', () {
      expect(
        () => _campaign(reviewerUserIds: const []),
        throwsArgumentError,
      );
    });

    test('allows only draft-active-completed or cancellation paths', () {
      expect(
        AccessReviewCampaignTransitionPolicy.canTransition(
          AccessReviewCampaignStatus.draft,
          AccessReviewCampaignStatus.active,
        ),
        isTrue,
      );
      expect(
        AccessReviewCampaignTransitionPolicy.canTransition(
          AccessReviewCampaignStatus.active,
          AccessReviewCampaignStatus.completed,
        ),
        isTrue,
      );
      expect(
        AccessReviewCampaignTransitionPolicy.canTransition(
          AccessReviewCampaignStatus.completed,
          AccessReviewCampaignStatus.active,
        ),
        isFalse,
      );
    });
  });

  group('AccessReviewItem and revocation task', () {
    test('round-trips a retain decision and immutable evidence', () {
      final source = _item(
        decision: AccessReviewDecision.retain,
        completionStatus: AccessReviewCompletionStatus.completed,
        decidedAt: DateTime.utc(2026, 8, 2),
        justification: 'Access remains required for payroll duties.',
      );

      final parsed = AccessReviewItem.fromMap(source.id, source.toMap());

      expect(parsed.subjectUser.userId, 'user-1');
      expect(parsed.decision, AccessReviewDecision.retain);
      expect(parsed.isOwnedBy('user-1'), isTrue);
      expect(() => parsed.evidence.clear(), throwsUnsupportedError);
    });

    test('requires a task when access is revoked or modified', () {
      expect(
        () => _item(
          decision: AccessReviewDecision.revoke,
          completionStatus: AccessReviewCompletionStatus.revocationPending,
          decidedAt: DateTime.utc(2026, 8, 2),
          justification: 'Access is no longer required.',
        ),
        throwsArgumentError,
      );
    });

    test('requires target access for modification tasks', () {
      expect(
        () => _task(action: AccessRevocationAction.modify),
        throwsArgumentError,
      );
    });

    test('requires completion evidence metadata for completed tasks', () {
      expect(
        () => AccessRevocationTask(
          id: 'task-1',
          accessReviewItemId: 'item-1',
          action: AccessRevocationAction.revoke,
          status: AccessRevocationTaskStatus.completed,
          assignedToUserId: 'manager-1',
          dueAt: DateTime.utc(2026, 8, 10),
          createdAt: DateTime.utc(2026, 8, 2),
          createdBy: 'manager-1',
        ),
        throwsArgumentError,
      );
    });
  });

  group('AccessReviewDecisionPolicy', () {
    test('allows assigned MANAGER to retain access with justification', () {
      final validation = AccessReviewDecisionPolicy.validate(
        item: _item(),
        actorRole: ItsmRole.manager,
        actorUserId: 'manager-1',
        decision: AccessReviewDecision.retain,
        justification: 'Required for assigned responsibilities.',
      );

      expect(validation.isValid, isTrue);
    });

    test('denies non-manager, non-reviewer and blank justification', () {
      final validation = AccessReviewDecisionPolicy.validate(
        item: _item(),
        actorRole: ItsmRole.admin,
        actorUserId: 'admin-1',
        decision: AccessReviewDecision.retain,
        justification: '',
      );

      expect(
        validation.issues,
        containsAll([
          AccessReviewDecisionIssue.actorMustBeManager,
          AccessReviewDecisionIssue.actorNotReviewer,
          AccessReviewDecisionIssue.justificationRequired,
        ]),
      );
    });

    test('requires matching revocation or modification task', () {
      final missing = AccessReviewDecisionPolicy.validate(
        item: _item(),
        actorRole: ItsmRole.manager,
        actorUserId: 'manager-1',
        decision: AccessReviewDecision.revoke,
        justification: 'Access is no longer required.',
      );
      final mismatched = AccessReviewDecisionPolicy.validate(
        item: _item(),
        actorRole: ItsmRole.manager,
        actorUserId: 'manager-1',
        decision: AccessReviewDecision.modify,
        justification: 'Reduce access to read only.',
        revocationTask: _task(action: AccessRevocationAction.revoke),
      );

      expect(
        missing.issues,
        contains(AccessReviewDecisionIssue.revocationTaskRequired),
      );
      expect(
        mismatched.issues,
        contains(AccessReviewDecisionIssue.taskActionMismatch),
      );
    });
  });

  group('Access correction request', () {
    test('serializes a governed self-service revocation request', () {
      final source = AccessCorrectionRequest(
        id: 'correction-1',
        accessReviewItemId: 'item-1',
        requestedBy: 'user-1',
        type: AccessCorrectionRequestType.revocation,
        reason: 'I no longer need this access.',
        status: AccessCorrectionRequestStatus.submitted,
        createdAt: DateTime.utc(2026, 8, 2),
      );

      final parsed = AccessCorrectionRequest.fromMap(source.toMap());

      expect(parsed.requestedBy, 'user-1');
      expect(parsed.type, AccessCorrectionRequestType.revocation);
      expect(parsed.status, AccessCorrectionRequestStatus.submitted);
    });
  });
}

AccessReviewCampaign _campaign({
  Iterable<String> reviewerUserIds = const ['manager-1'],
}) =>
    AccessReviewCampaign(
      id: 'campaign-1',
      reference: 'AR-2026-01',
      title: 'Quarterly directory review',
      scope: 'Finance department privileged access',
      systemId: 'directory-1',
      systemName: 'Corporate Directory',
      owner: SecurityActor(userId: 'manager-1', displayName: 'Manager One'),
      status: AccessReviewCampaignStatus.active,
      startsAt: DateTime.utc(2026, 8, 1),
      dueAt: DateTime.utc(2026, 8, 31),
      reviewerUserIds: reviewerUserIds,
      departmentIds: const ['department-1'],
      createdAt: DateTime.utc(2026, 7, 31),
      createdBy: 'manager-1',
      updatedAt: DateTime.utc(2026, 8, 1),
    );

AccessReviewItem _item({
  AccessReviewDecision decision = AccessReviewDecision.pending,
  AccessReviewCompletionStatus completionStatus =
      AccessReviewCompletionStatus.pending,
  DateTime? decidedAt,
  String justification = '',
  AccessRevocationTask? revocationTask,
}) =>
    AccessReviewItem(
      id: 'item-1',
      campaignId: 'campaign-1',
      systemId: 'directory-1',
      systemName: 'Corporate Directory',
      subjectUser: SecurityActor(userId: 'user-1', displayName: 'User One'),
      currentAccess: 'Finance records read/write',
      currentRole: 'finance_operator',
      departmentId: 'department-1',
      departmentName: 'Finance',
      reviewer: SecurityActor(
        userId: 'manager-1',
        displayName: 'Manager One',
      ),
      decision: decision,
      completionStatus: completionStatus,
      dueAt: DateTime.utc(2026, 8, 31),
      createdAt: DateTime.utc(2026, 8, 1),
      updatedAt: DateTime.utc(2026, 8, 2),
      decidedAt: decidedAt,
      justification: justification,
      revocationTask: revocationTask,
    );

AccessRevocationTask _task({
  required AccessRevocationAction action,
  String targetAccess = '',
}) =>
    AccessRevocationTask(
      id: 'task-1',
      accessReviewItemId: 'item-1',
      action: action,
      targetAccess: targetAccess,
      status: AccessRevocationTaskStatus.pending,
      assignedToUserId: 'manager-1',
      dueAt: DateTime.utc(2026, 8, 10),
      createdAt: DateTime.utc(2026, 8, 2),
      createdBy: 'manager-1',
    );
