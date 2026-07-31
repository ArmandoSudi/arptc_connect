import 'package:arptc_connect/modules/itsm/reporting_administration/domain/reporting_administration_domain.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_common.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/sla.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/workflow.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SLA policy versions', () {
    test('validate business targets, timezone and immutable publication state',
        () {
      final version = _slaVersion();
      expect(version.validateForPublication().isValid, isTrue);
      expect(version.isImmutable, isFalse);

      final parsed = SlaPolicyVersionConfiguration.fromMap('sla-1', 'v1', {
        ...version.toCommandPayload(),
        'status': 'published',
        'createdAt': '2026-07-01T00:00:00Z',
        'createdBy': 'manager-1',
      });
      expect(parsed.isImmutable, isTrue);
      expect(parsed.calendar.isHoliday(DateTime.utc(2026, 7, 30)), isTrue);
    });

    test('rejects invalid publication inputs', () {
      final invalid = _slaVersion(
        timeZone: 'Kinshasa',
        response: const Duration(hours: 4),
        resolution: const Duration(hours: 2),
      );
      final codes =
          invalid.validateForPublication().issues.map((issue) => issue.code);
      expect(codes, containsAll(['target_order', 'invalid_timezone']));
    });
  });

  test('catalogue publication validates translations, unique keys and pins',
      () {
    final version = CatalogueItemVersionConfiguration(
      itemId: 'catalogue-1',
      versionId: 'v1',
      version: 1,
      state: ItsmPublicationState.draft,
      name: const {'en': 'Laptop request', 'fr': ''},
      description: const {'en': 'Request a laptop', 'fr': 'Demander un laptop'},
      categoryId: 'hardware',
      workflowId: 'request-flow',
      workflowVersion: 2,
      slaPolicyId: 'request-sla',
      slaPolicyVersion: 3,
      visibleRoles: const [ItsmRole.user],
      fieldKeys: const ['reason', 'reason'],
      requiredDocumentKeys: const ['approval'],
      createdAt: DateTime.utc(2026, 7, 1),
      createdBy: 'manager-1',
    );
    final codes =
        version.validateForPublication().issues.map((issue) => issue.code);
    expect(codes, containsAll(['name_fr', 'duplicate_fields']));
  });

  test(
      'workflow publication detects duplicate transitions and invalid SLA flags',
      () {
    final version = WorkflowVersionConfiguration(
      workflowId: 'wf-1',
      versionId: 'v1',
      workflow: WorkflowVersion(
        version: 1,
        state: ItsmPublicationState.draft,
        startStateId: 'open',
        states: const [
          WorkflowStateDefinition(id: 'open', label: 'Open'),
          WorkflowStateDefinition(
              id: 'closed', label: 'Closed', isTerminal: true),
        ],
        transitions: [
          for (var index = 0; index < 2; index++)
            WorkflowTransition(
              id: 'close',
              fromStateId: 'open',
              toStateId: 'closed',
              permittedRoles: const [ItsmRole.manager],
              pausesSla: true,
              resumesSla: true,
            ),
        ],
        createdAt: DateTime.utc(2026, 7, 1),
        createdBy: 'manager-1',
      ),
    );
    final messages = version
        .validateForPublication()
        .issues
        .map((issue) => issue.message)
        .join(' ');
    expect(messages, contains('declared more than once'));
    expect(messages, contains('cannot pause and resume'));
  });
}

SlaPolicyVersionConfiguration _slaVersion({
  String timeZone = 'Africa/Kinshasa',
  Duration response = const Duration(hours: 1),
  Duration resolution = const Duration(hours: 8),
}) =>
    SlaPolicyVersionConfiguration(
      policyId: 'sla-1',
      versionId: 'v1',
      version: 1,
      state: ItsmPublicationState.draft,
      name: 'Incident SLA',
      workItemType: ItsmWorkItemType.incident,
      timeZone: timeZone,
      responseTarget: response,
      resolutionTarget: resolution,
      calendar:
          BusinessCalendar.standardWeek(holidays: [DateTime.utc(2026, 7, 30)]),
      warningThreshold: .8,
      createdAt: DateTime.utc(2026, 7, 1),
      createdBy: 'manager-1',
    );
