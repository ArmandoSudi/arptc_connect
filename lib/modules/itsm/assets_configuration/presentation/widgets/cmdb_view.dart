import 'package:arptc_connect/widgets/app_search_bar.dart';
import 'package:arptc_connect/widgets/corporate_components.dart';
import 'package:flutter/material.dart';

import '../../application/assets_configuration_contracts.dart';
import '../assets_configuration_strings.dart';
import 'assets_configuration_state.dart';

class CmdbListView extends StatelessWidget {
  const CmdbListView({
    required this.items,
    required this.onSelected,
    super.key,
    this.searchQuery = '',
    this.onSearchChanged,
  });

  final List<ConfigurationItemSummary> items;
  final ValueChanged<ConfigurationItemSummary> onSelected;
  final String searchQuery;
  final ValueChanged<String>? onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AssetsConfigurationStrings.of(context);
    final query = searchQuery.trim().toLowerCase();
    final visible = items.where((item) {
      return query.isEmpty ||
          [item.name, item.typeName, item.ownerName, item.linkedAssetTag]
              .any((value) => value.toLowerCase().contains(query));
    }).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSearchBar(
          hintText: strings.searchConfigurationItems,
          onChanged: onSearchChanged,
        ),
        const SizedBox(height: 16),
        if (visible.isEmpty)
          AssetsConfigurationEmptyState(
            title: strings.noData,
            description: strings.noDataDescription,
            icon: Icons.account_tree_outlined,
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1050
                  ? 3
                  : constraints.maxWidth >= 680
                      ? 2
                      : 1;
              const spacing = 16.0;
              final width =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final item in visible)
                    SizedBox(
                      width: width,
                      child: CorporateSurfaceCard(
                        onTap: () => onSelected(item),
                        accentColor: Theme.of(context).colorScheme.secondary,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.hub_outlined),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    item.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                                '${item.typeName} • ${item.operationalStatus}'),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                Chip(label: Text(item.criticality)),
                                if (item.dataQuality.isNotEmpty)
                                  Chip(label: Text(item.dataQuality)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}

class ConfigurationDependencyViewWidget extends StatefulWidget {
  const ConfigurationDependencyViewWidget({
    required this.view,
    required this.onClose,
    super.key,
    this.onEdit,
    this.onCreateRelationship,
    this.onRetireRelationship,
  });

  final ConfigurationDependencyView view;
  final VoidCallback onClose;
  final ValueChanged<ConfigurationItemSummary>? onEdit;
  final ValueChanged<ConfigurationItemSummary>? onCreateRelationship;
  final ValueChanged<ConfigurationRelationship>? onRetireRelationship;

  @override
  State<ConfigurationDependencyViewWidget> createState() =>
      _ConfigurationDependencyViewWidgetState();
}

enum _RelationshipViewMode { all, dependencies, impact }

class _ConfigurationDependencyViewWidgetState
    extends State<ConfigurationDependencyViewWidget> {
  _RelationshipViewMode _mode = _RelationshipViewMode.all;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AssetsConfigurationStrings.of(context);
    final compact = MediaQuery.sizeOf(context).width < 640;
    final view = widget.view;
    final inbound = view.relationships
        .where((relationship) => relationship.targetId == view.root.id)
        .toList(growable: false);
    final outbound = view.relationships
        .where((relationship) => relationship.sourceId == view.root.id)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: widget.onClose,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                view.root.name,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            if (widget.onEdit != null)
              IconButton(
                tooltip: strings.editConfigurationItem,
                onPressed: () => widget.onEdit!(view.root),
                icon: const Icon(Icons.edit_outlined),
              ),
            if (widget.onCreateRelationship != null && !compact)
              FilledButton.icon(
                onPressed: () => widget.onCreateRelationship!(view.root),
                icon: const Icon(Icons.add_link_rounded),
                label: Text(strings.createRelationship),
              ),
            if (widget.onCreateRelationship != null && compact)
              IconButton.filled(
                tooltip: strings.createRelationship,
                onPressed: () => widget.onCreateRelationship!(view.root),
                icon: const Icon(Icons.add_link_rounded),
              ),
            const SizedBox(width: 8),
            Chip(label: Text(view.root.operationalStatus)),
          ],
        ),
        const SizedBox(height: 18),
        SegmentedButton<_RelationshipViewMode>(
          segments: [
            ButtonSegment(
              value: _RelationshipViewMode.all,
              label: Text(strings.allRelationships),
              icon: const Icon(Icons.hub_outlined),
            ),
            ButtonSegment(
              value: _RelationshipViewMode.dependencies,
              label: Text(strings.showDependencies),
              icon: const Icon(Icons.arrow_upward_rounded),
            ),
            ButtonSegment(
              value: _RelationshipViewMode.impact,
              label: Text(strings.showImpact),
              icon: const Icon(Icons.arrow_downward_rounded),
            ),
          ],
          selected: {_mode},
          showSelectedIcon: false,
          onSelectionChanged: (selection) => setState(() {
            _mode = selection.first;
          }),
        ),
        const SizedBox(height: 18),
        CorporateSurfaceCard(
          title: strings.dependencies,
          subtitle: strings.cmdbDescription,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final vertical = constraints.maxWidth < 760;
              final upstream = _RelationshipColumn(
                title: strings.upstream,
                icon: Icons.arrow_upward_rounded,
                relationships: inbound,
                displaySource: true,
                onRetire: widget.onRetireRelationship,
              );
              final root = Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.hub,
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 34,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      view.root.name,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(view.root.typeName),
                  ],
                ),
              );
              final downstream = _RelationshipColumn(
                title: strings.downstream,
                icon: Icons.arrow_downward_rounded,
                relationships: outbound,
                displaySource: false,
                onRetire: widget.onRetireRelationship,
              );
              if (vertical) {
                return Column(
                  children: [
                    if (_mode != _RelationshipViewMode.impact) upstream,
                    if (_mode != _RelationshipViewMode.impact)
                      const SizedBox(height: 16),
                    root,
                    if (_mode != _RelationshipViewMode.dependencies)
                      const SizedBox(height: 16),
                    if (_mode != _RelationshipViewMode.dependencies) downstream,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_mode != _RelationshipViewMode.impact)
                    Expanded(child: upstream),
                  if (_mode != _RelationshipViewMode.impact)
                    const SizedBox(width: 16),
                  Expanded(child: root),
                  if (_mode != _RelationshipViewMode.dependencies)
                    const SizedBox(width: 16),
                  if (_mode != _RelationshipViewMode.dependencies)
                    Expanded(child: downstream),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        CorporateSurfaceCard(
          title: strings.relatedRecords,
          subtitle: strings.cmdbDescription,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: const Icon(Icons.support_agent, size: 18),
                label: Text(strings.incidents),
              ),
              Chip(
                avatar: const Icon(Icons.inbox_outlined, size: 18),
                label: Text(strings.requests),
              ),
              Chip(
                avatar: const Icon(Icons.change_circle_outlined, size: 18),
                label: Text(strings.changes),
              ),
              Chip(
                avatar: const Icon(Icons.security_outlined, size: 18),
                label: Text(strings.findings),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RelationshipColumn extends StatelessWidget {
  const _RelationshipColumn({
    required this.title,
    required this.icon,
    required this.relationships,
    required this.displaySource,
    this.onRetire,
  });

  final String title;
  final IconData icon;
  final List<ConfigurationRelationship> relationships;
  final bool displaySource;
  final ValueChanged<ConfigurationRelationship>? onRetire;

  @override
  Widget build(BuildContext context) {
    final strings = AssetsConfigurationStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 6),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 8),
        if (relationships.isEmpty)
          Text(strings.noRelationships)
        else
          for (final relationship in relationships)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                tileColor: Theme.of(context).colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                title: Text(
                  displaySource
                      ? relationship.sourceName
                      : relationship.targetName,
                ),
                subtitle: Text(
                  '${relationship.type} • ${relationship.id}\n'
                  '${relationship.sourceId} -> ${relationship.targetId}',
                ),
                trailing: onRetire == null
                    ? null
                    : IconButton(
                        tooltip: strings.retireRelationship,
                        onPressed: () => onRetire!(relationship),
                        icon: const Icon(Icons.link_off_rounded),
                      ),
              ),
            ),
      ],
    );
  }
}
