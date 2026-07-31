import 'package:arptc_connect/modules/incident_management/domain/incident_ticket.dart';

class IncidentTicketPageCursor {
  const IncidentTicketPageCursor({
    required this.updatedAt,
    required this.documentId,
  });

  final DateTime updatedAt;
  final String documentId;
}

class IncidentTicketPageRequest {
  const IncidentTicketPageRequest({
    this.limit = 50,
    this.cursor,
  }) : assert(limit > 0 && limit <= 100);

  final int limit;
  final IncidentTicketPageCursor? cursor;
}

class IncidentTicketPage {
  const IncidentTicketPage({
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });

  final List<IncidentTicket> items;
  final bool hasMore;
  final IncidentTicketPageCursor? nextCursor;
}
