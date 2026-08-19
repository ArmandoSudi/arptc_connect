import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/domain/pagination.dart';
import '../../application/assets_configuration_contracts.dart';
import '../../application/assets_configuration_providers.dart';
import '../../domain/asset_parameter.dart';
import '../assets_configuration_error_message.dart';
import '../assets_configuration_strings.dart';
import 'asset_register_dialogs.dart';
import 'manager_configuration_dialogs.dart';

enum AssetStatusAction { condition, lifecycle, decommission }

bool canUpdateAssetStatus(AssetDetail detail) =>
    detail.summary.status != AssetLifecycleStatus.disposed;

Future<void> showUpdateAssetStatusDialog(
  BuildContext context,
  WidgetRef ref,
  AssetDetail detail,
) async {
  try {
    final parameters = await ref.read(
      assetParametersProvider(PageRequest.maximumLimit).future,
    );
    if (!context.mounted) return;
    final states = parameters
        .where((parameter) => parameter.type == AssetParameterType.state)
        .toList(growable: false);
    final transitions = availableAssetLifecycleTransitions(detail);
    final canChangeCondition = _canChangeCondition(detail, states);
    final canDecommission = _canDecommission(detail);
    final action = await _showStatusActionPicker(
      context,
      detail: detail,
      canChangeCondition: canChangeCondition,
      transitions: transitions,
      canDecommission: canDecommission,
    );
    if (action == null || !context.mounted) return;
    switch (action) {
      case AssetStatusAction.condition:
        await showChangeAssetStateDialog(
          context,
          ref,
          detail,
          availableStates: states,
        );
      case AssetStatusAction.lifecycle:
        await showAssetLifecycleTransitionDialog(
          context,
          ref,
          detail,
          validTransitions: transitions,
        );
      case AssetStatusAction.decommission:
        await showDecommissionAssetDialog(context, ref, detail);
    }
  } catch (error) {
    if (!context.mounted) return;
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
  }
}

Future<AssetStatusAction?> _showStatusActionPicker(
  BuildContext context, {
  required AssetDetail detail,
  required bool canChangeCondition,
  required List<AssetLifecycleStatus> transitions,
  required bool canDecommission,
}) {
  final content = _AssetStatusActionPanel(
    detail: detail,
    canChangeCondition: canChangeCondition,
    transitions: transitions,
    canDecommission: canDecommission,
  );
  if (MediaQuery.sizeOf(context).width < 600) {
    return showModalBottomSheet<AssetStatusAction>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => content,
    );
  }
  return showDialog<AssetStatusAction>(
    context: context,
    builder: (_) => Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: content,
      ),
    ),
  );
}

bool _canChangeCondition(
  AssetDetail detail,
  List<AssetParameter> states,
) {
  if (detail.summary.status == AssetLifecycleStatus.retired ||
      detail.summary.status == AssetLifecycleStatus.disposed) {
    return false;
  }
  final currentName =
      detail.stateName.isNotEmpty ? detail.stateName : detail.summary.stateName;
  return states.any((state) => state.name != currentName);
}

bool _canDecommission(AssetDetail detail) {
  if (detail.summary.assignedUserName.isNotEmpty) return false;
  return !const {
    AssetLifecycleStatus.assigned,
    AssetLifecycleStatus.retired,
    AssetLifecycleStatus.disposed,
  }.contains(detail.summary.status);
}

class _AssetStatusActionPanel extends StatelessWidget {
  const _AssetStatusActionPanel({
    required this.detail,
    required this.canChangeCondition,
    required this.transitions,
    required this.canDecommission,
  });

  final AssetDetail detail;
  final bool canChangeCondition;
  final List<AssetLifecycleStatus> transitions;
  final bool canDecommission;

  @override
  Widget build(BuildContext context) {
    final strings = AssetsConfigurationStrings.of(context);
    final colors = Theme.of(context).colorScheme;
    final actions = [
      _StatusActionCard(
        icon: Icons.health_and_safety_outlined,
        title: strings.assetCondition,
        description: canChangeCondition
            ? strings.assetConditionDescription
            : strings.noAssetConditionUpdates,
        enabled: canChangeCondition,
        onTap: () => Navigator.pop(context, AssetStatusAction.condition),
      ),
      _StatusActionCard(
        icon: Icons.alt_route_rounded,
        title: strings.assetLifecycle,
        description: transitions.isEmpty
            ? strings.noLifecycleTransitions
            : strings.assetLifecycleDescription,
        enabled: transitions.isNotEmpty,
        footer: transitions.isEmpty
            ? null
            : Wrap(
                spacing: 6,
                runSpacing: 6,
                children: transitions
                    .map(
                      (status) => Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text(strings.lifecycleStatus(status)),
                      ),
                    )
                    .toList(growable: false),
              ),
        onTap: () => Navigator.pop(context, AssetStatusAction.lifecycle),
      ),
      _StatusActionCard(
        icon: Icons.inventory_2_outlined,
        title: strings.decommissionAsset,
        description: canDecommission
            ? strings.decommissionAssetConfirmation
            : strings.decommissionUnavailable,
        enabled: canDecommission,
        destructive: true,
        onTap: () => Navigator.pop(context, AssetStatusAction.decommission),
      ),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.updateAssetStatus,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      strings.updateAssetStatusDescription,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CurrentValueChip(
                icon: Icons.route_outlined,
                label: strings.lifecycleStatus(detail.summary.status),
              ),
              if (detail.stateName.isNotEmpty ||
                  detail.summary.stateName.isNotEmpty ||
                  detail.summary.condition.isNotEmpty)
                _CurrentValueChip(
                  icon: Icons.health_and_safety_outlined,
                  label: detail.stateName.isNotEmpty
                      ? detail.stateName
                      : detail.summary.stateName.isNotEmpty
                          ? detail.summary.stateName
                          : detail.summary.condition,
                ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 680) {
                return Column(
                  children: [
                    for (var index = 0; index < actions.length; index++) ...[
                      actions[index],
                      if (index != actions.length - 1)
                        const SizedBox(height: 10),
                    ],
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var index = 0; index < actions.length; index++) ...[
                    Expanded(child: actions[index]),
                    if (index != actions.length - 1) const SizedBox(width: 10),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CurrentValueChip extends StatelessWidget {
  const _CurrentValueChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Chip(
        avatar: Icon(icon, size: 18),
        label: Text(label),
      );
}

class _StatusActionCard extends StatelessWidget {
  const _StatusActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.enabled,
    required this.onTap,
    this.footer,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool enabled;
  final VoidCallback onTap;
  final Widget? footer;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = destructive ? colors.error : colors.primary;
    return Semantics(
      button: true,
      enabled: enabled,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: enabled ? 1 : 0.55,
        child: Material(
          color: destructive
              ? colors.errorContainer.withOpacity(0.35)
              : colors.surfaceContainerHighest.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? onTap : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 176),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Icon(icon, color: accent),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: destructive ? colors.error : null,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                    if (footer != null) ...[
                      const SizedBox(height: 12),
                      footer!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
