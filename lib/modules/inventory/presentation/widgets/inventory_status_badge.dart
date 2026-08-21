import 'package:arptc_connect/core/theme.dart';
import 'package:arptc_connect/generated/l10n.dart';
import 'package:flutter/material.dart';

import '../../domain/inventory_domain.dart';

class InventoryRequestStatusBadge extends StatelessWidget {
  const InventoryRequestStatusBadge(this.status, {super.key});

  final MaterialRequestStatus status;

  @override
  Widget build(BuildContext context) {
    final presentation = _requestPresentation(context, status);
    return _Badge(
      label: presentation.label,
      icon: presentation.icon,
      color: presentation.color,
    );
  }
}

class InventoryAvailabilityBadge extends StatelessWidget {
  const InventoryAvailabilityBadge(this.availability, {super.key});

  final InventoryAvailability availability;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final tokens = context.corporateTheme;
    return switch (availability) {
      InventoryAvailability.available => _Badge(
          label: l10n.lookup('invAvailable'),
          icon: Icons.check_circle_outline_rounded,
          color: tokens.success,
        ),
      InventoryAvailability.limited => _Badge(
          label: l10n.lookup('invLimited'),
          icon: Icons.warning_amber_rounded,
          color: tokens.warning,
        ),
      InventoryAvailability.unavailable => _Badge(
          label: l10n.lookup('invUnavailable'),
          icon: Icons.schedule_rounded,
          color: Theme.of(context).colorScheme.error,
        ),
    };
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

({String label, IconData icon, Color color}) _requestPresentation(
  BuildContext context,
  MaterialRequestStatus status,
) {
  final l10n = S.of(context);
  final tokens = context.corporateTheme;
  final scheme = Theme.of(context).colorScheme;
  return switch (status) {
    MaterialRequestStatus.submitted => (
        label: l10n.lookup('invSubmitted'),
        icon: Icons.send_rounded,
        color: scheme.primary,
      ),
    MaterialRequestStatus.underReview => (
        label: l10n.lookup('invUnderReview'),
        icon: Icons.manage_search_rounded,
        color: const Color(0xFF4F46E5),
      ),
    MaterialRequestStatus.adjusted => (
        label: l10n.lookup('invAdjusted'),
        icon: Icons.tune_rounded,
        color: tokens.warning,
      ),
    MaterialRequestStatus.readyForIssue => (
        label: l10n.lookup('invReadyForIssue'),
        icon: Icons.inventory_2_outlined,
        color: const Color(0xFF0891B2),
      ),
    MaterialRequestStatus.partiallyFulfilled => (
        label: l10n.lookup('invPartiallyFulfilled'),
        icon: Icons.pending_actions_rounded,
        color: const Color(0xFF0F766E),
      ),
    MaterialRequestStatus.awaitingConfirmation => (
        label: l10n.lookup('invAwaitingConfirmation'),
        icon: Icons.fact_check_outlined,
        color: const Color(0xFF7C3AED),
      ),
    MaterialRequestStatus.fulfilled => (
        label: l10n.lookup('invFulfilled'),
        icon: Icons.check_circle_rounded,
        color: tokens.success,
      ),
    MaterialRequestStatus.closedShort => (
        label: l10n.lookup('invClosedShort'),
        icon: Icons.remove_circle_outline_rounded,
        color: const Color(0xFFEA580C),
      ),
    MaterialRequestStatus.cancelled => (
        label: l10n.lookup('invCancelled'),
        icon: Icons.cancel_outlined,
        color: scheme.outline,
      ),
    MaterialRequestStatus.rejected => (
        label: l10n.lookup('invRejected'),
        icon: Icons.block_rounded,
        color: scheme.error,
      ),
  };
}
