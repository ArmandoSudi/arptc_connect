import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/inventory_contracts.dart';
import '../../application/inventory_providers.dart';
import '../../domain/inventory_domain.dart';
import '../widgets/inventory_shell.dart';
import 'manager_inventory_dashboard_screen.dart';

class AdminInventoryDashboardScreen extends ConsumerWidget {
  const AdminInventoryDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);
    final stats = ref.watch(inventoryDashboardProvider);
    final requests = ref.watch(
        materialRequestsProvider(const InventoryRequestQuery(limit: 10)));
    final movements = ref.watch(inventoryMovementsProvider(
      const InventoryMovementQuery(limit: 10),
    ));
    return InventoryShell(
      title: l10n.lookup('invDashboard'),
      subtitle: l10n.lookup('invAdminSubtitle'),
      actions: [
        OutlinedButton.icon(
          onPressed: () => context.go('/service/inventory/catalog'),
          icon: const Icon(Icons.storefront_outlined),
          label: Text(l10n.lookup('invCatalogue')),
        ),
        OutlinedButton.icon(
          onPressed: () => context.go('/service/inventory/items'),
          icon: const Icon(Icons.inventory_2_outlined),
          label: Text(l10n.lookup('invItemRegister')),
        ),
        OutlinedButton.icon(
          onPressed: () => context.go('/service/inventory/requests/history'),
          icon: const Icon(Icons.history_rounded),
          label: Text(l10n.lookup('invRequestHistory')),
        ),
        OutlinedButton.icon(
          onPressed: () => context.go('/service/inventory/audit'),
          icon: const Icon(Icons.policy_outlined),
          label: Text(l10n.lookup('invAuditHistory')),
        ),
      ],
      child: stats.when(
        loading: () => LoadingStateView(message: l10n.loading),
        error: (error, _) => ErrorStateView(
          title: l10n.unableToLoad,
          description: error.toString(),
          onRetry: () => ref.invalidate(inventoryDashboardProvider),
        ),
        data: (value) => InventoryDashboardContent(
          stats: value,
          oldest: requests.valueOrNull ?? const <MaterialRequest>[],
          movements: movements.valueOrNull ?? const <InventoryStockMovement>[],
          readOnly: true,
        ),
      ),
    );
  }
}
