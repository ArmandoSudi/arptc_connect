import 'package:flutter/material.dart';

import '../../domain/workflow_configuration.dart';
import '../widgets/configuration_widgets.dart';
import '../widgets/reporting_page_shell.dart';
import '../reporting_administration_strings.dart';

class WorkflowEditorScreen extends StatelessWidget {
  const WorkflowEditorScreen({
    required this.version,
    required this.readOnly,
    super.key,
    this.onSave,
    this.onValidate,
    this.onPublish,
  });

  final WorkflowVersionConfiguration version;
  final bool readOnly;
  final VoidCallback? onSave;
  final VoidCallback? onValidate;
  final VoidCallback? onPublish;

  @override
  Widget build(BuildContext context) {
    final strings = ReportingAdministrationStrings.of(context);
    final immutable = version.isImmutable;
    final validation = version.validateForPublication();
    return ReportingPageShell(
      title: 'Workflow ${version.workflowId} v${version.workflow.version}',
      subtitle: readOnly || immutable
          ? strings.value('immutable')
          : strings.value('editDraft'),
      actions: [
        if (!readOnly && !immutable)
          OutlinedButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.save_outlined),
              label: Text(strings.value('saveDraft'))),
        if (!readOnly && !immutable)
          OutlinedButton.icon(
              onPressed: onValidate,
              icon: const Icon(Icons.fact_check_outlined),
              label: Text(strings.value('validate'))),
        if (!readOnly && !immutable && validation.isValid)
          FilledButton.icon(
              onPressed: onPublish,
              icon: const Icon(Icons.publish_outlined),
              label: Text(strings.value('publish'))),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ReportingPanel(
            title: strings.value('statesTransitions'),
            child: LayoutBuilder(builder: (context, constraints) {
              final stateCards = version.workflow.states.map((state) => Card(
                    color: state.id == version.workflow.startStateId
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(state.label,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text(state.id),
                            if (state.isTerminal)
                              Chip(label: Text(strings.value('terminal'))),
                          ]),
                    ),
                  ));
              return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: stateCards.toList(growable: false));
            }),
          ),
          const SizedBox(height: 16),
          ReportingPanel(
            title: strings.value('transitions'),
            child: Column(
                children: version.workflow.transitions
                    .map((transition) => ListTile(
                          leading: const Icon(Icons.arrow_forward_rounded),
                          title: Text(
                              '${transition.fromStateId} → ${transition.toStateId}'),
                          subtitle: Text(transition.permittedRoles
                              .map((role) => role.value)
                              .join(', ')),
                          trailing: transition.approvalPolicyId == null
                              ? null
                              : const Icon(Icons.approval_outlined),
                        ))
                    .toList(growable: false)),
          ),
          const SizedBox(height: 16),
          WorkflowValidationPanel(issues: validation.issues),
        ],
      ),
    );
  }
}
