import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/widgets/app_search_bar.dart';
import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/inventory_contracts.dart';
import '../../application/inventory_providers.dart';
import '../../application/inventory_request_draft_controller.dart';
import '../../domain/inventory_domain.dart';
import '../widgets/inventory_shell.dart';
import '../widgets/inventory_status_badge.dart';

class UserInventoryHomeScreen extends ConsumerStatefulWidget {
  const UserInventoryHomeScreen({super.key});

  @override
  ConsumerState<UserInventoryHomeScreen> createState() =>
      _UserInventoryHomeScreenState();
}

class _UserInventoryHomeScreenState
    extends ConsumerState<UserInventoryHomeScreen> {
  String _search = '';
  String _categoryId = '';

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final session = ref.watch(inventorySessionProvider).valueOrNull;
    final query = InventoryCatalogueQuery(
      search: _search,
      categoryId: _categoryId,
    );
    final catalogue = ref.watch(inventoryCatalogueProvider(query));
    final catalogueForCategories = ref.watch(
      inventoryCatalogueProvider(InventoryCatalogueQuery(search: _search)),
    );
    final draft = session == null
        ? const InventoryRequestDraft()
        : ref.watch(inventoryRequestDraftProvider(session.sessionKey));
    return InventoryShell(
      title: l10n.lookup('invCatalogue'),
      subtitle: l10n.lookup('invCatalogueSubtitle'),
      actions: [
        OutlinedButton.icon(
          onPressed: () => context.go('/service/inventory/requests/mine'),
          icon: const Icon(Icons.receipt_long_outlined),
          label: Text(l10n.lookup('invMyRequests')),
        ),
        FilledButton.icon(
          onPressed: draft.lines.isEmpty
              ? null
              : () => context.go('/service/inventory/requests/new'),
          icon: Badge(
            isLabelVisible: draft.lines.isNotEmpty,
            label: Text(draft.lines.length.toString()),
            child: const Icon(Icons.shopping_basket_outlined),
          ),
          label: Text(l10n.lookup('invRequestCart')),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSearchBar(
            hintText: l10n.lookup('invSearchItems'),
            onChanged: (value) => setState(() => _search = value),
          ),
          const SizedBox(height: 16),
          catalogue.when(
            loading: () => LoadingStateView(message: l10n.loading),
            error: (error, _) => ErrorStateView(
              title: l10n.unableToLoad,
              description: error.toString(),
              onRetry: () => ref.invalidate(inventoryCatalogueProvider(query)),
            ),
            data: (items) {
              final categories = <String, String>{
                for (final item
                    in catalogueForCategories.valueOrNull ??
                        const <InventoryCatalogueItem>[])
                  if (item.categoryId.isNotEmpty)
                    item.categoryId: item.categoryName,
              };
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (categories.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      value: categories.containsKey(_categoryId)
                          ? _categoryId
                          : '',
                      decoration: InputDecoration(
                        labelText: l10n.lookup('invCategory'),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: '',
                          child: Text(l10n.lookup('invAllCategories')),
                        ),
                        for (final entry in categories.entries)
                          DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                      ],
                      onChanged: (value) => setState(() {
                        _categoryId = value ?? '';
                      }),
                    ),
                    const SizedBox(height: 18),
                  ],
                  if (items.isEmpty)
                    EmptyStateView(
                      icon: Icons.inventory_2_outlined,
                      title: l10n.lookup('invNoItems'),
                    )
                  else
                    InventoryResponsiveGrid(
                      minItemWidth: 280,
                      maxColumns: 3,
                      children: [
                        for (final item in items)
                          _CatalogueCard(
                            item: item,
                            currentQuantity: _quantityFor(draft, item.id),
                            onAdd: session == null
                                ? null
                                : () => _setQuantity(session.sessionKey, item),
                          ),
                      ],
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  InventoryQuantity? _quantityFor(InventoryRequestDraft draft, String itemId) {
    for (final line in draft.lines) {
      if (line.item.id == itemId) return line.quantity;
    }
    return null;
  }

  Future<void> _setQuantity(
    String sessionKey,
    InventoryCatalogueItem item,
  ) async {
    final quantity = await showDialog<InventoryQuantity>(
      context: context,
      builder: (context) => _QuantityDialog(item: item),
    );
    if (quantity == null) return;
    ref
        .read(inventoryRequestDraftProvider(sessionKey).notifier)
        .setQuantity(item, quantity);
  }
}

class _CatalogueCard extends StatelessWidget {
  const _CatalogueCard({
    required this.item,
    required this.currentQuantity,
    required this.onAdd,
  });

  final InventoryCatalogueItem item;
  final InventoryQuantity? currentQuantity;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final theme = Theme.of(context);
    return InventoryPanel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 8,
            color: switch (item.availability) {
              InventoryAvailability.available => Colors.green,
              InventoryAvailability.limited => Colors.orange,
              InventoryAvailability.unavailable => theme.colorScheme.error,
            },
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InventoryAvailabilityBadge(item.availability),
                const SizedBox(height: 16),
                Text(
                  item.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.sku}  |  ${item.categoryName}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    item.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (item.availability == InventoryAvailability.unavailable) ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.lookup('invUnavailableWarning'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add_shopping_cart_rounded),
                    label: Text(currentQuantity == null
                        ? l10n.lookup('invAddToRequest')
                        : '${l10n.lookup('invQuantity')}: ${currentQuantity!.format()} ${item.unitOfMeasureName}'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityDialog extends StatefulWidget {
  const _QuantityDialog({required this.item});

  final InventoryCatalogueItem item;

  @override
  State<_QuantityDialog> createState() => _QuantityDialogState();
}

class _QuantityDialogState extends State<_QuantityDialog> {
  final _controller = TextEditingController(text: '1');
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return AlertDialog(
      title: Text(widget.item.name),
      content: SizedBox(
        width: 420,
        child: CommonTextInput(
          label:
              '${l10n.lookup('invQuantity')} (${widget.item.unitOfMeasureName})',
          type: CommonTextInputType.decimal,
          controller: _controller,
          decoration: InputDecoration(errorText: _error),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            try {
              final quantity = InventoryQuantity.parse(_controller.text);
              if (!quantity.isPositive) throw const FormatException();
              Navigator.pop(context, quantity);
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
