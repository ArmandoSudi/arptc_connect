import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../application/inventory_contracts.dart';
import '../../application/inventory_providers.dart';
import '../widgets/inventory_shell.dart';

class InventoryMovementsScreen extends ConsumerWidget {
  const InventoryMovementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);
    final movements = ref.watch(inventoryMovementsProvider(
      const InventoryMovementQuery(limit: 100),
    ));
    return InventoryShell(
      title: l10n.lookup('invStockMovements'),
      subtitle: l10n.lookup('invManagerSubtitle'),
      onBack: () => context.pop(),
      child: movements.when(
        loading: () => LoadingStateView(message: l10n.loading),
        error: (error, _) => ErrorStateView(
          title: l10n.unableToLoad,
          description: error.toString(),
        ),
        data: (entries) => entries.isEmpty
            ? EmptyStateView(
                icon: Icons.swap_vert_rounded,
                title: l10n.lookup('invNoMovements'),
              )
            : InventoryPanel(
                padding: EdgeInsets.zero,
                child: LayoutBuilder(
                  builder: (context, constraints) => constraints.maxWidth < 820
                      ? Column(
                          children: [
                            for (final movement in entries)
                              ListTile(
                                title: Text(movement.itemName),
                                subtitle: Text(
                                  '${movement.type.value.replaceAll('_', ' ')}  |  ${movement.locationName}',
                                ),
                                trailing: Text(movement.quantity.format()),
                              ),
                          ],
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: [
                              DataColumn(
                                  label: Text(l10n.lookup('invReference'))),
                              DataColumn(
                                  label: Text(l10n.lookup('invItemName'))),
                              DataColumn(label: Text(l10n.type)),
                              DataColumn(
                                  label: Text(l10n.lookup('invLocation'))),
                              DataColumn(
                                  label: Text(l10n.lookup('invQuantity'))),
                              DataColumn(label: Text(l10n.createdBy)),
                              DataColumn(label: Text(l10n.createdAt)),
                            ],
                            rows: [
                              for (final movement in entries)
                                DataRow(cells: [
                                  DataCell(Text(movement.movementNumber)),
                                  DataCell(Text(movement.itemName)),
                                  DataCell(Text(movement.type.value
                                      .replaceAll('_', ' '))),
                                  DataCell(Text(
                                      '${movement.warehouseName} / ${movement.locationName}')),
                                  DataCell(Text(movement.quantity.format())),
                                  DataCell(Text(movement.actor.name)),
                                  DataCell(Text(_date(movement.createdAt))),
                                ]),
                            ],
                          ),
                        ),
                ),
              ),
      ),
    );
  }
}

String _date(DateTime? value) =>
    value == null ? '-' : DateFormat.yMMMd().add_Hm().format(value.toLocal());
