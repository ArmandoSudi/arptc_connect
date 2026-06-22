import 'package:arptc_connect/core/theme.dart';
import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_enums.dart';
import 'package:arptc_connect/modules/incident_management/presentation/incident_localizations.dart';
import 'package:flutter/material.dart';

class IncidentStatusBadge extends StatelessWidget {
  const IncidentStatusBadge({
    required this.status,
    super.key,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    final resolved = IncidentStatus.fromValue(status);
    final color = _colorFor(context, resolved);
    final l10n = S.of(context);
    return Chip(
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
      backgroundColor: color.withOpacity(0.12),
      label: Text(
        localizedIncidentStatusLabel(l10n, resolved),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  Color _colorFor(BuildContext context, IncidentStatus status) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.corporateTheme;
    switch (status) {
      case IncidentStatus.open:
        return scheme.primary;
      case IncidentStatus.categorized:
        return tokens.info;
      case IncidentStatus.assigned:
        return scheme.secondary;
      case IncidentStatus.inProgress:
        return tokens.info;
      case IncidentStatus.resolved:
        return tokens.success;
      case IncidentStatus.closed:
        return scheme.onSurfaceVariant;
      case IncidentStatus.archived:
        return scheme.outline;
      case IncidentStatus.cancelled:
        return scheme.error;
    }
  }
}
