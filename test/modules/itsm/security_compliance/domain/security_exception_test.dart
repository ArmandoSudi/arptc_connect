import 'package:arptc_connect/modules/itsm/security_compliance/domain/security_compliance_domain.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/approval.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_common.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SecurityException', () {
    test('round-trips request, controls, approvals and work-item summary', () {
      final source = _exception(
        approvals: [
          _approval(approverUserIds: const ['manager-1'])
        ],
      );

      final parsed = SecurityException.fromMap(source.id, source.toMap());
      final summary = parsed.toWorkItemSummary();

      expect(parsed.requester.userId, 'user-1');
      expect(parsed.compensatingControls.single.effective, isTrue);
      expect(parsed.approvals.single.status, ApprovalStatus.pending);
      expect(summary.requesterId, 'user-1');
      expect(summary.type.value, 'security_exception');
      expect(summary.dueAt, DateTime.utc(2026, 12, 31));
    });

    test('rejects invalid exception periods and review dates', () {
      expect(
        () => _exception(
          requestedStartAt: DateTime.utc(2026, 12, 31),
          requestedEndAt: DateTime.utc(2026, 12, 1),
        ),
        throwsArgumentError,
      );
      expect(
        () => _exception(reviewAt: DateTime.utc(2027, 1, 1)),
        throwsArgumentError,
      );
    });

    test('calculates expiry and lead-time notification deterministically', () {
      final exception = _exception(status: SecurityExceptionStatus.active);

      expect(
        exception.shouldNotifyExpiryAt(DateTime.utc(2026, 12, 20)),
        isTrue,
      );
      expect(
        exception.shouldNotifyExpiryAt(DateTime.utc(2026, 12, 1)),
        isFalse,
      );
      expect(exception.isExpiredAt(DateTime.utc(2026, 12, 31)), isTrue);
    });

    test('keeps controls and approvals immutable', () {
      final exception = _exception(
        approvals: [
          _approval(approverUserIds: const ['manager-1'])
        ],
      );

      expect(
        () => exception.compensatingControls.clear(),
        throwsUnsupportedError,
      );
      expect(() => exception.approvals.clear(), throwsUnsupportedError);
    });
  });

  group('SecurityExceptionApprovalPolicy', () {
    test('prevents requester from being the sole approver', () {
      final exception = _exception();
      final approval = _approval(approverUserIds: const ['user-1']);

      final validation = SecurityExceptionApprovalPolicy.validate(
        exception: exception,
        approval: approval,
        actorRole: ItsmRole.manager,
        actorUserId: 'user-1',
        decision: ApprovalDecision.approve,
      );

      expect(
        validation.issues,
        contains(
          SecurityExceptionApprovalIssue.requesterCannotBeSoleApprover,
        ),
      );
    });

    test('prevents sole self-approval through an approver group', () {
      final validation = SecurityExceptionApprovalPolicy.validate(
        exception: _exception(),
        approval: SecurityExceptionApproval(
          id: 'approval-1',
          status: ApprovalStatus.pending,
          requestedAt: DateTime.utc(2026, 8, 1),
          approverGroupId: 'security-managers',
        ),
        actorRole: ItsmRole.manager,
        actorUserId: 'user-1',
        actorGroupIds: const {'security-managers'},
        decision: ApprovalDecision.approve,
      );

      expect(
        validation.issues,
        contains(
          SecurityExceptionApprovalIssue.requesterCannotBeSoleApprover,
        ),
      );
    });

    test('allows a separately assigned MANAGER to approve', () {
      final validation = SecurityExceptionApprovalPolicy.validate(
        exception: _exception(),
        approval: _approval(approverUserIds: const ['manager-1']),
        actorRole: ItsmRole.manager,
        actorUserId: 'manager-1',
        decision: ApprovalDecision.approve,
      );

      expect(validation.isValid, isTrue);
    });

    test('requires MANAGER role, assignment and rejection reason', () {
      final validation = SecurityExceptionApprovalPolicy.validate(
        exception: _exception(),
        approval: _approval(approverUserIds: const ['manager-1']),
        actorRole: ItsmRole.admin,
        actorUserId: 'admin-1',
        decision: ApprovalDecision.reject,
      );

      expect(
        validation.issues,
        containsAll([
          SecurityExceptionApprovalIssue.actorMustBeManager,
          SecurityExceptionApprovalIssue.actorNotAssigned,
          SecurityExceptionApprovalIssue.rejectionReasonRequired,
        ]),
      );
    });
  });

  group('SecurityException renewal and lifecycle', () {
    test('accepts an extending renewal with review and new approval', () {
      final exception = _exception(status: SecurityExceptionStatus.active);
      final renewal = _renewal(
        requestedEndAt: DateTime.utc(2027, 6, 30),
        reviewAt: DateTime.utc(2027, 3, 31),
        justification: 'The replacement remains in procurement.',
        approvalIds: const ['approval-2'],
      );

      expect(
        SecurityExceptionRenewalPolicy.validate(
          exception: exception,
          renewal: renewal,
        ).isValid,
        isTrue,
      );
    });

    test('rejects non-extending and unapproved renewal requests', () {
      final validation = SecurityExceptionRenewalPolicy.validate(
        exception: _exception(status: SecurityExceptionStatus.active),
        renewal: _renewal(
          requestedEndAt: DateTime.utc(2026, 12, 31),
          reviewAt: DateTime.utc(2026, 12, 31),
          justification: '',
        ),
      );

      expect(
        validation.issues,
        containsAll([
          SecurityExceptionRenewalIssue.endDateMustExtendException,
          SecurityExceptionRenewalIssue.justificationRequired,
          SecurityExceptionRenewalIssue.newApprovalRequired,
        ]),
      );
    });

    test('permits only governed exception transitions', () {
      expect(
        SecurityExceptionTransitionPolicy.canTransition(
          SecurityExceptionStatus.awaitingApproval,
          SecurityExceptionStatus.approved,
        ),
        isTrue,
      );
      expect(
        SecurityExceptionTransitionPolicy.canTransition(
          SecurityExceptionStatus.draft,
          SecurityExceptionStatus.active,
        ),
        isFalse,
      );
      expect(
        SecurityExceptionTransitionPolicy.canTransition(
          SecurityExceptionStatus.closed,
          SecurityExceptionStatus.active,
        ),
        isFalse,
      );
    });
  });
}

SecurityException _exception({
  SecurityExceptionStatus status = SecurityExceptionStatus.submitted,
  DateTime? requestedStartAt,
  DateTime? requestedEndAt,
  DateTime? reviewAt,
  Iterable<SecurityExceptionApproval> approvals = const [],
}) {
  return SecurityException(
    id: 'exception-1',
    reference: 'EXC-1',
    title: 'Temporary encryption exception',
    requirementOrControl: 'Endpoint encryption baseline',
    businessJustification: 'A legacy appliance needs a supported replacement.',
    scope: 'One legacy monitoring appliance',
    affectedAssetId: 'asset-1',
    affectedServiceId: 'service-1',
    affectedUserId: 'user-1',
    riskDescription: 'Data could be exposed if the appliance is removed.',
    compensatingControls: [
      CompensatingControl(
        id: 'control-1',
        description: 'Restrict the appliance to an isolated VLAN.',
        effective: true,
      ),
    ],
    requester: SecurityActor(userId: 'user-1', displayName: 'User One'),
    owner: SecurityActor(userId: 'manager-1', displayName: 'Manager One'),
    status: status,
    requestedStartAt: requestedStartAt ?? DateTime.utc(2026, 8, 1),
    requestedEndAt: requestedEndAt ?? DateTime.utc(2026, 12, 31),
    reviewAt: reviewAt ?? DateTime.utc(2026, 10, 31),
    approvals: approvals,
    createdAt: DateTime.utc(2026, 7, 31),
    updatedAt: DateTime.utc(2026, 8, 1),
    updatedBy: 'manager-1',
  );
}

SecurityExceptionApproval _approval({
  required Iterable<String> approverUserIds,
}) =>
    SecurityExceptionApproval(
      id: 'approval-1',
      status: ApprovalStatus.pending,
      requestedAt: DateTime.utc(2026, 8, 1),
      approverUserIds: approverUserIds,
    );

SecurityExceptionRenewalRequest _renewal({
  required DateTime requestedEndAt,
  required DateTime reviewAt,
  required String justification,
  Iterable<String> approvalIds = const [],
}) =>
    SecurityExceptionRenewalRequest(
      id: 'renewal-1',
      exceptionId: 'exception-1',
      requestedEndAt: requestedEndAt,
      reviewAt: reviewAt,
      justification: justification,
      requestedBy: 'user-1',
      requestedAt: DateTime.utc(2026, 12, 1),
      approvalIds: approvalIds,
    );
