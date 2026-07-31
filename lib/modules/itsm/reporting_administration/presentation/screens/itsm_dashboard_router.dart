import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/domain/itsm_common.dart';
import '../../application/reporting_administration_providers.dart';
import '../reporting_administration_strings.dart';
import '../widgets/reporting_async_state.dart';
import 'admin_itsm_dashboard_screen.dart';
import 'manager_itsm_dashboard_screen.dart';

class ItsmDashboardRouter extends ConsumerWidget {
  const ItsmDashboardRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ReportingAdministrationStrings.of(context);
    return ref.watch(reportingAdministrationAccessProvider).when(
          loading: () => Center(child: Text(strings.value('loading'))),
          error: (_, __) => Center(child: Text(strings.value('error'))),
          data: (access) => switch (access.role) {
            ItsmRole.manager => const ManagerItsmDashboardScreen(),
            ItsmRole.admin => const AdminItsmDashboardScreen(),
            _ => ReportingAccessDenied(
                title: strings.value('accessDenied'),
                description: strings.value('accessDeniedDescription'),
              ),
          },
        );
  }
}
