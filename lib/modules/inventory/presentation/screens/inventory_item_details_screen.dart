import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../application/inventory_contracts.dart';
import '../../application/inventory_providers.dart';
import '../../domain/inventory_domain.dart';
import '../widgets/inventory_shell.dart';
import '../widgets/inventory_reason_field.dart';

class InventoryItemDetailsScreen extends ConsumerWidget {
  const InventoryItemDetailsScreen({required this.itemId, super.key});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);
    final item = ref.watch(inventoryItemProvider(itemId));
    final balances = ref.watch(inventoryBalancesProvider(itemId));
    final movements = ref.watch(inventoryMovementsProvider(
      InventoryMovementQuery(itemId: itemId),
    ));
    final policy = ref.watch(inventoryAccessPolicyProvider);
    final movementReasons = ref
            .watch(inventoryParametersProvider(
              InventoryParameterType.movementReason,
            ))
            .valueOrNull ??
        const <InventoryParameter>[];
    final adjustmentReasons = ref
            .watch(inventoryParametersProvider(
              InventoryParameterType.adjustmentReason,
            ))
            .valueOrNull ??
        const <InventoryParameter>[];
    return item.when(
      loading: () => Scaffold(body: LoadingStateView(message: l10n.loading)),
      error: (error, _) => Scaffold(
        body: ErrorStateView(
          title: l10n.unableToLoad,
          description: error.toString(),
        ),
      ),
      data: (value) {
        if (value == null) {
          return Scaffold(
            body: EmptyStateView(
              icon: Icons.inventory_2_outlined,
              title: l10n.notAvailable,
            ),
          );
        }
        return InventoryShell(
          title: value.name,
          subtitle: '${value.sku}  |  ${value.categoryName}',
          onBack: () => context.pop(),
          actions: [
            if (policy.canManageInventory)
              OutlinedButton.icon(
                onPressed: () => context.go(
                  '/service/inventory/items/${value.id}/edit',
                ),
                icon: const Icon(Icons.edit_outlined),
                label: Text(l10n.edit),
              ),
            if (policy.canManageInventory)
              OutlinedButton.icon(
                onPressed: () => _toggleActive(context, ref, value),
                icon: Icon(value.isActive
                    ? Icons.pause_circle_outline
                    : Icons.play_circle_outline),
                label: Text(value.isActive ? l10n.disabled : l10n.enabled),
              ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InventoryPanel(
                child: Wrap(
                  spacing: 36,
                  runSpacing: 18,
                  children: [
                    _Fact(
                        label: l10n.lookup('invCategory'),
                        value: value.categoryName),
                    _Fact(
                        label: l10n.lookup('invUnitOfMeasure'),
                        value: value.unitOfMeasureName),
                    _Fact(
                        label: l10n.lookup('invItemType'),
                        value: value.itemTypeName),
                    _Fact(
                        label: l10n.status,
                        value: value.isActive ? l10n.active : l10n.inactive),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              InventoryPanel(
                title: l10n.lookup('invWarehouseBalances'),
                trailing: policy.canExecuteStockOperations &&
                        (balances.valueOrNull?.length ?? 0) > 1
                    ? TextButton.icon(
                        onPressed: () => _transfer(
                          context,
                          ref,
                          balances.valueOrNull ?? const [],
                          movementReasons,
                        ),
                        icon: const Icon(Icons.swap_horiz_rounded),
                        label: Text(l10n.lookup('invTransferStock')),
                      )
                    : null,
                child: balances.when(
                  loading: () => LoadingStateView(message: l10n.loading),
                  error: (error, _) => Text(error.toString()),
                  data: (entries) => entries.isEmpty
                      ? Text(l10n.noDataAvailable)
                      : InventoryResponsiveGrid(
                          minItemWidth: 300,
                          maxColumns: 3,
                          children: [
                            for (final balance in entries)
                              _BalanceCard(
                                balance: balance,
                                canOperate: policy.canExecuteStockOperations,
                                onOperation: (operation) => _operate(
                                  context,
                                  ref,
                                  balance,
                                  operation,
                                  operation == _StockOperation.adjust ||
                                          operation == _StockOperation.reconcile
                                      ? adjustmentReasons
                                      : movementReasons,
                                ),
                              ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 18),
              InventoryPanel(
                title: l10n.lookup('invStockMovements'),
                child: movements.when(
                  loading: () => LoadingStateView(message: l10n.loading),
                  error: (error, _) => Text(error.toString()),
                  data: (entries) => entries.isEmpty
                      ? Text(l10n.lookup('invNoMovements'))
                      : Column(
                          children: [
                            for (final movement in entries.take(20))
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const CircleAvatar(
                                  child: Icon(Icons.swap_vert_rounded),
                                ),
                                title: Text(_movementLabel(movement.type)),
                                subtitle: Text(
                                  '${movement.locationName}  |  ${movement.actor.name}\n${movement.reason}',
                                ),
                                isThreeLine: movement.reason.isNotEmpty,
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      movement.quantity.format(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w900),
                                    ),
                                    Text(_date(movement.createdAt)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _toggleActive(
    BuildContext context,
    WidgetRef ref,
    InventoryItem item,
  ) async {
    try {
      await ref.read(inventoryCommandControllerProvider.notifier).execute(
        functionName: InventoryCommands.setItemActive,
        commandId: ref.read(inventoryCommandIdFactoryProvider)(),
        payload: {'itemId': item.id, 'isActive': !item.isActive},
      );
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }

  Future<void> _operate(
    BuildContext context,
    WidgetRef ref,
    InventoryBalance balance,
    _StockOperation operation,
    List<InventoryParameter> reasons,
  ) async {
    final input = await showDialog<_StockOperationInput>(
      context: context,
      builder: (context) => _StockOperationDialog(
        operation: operation,
        balance: balance,
        reasons: reasons,
      ),
    );
    if (input == null) return;
    final functionName = switch (operation) {
      _StockOperation.receipt => InventoryCommands.receiveStock,
      _StockOperation.returnToStock => InventoryCommands.returnStock,
      _StockOperation.adjust => InventoryCommands.adjustStock,
      _StockOperation.reconcile => InventoryCommands.reconcileStock,
      _StockOperation.threshold => InventoryCommands.setBalanceThreshold,
    };
    try {
      await ref.read(inventoryCommandControllerProvider.notifier).execute(
        functionName: functionName,
        commandId: ref.read(inventoryCommandIdFactoryProvider)(),
        payload: {
          'balanceId': balance.id,
          if (operation == _StockOperation.reconcile)
            'targetOnHandMilli': input.quantity.milliUnits
          else if (operation == _StockOperation.threshold)
            'thresholdMilli': input.quantity.milliUnits
          else
            'quantityMilli': input.quantity.milliUnits,
          'reason': input.reason,
          'reference': input.reference,
        },
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).lookup('invActionCompleted'))),
        );
      }
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }

  Future<void> _transfer(
    BuildContext context,
    WidgetRef ref,
    List<InventoryBalance> balances,
    List<InventoryParameter> reasons,
  ) async {
    final input = await showDialog<_TransferInput>(
      context: context,
      builder: (context) => _TransferDialog(
        balances: balances,
        reasons: reasons,
      ),
    );
    if (input == null) return;
    try {
      await ref.read(inventoryCommandControllerProvider.notifier).execute(
        functionName: InventoryCommands.transferStock,
        commandId: ref.read(inventoryCommandIdFactoryProvider)(),
        payload: {
          'sourceBalanceId': input.sourceId,
          'destinationBalanceId': input.destinationId,
          'quantityMilli': input.quantity.milliUnits,
          'reason': input.reason,
        },
      );
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.balance,
    required this.canOperate,
    required this.onOperation,
  });

  final InventoryBalance balance;
  final bool canOperate;
  final ValueChanged<_StockOperation> onOperation;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final theme = Theme.of(context);
    final danger = balance.isOutOfStock || balance.isLowStock;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: danger
            ? theme.colorScheme.errorContainer.withOpacity(0.3)
            : theme.colorScheme.primaryContainer.withOpacity(0.25),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${balance.warehouseName} / ${balance.locationName}',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              if (canOperate)
                PopupMenuButton<_StockOperation>(
                  onSelected: onOperation,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                        value: _StockOperation.receipt,
                        child: Text(l10n.lookup('invReceiveStock'))),
                    PopupMenuItem(
                        value: _StockOperation.returnToStock,
                        child: Text(l10n.lookup('invReturnStock'))),
                    PopupMenuItem(
                        value: _StockOperation.adjust,
                        child: Text(l10n.lookup('invAdjustStock'))),
                    PopupMenuItem(
                        value: _StockOperation.reconcile,
                        child: Text(l10n.lookup('invReconcileStock'))),
                    PopupMenuItem(
                        value: _StockOperation.threshold,
                        child: Text(l10n.lookup('invThreshold'))),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 14),
          _quantity(context, l10n.lookup('invOnHand'), balance.onHand),
          _quantity(context, l10n.lookup('invReserved'), balance.reserved),
          _quantity(
              context, l10n.lookup('invAvailableStock'), balance.available),
          _quantity(context, l10n.lookup('invThreshold'), balance.threshold),
        ],
      ),
    );
  }

  Widget _quantity(
      BuildContext context, String label, InventoryQuantity value) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value.format(),
              style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

enum _StockOperation { receipt, returnToStock, adjust, reconcile, threshold }

class _StockOperationInput {
  const _StockOperationInput(this.quantity, this.reason, this.reference);
  final InventoryQuantity quantity;
  final String reason;
  final String reference;
}

class _StockOperationDialog extends StatefulWidget {
  const _StockOperationDialog({
    required this.operation,
    required this.balance,
    required this.reasons,
  });
  final _StockOperation operation;
  final InventoryBalance balance;
  final List<InventoryParameter> reasons;

  @override
  State<_StockOperationDialog> createState() => _StockOperationDialogState();
}

class _StockOperationDialogState extends State<_StockOperationDialog> {
  final _quantity = TextEditingController();
  final _reason = TextEditingController();
  final _reference = TextEditingController();
  String _selectedReason = '';
  String? _error;

  @override
  void dispose() {
    _quantity.dispose();
    _reason.dispose();
    _reference.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final title = switch (widget.operation) {
      _StockOperation.receipt => l10n.lookup('invReceiveStock'),
      _StockOperation.returnToStock => l10n.lookup('invReturnStock'),
      _StockOperation.adjust => l10n.lookup('invAdjustStock'),
      _StockOperation.reconcile => l10n.lookup('invReconcileStock'),
      _StockOperation.threshold => l10n.lookup('invThreshold'),
    };
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            children: [
              CommonTextInput(
                label: widget.operation == _StockOperation.reconcile
                    ? l10n.lookup('invOnHand')
                    : widget.operation == _StockOperation.threshold
                        ? l10n.lookup('invThreshold')
                        : l10n.lookup('invQuantity'),
                type: CommonTextInputType.decimal,
                controller: _quantity,
                decoration: InputDecoration(errorText: _error),
              ),
              const SizedBox(height: 14),
              InventoryReasonField(
                options: widget.reasons,
                controller: _reason,
                selectedReason: _selectedReason,
                onSelected: (value) => setState(() => _selectedReason = value),
              ),
              const SizedBox(height: 14),
              CommonTextInput(
                  label: l10n.lookup('invReference'), controller: _reference),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(
          onPressed: () {
            try {
              final quantity = InventoryQuantity.parse(_quantity.text);
              final allowZero = widget.operation == _StockOperation.reconcile ||
                  widget.operation == _StockOperation.threshold;
              if (!allowZero && !quantity.isPositive) {
                throw const FormatException();
              }
              if (widget.operation == _StockOperation.adjust &&
                  quantity.isZero) {
                throw const FormatException();
              }
              if (widget.operation == _StockOperation.receipt &&
                  _reference.text.trim().isEmpty) {
                setState(() => _error = l10n.lookup('invReferenceRequired'));
                return;
              }
              final reason = _selectedReason.isNotEmpty
                  ? _selectedReason
                  : _reason.text.trim();
              if ({
                    _StockOperation.returnToStock,
                    _StockOperation.adjust,
                    _StockOperation.reconcile,
                  }.contains(widget.operation) &&
                  reason.isEmpty) {
                setState(() => _error = l10n.lookup('invSelectReason'));
                return;
              }
              Navigator.pop(
                context,
                _StockOperationInput(quantity, reason, _reference.text.trim()),
              );
            } on FormatException {
              setState(() => _error = l10n.lookup('invPositiveQuantity'));
            }
          },
          child: Text(l10n.confirm),
        ),
      ],
    );
  }
}

class _TransferInput {
  const _TransferInput(
      this.sourceId, this.destinationId, this.quantity, this.reason);
  final String sourceId;
  final String destinationId;
  final InventoryQuantity quantity;
  final String reason;
}

class _TransferDialog extends StatefulWidget {
  const _TransferDialog({required this.balances, required this.reasons});
  final List<InventoryBalance> balances;
  final List<InventoryParameter> reasons;

  @override
  State<_TransferDialog> createState() => _TransferDialogState();
}

class _TransferDialogState extends State<_TransferDialog> {
  String _source = '';
  String _destination = '';
  final _quantity = TextEditingController();
  final _reason = TextEditingController();
  String _selectedReason = '';

  @override
  void dispose() {
    _quantity.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return AlertDialog(
      title: Text(l10n.lookup('invTransferStock')),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _balanceDropdown(l10n.lookup('invWarehouse'), _source,
                (value) => setState(() => _source = value ?? '')),
            const SizedBox(height: 12),
            _balanceDropdown(
                l10n.lookup('invDeliveryDestination'),
                _destination,
                (value) => setState(() => _destination = value ?? '')),
            const SizedBox(height: 12),
            CommonTextInput(
                label: l10n.lookup('invQuantity'),
                type: CommonTextInputType.decimal,
                controller: _quantity),
            const SizedBox(height: 12),
            InventoryReasonField(
              options: widget.reasons,
              controller: _reason,
              selectedReason: _selectedReason,
              onSelected: (value) => setState(() => _selectedReason = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(
          onPressed: () {
            try {
              if (_source.isEmpty ||
                  _destination.isEmpty ||
                  _source == _destination) {
                throw const FormatException();
              }
              final quantity = InventoryQuantity.parse(_quantity.text);
              if (!quantity.isPositive) throw const FormatException();
              final reason = _selectedReason.isNotEmpty
                  ? _selectedReason
                  : _reason.text.trim();
              if (reason.isEmpty) throw const FormatException();
              Navigator.pop(context,
                  _TransferInput(_source, _destination, quantity, reason));
            } on FormatException {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.lookup('invPositiveQuantity'))),
              );
            }
          },
          child: Text(l10n.confirm),
        ),
      ],
    );
  }

  Widget _balanceDropdown(
      String label, String value, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value.isEmpty ? null : value,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final balance in widget.balances)
          DropdownMenuItem(
            value: balance.id,
            child: Text('${balance.warehouseName} / ${balance.locationName}'),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

void _showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(error.toString())),
  );
}

String _movementLabel(InventoryMovementType type) =>
    type.value.replaceAll('_', ' ');
String _date(DateTime? value) =>
    value == null ? '-' : DateFormat.yMMMd().add_Hm().format(value.toLocal());
