import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/domain/pagination.dart';
import '../../application/reporting_administration_providers.dart';
import '../../domain/configuration_common.dart';
import '../reporting_administration_strings.dart';
import '../widgets/configuration_widgets.dart';
import '../widgets/reporting_async_state.dart';
import '../widgets/reporting_page_shell.dart';

class WorkflowDefinitionDetailScreen extends ConsumerStatefulWidget {
  const WorkflowDefinitionDetailScreen(
      {required this.workflowId, super.key, this.onEditVersion});
  final String workflowId;
  final ValueChanged<String>? onEditVersion;

  @override
  ConsumerState<WorkflowDefinitionDetailScreen> createState() =>
      _WorkflowDefinitionDetailScreenState();
}

class _WorkflowDefinitionDetailScreenState
    extends ConsumerState<WorkflowDefinitionDetailScreen> {
  late final versionsRequest = ConfigurationVersionsPageRequest(
      parentId: widget.workflowId, page: PageRequest());

  @override
  Widget build(BuildContext context) {
    final strings = ReportingAdministrationStrings.of(context);
    final definition = ref.watch(workflowDefinitionProvider(widget.workflowId));
    final versions = ref.watch(workflowVersionsProvider(versionsRequest));
    final access = ref.watch(reportingAdministrationAccessProvider).valueOrNull;
    return ReportingPageShell(
      title: definition.valueOrNull?.name ?? strings.value('workflows'),
      subtitle: access?.isReadOnly == true
          ? strings.value('configurationReadOnly')
          : strings.value('immutable'),
      child: ReportingAsyncState(
        value: versions,
        loadingLabel: strings.value('loading'),
        errorLabel: strings.value('error'),
        emptyLabel: strings.value('empty'),
        isEmpty: (page) => page.isEmpty,
        data: (page) => VersionHistoryPanel(
          versions: page.items
              .map((version) => ConfigurationVersionSummary(
                    id: version.versionId,
                    version: version.workflow.version,
                    state: version.workflow.state,
                    createdAt: version.workflow.createdAt,
                    createdBy: version.workflow.createdBy,
                    publishedAt: version.workflow.publishedAt,
                  ))
              .toList(growable: false),
          onSelected: access?.canOperate == true && widget.onEditVersion != null
              ? (version) => widget.onEditVersion!(version.id)
              : null,
        ),
      ),
    );
  }
}
