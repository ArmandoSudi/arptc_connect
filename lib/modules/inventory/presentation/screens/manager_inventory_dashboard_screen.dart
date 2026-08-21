import 'package:arptc_connect/core/theme.dart';
import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/widgets/corporate_components.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/inventory_contracts.dart';
import '../../application/inventory_providers.dart';
import '../../domain/inventory_domain.dart';
import '../widgets/inventory_bar_chart.dart';
import '../widgets/inventory_shell.dart';

class ManagerInventoryDashboardScreen extends ConsumerWidget {
  const ManagerInventoryDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);
    final stats = ref.watch(inventoryDashboardProvider);
    final oldest =
        ref.watch(materialRequestsProvider(const InventoryRequestQuery(
      statuses: [
        MaterialRequestStatus.submitted,
        MaterialRequestStatus.underReview,
        MaterialRequestStatus.adjusted,
        MaterialRequestStatus.readyForIssue,
        MaterialRequestStatus.partiallyFulfilled,
      ],
      limit: 10,
    )));
    final movements = ref.watch(inventoryMovementsProvider(
      const InventoryMovementQuery(limit: 10),
    ));
    return InventoryShell(
      title: l10n.lookup('invDashboard'),
      subtitle: l10n.lookup('invManagerSubtitle'),
      actions: [
        OutlinedButton.icon(
          onPressed: () => context.go('/service/inventory/requests/history'),
          icon: const Icon(Icons.history_rounded),
          label: Text(l10n.lookup('invRequestHistory')),
        ),
        OutlinedButton.icon(
          onPressed: () => context.go('/service/inventory/parameters'),
          icon: const Icon(Icons.tune_rounded),
          label: Text(l10n.lookup('invParameters')),
        ),
        OutlinedButton.icon(
          onPressed: () => context.go('/service/inventory/items'),
          icon: const Icon(Icons.inventory_2_outlined),
          label: Text(l10n.lookup('invItemRegister')),
        ),
        FilledButton.icon(
          onPressed: () => context.go('/service/inventory/catalog'),
          icon: const Icon(Icons.add_rounded),
          label: Text(l10n.lookup('invRequestItems')),
        ),
      ],
      child: stats.when(
        loading: () => LoadingStateView(message: l10n.loading),
        error: (error, _) => ErrorStateView(
          title: l10n.unableToLoad,
          description: error.toString(),
          onRetry: () => ref.invalidate(inventoryDashboardProvider),
        ),
        data: (value) => _DashboardContent(
          stats: value,
          oldest: oldest.valueOrNull ?? const [],
          movements: movements.valueOrNull ?? const [],
          readOnly: false,
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.stats,
    required this.oldest,
    required this.movements,
    required this.readOnly,
    super.key,
  });

  final InventoryDashboardStats stats;
  final List<MaterialRequest> oldest;
  final List<InventoryStockMovement> movements;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final tokens = context.corporateTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (readOnly)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                avatar: const Icon(Icons.visibility_outlined, size: 18),
                label: Text(l10n.lookup('invReadOnly')),
              ),
            ),
          ),
        InventoryResponsiveGrid(
          minItemWidth: 210,
          maxColumns: 4,
          children: [
            _kpi(
                context,
                l10n.lookup('invSubmittedRequests'),
                stats.submittedCount,
                Icons.send_rounded,
                scheme.primary,
                'submitted'),
            _kpi(
                context,
                l10n.lookup('invUnderReviewRequests'),
                stats.underReviewCount,
                Icons.manage_search_rounded,
                const Color(0xFF4F46E5),
                'under_review'),
            _kpi(
                context,
                l10n.lookup('invReadyRequests'),
                stats.readyForIssueCount,
                Icons.inventory_2_outlined,
                const Color(0xFF0891B2),
                'ready_for_issue'),
            _kpi(
                context,
                l10n.lookup('invPartialRequests'),
                stats.partiallyFulfilledCount,
                Icons.pending_actions_rounded,
                const Color(0xFF0F766E),
                'partially_fulfilled'),
            CorporateKpiCard(
              title: l10n.lookup('invLowStockItems'),
              value: stats.lowStockCount.toString(),
              icon: Icons.warning_amber_rounded,
              accentColor: tokens.warning,
              onTap: () => context.go('/service/inventory/items'),
            ),
            CorporateKpiCard(
              title: l10n.lookup('invOutOfStockItems'),
              value: stats.outOfStockCount.toString(),
              icon: Icons.production_quantity_limits_rounded,
              accentColor: scheme.error,
              onTap: () => context.go('/service/inventory/items'),
            ),
            CorporateKpiCard(
              title: l10n.lookup('invFulfilledToday'),
              value: stats.fulfilledTodayCount.toString(),
              icon: Icons.task_alt_rounded,
              accentColor: tokens.success,
            ),
            CorporateKpiCard(
              title: l10n.lookup('invAverageFulfillment'),
              value: _duration(stats.averageFulfillmentMinutes),
              icon: Icons.timer_outlined,
              accentColor: scheme.secondary,
            ),
          ],
        ),
        const SizedBox(height: 18),
        InventoryResponsiveGrid(
          minItemWidth: 390,
          maxColumns: 2,
          children: [
            InventoryBarChart(
              title: l10n.lookup('invRequestsByStatus'),
              data: stats.requestsByStatus,
            ),
            InventoryBarChart(
              title: l10n.lookup('invLowStockByWarehouse'),
              data: stats.lowStockByWarehouse,
            ),
            InventoryBarChart(
              title: l10n.lookup('invTopRequestedItems'),
              data: stats.topRequestedItems,
            ),
            InventoryBarChart(
              title: l10n.lookup('invConsumptionByDepartment'),
              data: stats.consumptionByDepartment,
            ),
            InventoryBarChart(
              title: l10n.lookup('invIssuesVsReceipts'),
              data: stats.issuesVsReceipts,
            ),
            InventoryBarChart(
              title: l10n.lookup('invMonthlyFulfillmentTrend'),
              data: stats.monthlyFulfillmentTrend,
            ),
          ],
        ),
        const SizedBox(height: 18),
        InventoryResponsiveGrid(
          minItemWidth: 440,
          maxColumns: 2,
          children: [
            InventoryPanel(
              title: l10n.lookup('invOldestPending'),
              child: oldest.isEmpty
                  ? Text(l10n.lookup('invNoRequests'))
                  : Column(
                      children: [
                        for (final request in oldest.take(8))
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(request.requestNumber),
                            subtitle: Text(request.requestedFor.name),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => context.go(
                              '/service/inventory/requests/${request.id}',
                            ),
                          ),
                      ],
                    ),
            ),
            InventoryPanel(
              title: l10n.lookup('invRecentMovements'),
              child: movements.isEmpty
                  ? Text(l10n.lookup('invNoMovements'))
                  : Column(
                      children: [
                        for (final movement in movements.take(8))
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(
                              child: Icon(Icons.swap_vert_rounded),
                            ),
                            title: Text(movement.itemName),
                            subtitle: Text(movement.locationName),
                            trailing: Text(movement.quantity.format()),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _kpi(
    BuildContext context,
    String title,
    int value,
    IconData icon,
    Color color,
    String status,
  ) {
    return CorporateKpiCard(
      title: title,
      value: value.toString(),
      icon: icon,
      accentColor: color,
      onTap: readOnly
          ? null
          : () =>
              context.go('/service/inventory/requests/queue?status=$status'),
    );
  }
}

String _duration(num minutes) {
  if (minutes < 60) return '${minutes.round()} min';
  if (minutes < 1440) return '${(minutes / 60).toStringAsFixed(1)} h';
  return '${(minutes / 1440).toStringAsFixed(1)} d';
}

class InventoryDashboardContent extends _DashboardContent {
  const InventoryDashboardContent({
    required super.stats,
    required super.oldest,
    required super.movements,
    required super.readOnly,
    super.key,
  });
}
