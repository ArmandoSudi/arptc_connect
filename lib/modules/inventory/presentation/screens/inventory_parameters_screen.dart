import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/inventory_contracts.dart';
import '../../application/inventory_providers.dart';
import '../../domain/inventory_domain.dart';
import '../widgets/inventory_shell.dart';

class InventoryParametersScreen extends ConsumerWidget {
  const InventoryParametersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);
    final policy = ref.watch(inventoryAccessPolicyProvider);
    if (!policy.canManageParameters) {
      return Scaffold(
        body: EmptyStateView(
          icon: Icons.lock_outline_rounded,
          title: l10n.lookup('invNoAccess'),
        ),
      );
    }
    final tabHeight = (MediaQuery.sizeOf(context).height - 220)
        .clamp(520.0, 760.0)
        .toDouble();
    return DefaultTabController(
      length: 6,
      child: InventoryShell(
        title: l10n.lookup('invParameters'),
        subtitle: l10n.lookup('invManagerSubtitle'),
        onBack: () => context.pop(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: l10n.lookup('invConfigureWarehouses')),
                Tab(text: l10n.lookup('invConfigureLocations')),
                Tab(text: l10n.lookup('invConfigureCategories')),
                Tab(text: l10n.lookup('invConfigureUnits')),
                Tab(text: l10n.lookup('invConfigureItemTypes')),
                Tab(text: l10n.lookup('invConfigureReasons')),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: tabHeight,
              child: const TabBarView(
                children: [
                  _WarehouseTab(),
                  _LocationTab(),
                  _ParameterTab(type: InventoryParameterType.category),
                  _ParameterTab(
                    type: InventoryParameterType.unitOfMeasure,
                  ),
                  _ParameterTab(type: InventoryParameterType.itemType),
                  _ReasonTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarehouseTab extends ConsumerWidget {
  const _WarehouseTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);
    final values = ref.watch(inventoryWarehousesProvider(false));
    return _ParameterPanel(
      title: l10n.lookup('invConfigureWarehouses'),
      onAdd: () => _editWarehouse(context, ref),
      child: values.when(
        loading: () => LoadingStateView(message: l10n.loading),
        error: (error, _) => _ParameterLoadError(
          error: error,
          onRetry: () => ref.invalidate(inventoryWarehousesProvider),
        ),
        data: (entries) => _ConfigurationList(
          entries: [
            for (final entry in entries)
              _ConfigRow(
                title: entry.name,
                subtitle: '${entry.code}  |  ${entry.address}',
                isActive: entry.isActive,
                onEdit: () => _editWarehouse(context, ref, entry),
                onToggle: () =>
                    _saveWarehouse(context, ref, entry, !entry.isActive),
              ),
          ],
        ),
      ),
    );
  }
}

class _LocationTab extends ConsumerWidget {
  const _LocationTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);
    final values = ref.watch(inventoryLocationsProvider(''));
    final warehouses = ref.watch(inventoryWarehousesProvider(true));
    return _ParameterPanel(
      title: l10n.lookup('invConfigureLocations'),
      onAdd: () => _editLocation(
        context,
        ref,
        warehouses.valueOrNull ?? const [],
      ),
      child: values.when(
        loading: () => LoadingStateView(message: l10n.loading),
        error: (error, _) => _ParameterLoadError(
          error: error,
          onRetry: () => ref.invalidate(inventoryLocationsProvider),
        ),
        data: (entries) => _ConfigurationList(
          entries: [
            for (final entry in entries)
              _ConfigRow(
                title: entry.name,
                subtitle: '${entry.warehouseName}  |  ${entry.code}',
                isActive: entry.isActive,
                onEdit: () => _editLocation(
                  context,
                  ref,
                  warehouses.valueOrNull ?? const [],
                  entry,
                ),
                onToggle: () =>
                    _saveLocation(context, ref, entry, !entry.isActive),
              ),
          ],
        ),
      ),
    );
  }
}

class _ParameterTab extends ConsumerWidget {
  const _ParameterTab({required this.type});
  final InventoryParameterType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);
    final values = ref.watch(inventoryParametersProvider(type));
    return _ParameterPanel(
      title: _typeLabel(context, type),
      onAdd: () => _editParameter(context, ref, type),
      child: values.when(
        loading: () => LoadingStateView(message: l10n.loading),
        error: (error, _) => _ParameterLoadError(
          error: error,
          onRetry: () => ref.invalidate(inventoryParametersProvider),
        ),
        data: (entries) => _ConfigurationList(
          entries: [
            for (final entry in entries)
              _ConfigRow(
                title: entry.name,
                isActive: entry.isActive,
                onEdit: () => _editParameter(context, ref, type, entry),
                onToggle: () =>
                    _saveParameter(context, ref, entry, !entry.isActive),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReasonTab extends ConsumerStatefulWidget {
  const _ReasonTab();

  @override
  ConsumerState<_ReasonTab> createState() => _ReasonTabState();
}

class _ReasonTabState extends ConsumerState<_ReasonTab> {
  InventoryParameterType _type = InventoryParameterType.movementReason;

  @override
  Widget build(BuildContext context) {
    final reasonTypes = [
      InventoryParameterType.movementReason,
      InventoryParameterType.adjustmentReason,
      InventoryParameterType.rejectionReason,
      InventoryParameterType.shortfallReason,
    ];
    return Column(
      children: [
        DropdownButtonFormField<InventoryParameterType>(
          value: _type,
          decoration: InputDecoration(
            labelText: S.of(context).lookup('invConfigureReasons'),
          ),
          items: [
            for (final type in reasonTypes)
              DropdownMenuItem(
                  value: type, child: Text(_typeLabel(context, type))),
          ],
          onChanged: (value) => setState(() => _type = value ?? _type),
        ),
        const SizedBox(height: 16),
        Expanded(child: _ParameterTab(type: _type)),
      ],
    );
  }
}

class _ParameterPanel extends StatelessWidget {
  const _ParameterPanel(
      {required this.title, required this.onAdd, required this.child});
  final String title;
  final VoidCallback onAdd;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InventoryPanel(
      title: title,
      expandChild: true,
      trailing: FilledButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add_rounded),
        label: Text(S.of(context).lookup('invAddParameter')),
      ),
      child: child,
    );
  }
}

class _ConfigurationList extends StatelessWidget {
  const _ConfigurationList({required this.entries});
  final List<Widget> entries;

  @override
  Widget build(BuildContext context) {
    return entries.isEmpty
        ? EmptyStateView(
            icon: Icons.tune_rounded,
            title: S.of(context).lookup('invNoParameters'),
          )
        : ListView.separated(
            itemCount: entries.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, index) => entries[index],
          );
  }
}

class _ParameterLoadError extends StatelessWidget {
  const _ParameterLoadError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_outlined,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 8),
          Text(l10n.errorLoadingData),
          const SizedBox(height: 4),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n.retry),
          ),
        ],
      ),
    );
  }
}

class _ConfigRow extends StatelessWidget {
  const _ConfigRow({
    required this.title,
    required this.isActive,
    required this.onEdit,
    required this.onToggle,
    this.subtitle,
  });
  final String title;
  final String? subtitle;
  final bool isActive;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      leading: Icon(
        isActive ? Icons.check_circle_rounded : Icons.pause_circle_outline,
        color: isActive ? Colors.green : Theme.of(context).colorScheme.outline,
      ),
      trailing: Wrap(
        children: [
          IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
          IconButton(
            onPressed: onToggle,
            icon:
                Icon(isActive ? Icons.pause_rounded : Icons.play_arrow_rounded),
          ),
        ],
      ),
    );
  }
}

Future<void> _editWarehouse(
  BuildContext context,
  WidgetRef ref, [
  InventoryWarehouse? warehouse,
]) async {
  final value = await showDialog<_NamedConfigInput>(
    context: context,
    builder: (context) => _NamedConfigDialog(
      title: S.of(context).lookup('invConfigureWarehouses'),
      code: warehouse?.code ?? '',
      name: warehouse?.name ?? '',
      extra: warehouse?.address ?? '',
      extraLabel: S.of(context).address,
    ),
  );
  if (value == null) return;
  if (!context.mounted) return;
  await _execute(context, ref, InventoryCommands.saveWarehouse, {
    if (warehouse != null) 'id': warehouse.id,
    'code': value.code,
    'name': value.name,
    'address': value.extra,
    'isActive': warehouse?.isActive ?? true,
  });
}

Future<void> _saveWarehouse(
  BuildContext context,
  WidgetRef ref,
  InventoryWarehouse value,
  bool isActive,
) =>
    _execute(context, ref, InventoryCommands.saveWarehouse, {
      'id': value.id,
      'code': value.code,
      'name': value.name,
      'address': value.address,
      'isActive': isActive,
    });

Future<void> _editLocation(
  BuildContext context,
  WidgetRef ref,
  List<InventoryWarehouse> warehouses, [
  InventoryLocation? location,
]) async {
  final value = await showDialog<_LocationInput>(
    context: context,
    builder: (context) => _LocationDialog(
      warehouses: warehouses,
      location: location,
    ),
  );
  if (value == null) return;
  if (!context.mounted) return;
  await _execute(context, ref, InventoryCommands.saveLocation, {
    if (location != null) 'id': location.id,
    'warehouseId': value.warehouseId,
    'code': value.code,
    'name': value.name,
    'isActive': location?.isActive ?? true,
  });
}

Future<void> _saveLocation(
  BuildContext context,
  WidgetRef ref,
  InventoryLocation value,
  bool isActive,
) =>
    _execute(context, ref, InventoryCommands.saveLocation, {
      'id': value.id,
      'warehouseId': value.warehouseId,
      'code': value.code,
      'name': value.name,
      'isActive': isActive,
    });

Future<void> _editParameter(
  BuildContext context,
  WidgetRef ref,
  InventoryParameterType type, [
  InventoryParameter? parameter,
]) async {
  final value = await showDialog<_NamedConfigInput>(
    context: context,
    builder: (context) => _NamedConfigDialog(
      title: _typeLabel(context, type),
      name: parameter?.name ?? '',
    ),
  );
  if (value == null) return;
  if (!context.mounted) return;
  await _execute(context, ref, InventoryCommands.saveParameter, {
    if (parameter != null) 'id': parameter.id,
    'type': type.value,
    'name': value.name,
    'isActive': parameter?.isActive ?? true,
  });
}

Future<void> _saveParameter(
  BuildContext context,
  WidgetRef ref,
  InventoryParameter value,
  bool isActive,
) =>
    _execute(context, ref, InventoryCommands.saveParameter, {
      'id': value.id,
      'type': value.type.value,
      'name': value.name,
      'isActive': isActive,
    });

Future<void> _execute(
  BuildContext context,
  WidgetRef ref,
  String functionName,
  Map<String, Object?> payload,
) async {
  try {
    await ref.read(inventoryCommandControllerProvider.notifier).execute(
          functionName: functionName,
          commandId: ref.read(inventoryCommandIdFactoryProvider)(),
          payload: payload,
        );
    switch (functionName) {
      case InventoryCommands.saveWarehouse:
        ref.invalidate(inventoryWarehousesProvider);
      case InventoryCommands.saveLocation:
        ref.invalidate(inventoryLocationsProvider);
      case InventoryCommands.saveParameter:
        ref.invalidate(inventoryParametersProvider);
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.of(context).lookup('invParameterSaved'))),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString())),
    );
  }
}

class _NamedConfigInput {
  const _NamedConfigInput(this.code, this.name, this.extra);
  final String code;
  final String name;
  final String extra;
}

class _NamedConfigDialog extends StatefulWidget {
  const _NamedConfigDialog({
    required this.title,
    required this.name,
    this.code = '',
    this.extra = '',
    this.extraLabel = '',
  });
  final String title;
  final String code;
  final String name;
  final String extra;
  final String extraLabel;

  @override
  State<_NamedConfigDialog> createState() => _NamedConfigDialogState();
}

class _NamedConfigDialogState extends State<_NamedConfigDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _code;
  late final TextEditingController _name;
  late final TextEditingController _extra;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController(text: widget.code);
    _name = TextEditingController(text: widget.name);
    _extra = TextEditingController(text: widget.extra);
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _extra.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 520),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.code.isNotEmpty || widget.extraLabel.isNotEmpty) ...[
                  CommonTextInput(
                    label: l10n.lookup('invCode'),
                    controller: _code,
                    autofocus: true,
                    validator: _requiredValidator(l10n),
                  ),
                  const SizedBox(height: 12),
                ],
                CommonTextInput(
                  label: l10n.name,
                  controller: _name,
                  autofocus: widget.code.isEmpty && widget.extraLabel.isEmpty,
                  validator: _requiredValidator(l10n),
                ),
                if (widget.extraLabel.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  CommonTextInput(
                    label: widget.extraLabel,
                    controller: _extra,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(
          onPressed: _submit,
          child: Text(l10n.save),
        ),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    Navigator.pop(
      context,
      _NamedConfigInput(
        _code.text.trim(),
        _name.text.trim(),
        _extra.text.trim(),
      ),
    );
  }
}

class _LocationInput {
  const _LocationInput(this.warehouseId, this.code, this.name);
  final String warehouseId;
  final String code;
  final String name;
}

class _LocationDialog extends StatefulWidget {
  const _LocationDialog({required this.warehouses, this.location});
  final List<InventoryWarehouse> warehouses;
  final InventoryLocation? location;

  @override
  State<_LocationDialog> createState() => _LocationDialogState();
}

class _LocationDialogState extends State<_LocationDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _warehouseId;
  late final TextEditingController _code;
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _warehouseId = widget.location?.warehouseId ?? '';
    _code = TextEditingController(text: widget.location?.code ?? '');
    _name = TextEditingController(text: widget.location?.name ?? '');
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return AlertDialog(
      title: Text(l10n.lookup('invConfigureLocations')),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 520),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _warehouseId.isEmpty ? null : _warehouseId,
                  decoration:
                      InputDecoration(labelText: l10n.lookup('invWarehouse')),
                  items: [
                    for (final warehouse in widget.warehouses)
                      DropdownMenuItem(
                        value: warehouse.id,
                        child: Text(warehouse.name),
                      ),
                  ],
                  validator: (value) => value == null || value.isEmpty
                      ? l10n.lookup('invRequired')
                      : null,
                  onChanged: (value) =>
                      setState(() => _warehouseId = value ?? ''),
                ),
                const SizedBox(height: 12),
                CommonTextInput(
                  label: l10n.lookup('invCode'),
                  controller: _code,
                  validator: _requiredValidator(l10n),
                ),
                const SizedBox(height: 12),
                CommonTextInput(
                  label: l10n.name,
                  controller: _name,
                  validator: _requiredValidator(l10n),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(
          onPressed: _submit,
          child: Text(l10n.save),
        ),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    Navigator.pop(
      context,
      _LocationInput(
        _warehouseId,
        _code.text.trim(),
        _name.text.trim(),
      ),
    );
  }
}

String? Function(String?) _requiredValidator(S l10n) => (value) =>
    value == null || value.trim().isEmpty ? l10n.lookup('invRequired') : null;

String _typeLabel(BuildContext context, InventoryParameterType type) {
  final l10n = S.of(context);
  return switch (type) {
    InventoryParameterType.category => l10n.lookup('invConfigureCategories'),
    InventoryParameterType.unitOfMeasure => l10n.lookup('invConfigureUnits'),
    InventoryParameterType.itemType => l10n.lookup('invConfigureItemTypes'),
    InventoryParameterType.movementReason => l10n.lookup('invMovementReasons'),
    InventoryParameterType.adjustmentReason =>
      l10n.lookup('invAdjustmentReasons'),
    InventoryParameterType.rejectionReason =>
      l10n.lookup('invRejectionReasons'),
    InventoryParameterType.shortfallReason =>
      l10n.lookup('invShortfallReasons'),
  };
}
