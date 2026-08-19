import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/application/itsm_providers.dart';
import '../../../shared/data/trusted_command_gateways.dart';
import '../../../shared/domain/pagination.dart';
import '../../application/assets_configuration_contracts.dart';
import '../../application/assets_configuration_providers.dart';
import '../../domain/asset_parameter.dart';
import '../assets_configuration_error_message.dart';
import '../assets_configuration_strings.dart';
import '../widgets/assets_configuration_shell.dart';
import '../widgets/assets_configuration_state.dart';

class AssetParametersScreen extends ConsumerStatefulWidget {
  const AssetParametersScreen({
    super.key,
    this.onBack,
    this.limit = PageRequest.maximumLimit,
  });

  final VoidCallback? onBack;
  final int limit;

  @override
  ConsumerState<AssetParametersScreen> createState() =>
      _AssetParametersScreenState();
}

class _AssetParametersScreenState extends ConsumerState<AssetParametersScreen>
    with SingleTickerProviderStateMixin {
  static const _types = [
    AssetParameterType.location,
    AssetParameterType.category,
    AssetParameterType.state,
  ];

  late final TabController _tabController;
  var _selectedIndex = 0;
  var _submitting = false;

  AssetParameterType get _selectedType => _types[_selectedIndex];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _types.length, vsync: this)
      ..addListener(_tabChanged);
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_tabChanged)
      ..dispose();
    super.dispose();
  }

  void _tabChanged() {
    if (_tabController.indexIsChanging ||
        _selectedIndex == _tabController.index) {
      return;
    }
    setState(() => _selectedIndex = _tabController.index);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AssetsConfigurationStrings.of(context);
    final parameters = ref.watch(assetParametersProvider(widget.limit));

    return AssetsConfigurationShell(
      title: strings.assetParameters,
      subtitle: strings.assetParametersDescription,
      onBack: widget.onBack,
      actions: [
        FilledButton.icon(
          onPressed: _submitting ? null : () => _addParameter(_selectedType),
          icon: const Icon(Icons.add),
          label: Text(_addLabel(strings, _selectedType)),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: MediaQuery.sizeOf(context).width < 600,
            tabs: [
              Tab(
                icon: const Icon(Icons.location_on_outlined),
                text: strings.assetParameterLocations,
              ),
              Tab(
                icon: const Icon(Icons.category_outlined),
                text: strings.assetParameterCategories,
              ),
              Tab(
                icon: const Icon(Icons.fact_check_outlined),
                text: strings.assetParameterStates,
              ),
            ],
          ),
          const SizedBox(height: 20),
          AssetsConfigurationAsyncView<List<AssetParameter>>(
            value: parameters,
            onRetry: () =>
                ref.invalidate(assetParametersProvider(widget.limit)),
            data: (items) => AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _AssetParameterList(
                key: ValueKey(_selectedType),
                items: items
                    .where((parameter) => parameter.type == _selectedType)
                    .toList(growable: false),
                type: _selectedType,
                deleting: _submitting,
                onDelete: _deleteParameter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addParameter(AssetParameterType type) async {
    final strings = AssetsConfigurationStrings.of(context);
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _AssetParameterNameDialog(
        title: _addLabel(strings, type),
      ),
    );
    if (name == null || !mounted) return;
    await _execute(
      recordId: '',
      fields: {
        'type': type.name,
        'name': name,
        'isActive': true,
        'sortOrder': 0,
      },
      successMessage: strings.assetParameterSaved,
    );
  }

  Future<void> _deleteParameter(AssetParameter parameter) async {
    final strings = AssetsConfigurationStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.deleteAssetParameterTitle),
        content: Text(strings.deleteAssetParameterMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(strings.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _execute(
      recordId: parameter.id,
      fields: {
        'expectedRevision': parameter.revision,
        'type': parameter.type.name,
        'name': parameter.name,
        'isActive': false,
        'sortOrder': parameter.sortOrder,
      },
      successMessage: strings.assetParameterDeleted,
    );
  }

  Future<void> _execute({
    required String recordId,
    required Map<String, Object?> fields,
    required String successMessage,
  }) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final session = await ref.read(itsmSessionProvider.future);
      if (session == null) {
        throw const AssetsConfigurationAccessDenied(
          'An authenticated ITSM session is required.',
        );
      }
      final controller =
          await ref.read(assetsConfigurationCommandControllerProvider.future);
      final nonce = DateTime.now().toUtc().microsecondsSinceEpoch;
      await controller.manageConfiguration(
        ManagerConfigurationCommand(
          context: ItsmCommandContext(
            idempotencyKey: 'asset-parameter-$nonce',
            correlationId: 'asset-parameters-$nonce',
            actorUserId: session.userId,
            actorRole: session.role,
            actorDisplayName: session.displayName,
          ),
          recordType: 'asset_parameter',
          operation: 'asset.parameter.save',
          recordId: recordId,
          fields: fields,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            assetsConfigurationErrorMessage(
              error,
              AssetsConfigurationStrings.of(context),
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _AssetParameterList extends StatelessWidget {
  const _AssetParameterList({
    required this.items,
    required this.type,
    required this.deleting,
    required this.onDelete,
    super.key,
  });

  final List<AssetParameter> items;
  final AssetParameterType type;
  final bool deleting;
  final ValueChanged<AssetParameter> onDelete;

  @override
  Widget build(BuildContext context) {
    final strings = AssetsConfigurationStrings.of(context);
    if (items.isEmpty) {
      return AssetsConfigurationEmptyState(
        title: _emptyLabel(strings, type),
        description: strings.assetParametersDescription,
      );
    }
    return AssetsConfigurationPanel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            ListTile(
              leading: CircleAvatar(child: Icon(_typeIcon(type))),
              title: Text(items[index].name),
              trailing: IconButton(
                tooltip: strings.delete,
                onPressed: deleting ? null : () => onDelete(items[index]),
                icon: const Icon(Icons.delete_outline),
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            if (index < items.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _AssetParameterNameDialog extends StatefulWidget {
  const _AssetParameterNameDialog({required this.title});

  final String title;

  @override
  State<_AssetParameterNameDialog> createState() =>
      _AssetParameterNameDialogState();
}

class _AssetParameterNameDialogState extends State<_AssetParameterNameDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AssetsConfigurationStrings.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: CommonTextInput(
            label: strings.name,
            controller: _name,
            autofocus: true,
            validator: (value) => (value?.trim().isEmpty ?? true)
                ? strings.positiveQuantityError
                : null,
            onSubmitted: (_) => _submit(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(strings.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(strings.save),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, _name.text.trim());
  }
}

String _addLabel(
  AssetsConfigurationStrings strings,
  AssetParameterType type,
) =>
    switch (type) {
      AssetParameterType.location => strings.addAssetLocation,
      AssetParameterType.category => strings.addAssetCategory,
      AssetParameterType.state => strings.addAssetState,
    };

String _emptyLabel(
  AssetsConfigurationStrings strings,
  AssetParameterType type,
) =>
    switch (type) {
      AssetParameterType.location => strings.noAssetLocations,
      AssetParameterType.category => strings.noAssetCategories,
      AssetParameterType.state => strings.noAssetStates,
    };

IconData _typeIcon(AssetParameterType type) => switch (type) {
      AssetParameterType.location => Icons.location_on_outlined,
      AssetParameterType.category => Icons.category_outlined,
      AssetParameterType.state => Icons.fact_check_outlined,
    };
