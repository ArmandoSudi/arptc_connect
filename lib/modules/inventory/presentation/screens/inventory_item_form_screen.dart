import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/inventory_contracts.dart';
import '../../application/inventory_providers.dart';
import '../../domain/inventory_domain.dart';
import '../widgets/inventory_shell.dart';

class InventoryItemFormScreen extends ConsumerStatefulWidget {
  const InventoryItemFormScreen({super.key, this.itemId});

  final String? itemId;

  @override
  ConsumerState<InventoryItemFormScreen> createState() =>
      _InventoryItemFormScreenState();
}

class _InventoryItemFormScreenState
    extends ConsumerState<InventoryItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sku = TextEditingController();
  final _name = TextEditingController();
  final _description = TextEditingController();
  String _categoryId = '';
  String _unitId = '';
  String _typeId = '';
  bool _requestable = true;
  bool _initialized = false;
  final List<_OpeningBalanceDraft> _openingBalances = [];

  bool get _editing => widget.itemId?.trim().isNotEmpty == true;

  @override
  void dispose() {
    _sku.dispose();
    _name.dispose();
    _description.dispose();
    for (final row in _openingBalances) {
      row.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final item =
        _editing ? ref.watch(inventoryItemProvider(widget.itemId!)) : null;
    final categories =
        ref.watch(inventoryParametersProvider(InventoryParameterType.category));
    final units = ref.watch(
        inventoryParametersProvider(InventoryParameterType.unitOfMeasure));
    final types =
        ref.watch(inventoryParametersProvider(InventoryParameterType.itemType));
    final locations = ref.watch(inventoryLocationsProvider(''));
    if (_editing && item!.isLoading) {
      return Scaffold(body: LoadingStateView(message: l10n.loading));
    }
    final existing = item?.valueOrNull;
    if (existing != null && !_initialized) {
      _initialized = true;
      _sku.text = existing.sku;
      _name.text = existing.name;
      _description.text = existing.description;
      _categoryId = existing.categoryId;
      _unitId = existing.unitOfMeasureId;
      _typeId = existing.itemTypeId;
      _requestable = existing.isRequestable;
    }
    return InventoryShell(
      title: l10n.lookup(_editing ? 'invEditItem' : 'invNewItem'),
      subtitle: l10n.lookup('invManagerSubtitle'),
      onBack: () => context.pop(),
      child: Form(
        key: _formKey,
        child: InventoryPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _twoColumns(
                CommonTextInput(
                  label: l10n.lookup('invSku'),
                  controller: _sku,
                  validator: _required,
                ),
                CommonTextInput(
                  label: l10n.lookup('invItemName'),
                  controller: _name,
                  validator: _required,
                ),
              ),
              const SizedBox(height: 16),
              CommonTextInput(
                label: l10n.description,
                controller: _description,
                isMultiline: true,
              ),
              const SizedBox(height: 16),
              _twoColumns(
                _parameterDropdown(
                  l10n.lookup('invCategory'),
                  _categoryId,
                  categories.valueOrNull ?? const [],
                  (value) => setState(() => _categoryId = value ?? ''),
                ),
                _parameterDropdown(
                  l10n.lookup('invUnitOfMeasure'),
                  _unitId,
                  units.valueOrNull ?? const [],
                  (value) => setState(() => _unitId = value ?? ''),
                ),
              ),
              const SizedBox(height: 16),
              _parameterDropdown(
                l10n.lookup('invItemType'),
                _typeId,
                types.valueOrNull ?? const [],
                (value) => setState(() => _typeId = value ?? ''),
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _requestable,
                title: Text(l10n.lookup('invRequestable')),
                onChanged: (value) => setState(() => _requestable = value),
              ),
              if (!_editing) ...[
                const Divider(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.lookup('invOpeningBalances'),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => setState(() {
                        _openingBalances.add(_OpeningBalanceDraft());
                      }),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(l10n.add),
                    ),
                  ],
                ),
                for (var index = 0;
                    index < _openingBalances.length;
                    index++) ...[
                  const SizedBox(height: 12),
                  _OpeningBalanceRow(
                    draft: _openingBalances[index],
                    locations: locations.valueOrNull ?? const [],
                    onRemove: () => setState(() {
                      _openingBalances.removeAt(index).dispose();
                    }),
                  ),
                ],
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed:
                    ref.watch(inventoryCommandControllerProvider).isLoading
                        ? null
                        : () => _save(
                              categories.valueOrNull ?? const [],
                              units.valueOrNull ?? const [],
                              types.valueOrNull ?? const [],
                            ),
                icon: const Icon(Icons.save_outlined),
                label: Text(l10n.lookup('invSaveItem')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _twoColumns(Widget first, Widget second) {
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth < 650
          ? Column(children: [first, const SizedBox(height: 16), second])
          : Row(children: [
              Expanded(child: first),
              const SizedBox(width: 16),
              Expanded(child: second)
            ]),
    );
  }

  Widget _parameterDropdown(
    String label,
    String value,
    List<InventoryParameter> values,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: values.any((entry) => entry.id == value) ? value : null,
      decoration: InputDecoration(labelText: label),
      validator: (value) => value == null || value.isEmpty
          ? S.of(context).lookup('invRequired')
          : null,
      items: [
        for (final entry in values.where((entry) => entry.isActive))
          DropdownMenuItem(value: entry.id, child: Text(entry.name)),
      ],
      onChanged: onChanged,
    );
  }

  String? _required(String? value) => value == null || value.trim().isEmpty
      ? S.of(context).lookup('invRequired')
      : null;

  Future<void> _save(
    List<InventoryParameter> categories,
    List<InventoryParameter> units,
    List<InventoryParameter> types,
  ) async {
    if (!_formKey.currentState!.validate()) return;
    try {
      final result =
          await ref.read(inventoryCommandControllerProvider.notifier).execute(
        functionName: InventoryCommands.saveItem,
        commandId: ref.read(inventoryCommandIdFactoryProvider)(),
        payload: {
          if (_editing) 'itemId': widget.itemId,
          'sku': _sku.text.trim(),
          'name': _name.text.trim(),
          'description': _description.text.trim(),
          'categoryId': _categoryId,
          'categoryName': _nameFor(categories, _categoryId),
          'unitOfMeasureId': _unitId,
          'unitOfMeasureName': _nameFor(units, _unitId),
          'itemTypeId': _typeId,
          'itemTypeName': _nameFor(types, _typeId),
          'isRequestable': _requestable,
          if (!_editing) 'isActive': true,
          if (!_editing)
            'openingBalances': [
              for (final row in _openingBalances)
                if (row.locationId.isNotEmpty)
                  {
                    'locationId': row.locationId,
                    'quantityMilli':
                        InventoryQuantity.parse(row.quantity.text).milliUnits,
                    'thresholdMilli': InventoryQuantity.parse(
                            row.threshold.text.isEmpty
                                ? '0'
                                : row.threshold.text)
                        .milliUnits,
                    'reason': 'Opening balance',
                  },
            ],
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).lookup('invItemSaved'))),
      );
      context.go('/service/inventory/items/${result.entityId}');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }
}

String _nameFor(List<InventoryParameter> values, String id) =>
    values.firstWhere((entry) => entry.id == id).name;

class _OpeningBalanceDraft {
  String locationId = '';
  final quantity = TextEditingController(text: '0');
  final threshold = TextEditingController(text: '0');

  void dispose() {
    quantity.dispose();
    threshold.dispose();
  }
}

class _OpeningBalanceRow extends StatefulWidget {
  const _OpeningBalanceRow({
    required this.draft,
    required this.locations,
    required this.onRemove,
  });

  final _OpeningBalanceDraft draft;
  final List<InventoryLocation> locations;
  final VoidCallback onRemove;

  @override
  State<_OpeningBalanceRow> createState() => _OpeningBalanceRowState();
}

class _OpeningBalanceRowState extends State<_OpeningBalanceRow> {
  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: widget.draft.locationId.isEmpty
                ? null
                : widget.draft.locationId,
            decoration: InputDecoration(labelText: l10n.lookup('invLocation')),
            items: [
              for (final location
                  in widget.locations.where((entry) => entry.isActive))
                DropdownMenuItem(
                  value: location.id,
                  child: Text('${location.warehouseName} / ${location.name}'),
                ),
            ],
            onChanged: (value) =>
                setState(() => widget.draft.locationId = value ?? ''),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CommonTextInput(
                  label: l10n.lookup('invQuantity'),
                  type: CommonTextInputType.decimal,
                  controller: widget.draft.quantity,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonTextInput(
                  label: l10n.lookup('invThreshold'),
                  type: CommonTextInputType.decimal,
                  controller: widget.draft.threshold,
                ),
              ),
              IconButton(
                onPressed: widget.onRemove,
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: l10n.delete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
