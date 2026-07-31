import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_enums.dart';
import 'package:arptc_connect/modules/incident_management/presentation/controllers/incident_providers.dart';
import 'package:arptc_connect/modules/itsm/presentation/navigation/itsm_navigation.dart';
import 'package:arptc_connect/modules/itsm/presentation/navigation/itsm_route_access.dart';
import 'package:arptc_connect/modules/itsm/presentation/widgets/itsm_access_state.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_common.dart';
import 'package:arptc_connect/widgets/content_view.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ItsmRouteGuard extends ConsumerWidget {
  const ItsmRouteGuard({
    required this.child,
    this.section,
    this.feature,
    this.requirement = ItsmRouteRequirement.automatic,
    super.key,
  });

  final Widget child;
  final ItsmSection? section;
  final ItsmFeature? feature;
  final ItsmRouteRequirement requirement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(currentUserIncidentRoleProvider);
    final l10n = S.of(context);

    return roleAsync.when(
      data: (incidentRole) {
        final role = _toItsmRole(incidentRole);
        final allowed = role != null &&
            ItsmRouteAccessPolicy.canAccess(
              role: role,
              section: section,
              feature: feature,
              requirement: requirement,
            );
        if (allowed) {
          return child;
        }

        return ItsmAccessState(
          title: l10n.itsmAccessDeniedTitle,
          description: l10n.itsmAccessDeniedDescription,
          backLabel: l10n.itsmLandingTitle,
          backRoute: ItsmRoutes.root,
          icon: Icons.lock_outline_rounded,
        );
      },
      loading: () => ContentView(
        child: LoadingStateView(message: l10n.itsmLoadingAccess),
      ),
      error: (error, _) => ContentView(
        child: ErrorStateView(
          title: l10n.itsmUnableToLoadAccess,
          description: error.toString(),
          onRetry: () => ref.invalidate(currentUserIncidentRoleProvider),
        ),
      ),
    );
  }
}

ItsmRole? _toItsmRole(IncidentRole role) {
  switch (role) {
    case IncidentRole.user:
      return ItsmRole.user;
    case IncidentRole.manager:
      return ItsmRole.manager;
    case IncidentRole.admin:
      return ItsmRole.admin;
    case IncidentRole.none:
      return null;
  }
}
