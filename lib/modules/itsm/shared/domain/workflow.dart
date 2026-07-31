import 'dart:collection';

import 'itsm_common.dart';

enum WorkflowValidationCode {
  noStates,
  duplicateState,
  missingStartState,
  unknownStartState,
  unknownTransitionState,
  transitionWithoutRole,
  unauditedTransition,
  unreachableRequiredState,
  approvalBypass,
}

class WorkflowValidationIssue {
  const WorkflowValidationIssue({
    required this.code,
    required this.message,
    this.subjectId,
  });

  final WorkflowValidationCode code;
  final String message;
  final String? subjectId;
}

class WorkflowValidationResult {
  WorkflowValidationResult(Iterable<WorkflowValidationIssue> issues)
      : issues = List<WorkflowValidationIssue>.unmodifiable(issues);

  final List<WorkflowValidationIssue> issues;

  bool get isValid => issues.isEmpty;
}

class WorkflowStateDefinition {
  const WorkflowStateDefinition({
    required this.id,
    required this.label,
    this.isTerminal = false,
    this.isRequired = true,
    this.requiresApprovalBeforeEntry = false,
  });

  final String id;
  final String label;
  final bool isTerminal;
  final bool isRequired;
  final bool requiresApprovalBeforeEntry;
}

class WorkflowTransition {
  WorkflowTransition({
    required this.id,
    required this.fromStateId,
    required this.toStateId,
    required Iterable<ItsmRole> permittedRoles,
    Iterable<String> mandatoryFields = const [],
    this.approvalPolicyId,
    this.pausesSla = false,
    this.resumesSla = false,
    Iterable<String> notificationEvents = const [],
    Iterable<String> automationActions = const [],
    this.isAuditable = true,
  })  : permittedRoles = Set<ItsmRole>.unmodifiable(permittedRoles),
        mandatoryFields = Set<String>.unmodifiable(
          mandatoryFields
              .map((field) => field.trim())
              .where((field) => field.isNotEmpty),
        ),
        notificationEvents = List<String>.unmodifiable(notificationEvents),
        automationActions = List<String>.unmodifiable(automationActions);

  final String id;
  final String fromStateId;
  final String toStateId;
  final Set<ItsmRole> permittedRoles;
  final Set<String> mandatoryFields;
  final String? approvalPolicyId;
  final bool pausesSla;
  final bool resumesSla;
  final List<String> notificationEvents;
  final List<String> automationActions;
  final bool isAuditable;

  bool permits(ItsmRole role) => permittedRoles.contains(role);
}

class WorkflowVersion {
  WorkflowVersion({
    required this.version,
    required this.state,
    required this.startStateId,
    required Iterable<WorkflowStateDefinition> states,
    required Iterable<WorkflowTransition> transitions,
    required this.createdAt,
    required this.createdBy,
    this.publishedAt,
  })  : states = List<WorkflowStateDefinition>.unmodifiable(states),
        transitions = List<WorkflowTransition>.unmodifiable(transitions) {
    if (version < 1) throw RangeError.value(version, 'version');
  }

  final int version;
  final ItsmPublicationState state;
  final String startStateId;
  final List<WorkflowStateDefinition> states;
  final List<WorkflowTransition> transitions;
  final DateTime createdAt;
  final String createdBy;
  final DateTime? publishedAt;

  WorkflowValidationResult validateForPublication() {
    final issues = <WorkflowValidationIssue>[];
    final stateIds = <String>{};
    final duplicateIds = <String>{};

    if (states.isEmpty) {
      issues.add(
        const WorkflowValidationIssue(
          code: WorkflowValidationCode.noStates,
          message: 'A workflow must contain at least one state.',
        ),
      );
    }

    for (final stateDefinition in states) {
      if (!stateIds.add(stateDefinition.id)) {
        duplicateIds.add(stateDefinition.id);
      }
    }
    for (final duplicateId in duplicateIds) {
      issues.add(
        WorkflowValidationIssue(
          code: WorkflowValidationCode.duplicateState,
          message: 'State "$duplicateId" is declared more than once.',
          subjectId: duplicateId,
        ),
      );
    }

    if (startStateId.trim().isEmpty) {
      issues.add(
        const WorkflowValidationIssue(
          code: WorkflowValidationCode.missingStartState,
          message: 'A workflow must define a start state.',
        ),
      );
    } else if (!stateIds.contains(startStateId)) {
      issues.add(
        WorkflowValidationIssue(
          code: WorkflowValidationCode.unknownStartState,
          message: 'Start state "$startStateId" is not defined.',
          subjectId: startStateId,
        ),
      );
    }

    final validTransitions = <WorkflowTransition>[];
    for (final transition in transitions) {
      final referencesKnownStates = stateIds.contains(transition.fromStateId) &&
          stateIds.contains(transition.toStateId);
      if (!referencesKnownStates) {
        issues.add(
          WorkflowValidationIssue(
            code: WorkflowValidationCode.unknownTransitionState,
            message:
                'Transition "${transition.id}" references an unknown state.',
            subjectId: transition.id,
          ),
        );
      } else {
        validTransitions.add(transition);
      }
      if (transition.permittedRoles.isEmpty) {
        issues.add(
          WorkflowValidationIssue(
            code: WorkflowValidationCode.transitionWithoutRole,
            message:
                'Transition "${transition.id}" must permit at least one role.',
            subjectId: transition.id,
          ),
        );
      }
      if (!transition.isAuditable) {
        issues.add(
          WorkflowValidationIssue(
            code: WorkflowValidationCode.unauditedTransition,
            message: 'Transition "${transition.id}" must be auditable.',
            subjectId: transition.id,
          ),
        );
      }
    }

    if (stateIds.contains(startStateId)) {
      final reachable = _reachableStates(startStateId, validTransitions);
      for (final stateDefinition in states) {
        if (stateDefinition.isRequired &&
            !reachable.contains(stateDefinition.id)) {
          issues.add(
            WorkflowValidationIssue(
              code: WorkflowValidationCode.unreachableRequiredState,
              message: 'Required state "${stateDefinition.id}" is unreachable.',
              subjectId: stateDefinition.id,
            ),
          );
        }
      }
    }

    final statesById = {
      for (final stateDefinition in states) stateDefinition.id: stateDefinition,
    };
    for (final transition in validTransitions) {
      final target = statesById[transition.toStateId];
      if (target != null &&
          target.requiresApprovalBeforeEntry &&
          (transition.approvalPolicyId?.trim().isEmpty ?? true)) {
        issues.add(
          WorkflowValidationIssue(
            code: WorkflowValidationCode.approvalBypass,
            message:
                'Transition "${transition.id}" bypasses mandatory approval.',
            subjectId: transition.id,
          ),
        );
      }
    }

    return WorkflowValidationResult(issues);
  }

  WorkflowVersion publish(DateTime publishedAt) {
    if (state != ItsmPublicationState.draft) {
      throw StateError('Only a draft workflow version can be published.');
    }
    final validation = validateForPublication();
    if (!validation.isValid) {
      throw WorkflowPublicationException(validation);
    }
    return _copyWith(
      state: ItsmPublicationState.published,
      publishedAt: publishedAt,
    );
  }

  WorkflowVersion retire() {
    if (state == ItsmPublicationState.draft) {
      throw StateError('A draft version cannot be retired.');
    }
    return _copyWith(state: ItsmPublicationState.retired);
  }

  WorkflowVersion _copyWith({
    required ItsmPublicationState state,
    DateTime? publishedAt,
  }) {
    return WorkflowVersion(
      version: version,
      state: state,
      startStateId: startStateId,
      states: states,
      transitions: transitions,
      createdAt: createdAt,
      createdBy: createdBy,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }
}

class WorkflowDefinition {
  WorkflowDefinition({
    required this.key,
    required this.module,
    required this.workItemType,
    required Iterable<WorkflowVersion> versions,
  }) : versions = List<WorkflowVersion>.unmodifiable(versions) {
    if (key.trim().isEmpty) {
      throw ArgumentError.value(key, 'key', 'A workflow key is required.');
    }
    final versionNumbers = <int>{};
    for (final workflowVersion in this.versions) {
      if (!versionNumbers.add(workflowVersion.version)) {
        throw ArgumentError(
          'Workflow version ${workflowVersion.version} is duplicated.',
        );
      }
    }
  }

  final String key;
  final String module;
  final ItsmWorkItemType workItemType;
  final List<WorkflowVersion> versions;

  WorkflowVersion? get publishedVersion {
    for (final version in versions.reversed) {
      if (version.state == ItsmPublicationState.published) return version;
    }
    return null;
  }

  WorkflowDefinition addDraftVersion(WorkflowVersion draft) {
    if (draft.state != ItsmPublicationState.draft) {
      throw ArgumentError('Only draft versions can be added.');
    }
    final expectedVersion = versions.isEmpty
        ? 1
        : versions
                .map((version) => version.version)
                .reduce((left, right) => left > right ? left : right) +
            1;
    if (draft.version != expectedVersion) {
      throw StateError('The next workflow version must be $expectedVersion.');
    }
    return WorkflowDefinition(
      key: key,
      module: module,
      workItemType: workItemType,
      versions: [...versions, draft],
    );
  }

  WorkflowDefinition publishVersion(int versionNumber, DateTime publishedAt) {
    final targetIndex =
        versions.indexWhere((version) => version.version == versionNumber);
    if (targetIndex < 0) {
      throw StateError('Workflow version $versionNumber does not exist.');
    }

    final published = versions[targetIndex].publish(publishedAt);
    final updatedVersions = <WorkflowVersion>[];
    for (var index = 0; index < versions.length; index++) {
      final current = versions[index];
      if (index == targetIndex) {
        updatedVersions.add(published);
      } else if (current.state == ItsmPublicationState.published) {
        updatedVersions.add(current.retire());
      } else {
        updatedVersions.add(current);
      }
    }
    return WorkflowDefinition(
      key: key,
      module: module,
      workItemType: workItemType,
      versions: updatedVersions,
    );
  }
}

class WorkflowPublicationException implements Exception {
  const WorkflowPublicationException(this.validation);

  final WorkflowValidationResult validation;

  @override
  String toString() {
    return 'WorkflowPublicationException('
        '${validation.issues.map((issue) => issue.message).join(', ')})';
  }
}

Set<String> _reachableStates(
  String startStateId,
  Iterable<WorkflowTransition> transitions,
) {
  final outgoing = <String, List<String>>{};
  for (final transition in transitions) {
    outgoing
        .putIfAbsent(transition.fromStateId, () => <String>[])
        .add(transition.toStateId);
  }

  final reachable = <String>{startStateId};
  final queue = Queue<String>()..add(startStateId);
  while (queue.isNotEmpty) {
    final current = queue.removeFirst();
    for (final next in outgoing[current] ?? const <String>[]) {
      if (reachable.add(next)) queue.add(next);
    }
  }
  return reachable;
}
