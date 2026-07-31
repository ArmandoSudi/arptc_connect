import 'package:arptc_connect/widgets/app_search_bar.dart';
import 'package:arptc_connect/widgets/corporate_components.dart';
import 'package:flutter/material.dart';

import '../../application/assets_configuration_contracts.dart';
import '../assets_configuration_strings.dart';
import 'assets_configuration_shell.dart';
import 'assets_configuration_state.dart';

class MyAssetsView extends StatelessWidget {
  const MyAssetsView({
    required this.assets,
    required this.onSelected,
    super.key,
    this.searchQuery = '',
    this.onSearchChanged,
  });

  final List<AssetSummary> assets;
  final ValueChanged<AssetSummary> onSelected;
  final String searchQuery;
  final ValueChanged<String>? onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AssetsConfigurationStrings.of(context);
    final normalized = searchQuery.trim().toLowerCase();
    final visible = assets.where((asset) {
      if (normalized.isEmpty) return true;
      return [
        asset.name,
        asset.assetTag,
        asset.serialNumber,
        asset.brand,
        asset.model,
      ].any((value) => value.toLowerCase().contains(normalized));
    }).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSearchBar(
          hintText: strings.searchAssets,
          onChanged: onSearchChanged,
        ),
        const SizedBox(height: 20),
        if (visible.isEmpty)
          AssetsConfigurationEmptyState(
            title: strings.noAssignedAssets,
            description: strings.myAssetsDescription,
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
                  for (final asset in visible)
                    SizedBox(
                      width: width,
                      child: AssetSummaryCard(
                        asset: asset,
                        onTap: () => onSelected(asset),
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

class AssetRegisterView extends StatelessWidget {
  const AssetRegisterView({
    required this.assets,
    required this.onSelected,
    super.key,
    this.searchQuery = '',
    this.onSearchChanged,
    this.onPreviousPage,
    this.onNextPage,
  });

  final List<AssetSummary> assets;
  final ValueChanged<AssetSummary> onSelected;
  final String searchQuery;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;

  @override
  Widget build(BuildContext context) {
    final strings = AssetsConfigurationStrings.of(context);
    if (assets.isEmpty) {
      return Column(
        children: [
          AppSearchBar(
            hintText: strings.searchAssets,
            onChanged: onSearchChanged,
          ),
          AssetsConfigurationEmptyState(
            title: strings.noAssets,
            description: strings.noDataDescription,
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSearchBar(
          hintText: strings.searchAssets,
          onChanged: onSearchChanged,
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 760) {
              return Column(
                children: [
                  for (final asset in assets) ...[
                    AssetSummaryCard(
                      asset: asset,
                      onTap: () => onSelected(asset),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              );
            }
            return _AssetRegisterTable(assets: assets, onSelected: onSelected);
          },
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton.icon(
              onPressed: onPreviousPage,
              icon: const Icon(Icons.chevron_left),
              label: Text(strings.previous),
            ),
            const SizedBox(width: 8),
            FilledButton.tonalIcon(
              onPressed: onNextPage,
              icon: const Icon(Icons.chevron_right),
              label: Text(strings.next),
            ),
          ],
        ),
      ],
    );
  }
}

class AssetSummaryCard extends StatelessWidget {
  const AssetSummaryCard({required this.asset, required this.onTap, super.key});

  final AssetSummary asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CorporateSurfaceCard(
      onTap: onTap,
      accentColor: _statusColor(context, asset.status),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: asset.photoUrl == null
                ? Icon(
                    Icons.devices_other_outlined,
                    color: theme.colorScheme.onPrimaryContainer,
                  )
                : Image.network(
                    asset.photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image_outlined),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text('${asset.assetTag} • ${asset.categoryName}'),
                if (asset.brand.isNotEmpty || asset.model.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${asset.brand} ${asset.model}'.trim(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                _StatusChip(status: asset.status),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class AssetDetailView extends StatelessWidget {
  const AssetDetailView({
    required this.detail,
    required this.isManager,
    super.key,
    this.onCatalogueAction,
    this.onEdit,
    this.onAssign,
    this.onReturn,
    this.onTransition,
    this.onUploadAttachment,
    this.onUploadPhotograph,
    this.isUploading = false,
  });

  final AssetDetail detail;
  final bool isManager;
  final ValueChanged<AssetCatalogueAction>? onCatalogueAction;
  final VoidCallback? onEdit;
  final VoidCallback? onAssign;
  final VoidCallback? onReturn;
  final VoidCallback? onTransition;
  final VoidCallback? onUploadAttachment;
  final VoidCallback? onUploadPhotograph;
  final bool isUploading;

  @override
  Widget build(BuildContext context) {
    final summary = detail.summary;
    final strings = AssetsConfigurationStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CorporateSurfaceCard(
          accentColor: _statusColor(context, summary.status),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 20,
                runSpacing: 20,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _AssetHero(detail: detail),
                  _DetailBlock(
                      label: strings.assetTag, value: summary.assetTag),
                  _DetailBlock(
                    label: strings.serialNumber,
                    value: summary.serialNumber,
                  ),
                  _DetailBlock(
                      label: strings.category, value: summary.categoryName),
                  _DetailBlock(label: strings.type, value: detail.typeName),
                  _DetailBlock(
                      label: strings.location, value: summary.locationName),
                  _DetailBlock(
                    label: strings.custodian,
                    value: summary.assignedUserName,
                  ),
                  _DetailBlock(
                      label: strings.condition, value: summary.condition),
                  _DetailBlock(
                    label: strings.compliance,
                    value: strings.complianceState(detail.complianceState),
                  ),
                ],
              ),
              if (detail.description.isNotEmpty) ...[
                const Divider(height: 32),
                Text(detail.description),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (isManager)
          CorporateSurfaceCard(
            title: strings.operational,
            subtitle: summary.assignedUserName.isEmpty
                ? null
                : strings.assignedAssetReturnHint,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(strings.editAsset),
                ),
                FilledButton.tonalIcon(
                  onPressed: onAssign,
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: Text(strings.assignAsset),
                ),
                if (summary.assignedUserName.isNotEmpty ||
                    summary.status == AssetLifecycleStatus.assigned ||
                    summary.status == AssetLifecycleStatus.inMaintenance)
                  FilledButton.tonalIcon(
                    onPressed: onReturn,
                    icon: const Icon(Icons.keyboard_return_outlined),
                    label: Text(strings.returnAsset),
                  ),
                FilledButton.icon(
                  onPressed: onTransition,
                  icon: const Icon(Icons.alt_route_rounded),
                  label: Text(strings.transitionAsset),
                ),
              ],
            ),
          )
        else
          AssetCatalogueActions(onSelected: onCatalogueAction),
        const SizedBox(height: 16),
        _LifecyclePanel(entries: detail.lifecycle),
        const SizedBox(height: 16),
        CorporateSurfaceCard(
          title: strings.attachments,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isManager) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: onUploadAttachment,
                      icon: isUploading
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.attach_file),
                      label: Text(
                        isUploading
                            ? strings.uploading
                            : strings.uploadAttachment,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: onUploadPhotograph,
                      icon: const Icon(Icons.add_a_photo_outlined),
                      label: Text(strings.uploadPhotograph),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              if (detail.attachmentNames.isEmpty &&
                  detail.photographIds.isEmpty)
                Text(strings.noAttachments)
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final name in detail.attachmentNames)
                      Chip(
                        avatar: const Icon(Icons.attach_file, size: 18),
                        label: Text(name),
                      ),
                    for (final name in detail.photographIds)
                      Chip(
                        avatar: const Icon(Icons.photo_outlined, size: 18),
                        label: Text(name),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class AssetCatalogueActions extends StatelessWidget {
  const AssetCatalogueActions({required this.onSelected, super.key});

  final ValueChanged<AssetCatalogueAction>? onSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AssetsConfigurationStrings.of(context);
    final actions = <AssetCatalogueAction, (IconData, String)>{
      AssetCatalogueAction.reportFault: (
        Icons.report_problem_outlined,
        strings.reportFault,
      ),
      AssetCatalogueAction.requestRepair: (
        Icons.handyman_outlined,
        strings.requestRepair,
      ),
      AssetCatalogueAction.requestReplacement: (
        Icons.swap_horiz_outlined,
        strings.requestReplacement,
      ),
      AssetCatalogueAction.requestConfiguration: (
        Icons.tune_outlined,
        strings.requestConfiguration,
      ),
      AssetCatalogueAction.requestReturn: (
        Icons.keyboard_return_outlined,
        strings.requestReturn,
      ),
    };
    return CorporateSurfaceCard(
      title: strings.requestSupport,
      subtitle: strings.requestActionDescription,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final entry in actions.entries)
            FilledButton.tonalIcon(
              onPressed:
                  onSelected == null ? null : () => onSelected!(entry.key),
              icon: Icon(entry.value.$1),
              label: Text(entry.value.$2),
            ),
        ],
      ),
    );
  }
}

class _AssetRegisterTable extends StatelessWidget {
  const _AssetRegisterTable({required this.assets, required this.onSelected});

  final List<AssetSummary> assets;
  final ValueChanged<AssetSummary> onSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AssetsConfigurationStrings.of(context);
    return AssetsConfigurationPanel(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text(strings.assetTag)),
            DataColumn(label: Text(strings.assetRegister)),
            DataColumn(label: Text(strings.category)),
            DataColumn(label: Text(strings.status)),
            DataColumn(label: Text(strings.custodian)),
            DataColumn(label: Text(strings.location)),
          ],
          rows: [
            for (final asset in assets)
              DataRow(
                onSelectChanged: (_) => onSelected(asset),
                cells: [
                  DataCell(Text(asset.assetTag)),
                  DataCell(Text(asset.name)),
                  DataCell(Text(asset.categoryName)),
                  DataCell(_StatusChip(status: asset.status)),
                  DataCell(Text(asset.assignedUserName)),
                  DataCell(Text(asset.locationName)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _AssetHero extends StatelessWidget {
  const _AssetHero({required this.detail});

  final AssetDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 280,
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(
              Icons.devices_other_outlined,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.summary.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                _StatusChip(status: detail.summary.status),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(value.isEmpty ? '—' : value),
        ],
      ),
    );
  }
}

class _LifecyclePanel extends StatelessWidget {
  const _LifecyclePanel({required this.entries});

  final List<AssetLifecycleEntry> entries;

  @override
  Widget build(BuildContext context) {
    final strings = AssetsConfigurationStrings.of(context);
    return CorporateSurfaceCard(
      title: strings.lifecycleHistory,
      child: entries.isEmpty
          ? Text(strings.noLifecycle)
          : Column(
              children: [
                for (final entry in entries)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.history_toggle_off_outlined),
                    title: Text(strings.lifecycleStatus(entry.status)),
                    subtitle: Text(
                      '${entry.actorName} • '
                      '${MaterialLocalizations.of(context).formatShortDate(entry.occurredAt)}'
                      '${entry.note.isEmpty ? '' : '\n${entry.note}'}',
                    ),
                  ),
              ],
            ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final AssetLifecycleStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context, status);
    final strings = AssetsConfigurationStrings.of(context);
    return Chip(
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
      backgroundColor: color.withOpacity(0.13),
      label: Text(
        strings.lifecycleStatus(status),
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

Color _statusColor(BuildContext context, AssetLifecycleStatus status) {
  final colors = Theme.of(context).colorScheme;
  return switch (status) {
    AssetLifecycleStatus.assigned ||
    AssetLifecycleStatus.configured =>
      Colors.green.shade700,
    AssetLifecycleStatus.inMaintenance ||
    AssetLifecycleStatus.lost ||
    AssetLifecycleStatus.stolen =>
      colors.error,
    AssetLifecycleStatus.retired ||
    AssetLifecycleStatus.disposed =>
      colors.outline,
    _ => colors.primary,
  };
}
