import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/widgets/app_search_bar.dart';
import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/inventory_contracts.dart';
import '../../application/inventory_providers.dart';
import '../../domain/inventory_domain.dart';
import '../widgets/inventory_shell.dart';

class InventoryItemsScreen extends ConsumerStatefulWidget {
  const InventoryItemsScreen({super.key});

  @override
  ConsumerState<InventoryItemsScreen> createState() =>
      _InventoryItemsScreenState();
}

class _InventoryItemsScreenState extends ConsumerState<InventoryItemsScreen> {
  String _search = '';
  String _categoryId = '';

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final policy = ref.watch(inventoryAccessPolicyProvider);
    final query = InventoryItemQuery(
      search: _search,
      categoryId: _categoryId,
      limit: 100,
    );
    final items = ref.watch(inventoryItemsProvider(query));
    final balances = ref.watch(inventoryBalancesProvider(''));
    final categories = ref.watch(
      inventoryParametersProvider(InventoryParameterType.category),
    );
    return InventoryShell(
      title: l10n.lookup('invItemRegister'),
      subtitle: policy.isReadOnlyAdmin
          ? l10n.lookup('invReadOnly')
          : l10n.lookup('invManagerSubtitle'),
      onBack: () => context.pop(),
      actions: [
        OutlinedButton.icon(
          onPressed: () => context.go('/service/inventory/movements'),
          icon: const Icon(Icons.swap_vert_rounded),
          label: Text(l10n.lookup('invStockMovements')),
        ),
        if (policy.canManageParameters)
          OutlinedButton.icon(
            onPressed: () => context.go('/service/inventory/parameters'),
            icon: const Icon(Icons.tune_rounded),
            label: Text(l10n.lookup('invParameters')),
          ),
        if (policy.canManageInventory)
          FilledButton.icon(
            onPressed: () => context.go('/service/inventory/items/new'),
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.lookup('invNewItem')),
          ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final search = AppSearchBar(
                hintText: l10n.lookup('invSearchItems'),
                onChanged: (value) => setState(() => _search = value),
              );
              final filter = DropdownButtonFormField<String>(
                value: _categoryId,
                decoration: InputDecoration(
                  labelText: l10n.lookup('invCategory'),
                ),
                items: [
                  DropdownMenuItem(
                    value: '',
                    child: Text(l10n.lookup('invAllCategories')),
                  ),
                  for (final category
                      in categories.valueOrNull ?? const <InventoryParameter>[])
                    DropdownMenuItem(
                      value: category.id,
                      child: Text(category.name),
                    ),
                ],
                onChanged: (value) => setState(() => _categoryId = value ?? ''),
              );
              if (constraints.maxWidth < 700) {
                return Column(
                    children: [search, const SizedBox(height: 12), filter]);
              }
              return Row(children: [
                Expanded(child: search),
                const SizedBox(width: 16),
                SizedBox(width: 260, child: filter),
              ]);
            },
          ),
          const SizedBox(height: 18),
          items.when(
            loading: () => LoadingStateView(message: l10n.loading),
            error: (error, _) => ErrorStateView(
              title: l10n.unableToLoad,
              description: error.toString(),
              onRetry: () => ref.invalidate(inventoryItemsProvider(query)),
            ),
            data: (entries) {
              if (entries.isEmpty) {
                return EmptyStateView(
                  icon: Icons.inventory_2_outlined,
                  title: l10n.lookup('invNoItems'),
                );
              }
              final allBalances =
                  balances.valueOrNull ?? const <InventoryBalance>[];
              return InventoryPanel(
                padding: EdgeInsets.zero,
                child: LayoutBuilder(
                  builder: (context, constraints) => constraints.maxWidth < 820
                      ? _ItemCards(items: entries, balances: allBalances)
                      : _ItemTable(items: entries, balances: allBalances),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ItemTable extends StatelessWidget {
  const _ItemTable({required this.items, required this.balances});

  final List<InventoryItem> items;
  final List<InventoryBalance> balances;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        showCheckboxColumn: false,
        columns: [
          DataColumn(label: Text(l10n.lookup('invSku'))),
          DataColumn(label: Text(l10n.lookup('invItemName'))),
          DataColumn(label: Text(l10n.lookup('invCategory'))),
          DataColumn(label: Text(l10n.lookup('invOnHand')), numeric: true),
          DataColumn(label: Text(l10n.lookup('invReserved')), numeric: true),
          DataColumn(
              label: Text(l10n.lookup('invAvailableStock')), numeric: true),
          DataColumn(label: Text(l10n.status)),
        ],
        rows: [
          for (final item in items)
            _row(context, item,
                balances.where((balance) => balance.itemId == item.id)),
        ],
      ),
    );
  }

  DataRow _row(
    BuildContext context,
    InventoryItem item,
    Iterable<InventoryBalance> values,
  ) {
    final onHand = _sum(values.map((balance) => balance.onHand));
    final reserved = _sum(values.map((balance) => balance.reserved));
    final available = onHand - reserved;
    return DataRow(
      onSelectChanged: (_) => context.go('/service/inventory/items/${item.id}'),
      cells: [
        DataCell(Text(item.sku)),
        DataCell(Text(item.name)),
        DataCell(Text(item.categoryName)),
        DataCell(Text(onHand.format())),
        DataCell(Text(reserved.format())),
        DataCell(Text(available.format())),
        DataCell(Icon(
          item.isActive
              ? Icons.check_circle_rounded
              : Icons.pause_circle_outline,
          color: item.isActive
              ? Colors.green
              : Theme.of(context).colorScheme.outline,
        )),
      ],
    );
  }
}

class _ItemCards extends StatelessWidget {
  const _ItemCards({required this.items, required this.balances});

  final List<InventoryItem> items;
  final List<InventoryBalance> balances;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return Column(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            leading: CircleAvatar(
              child: Icon(items[index].isActive
                  ? Icons.inventory_2_outlined
                  : Icons.pause_rounded),
            ),
            title: Text(items[index].name),
            subtitle:
                Text('${items[index].sku}  |  ${items[index].categoryName}'),
            trailing: Text(
              '${l10n.lookup('invAvailableStock')}: ${_available(items[index].id).format()}',
            ),
            onTap: () =>
                context.go('/service/inventory/items/${items[index].id}'),
          ),
          if (index != items.length - 1) const Divider(height: 1),
        ],
      ],
    );
  }

  InventoryQuantity _available(String itemId) {
    final values = balances.where((balance) => balance.itemId == itemId);
    return _sum(values.map((balance) => balance.available));
  }
}

InventoryQuantity _sum(Iterable<InventoryQuantity> values) => values.fold(
      InventoryQuantity.zero,
      (total, value) => total + value,
    );
