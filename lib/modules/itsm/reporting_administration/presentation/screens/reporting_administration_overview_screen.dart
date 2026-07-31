import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/reporting_administration_providers.dart';
import '../reporting_administration_strings.dart';
import '../widgets/reporting_async_state.dart';
import '../widgets/reporting_page_shell.dart';

enum ReportingAdministrationDestination {
  dashboards,
  sla,
  catalogue,
  workflows,
  audit
}

class ReportingAdministrationOverviewScreen extends ConsumerWidget {
  const ReportingAdministrationOverviewScreen({super.key, this.onOpen});
  final ValueChanged<ReportingAdministrationDestination>? onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ReportingAdministrationStrings.of(context);
    final access = ref.watch(reportingAdministrationAccessProvider);
    return ReportingPageShell(
      title: strings.value('title'),
      subtitle: strings.value('subtitle'),
      child: ReportingAsyncState(
        value: access,
        loadingLabel: strings.value('loading'),
        errorLabel: strings.value('error'),
        emptyLabel: strings.value('empty'),
        data: (access) {
          if (!access.canAccess) {
            return ReportingAccessDenied(
              title: strings.value('accessDenied'),
              description: strings.value('accessDeniedDescription'),
            );
          }
          final items =
              <(ReportingAdministrationDestination, IconData, String, String)>[
            (
              ReportingAdministrationDestination.dashboards,
              Icons.dashboard_customize_outlined,
              strings.value('dashboards'),
              strings.value('dashboardsDescription')
            ),
            (
              ReportingAdministrationDestination.sla,
              Icons.timer_outlined,
              strings.value('sla'),
              strings.value('slaDescription')
            ),
            (
              ReportingAdministrationDestination.catalogue,
              Icons.menu_book_outlined,
              strings.value('catalogue'),
              strings.value('catalogueDescription')
            ),
            (
              ReportingAdministrationDestination.workflows,
              Icons.account_tree_outlined,
              strings.value('workflows'),
              strings.value('workflowsDescription')
            ),
            (
              ReportingAdministrationDestination.audit,
              Icons.history_rounded,
              strings.value('audit'),
              strings.value('auditDescription')
            ),
          ];
          return LayoutBuilder(builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1050
                ? 3
                : constraints.maxWidth >= 650
                    ? 2
                    : 1;
            final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: items
                  .map((item) => SizedBox(
                        width: width,
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap:
                                onOpen == null ? null : () => onOpen!(item.$1),
                            child: Padding(
                              padding: const EdgeInsets.all(22),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(item.$2,
                                      size: 32,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                  const SizedBox(height: 18),
                                  Text(item.$3,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                              fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 6),
                                  Text(item.$4),
                                  if (access.isReadOnly) ...[
                                    const SizedBox(height: 14),
                                    Chip(
                                        avatar: const Icon(
                                            Icons.visibility_outlined,
                                            size: 16),
                                        label: Text(strings.value('readOnly'))),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ))
                  .toList(growable: false),
            );
          });
        },
      ),
    );
  }
}
