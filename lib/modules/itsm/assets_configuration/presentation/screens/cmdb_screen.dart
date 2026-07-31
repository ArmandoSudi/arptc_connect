import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/assets_configuration_contracts.dart';
import '../../application/assets_configuration_providers.dart';
import '../assets_configuration_strings.dart';
import '../widgets/assets_configuration_shell.dart';
import '../widgets/assets_configuration_state.dart';
import '../widgets/cmdb_view.dart';
import '../widgets/manager_configuration_dialogs.dart';

class CmdbScreen extends ConsumerStatefulWidget {
  const CmdbScreen({
    super.key,
    this.onBack,
    this.onAddConfigurationItem,
    this.onCreateRelationship,
    this.onRetireRelationship,
    this.limit = 50,
  });

  final VoidCallback? onBack;
  final ManagerDialogAction? onAddConfigurationItem;
  final ManagerConfigurationItemDialogAction? onCreateRelationship;
  final ManagerRelationshipDialogAction? onRetireRelationship;
  final int limit;

  @override
  ConsumerState<CmdbScreen> createState() => _CmdbScreenState();
}

class _CmdbScreenState extends ConsumerState<CmdbScreen> {
  String _search = '';
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(configurationItemsProvider(widget.limit));
    final strings = AssetsConfigurationStrings.of(context);
    return AssetsConfigurationShell(
      title: strings.cmdb,
      subtitle: strings.cmdbDescription,
      onBack: widget.onBack,
      actions: [
        FilledButton.icon(
          onPressed: widget.onAddConfigurationItem == null
              ? null
              : () => widget.onAddConfigurationItem!(context, ref),
          icon: const Icon(Icons.add),
          label: Text(strings.addConfigurationItem),
        ),
      ],
      child: _selectedId == null
          ? AssetsConfigurationAsyncView<List<ConfigurationItemSummary>>(
              value: items,
              onRetry: () =>
                  ref.invalidate(configurationItemsProvider(widget.limit)),
              data: (records) => CmdbListView(
                items: records,
                searchQuery: _search,
                onSearchChanged: (value) => setState(() => _search = value),
                onSelected: (item) => setState(() => _selectedId = item.id),
              ),
            )
          : AssetsConfigurationAsyncView<ConfigurationDependencyView?>(
              value: ref.watch(configurationDependencyProvider(_selectedId!)),
              onRetry: () => ref.invalidate(
                configurationDependencyProvider(_selectedId!),
              ),
              data: (view) => view == null
                  ? AssetsConfigurationEmptyState(
                      title: strings.noData,
                      description: strings.noDataDescription,
                      icon: Icons.account_tree_outlined,
                    )
                  : ConfigurationDependencyViewWidget(
                      view: view,
                      onClose: () => setState(() => _selectedId = null),
                      onEdit: (item) => showAddConfigurationItemDialog(
                        context,
                        ref,
                        item: item,
                      ),
                      onCreateRelationship: widget.onCreateRelationship == null
                          ? null
                          : (item) => widget.onCreateRelationship!(
                                context,
                                ref,
                                item,
                              ),
                      onRetireRelationship: widget.onRetireRelationship == null
                          ? null
                          : (relationship) => widget.onRetireRelationship!(
                                context,
                                ref,
                                relationship,
                              ),
                    ),
            ),
    );
  }
}
