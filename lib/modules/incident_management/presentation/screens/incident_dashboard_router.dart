import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_enums.dart';
import 'package:arptc_connect/modules/incident_management/presentation/controllers/incident_providers.dart';
import 'package:arptc_connect/modules/incident_management/presentation/screens/admin_incident_dashboard_screen.dart';
import 'package:arptc_connect/modules/incident_management/presentation/screens/manager_incident_dashboard_screen.dart';
import 'package:arptc_connect/widgets/content_view.dart';
import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class IncidentDashboardRouter extends ConsumerWidget {
  const IncidentDashboardRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(currentUserIncidentRoleProvider);
    final l10n = S.of(context);

    return roleAsync.when(
      data: (role) {
        switch (role) {
          case IncidentRole.manager:
            return const ManagerIncidentDashboardScreen();
          case IncidentRole.admin:
            return const AdminIncidentDashboardScreen();
          case IncidentRole.user:
          case IncidentRole.none:
            return ContentView(
              child: EmptyStateView(
                icon: Icons.lock_outline,
                title: l10n.noIncidentDashboardAccess,
              ),
            );
        }
      },
      loading: () => ContentView(
        child: LoadingStateView(message: l10n.loadingIncidentDashboardAccess),
      ),
      error: (error, _) => ContentView(
        child: ErrorStateView(
          title: l10n.unableToLoadIncidentDashboardAccess,
          description: error.toString(),
          onRetry: () => ref.invalidate(currentUserIncidentRoleProvider),
        ),
      ),
    );
  }
}
