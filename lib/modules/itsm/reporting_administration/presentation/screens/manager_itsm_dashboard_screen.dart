import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/reporting_administration_providers.dart';
import '../../domain/dashboard_snapshot.dart';
import '../reporting_administration_strings.dart';
import '../widgets/reporting_async_state.dart';
import '../widgets/reporting_dashboard_layout.dart';
import '../widgets/reporting_page_shell.dart';

class ManagerItsmDashboardScreen extends ConsumerWidget {
  const ManagerItsmDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ReportingAdministrationStrings.of(context);
    final snapshot = ref
        .watch(currentReportSnapshotProvider(ReportSnapshotType.operational));
    return ReportingPageShell(
      title: strings.value('operationalDashboard'),
      subtitle: strings.value('dashboardsDescription'),
      child: ReportingAsyncState<ItsmReportSnapshot?>(
        value: snapshot,
        loadingLabel: strings.value('loading'),
        errorLabel: strings.value('error'),
        emptyLabel: strings.value('empty'),
        isEmpty: (value) => value == null,
        onRetry: () => ref.invalidate(
            currentReportSnapshotProvider(ReportSnapshotType.operational)),
        data: (value) => ReportingDashboardLayout(snapshot: value!),
      ),
    );
  }
}
