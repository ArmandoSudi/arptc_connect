import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_enums.dart';
import 'package:arptc_connect/modules/incident_management/presentation/controllers/incident_providers.dart';
import 'package:arptc_connect/modules/incident_management/presentation/screens/incident_dashboard_router.dart';
import 'package:arptc_connect/modules/incident_management/presentation/screens/user_incident_home_screen.dart';
import 'package:arptc_connect/widgets/content_view.dart';
import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class IncidentRoleGateScreen extends ConsumerWidget {
  const IncidentRoleGateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(currentUserIncidentRoleProvider);
    final l10n = S.of(context);

    return roleAsync.when(
      data: (role) {
        switch (role) {
          case IncidentRole.user:
            return const UserIncidentHomeScreen();
          case IncidentRole.manager:
          case IncidentRole.admin:
            return const IncidentDashboardRouter();
          case IncidentRole.none:
            return ContentView(
              child: EmptyStateView(
                icon: Icons.lock_outline,
                title: l10n.incidentAccessUnavailable,
                description: l10n.incidentAccessUnavailableDescription,
              ),
            );
        }
      },
      loading: () => ContentView(
        child: LoadingStateView(message: l10n.loadingIncidentAccess),
      ),
      error: (error, _) => ContentView(
        child: ErrorStateView(
          title: l10n.unableToLoadIncidentAccess,
          description: error.toString(),
          onRetry: () => ref.invalidate(currentUserIncidentRoleProvider),
        ),
      ),
    );
  }
}
