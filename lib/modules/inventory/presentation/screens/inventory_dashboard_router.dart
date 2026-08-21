import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/inventory_providers.dart';
import '../../domain/inventory_access.dart';
import 'admin_inventory_dashboard_screen.dart';
import 'manager_inventory_dashboard_screen.dart';
import 'user_inventory_home_screen.dart';

class InventoryDashboardRouter extends ConsumerWidget {
  const InventoryDashboardRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(inventorySessionProvider);
    return session.when(
      loading: () => LoadingStateView(message: S.of(context).loading),
      error: (_, __) => const InventoryAccessDeniedScreen(),
      data: (current) => switch (current.role) {
        InventoryRole.user => const UserInventoryHomeScreen(),
        InventoryRole.manager => const ManagerInventoryDashboardScreen(),
        InventoryRole.admin => const AdminInventoryDashboardScreen(),
        InventoryRole.none => const InventoryAccessDeniedScreen(),
      },
    );
  }
}

class InventoryAccessDeniedScreen extends StatelessWidget {
  const InventoryAccessDeniedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: EmptyStateView(
        icon: Icons.lock_outline_rounded,
        title: S.of(context).lookup('invNoAccess'),
      ),
    );
  }
}
