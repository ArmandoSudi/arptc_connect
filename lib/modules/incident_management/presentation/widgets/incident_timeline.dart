import 'package:arptc_connect/modules/incident_management/domain/incident_audit_log.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_comment.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class IncidentTimeline extends StatelessWidget {
  const IncidentTimeline({
    required this.comments,
    required this.auditLogs,
    this.showInternalNotes = true,
    super.key,
  });

  final List<IncidentComment> comments;
  final List<IncidentAuditLog> auditLogs;
  final bool showInternalNotes;

  @override
  Widget build(BuildContext context) {
    final items = <_TimelineItem>[
      ...comments
          .where((comment) => showInternalNotes || !comment.isInternal)
          .map(_TimelineItem.fromComment),
      ...auditLogs.map(_TimelineItem.fromAuditLog),
    ]..sort((left, right) => left.createdAt.compareTo(right.createdAt));

    if (items.isEmpty) {
      return Text(
        'No activity yet.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      );
    }

    return Column(
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: item.isComment
                      ? Theme.of(context).colorScheme.secondaryContainer
                      : Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.isComment
                      ? Icons.chat_bubble_outline
                      : Icons.history_toggle_off,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          DateFormat('dd MMM HH:mm').format(item.createdAt),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    if (item.body.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(item.body),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _TimelineItem {
  const _TimelineItem({
    required this.title,
    required this.subtitle,
    required this.body,
    required this.createdAt,
    required this.isComment,
  });

  final String title;
  final String subtitle;
  final String body;
  final DateTime createdAt;
  final bool isComment;

  factory _TimelineItem.fromComment(IncidentComment comment) {
    return _TimelineItem(
      title: comment.isInternal ? 'Internal note' : 'Comment',
      subtitle: comment.createdByName,
      body: comment.body,
      createdAt: comment.createdAt ?? DateTime(1900),
      isComment: true,
    );
  }

  factory _TimelineItem.fromAuditLog(IncidentAuditLog log) {
    return _TimelineItem(
      title: log.message.isEmpty ? log.action : log.message,
      subtitle: log.actorName,
      body: '',
      createdAt: log.createdAt ?? DateTime(1900),
      isComment: false,
    );
  }
}
