import 'package:arptc_connect/modules/incident_management/domain/incident_ticket.dart';
import 'package:arptc_connect/modules/incident_management/presentation/widgets/incident_priority_badge.dart';
import 'package:arptc_connect/modules/incident_management/presentation/widgets/incident_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class IncidentTicketCard extends StatelessWidget {
  const IncidentTicketCard({
    required this.ticket,
    required this.onTap,
    super.key,
  });

  final IncidentTicket ticket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final updatedAt = ticket.updatedAt ?? ticket.createdAt;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ticket.ticketNumber.isEmpty
                          ? 'Incident'
                          : ticket.ticketNumber,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IncidentStatusBadge(status: ticket.status),
                  const SizedBox(width: 8),
                  IncidentPriorityBadge(priority: ticket.priority),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                ticket.title.isEmpty ? 'Untitled incident' : ticket.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                ticket.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  _MetaItem(
                    icon: Icons.person_outline,
                    label: ticket.createdByName,
                  ),
                  if (ticket.assignedToName.isNotEmpty)
                    _MetaItem(
                      icon: Icons.support_agent_outlined,
                      label: ticket.assignedToName,
                    ),
                  if (ticket.affectedServiceName.isNotEmpty)
                    _MetaItem(
                      icon: Icons.design_services_outlined,
                      label: ticket.affectedServiceName,
                    ),
                  if (updatedAt != null)
                    _MetaItem(
                      icon: Icons.schedule,
                      label: DateFormat('dd MMM yyyy HH:mm').format(updatedAt),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (label.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
