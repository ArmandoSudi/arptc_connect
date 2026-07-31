import 'package:arptc_connect/modules/itsm/changes/domain/changes_domain.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_common.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChangeRequest', () {
    test('reads a trusted backend draft before an owner is assigned', () {
      final parsed = ChangeRequest.fromMap('change-1', {
        'changeNumber': 'CHG-1',
        'changeType': 'normal',
        'status': 'draft',
        'title': 'Upgrade service',
        'description': 'Upgrade the internal service.',
        'justification': 'Supported version required.',
        'requesterId': 'user-1',
        'requesterName': 'User One',
        'requesterEmail': 'user@example.test',
        'risk': 'medium',
        'revision': 3,
        'createdAt': DateTime.utc(2026, 7, 1),
        'createdByUserId': 'user-1',
        'updatedAt': DateTime.utc(2026, 7, 2),
        'updatedByUserId': 'manager-1',
      });

      expect(parsed.owner, isNull);
      expect(parsed.revision, 3);
      expect(parsed.createdBy, 'user-1');
      expect(parsed.updatedBy, 'manager-1');
    });

    test('named factories create all supported change types as drafts', () {
      expect(_draft(ChangeType.standard).type, ChangeType.standard);
      expect(_draft(ChangeType.normal).type, ChangeType.normal);
      expect(_draft(ChangeType.emergency).type, ChangeType.emergency);
      expect(_draft(ChangeType.normal).status, ChangeStatus.draft);
    });

    test('round-trips the complete additive Firestore contract', () {
      final source = _change();

      final parsed = ChangeRequest.fromMap(source.id, source.toFirestore());

      expect(parsed.changeNumber, 'CHG-2026-001');
      expect(parsed.type, ChangeType.normal);
      expect(parsed.status, ChangeStatus.scheduled);
      expect(parsed.requester.userId, 'requester-1');
      expect(parsed.owner!.email, 'owner@example.test');
      expect(parsed.affectedServices.single.name, 'Professional email');
      expect(parsed.affectedCiIds, ['ci-mail']);
      expect(parsed.affectedAssetIds, ['asset-server']);
      expect(parsed.relatedIncidentIds, ['incident-1']);
      expect(parsed.relatedRequestIds, ['request-1']);
      expect(parsed.plannedWindow!.expectedDowntimeMinutes, 30);
      expect(parsed.maintenancePublication!.isPublished, isTrue);
      expect(parsed.plans.testEvidenceIds, ['evidence-plan']);
      expect(parsed.workflowVersion, 3);
      expect(parsed.toFirestore()['changeType'], 'normal');
      expect(parsed.toFirestore()['lifecycleState'], 'active');
    });

    test('accepts legacy flattened requester and owner fields', () {
      final parsed = ChangeRequest.fromMap('change-legacy', {
        ..._change().toFirestore(),
        'requester': null,
        'owner': null,
      });

      expect(parsed.requester.name, 'Requester One');
      expect(parsed.owner!.userId, 'owner-1');
    });

    test('normalizes emails and exposes immutable related collections', () {
      final change = _change();

      expect(change.requester.email, 'requester@example.test');
      expect(() => change.affectedCiIds.add('ci-2'), throwsUnsupportedError);
      expect(
        () => change.affectedServices.add(
          ChangeAffectedReference(id: 'service-2', name: 'Internet'),
        ),
        throwsUnsupportedError,
      );
      expect(
        () => change.plans.testEvidenceIds.add('evidence-2'),
        throwsUnsupportedError,
      );
    });

    test('requires reasons and closure evidence for terminal states', () {
      expect(
        () => _change(status: ChangeStatus.rejected),
        throwsArgumentError,
      );
      expect(
        () => _change(status: ChangeStatus.cancelled),
        throwsArgumentError,
      );
      expect(
        () => _change(status: ChangeStatus.closed),
        throwsArgumentError,
      );
    });
  });

  group('nested change records', () {
    test('validates windows and published maintenance', () {
      expect(
        () => ChangeWindow(
          startsAt: DateTime.utc(2026, 8, 1, 12),
          endsAt: DateTime.utc(2026, 8, 1, 11),
        ),
        throwsArgumentError,
      );
      expect(
        () => MaintenancePublication(isPublished: true),
        throwsArgumentError,
      );
    });

    test('round-trips implementation results and PIR', () {
      final result = _implementationResult();
      final review = _review();

      final parsedResult = ChangeImplementationResult.fromMap(
        result.toFirestore(),
      );
      final parsedReview = PostImplementationReview.fromMap(
        review.toFirestore(),
      );

      expect(parsedResult.outcome, ChangeImplementationOutcome.successful);
      expect(parsedResult.evidenceIds, ['implementation-evidence']);
      expect(parsedReview.objectivesMet, isTrue);
      expect(parsedReview.actionItems, ['Monitor for 48 hours']);
    });

    test('adapts flattened trusted command fields without data loss', () {
      final change = ChangeRequest.fromMap('change-backend', {
        'changeNumber': 'CHG-2026-BACKEND',
        'changeType': 'normal',
        'status': 'review',
        'title': 'Backend-shaped change',
        'description': 'Created by the trusted command service.',
        'justification': 'Compatibility test',
        'requesterId': 'requester-1',
        'requesterName': 'Requester One',
        'requesterEmail': 'requester@example.test',
        'ownerUserId': 'manager-1',
        'ownerName': 'Manager One',
        'ownerEmail': 'manager@example.test',
        'affectedServiceIds': ['service-mail'],
        'impact': 'high',
        'urgency': 'medium',
        'risk': 'high',
        'implementationPlan': 'Deploy safely.',
        'testPlan': 'Run tests.',
        'communicationPlan': 'Notify users.',
        'rollbackPlan': 'Restore the prior version.',
        'plannedStartAt': DateTime.utc(2026, 8, 10, 20),
        'plannedEndAt': DateTime.utc(2026, 8, 10, 22),
        'expectedDowntimeMinutes': 30,
        'publishMaintenance': true,
        'scheduledAt': DateTime.utc(2026, 8, 5),
        'scheduledByUserId': 'manager-1',
        'implementationOutcome': 'succeeded',
        'implementationResult': 'Deployment completed.',
        'implementationStartedAt': DateTime.utc(2026, 8, 10, 20),
        'implementationCompletedAt': DateTime.utc(2026, 8, 10, 21),
        'implementationCompletedByUserId': 'manager-1',
        'postImplementationReview': {
          'outcome': 'partial',
          'summary': 'One follow-up remains.',
          'reviewedByUserId': 'manager-2',
          'reviewedAt': DateTime.utc(2026, 8, 12),
        },
        'createdAt': DateTime.utc(2026, 8, 1),
        'createdByUserId': 'requester-1',
        'updatedAt': DateTime.utc(2026, 8, 12),
        'updatedByUserId': 'manager-2',
        'revision': 8,
      });

      expect(change.affectedServices.single.id, 'service-mail');
      expect(change.isMaintenancePublished, isTrue);
      expect(
        change.implementationResult?.outcome,
        ChangeImplementationOutcome.successful,
      );
      expect(
        change.postImplementationReview?.outcome,
        PostImplementationReviewOutcome.partiallySuccessful,
      );
    });

    test('requires a rollback reason for rolled-back results', () {
      expect(
        () => ChangeImplementationResult(
          outcome: ChangeImplementationOutcome.rolledBack,
          summary: 'Rollback completed',
          implementedBy: 'manager-1',
          startedAt: DateTime.utc(2026, 8, 1, 10),
          endedAt: DateTime.utc(2026, 8, 1, 11),
        ),
        throwsArgumentError,
      );
    });
  });
}

ChangeRequest _draft(ChangeType type) {
  final parameters = (
    id: 'change-draft',
    changeNumber: 'CHG-DRAFT',
    title: 'Draft change',
    description: 'Draft description',
    justification: 'Required by the business',
    requester: _actor('requester-1', 'Requester One'),
    owner: _actor('owner-1', 'Owner One'),
    impact: ItsmImpact.medium,
    urgency: ItsmUrgency.medium,
    risk: ChangeRiskLevel.medium,
    plans: _plans(),
    createdAt: DateTime.utc(2026, 8, 1),
    createdBy: 'requester-1',
  );
  return switch (type) {
    ChangeType.standard => ChangeRequest.standard(
        id: parameters.id,
        changeNumber: parameters.changeNumber,
        title: parameters.title,
        description: parameters.description,
        justification: parameters.justification,
        requester: parameters.requester,
        owner: parameters.owner,
        impact: parameters.impact,
        urgency: parameters.urgency,
        risk: parameters.risk,
        plans: parameters.plans,
        createdAt: parameters.createdAt,
        createdBy: parameters.createdBy,
      ),
    ChangeType.normal => ChangeRequest.normal(
        id: parameters.id,
        changeNumber: parameters.changeNumber,
        title: parameters.title,
        description: parameters.description,
        justification: parameters.justification,
        requester: parameters.requester,
        owner: parameters.owner,
        impact: parameters.impact,
        urgency: parameters.urgency,
        risk: parameters.risk,
        plans: parameters.plans,
        createdAt: parameters.createdAt,
        createdBy: parameters.createdBy,
      ),
    ChangeType.emergency => ChangeRequest.emergency(
        id: parameters.id,
        changeNumber: parameters.changeNumber,
        title: parameters.title,
        description: parameters.description,
        justification: parameters.justification,
        requester: parameters.requester,
        owner: parameters.owner,
        impact: parameters.impact,
        urgency: parameters.urgency,
        risk: parameters.risk,
        plans: parameters.plans,
        createdAt: parameters.createdAt,
        createdBy: parameters.createdBy,
      ),
  };
}

ChangeRequest _change({ChangeStatus status = ChangeStatus.scheduled}) {
  return ChangeRequest(
    id: 'change-1',
    changeNumber: 'CHG-2026-001',
    type: ChangeType.normal,
    status: status,
    title: 'Upgrade email platform',
    description: 'Upgrade the production email platform.',
    justification: 'Vendor support ends this quarter.',
    requester: _actor('requester-1', 'Requester One'),
    owner: _actor('owner-1', 'Owner One'),
    affectedServices: [
      ChangeAffectedReference(
        id: 'service-mail',
        name: 'Professional email',
      ),
    ],
    affectedCiIds: const ['ci-mail'],
    affectedAssetIds: const ['asset-server'],
    relatedIncidentIds: const ['incident-1'],
    relatedRequestIds: const ['request-1'],
    impact: ItsmImpact.high,
    urgency: ItsmUrgency.medium,
    risk: ChangeRiskLevel.high,
    plannedWindow: ChangeWindow(
      startsAt: DateTime.utc(2026, 8, 10, 20),
      endsAt: DateTime.utc(2026, 8, 10, 22),
      expectedDowntimeMinutes: 30,
    ),
    maintenancePublication: MaintenancePublication(
      isPublished: true,
      title: 'Email maintenance',
      message: 'Email may be unavailable during the maintenance window.',
      publishedAt: DateTime.utc(2026, 8, 5),
      publishedBy: 'manager-1',
    ),
    plans: _plans(),
    workflowDefinitionId: 'normal-change',
    workflowVersion: 3,
    workflowInstanceId: 'workflow-instance-1',
    createdAt: DateTime.utc(2026, 8, 1),
    createdBy: 'requester-1',
    updatedAt: DateTime.utc(2026, 8, 5),
    updatedBy: 'owner-1',
  );
}

ChangeActor _actor(String id, String name) => ChangeActor(
      userId: id,
      name: name,
      email: '${id == 'owner-1' ? 'OWNER' : 'REQUESTER'}@example.test',
    );

ChangePlans _plans() => ChangePlans(
      implementationPlan: 'Deploy through the controlled pipeline.',
      testPlan: 'Run smoke and regression tests.',
      communicationPlan: 'Notify affected employees.',
      rollbackPlan: 'Restore the previous platform version.',
      testEvidenceIds: const ['evidence-plan'],
    );

ChangeImplementationResult _implementationResult() =>
    ChangeImplementationResult(
      outcome: ChangeImplementationOutcome.successful,
      summary: 'Upgrade completed successfully.',
      implementedBy: 'manager-1',
      startedAt: DateTime.utc(2026, 8, 10, 20),
      endedAt: DateTime.utc(2026, 8, 10, 21),
      evidenceIds: const ['implementation-evidence'],
    );

PostImplementationReview _review() => PostImplementationReview(
      outcome: PostImplementationReviewOutcome.successful,
      summary: 'Objectives met and service stable.',
      reviewedBy: 'manager-2',
      reviewedAt: DateTime.utc(2026, 8, 12),
      objectivesMet: true,
      lessonsLearned: 'Allow more time for cache warm-up.',
      actionItems: const ['Monitor for 48 hours'],
    );
