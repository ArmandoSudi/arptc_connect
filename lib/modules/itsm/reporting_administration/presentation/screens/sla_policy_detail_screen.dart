import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/domain/pagination.dart';
import '../../application/reporting_administration_providers.dart';
import '../../domain/configuration_common.dart';
import '../reporting_administration_strings.dart';
import '../widgets/configuration_widgets.dart';
import '../widgets/reporting_async_state.dart';
import '../widgets/reporting_page_shell.dart';

class SlaPolicyDetailScreen extends ConsumerStatefulWidget {
  const SlaPolicyDetailScreen(
      {required this.policyId, super.key, this.onEditVersion});
  final String policyId;
  final ValueChanged<String>? onEditVersion;

  @override
  ConsumerState<SlaPolicyDetailScreen> createState() =>
      _SlaPolicyDetailScreenState();
}

class _SlaPolicyDetailScreenState extends ConsumerState<SlaPolicyDetailScreen> {
  late final versionsRequest = ConfigurationVersionsPageRequest(
      parentId: widget.policyId, page: PageRequest());

  @override
  Widget build(BuildContext context) {
    final strings = ReportingAdministrationStrings.of(context);
    final policy = ref.watch(slaPolicyProvider(widget.policyId));
    final versions = ref.watch(slaPolicyVersionsProvider(versionsRequest));
    final access = ref.watch(reportingAdministrationAccessProvider).valueOrNull;
    return ReportingPageShell(
      title: policy.valueOrNull?.name ?? strings.value('sla'),
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
                    version: version.version,
                    state: version.state,
                    createdAt: version.createdAt,
                    createdBy: version.createdBy,
                    publishedAt: version.publishedAt,
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
