import 'package:arptc_connect/modules/itsm/shared/domain/itsm_shared_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Workflow publication validation', () {
    test('publishes a reachable, auditable workflow with mandatory approval',
        () {
      final draft = _validDraft(version: 1);

      final validation = draft.validateForPublication();
      final published = draft.publish(DateTime.utc(2026, 8, 1));

      expect(validation.isValid, isTrue);
      expect(published.state, ItsmPublicationState.published);
      expect(published.publishedAt, DateTime.utc(2026, 8, 1));
      expect(published.version, 1);
    });

    test('reports structural, reachability, role, audit, and approval errors',
        () {
      final draft = WorkflowVersion(
        version: 1,
        state: ItsmPublicationState.draft,
        startStateId: 'missing',
        states: const [
          WorkflowStateDefinition(id: 'draft', label: 'Draft'),
          WorkflowStateDefinition(
            id: 'approval',
            label: 'Approval',
            requiresApprovalBeforeEntry: true,
          ),
          WorkflowStateDefinition(id: 'closed', label: 'Closed'),
        ],
        transitions: [
          WorkflowTransition(
            id: 'submit',
            fromStateId: 'draft',
            toStateId: 'approval',
            permittedRoles: const [],
            isAuditable: false,
          ),
        ],
        createdAt: DateTime.utc(2026, 7, 31),
        createdBy: 'manager-1',
      );

      final codes =
          draft.validateForPublication().issues.map((issue) => issue.code);

      expect(codes, contains(WorkflowValidationCode.unknownStartState));
      expect(codes, contains(WorkflowValidationCode.transitionWithoutRole));
      expect(codes, contains(WorkflowValidationCode.unauditedTransition));
      expect(codes, contains(WorkflowValidationCode.approvalBypass));
      expect(
        () => draft.publish(DateTime.utc(2026, 8, 1)),
        throwsA(isA<WorkflowPublicationException>()),
      );
    });

    test('reports required states that cannot be reached from the start', () {
      final draft = WorkflowVersion(
        version: 1,
        state: ItsmPublicationState.draft,
        startStateId: 'draft',
        states: const [
          WorkflowStateDefinition(id: 'draft', label: 'Draft'),
          WorkflowStateDefinition(id: 'closed', label: 'Closed'),
        ],
        transitions: const [],
        createdAt: DateTime.utc(2026, 7, 31),
        createdBy: 'manager-1',
      );

      expect(
        draft.validateForPublication().issues.map((issue) => issue.code),
        contains(WorkflowValidationCode.unreachableRequiredState),
      );
    });
  });

  group('WorkflowDefinition versioning', () {
    test('publishing a new version retires the previous published version', () {
      final publishedV1 =
          _validDraft(version: 1).publish(DateTime.utc(2026, 7, 1));
      final definition = WorkflowDefinition(
        key: 'service-request',
        module: 'support',
        workItemType: ItsmWorkItemType.serviceRequest,
        versions: [publishedV1],
      ).addDraftVersion(_validDraft(version: 2));

      final updated = definition.publishVersion(2, DateTime.utc(2026, 8, 1));

      expect(updated.publishedVersion?.version, 2);
      expect(updated.versions.first.state, ItsmPublicationState.retired);
      expect(updated.versions.last.state, ItsmPublicationState.published);
    });

    test('requires monotonically increasing immutable versions', () {
      final definition = WorkflowDefinition(
        key: 'service-request',
        module: 'support',
        workItemType: ItsmWorkItemType.serviceRequest,
        versions: [_validDraft(version: 1)],
      );

      expect(
        () => definition.addDraftVersion(_validDraft(version: 3)),
        throwsStateError,
      );
      expect(
        () => definition.versions.add(_validDraft(version: 2)),
        throwsUnsupportedError,
      );
    });
  });
}

WorkflowVersion _validDraft({required int version}) {
  return WorkflowVersion(
    version: version,
    state: ItsmPublicationState.draft,
    startStateId: 'draft',
    states: const [
      WorkflowStateDefinition(id: 'draft', label: 'Draft'),
      WorkflowStateDefinition(
        id: 'approval',
        label: 'Approval',
        requiresApprovalBeforeEntry: true,
      ),
      WorkflowStateDefinition(
        id: 'completed',
        label: 'Completed',
        isTerminal: true,
      ),
    ],
    transitions: [
      WorkflowTransition(
        id: 'submit',
        fromStateId: 'draft',
        toStateId: 'approval',
        permittedRoles: const [ItsmRole.user, ItsmRole.manager],
        approvalPolicyId: 'manager-approval',
      ),
      WorkflowTransition(
        id: 'complete',
        fromStateId: 'approval',
        toStateId: 'completed',
        permittedRoles: const [ItsmRole.manager],
      ),
    ],
    createdAt: DateTime.utc(2026, 7, 31),
    createdBy: 'manager-1',
  );
}
