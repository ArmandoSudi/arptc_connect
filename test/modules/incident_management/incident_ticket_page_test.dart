import 'package:arptc_connect/modules/incident_management/domain/incident_ticket_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('incident page requests default to a bounded page size', () {
    const request = IncidentTicketPageRequest();

    expect(request.limit, 50);
    expect(request.cursor, isNull);
  });

  test('incident page requests reject unbounded limits', () {
    expect(
      () => IncidentTicketPageRequest(limit: 101),
      throwsAssertionError,
    );
    expect(
      () => IncidentTicketPageRequest(limit: 0),
      throwsAssertionError,
    );
  });

  test('incident page cursor preserves stable sort values', () {
    final updatedAt = DateTime.utc(2026, 7, 31, 10, 30);
    final cursor = IncidentTicketPageCursor(
      updatedAt: updatedAt,
      documentId: 'incident-42',
    );

    expect(cursor.updatedAt, updatedAt);
    expect(cursor.documentId, 'incident-42');
  });
}
