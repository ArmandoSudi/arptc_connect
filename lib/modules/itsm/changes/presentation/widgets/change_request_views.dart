import 'package:arptc_connect/generated/l10n.dart';
import 'package:flutter/material.dart';

import '../../domain/changes_domain.dart';
import '../change_presentation_strings.dart';
import 'change_page_shell.dart';

class ChangeRequestListView extends StatelessWidget {
  const ChangeRequestListView({
    required this.changes,
    required this.onSelected,
    super.key,
  });

  final List<ChangeRequest> changes;
  final ValueChanged<ChangeRequest> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    if (changes.isEmpty) {
      return ChangeSurfaceCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 36),
          child: Column(
            children: [
              Icon(
                Icons.change_circle_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.changeEmptyTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                l10n.changeEmptyDescription,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return ChangeSurfaceCard(
      child: Column(
        children: [
          for (final change in changes)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 6),
              onTap: () => onSelected(change),
              leading: CircleAvatar(
                backgroundColor:
                    _riskColor(context, change.risk).withOpacity(0.12),
                child: Icon(
                  Icons.change_circle_outlined,
                  color: _riskColor(context, change.risk),
                ),
              ),
              title: Text(
                change.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${change.changeNumber} • '
                '${l10n.changeTypeLabel(change.type)} • '
                '${change.requester.name}',
              ),
              trailing: ChangeStatusBadge(status: change.status),
            ),
        ],
      ),
    );
  }
}

class ChangeStatusBadge extends StatelessWidget {
  const ChangeStatusBadge({required this.status, super.key});

  final ChangeStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        S.of(context).changeStatusLabel(status),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

Color _riskColor(BuildContext context, ChangeRiskLevel risk) => switch (risk) {
      ChangeRiskLevel.low => const Color(0xFF079455),
      ChangeRiskLevel.medium => const Color(0xFFF79009),
      ChangeRiskLevel.high => const Color(0xFFF04438),
      ChangeRiskLevel.critical => Theme.of(context).colorScheme.error,
    };

Color _statusColor(BuildContext context, ChangeStatus status) =>
    switch (status) {
      ChangeStatus.closed => const Color(0xFF079455),
      ChangeStatus.rejected ||
      ChangeStatus.failed =>
        Theme.of(context).colorScheme.error,
      ChangeStatus.cancelled ||
      ChangeStatus.rolledBack =>
        Theme.of(context).colorScheme.outline,
      ChangeStatus.approved ||
      ChangeStatus.scheduled =>
        const Color(0xFF155EEF),
      _ => const Color(0xFFF79009),
    };
