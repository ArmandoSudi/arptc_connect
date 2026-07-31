import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/reporting_administration_providers.dart';
import '../../domain/dashboard_snapshot.dart';
import '../reporting_administration_strings.dart';
import '../widgets/reporting_async_state.dart';
import '../widgets/reporting_dashboard_layout.dart';
import '../widgets/reporting_page_shell.dart';

class AdminItsmDashboardScreen extends ConsumerWidget {
  const AdminItsmDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ReportingAdministrationStrings.of(context);
    final snapshot =
        ref.watch(currentReportSnapshotProvider(ReportSnapshotType.executive));
    return ReportingPageShell(
      title: strings.value('executiveDashboard'),
      subtitle: strings.value('dashboardsDescription'),
      actions: [
        Chip(
            avatar: const Icon(Icons.visibility_outlined),
            label: Text(strings.value('readOnly')))
      ],
      child: ReportingAsyncState<ItsmReportSnapshot?>(
        value: snapshot,
        loadingLabel: strings.value('loading'),
        errorLabel: strings.value('error'),
        emptyLabel: strings.value('empty'),
        isEmpty: (value) => value == null,
        onRetry: () => ref.invalidate(
            currentReportSnapshotProvider(ReportSnapshotType.executive)),
        data: (value) => ReportingDashboardLayout(snapshot: value!),
      ),
    );
  }
}
