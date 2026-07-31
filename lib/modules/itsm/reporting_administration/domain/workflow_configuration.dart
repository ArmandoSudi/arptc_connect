import '../../shared/domain/itsm_common.dart';
import '../../shared/domain/workflow.dart';
import 'configuration_common.dart';

class WorkflowConfiguration {
  const WorkflowConfiguration({
    required this.id,
    required this.name,
    required this.module,
    required this.workItemType,
    required this.status,
    required this.latestVersion,
    required this.updatedAt,
    this.currentPublishedVersion,
  });

  final String id;
  final String name;
  final String module;
  final ItsmWorkItemType workItemType;
  final ItsmPublicationState status;
  final int latestVersion;
  final int? currentPublishedVersion;
  final DateTime updatedAt;

  factory WorkflowConfiguration.fromMap(String id, Map<String, Object?> map) {
    final type = ItsmWorkItemType.tryParse(map['workItemType']);
    if (type == null) {
      throw const FormatException('Unknown workflow work-item type.');
    }
    return WorkflowConfiguration(
      id: id,
      name: _localizedLabel(map['name'], id),
      module: configurationString(map['module'], 'itsm'),
      workItemType: type,
      status: publicationState(map['status']),
      latestVersion: configurationInt(map['latestVersion'], 1),
      currentPublishedVersion: map['currentPublishedVersion'] == null
          ? null
          : configurationInt(map['currentPublishedVersion']),
      updatedAt: configurationDate(map['updatedAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}

class WorkflowVersionConfiguration {
  const WorkflowVersionConfiguration({
    required this.workflowId,
    required this.versionId,
    required this.workflow,
    this.revision = 0,
  });

  final String workflowId;
  final String versionId;
  final WorkflowVersion workflow;
  final int revision;

  bool get isImmutable => workflow.state != ItsmPublicationState.draft;

  WorkflowValidationResult validateForPublication() {
    final base = workflow.validateForPublication().issues.toList();
    final transitionIds = <String>{};
    for (final transition in workflow.transitions) {
      if (!transitionIds.add(transition.id)) {
        base.add(WorkflowValidationIssue(
          code: WorkflowValidationCode.duplicateState,
          message: 'Transition "${transition.id}" is declared more than once.',
          subjectId: transition.id,
        ));
      }
      if (transition.pausesSla && transition.resumesSla) {
        base.add(WorkflowValidationIssue(
          code: WorkflowValidationCode.unknownTransitionState,
          message:
              'Transition "${transition.id}" cannot pause and resume SLA simultaneously.',
          subjectId: transition.id,
        ));
      }
      if (transition.notificationEvents.any((event) => event.trim().isEmpty)) {
        base.add(WorkflowValidationIssue(
          code: WorkflowValidationCode.unknownTransitionState,
          message:
              'Transition "${transition.id}" has an invalid notification event.',
          subjectId: transition.id,
        ));
      }
    }
    return WorkflowValidationResult(base);
  }

  factory WorkflowVersionConfiguration.fromMap(
    String workflowId,
    String versionId,
    Map<String, Object?> map,
  ) {
    final nestedDefinition = configurationMap(map['definition']);
    final definition = nestedDefinition.isEmpty ? map : nestedDefinition;
    final states =
        configurationList(definition['states']).map(configurationMap).map(
              (state) => WorkflowStateDefinition(
                id: configurationString(state['id']),
                label: _localizedLabel(state['label']),
                isTerminal: configurationBool(state['isTerminal']),
                isRequired: configurationBool(state['isRequired'], true),
                requiresApprovalBeforeEntry:
                    configurationBool(state['requiresApprovalBeforeEntry']),
              ),
            );
    final transitions =
        configurationList(definition['transitions']).map(configurationMap).map(
              (transition) => WorkflowTransition(
                id: configurationString(transition['id']),
                fromStateId: configurationString(transition['fromStateId']),
                toStateId: configurationString(transition['toStateId']),
                permittedRoles: configurationList(transition['permittedRoles'])
                    .map(ItsmRole.tryParse)
                    .whereType<ItsmRole>(),
                mandatoryFields:
                    configurationList(transition['mandatoryFields'])
                        .map(configurationString),
                approvalPolicyId: _nullable(transition['approvalPolicyId']),
                pausesSla: configurationBool(transition['pausesSla']),
                resumesSla: configurationBool(transition['resumesSla']),
                notificationEvents:
                    configurationList(transition['notificationEvents'])
                        .map(configurationString),
                automationActions:
                    configurationList(transition['automationActions'])
                        .map(configurationString),
                isAuditable: configurationBool(transition['isAuditable'], true),
              ),
            );
    return WorkflowVersionConfiguration(
      workflowId: workflowId,
      versionId: versionId,
      workflow: WorkflowVersion(
        version: configurationInt(map['version'], 1),
        state: publicationState(map['status'] ?? map['state']),
        startStateId: configurationString(definition['startStateId']),
        states: states,
        transitions: transitions,
        createdAt: configurationDate(map['createdAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        createdBy: configurationString(map['createdBy'], 'unknown'),
        publishedAt: configurationDate(map['publishedAt']),
      ),
      revision: configurationInt(map['revision']),
    );
  }
}

class PinnedWorkflowVersionView {
  const PinnedWorkflowVersionView({
    required this.workflowId,
    required this.version,
    required this.versionDocumentId,
  });

  final String workflowId;
  final int version;
  final String versionDocumentId;

  factory PinnedWorkflowVersionView.fromMap(Map<String, Object?> map) =>
      PinnedWorkflowVersionView(
        workflowId: configurationString(map['workflowId']),
        version: configurationInt(map['workflowVersion']),
        versionDocumentId:
            configurationString(map['workflowVersionDocumentId']),
      );
}

String? _nullable(Object? value) {
  final result = configurationString(value);
  return result.isEmpty ? null : result;
}

String _localizedLabel(Object? value, [String fallback = '']) {
  final localized = configurationMap(value);
  return configurationString(
    localized['en'] ?? localized['fr'] ?? value,
    fallback,
  );
}
