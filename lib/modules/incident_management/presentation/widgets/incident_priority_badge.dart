import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_enums.dart';
import 'package:arptc_connect/modules/incident_management/presentation/incident_localizations.dart';
import 'package:flutter/material.dart';

class IncidentPriorityBadge extends StatelessWidget {
  const IncidentPriorityBadge({
    required this.priority,
    super.key,
  });

  final String priority;

  @override
  Widget build(BuildContext context) {
    final resolved = IncidentPriority.fromValue(priority);
    final color = _colorFor(context, resolved);
    final l10n = S.of(context);
    return Chip(
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
      backgroundColor: color.withOpacity(0.12),
      label: Text(
        localizedIncidentPriorityLabel(l10n, resolved),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  Color _colorFor(BuildContext context, IncidentPriority priority) {
    final scheme = Theme.of(context).colorScheme;
    switch (priority) {
      case IncidentPriority.none:
        return scheme.onSurfaceVariant;
      case IncidentPriority.p1:
        return scheme.error;
      case IncidentPriority.p2:
        return Colors.deepOrange;
      case IncidentPriority.p3:
        return Colors.orange;
      case IncidentPriority.p4:
        return Colors.green;
    }
  }
}
