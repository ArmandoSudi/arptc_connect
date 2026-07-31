import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_ticket.dart';
import 'package:arptc_connect/modules/itsm/presentation/navigation/itsm_navigation.dart';
import 'package:flutter/material.dart';

enum IncidentLinkedRecordType {
  asset,
  configurationItem,
  serviceRequest,
  change,
  knowledgeArticle,
}

String incidentLinkedRecordLocation(IncidentLinkedRecord record) {
  final encodedId = Uri.encodeComponent(record.id.trim());
  return switch (record.type) {
    IncidentLinkedRecordType.asset =>
      '${ItsmRoutes.assets}?recordId=$encodedId',
    IncidentLinkedRecordType.configurationItem =>
      '${ItsmRoutes.cmdb}?recordId=$encodedId',
    IncidentLinkedRecordType.serviceRequest =>
      '${ItsmRoutes.serviceRequests}/$encodedId',
    IncidentLinkedRecordType.change =>
      '${ItsmRoutes.changeRequests}?recordId=$encodedId',
    IncidentLinkedRecordType.knowledgeArticle =>
      '${ItsmRoutes.knowledge}/$encodedId',
  };
}

class IncidentLinkedRecord {
  const IncidentLinkedRecord({
    required this.type,
    required this.id,
  });

  final IncidentLinkedRecordType type;
  final String id;
}

class IncidentLinkedRecordsCard extends StatelessWidget {
  const IncidentLinkedRecordsCard({
    required this.records,
    super.key,
    this.onRecordPressed,
  });

  factory IncidentLinkedRecordsCard.fromTicket({
    required IncidentTicket ticket,
    Key? key,
    ValueChanged<IncidentLinkedRecord>? onRecordPressed,
  }) {
    return IncidentLinkedRecordsCard(
      key: key,
      records: recordsForTicket(ticket),
      onRecordPressed: onRecordPressed,
    );
  }

  final List<IncidentLinkedRecord> records;
  final ValueChanged<IncidentLinkedRecord>? onRecordPressed;

  static List<IncidentLinkedRecord> recordsForTicket(IncidentTicket ticket) {
    return [
      if (ticket.assetId.trim().isNotEmpty)
        IncidentLinkedRecord(
          type: IncidentLinkedRecordType.asset,
          id: ticket.assetId.trim(),
        ),
      if (ticket.configurationItemId.trim().isNotEmpty)
        IncidentLinkedRecord(
          type: IncidentLinkedRecordType.configurationItem,
          id: ticket.configurationItemId.trim(),
        ),
      if (ticket.relatedServiceRequestId.trim().isNotEmpty)
        IncidentLinkedRecord(
          type: IncidentLinkedRecordType.serviceRequest,
          id: ticket.relatedServiceRequestId.trim(),
        ),
      if (ticket.relatedChangeId.trim().isNotEmpty)
        IncidentLinkedRecord(
          type: IncidentLinkedRecordType.change,
          id: ticket.relatedChangeId.trim(),
        ),
      for (final articleId in ticket.suggestedKnowledgeArticleIds)
        if (articleId.trim().isNotEmpty)
          IncidentLinkedRecord(
            type: IncidentLinkedRecordType.knowledgeArticle,
            id: articleId.trim(),
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = S.of(context);
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.linkedRecords,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final record in records)
                  ActionChip(
                    avatar: Icon(
                      _iconFor(record.type),
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    label: Text(
                      '${_labelFor(l10n, record.type)}: ${record.id}',
                    ),
                    onPressed: onRecordPressed == null
                        ? null
                        : () => onRecordPressed!(record),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _labelFor(S l10n, IncidentLinkedRecordType type) {
  switch (type) {
    case IncidentLinkedRecordType.asset:
      return l10n.relatedAsset;
    case IncidentLinkedRecordType.configurationItem:
      return l10n.configurationItem;
    case IncidentLinkedRecordType.serviceRequest:
      return l10n.relatedServiceRequest;
    case IncidentLinkedRecordType.change:
      return l10n.relatedChange;
    case IncidentLinkedRecordType.knowledgeArticle:
      return l10n.suggestedKnowledge;
  }
}

IconData _iconFor(IncidentLinkedRecordType type) {
  switch (type) {
    case IncidentLinkedRecordType.asset:
      return Icons.devices_other_rounded;
    case IncidentLinkedRecordType.configurationItem:
      return Icons.account_tree_outlined;
    case IncidentLinkedRecordType.serviceRequest:
      return Icons.assignment_outlined;
    case IncidentLinkedRecordType.change:
      return Icons.change_circle_outlined;
    case IncidentLinkedRecordType.knowledgeArticle:
      return Icons.menu_book_outlined;
  }
}
