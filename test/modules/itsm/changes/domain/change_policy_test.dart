import 'package:arptc_connect/modules/itsm/changes/domain/changes_domain.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_common.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChangeRiskCalculator', () {
    test('calculates low risk for a small standard change', () {
      final assessment = ChangeRiskCalculator.calculate(
        type: ChangeType.standard,
        impact: ItsmImpact.low,
        urgency: ItsmUrgency.low,
        likelihood: ChangeLikelihood.rare,
      );

      expect(assessment.score, 1);
      expect(assessment.level, ChangeRiskLevel.low);
      expect(assessment.requiresCab, isFalse);
    });

    test('raises risk for critical, urgent, disruptive emergency work', () {
      final assessment = ChangeRiskCalculator.calculate(
        type: ChangeType.emergency,
        impact: ItsmImpact.critical,
        urgency: ItsmUrgency.high,
        likelihood: ChangeLikelihood.almostCertain,
        affectsCriticalService: true,
        expectedDowntimeMinutes: 300,
      );

      expect(assessment.score, 29);
      expect(assessment.level, ChangeRiskLevel.critical);
      expect(assessment.requiresCab, isTrue);
      expect(assessment.requiresEmergencyApproval, isTrue);
    });

    test('rejects negative expected downtime', () {
      expect(
        () => ChangeRiskCalculator.calculate(
          type: ChangeType.normal,
          impact: ItsmImpact.medium,
          urgency: ItsmUrgency.medium,
          likelihood: ChangeLikelihood.possible,
          expectedDowntimeMinutes: -1,
        ),
        throwsRangeError,
      );
    });
  });

  group('ChangeTransitionPolicy', () {
    test('contains the complete lifecycle route and terminal guards', () {
      expect(
        ChangeTransitionPolicy.validNextStatuses(ChangeStatus.draft),
        containsAll([ChangeStatus.submitted, ChangeStatus.cancelled]),
      );
      expect(
        ChangeTransitionPolicy.validNextStatuses(ChangeStatus.implementation),
        containsAll([
          ChangeStatus.review,
          ChangeStatus.failed,
          ChangeStatus.rolledBack,
        ]),
      );
      expect(
        ChangeTransitionPolicy.validNextStatuses(ChangeStatus.closed),
        isEmpty,
      );
    });

    test('normal and emergency changes require approval', () {
      final validation = ChangeTransitionPolicy.validate(
        change: _change(
          type: ChangeType.normal,
          status: ChangeStatus.awaitingApproval,
        ),
        next: ChangeStatus.approved,
      );

      expect(validation.isValid, isFalse);
      expect(
        validation.issues,
        contains(ChangeTransitionIssue.approvalRequired),
      );
    });

    test('standard changes can follow a pre-authorized approval path', () {
      final validation = ChangeTransitionPolicy.validate(
        change: _change(
          type: ChangeType.standard,
          status: ChangeStatus.assessment,
        ),
        next: ChangeStatus.approved,
      );

      expect(validation.isValid, isTrue);
    });

    test('requires complete plans before entering approval', () {
      final validation = ChangeTransitionPolicy.validate(
        change: _change(
          status: ChangeStatus.assessment,
          plans: ChangePlans(
            implementationPlan: '',
            testPlan: '',
            communicationPlan: '',
            rollbackPlan: '',
          ),
        ),
        next: ChangeStatus.awaitingApproval,
      );

      expect(
        validation.issues,
        contains(ChangeTransitionIssue.completePlansRequired),
      );
    });

    test('requires a window to schedule and a reason to cancel', () {
      final scheduling = ChangeTransitionPolicy.validate(
        change: _change(status: ChangeStatus.approved, window: false),
        next: ChangeStatus.scheduled,
      );
      final cancellation = ChangeTransitionPolicy.validate(
        change: _change(status: ChangeStatus.approved),
        next: ChangeStatus.cancelled,
      );

      expect(
        scheduling.issues,
        contains(ChangeTransitionIssue.plannedWindowRequired),
      );
      expect(
        cancellation.issues,
        contains(ChangeTransitionIssue.cancellationReasonRequired),
      );
    });

    test('accepts a valid approved-to-scheduled transition', () {
      final validation = ChangeTransitionPolicy.validate(
        change: _change(status: ChangeStatus.approved),
        next: ChangeStatus.scheduled,
      );

      expect(validation.isValid, isTrue);
    });
  });

  group('ChangeApprovalPolicy', () {
    test('prevents self-approval for normal and emergency changes', () {
      for (final type in [ChangeType.normal, ChangeType.emergency]) {
        final validation = ChangeApprovalPolicy.validate(
          changeType: type,
          requesterUserId: 'manager-1',
          approverUserId: 'manager-1',
          isEmergencyDecision: type == ChangeType.emergency,
        );
        expect(
          validation.issues,
          contains(ChangeApprovalIssue.requesterCannotApproveOwnChange),
        );
      }
    });

    test('supports configurable standard change semantics', () {
      final preAuthorized = ChangeApprovalPolicy.validate(
        changeType: ChangeType.standard,
        requesterUserId: 'manager-1',
        approverUserId: 'manager-1',
      );
      final separated = ChangeApprovalPolicy.validate(
        changeType: ChangeType.standard,
        requesterUserId: 'manager-1',
        approverUserId: 'manager-1',
        standardSemantics:
            StandardChangeApprovalSemantics.enforceSeparationOfDuties,
      );

      expect(preAuthorized.isValid, isTrue);
      expect(separated.isValid, isFalse);
    });

    test('requires an explicit emergency decision', () {
      final validation = ChangeApprovalPolicy.validate(
        changeType: ChangeType.emergency,
        requesterUserId: 'manager-1',
        approverUserId: 'manager-2',
      );

      expect(
        validation.issues,
        contains(ChangeApprovalIssue.emergencyDecisionRequired),
      );
    });
  });
}

ChangeRequest _change({
  ChangeType type = ChangeType.normal,
  ChangeStatus status = ChangeStatus.assessment,
  ChangePlans? plans,
  bool window = true,
}) {
  return ChangeRequest(
    id: 'change-1',
    changeNumber: 'CHG-1',
    type: type,
    status: status,
    title: 'Change title',
    description: 'Change description',
    justification: 'Change justification',
    requester: ChangeActor(
      userId: 'requester-1',
      name: 'Requester',
      email: 'requester@example.test',
    ),
    owner: ChangeActor(
      userId: 'owner-1',
      name: 'Owner',
      email: 'owner@example.test',
    ),
    impact: ItsmImpact.medium,
    urgency: ItsmUrgency.medium,
    risk: ChangeRiskLevel.medium,
    plannedWindow: window
        ? ChangeWindow(
            startsAt: DateTime.utc(2026, 8, 2, 10),
            endsAt: DateTime.utc(2026, 8, 2, 12),
          )
        : null,
    plans: plans ??
        ChangePlans(
          implementationPlan: 'Implement',
          testPlan: 'Test',
          communicationPlan: 'Communicate',
          rollbackPlan: 'Rollback',
        ),
    createdAt: DateTime.utc(2026, 8, 1),
    createdBy: 'requester-1',
    updatedAt: DateTime.utc(2026, 8, 1),
    updatedBy: 'requester-1',
  );
}
