import 'package:arptc_connect/modules/incident_management/domain/incident_enums.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_ticket.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('incident lifecycle compatibility', () {
    test('all established status and lifecycle wire values remain stable', () {
      expect(
        IncidentStatus.values.map((status) => status.value),
        [
          'open',
          'categorized',
          'assigned',
          'in_progress',
          'resolved',
          'closed',
          'archived',
          'cancelled',
        ],
      );
      expect(
        IncidentLifecycleState.values.map((state) => state.value),
        ['active', 'closed', 'archived'],
      );
    });

    test('unknown legacy values degrade to safe active/open defaults', () {
      expect(IncidentStatus.fromValue('unknown'), IncidentStatus.open);
      expect(
        IncidentLifecycleState.fromValue('unknown'),
        IncidentLifecycleState.active,
      );
    });

    test('closed ticket persists the seven-day archival eligibility contract',
        () {
      final closedAt = DateTime.utc(2026, 7, 1, 10);
      final archiveEligibleAt = closedAt.add(const Duration(days: 7));
      final ticket = IncidentTicket.empty().copyWith(
        id: 'ticket-1',
        status: IncidentStatus.closed.value,
        lifecycleState: IncidentLifecycleState.closed.value,
        closedAt: closedAt,
        archiveEligibleAt: archiveEligibleAt,
      );

      final serialized = ticket.toFirestore();

      expect(serialized['status'], 'closed');
      expect(serialized['lifecycleState'], 'closed');
      expect(
        (serialized['closedAt'] as Timestamp).toDate().toUtc(),
        closedAt,
      );
      expect(
        (serialized['archiveEligibleAt'] as Timestamp).toDate().toUtc(),
        archiveEligibleAt,
      );
      expect(
        archiveEligibleAt.difference(closedAt),
        const Duration(days: 7),
      );
    });

    test('archived ticket retains server-populated archival timestamps', () {
      final archivedAt = DateTime.utc(2026, 7, 8, 10);
      final ticket = IncidentTicket.empty().copyWith(
        status: IncidentStatus.archived.value,
        lifecycleState: IncidentLifecycleState.archived.value,
        archivedAt: archivedAt,
      );

      final serialized = ticket.toFirestore();

      expect(serialized['status'], 'archived');
      expect(serialized['lifecycleState'], 'archived');
      expect(
        (serialized['archivedAt'] as Timestamp).toDate().toUtc(),
        archivedAt,
      );
    });
  });
}
