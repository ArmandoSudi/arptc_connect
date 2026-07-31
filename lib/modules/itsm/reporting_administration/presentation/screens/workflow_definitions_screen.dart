import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/domain/pagination.dart';
import '../../application/reporting_administration_providers.dart';
import '../../data/workflow_definition_repository.dart';
import '../reporting_administration_strings.dart';
import '../widgets/configuration_widgets.dart';
import '../widgets/reporting_async_state.dart';
import '../widgets/reporting_page_shell.dart';

class WorkflowDefinitionsScreen extends ConsumerStatefulWidget {
  const WorkflowDefinitionsScreen(
      {super.key, this.onOpenWorkflow, this.onCreateDraft});
  final ValueChanged<String>? onOpenWorkflow;
  final VoidCallback? onCreateDraft;

  @override
  ConsumerState<WorkflowDefinitionsScreen> createState() =>
      _WorkflowDefinitionsScreenState();
}

class _WorkflowDefinitionsScreenState
    extends ConsumerState<WorkflowDefinitionsScreen> {
  late final request = WorkflowDefinitionsPageRequest(
      query: const WorkflowConfigurationQuery(), page: PageRequest());

  @override
  Widget build(BuildContext context) {
    final strings = ReportingAdministrationStrings.of(context);
    final access = ref.watch(reportingAdministrationAccessProvider).valueOrNull;
    final result = ref.watch(workflowDefinitionsPageProvider(request));
    return ReportingPageShell(
      title: strings.value('workflows'),
      subtitle: strings.value('workflowsDescription'),
      actions: [
        if (access?.canOperate == true)
          FilledButton.icon(
              onPressed: widget.onCreateDraft,
              icon: const Icon(Icons.add),
              label: Text(strings.value('createDraft'))),
        if (access?.isReadOnly == true)
          Chip(label: Text(strings.value('readOnly'))),
      ],
      child: ReportingAsyncState(
        value: result,
        loadingLabel: strings.value('loading'),
        errorLabel: strings.value('error'),
        emptyLabel: strings.value('empty'),
        isEmpty: (page) => page.isEmpty,
        onRetry: () => ref.invalidate(workflowDefinitionsPageProvider(request)),
        data: (page) => ConfigurationList(
          children: page.items
              .map((workflow) => ListTile(
                    onTap: widget.onOpenWorkflow == null
                        ? null
                        : () => widget.onOpenWorkflow!(workflow.id),
                    leading: const Icon(Icons.account_tree_outlined),
                    title: Text(workflow.name),
                    subtitle: Text(
                        '${workflow.module} • ${workflow.workItemType.value} • v${workflow.latestVersion}'),
                    trailing: ConfigurationStatusBadge(workflow.status),
                  ))
              .toList(growable: false),
        ),
      ),
    );
  }
}
