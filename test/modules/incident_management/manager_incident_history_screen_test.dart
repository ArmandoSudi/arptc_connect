import 'package:arptc_connect/modules/incident_management/domain/incident_ticket.dart';
import 'package:arptc_connect/modules/incident_management/presentation/screens/manager_incident_history_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('filterAndSortClosedIncidentTickets', () {
    test('sorts tickets by most recent closed date', () {
      final older = _ticket(
        id: 'older',
        title: 'Older incident',
        closedAt: DateTime(2026, 7, 1),
      );
      final newer = _ticket(
        id: 'newer',
        title: 'Newer incident',
        closedAt: DateTime(2026, 7, 12),
      );

      final result = filterAndSortClosedIncidentTickets([older, newer], '');

      expect(result.map((ticket) => ticket.id), ['newer', 'older']);
    });

    test('searches across ticket details and resolution fields', () {
      final networkTicket = _ticket(
        id: 'network',
        title: 'Internet unavailable',
        closedAt: DateTime(2026, 7, 10),
        resolutionSummary: 'Router configuration corrected',
      );
      final printerTicket = _ticket(
        id: 'printer',
        title: 'Printer issue',
        closedAt: DateTime(2026, 7, 11),
      );

      final result = filterAndSortClosedIncidentTickets(
        [networkTicket, printerTicket],
        'router configuration',
      );

      expect(result.map((ticket) => ticket.id), ['network']);
    });
  });
}

IncidentTicket _ticket({
  required String id,
  required String title,
  required DateTime closedAt,
  String resolutionSummary = '',
}) {
  return IncidentTicket.empty().copyWith(
    id: id,
    ticketNumber: 'INC-$id',
    title: title,
    status: 'closed',
    lifecycleState: 'closed',
    closedAt: closedAt,
    resolutionSummary: resolutionSummary,
  );
}
