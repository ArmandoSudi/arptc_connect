import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/domain/pagination.dart';
import '../../application/reporting_administration_providers.dart';
import '../../data/sla_policy_repository.dart';
import '../reporting_administration_strings.dart';
import '../widgets/configuration_widgets.dart';
import '../widgets/reporting_async_state.dart';
import '../widgets/reporting_page_shell.dart';

class SlaPoliciesScreen extends ConsumerStatefulWidget {
  const SlaPoliciesScreen({super.key, this.onOpenPolicy, this.onCreateDraft});
  final ValueChanged<String>? onOpenPolicy;
  final VoidCallback? onCreateDraft;

  @override
  ConsumerState<SlaPoliciesScreen> createState() => _SlaPoliciesScreenState();
}

class _SlaPoliciesScreenState extends ConsumerState<SlaPoliciesScreen> {
  late final request = SlaPoliciesPageRequest(
      query: const SlaPolicyQuery(), page: PageRequest());

  @override
  Widget build(BuildContext context) {
    final strings = ReportingAdministrationStrings.of(context);
    final access = ref.watch(reportingAdministrationAccessProvider).valueOrNull;
    final result = ref.watch(slaPoliciesPageProvider(request));
    return ReportingPageShell(
      title: strings.value('sla'),
      subtitle: strings.value('slaDescription'),
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
        onRetry: () => ref.invalidate(slaPoliciesPageProvider(request)),
        data: (page) => ConfigurationList(
          children: page.items
              .map((policy) => ListTile(
                    onTap: widget.onOpenPolicy == null
                        ? null
                        : () => widget.onOpenPolicy!(policy.id),
                    leading: const Icon(Icons.timer_outlined),
                    title: Text(policy.name),
                    subtitle: Text(
                        '${policy.workItemType.value} • v${policy.latestVersion}'),
                    trailing: ConfigurationStatusBadge(policy.status),
                  ))
              .toList(growable: false),
        ),
      ),
    );
  }
}
