import 'package:arptc_connect/modules/incident_management/application/incident_dashboard_aggregator.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_enums.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_ticket.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('manager dashboard parity', () {
    test('preserves operational KPI definitions and queue ordering', () {
      final base = DateTime.now().subtract(const Duration(days: 3));
      final tickets = [
        _ticket(
          id: 'open',
          status: IncidentStatus.open.value,
          priority: '',
          createdAt: base,
        ),
        _ticket(
          id: 'unassigned-p2',
          status: IncidentStatus.inProgress.value,
          priority: 'P2',
          createdAt: base.add(const Duration(hours: 2)),
          service: 'Network',
        ),
        _ticket(
          id: 'assigned-p1',
          status: IncidentStatus.assigned.value,
          priority: 'P1',
          assignedToUserId: 'manager-1',
          createdAt: base.add(const Duration(hours: 4)),
          service: 'Email',
        ),
        _ticket(
          id: 'solved',
          status: IncidentStatus.resolved.value,
          priority: 'P3',
          createdAt: base.add(const Duration(hours: 1)),
          service: 'Network',
        ),
        _ticket(
          id: 'deleted',
          status: IncidentStatus.open.value,
          priority: 'P1',
          createdAt: base,
          isDeleted: true,
        ),
        _ticket(
          id: 'closed',
          status: IncidentStatus.closed.value,
          lifecycleState: IncidentLifecycleState.closed.value,
          createdAt: base,
          closedAt: base.add(const Duration(hours: 5)),
        ),
      ];

      final stats =
          IncidentDashboardAggregator.buildManagerStats(tickets, 'manager-1');

      expect(stats.totalOpenCount, 1);
      expect(stats.unassignedCount, 1);
      expect(stats.assignedToMeCount, 1);
      expect(stats.criticalCount, 2);
      expect(stats.solvedCount, 1);
      expect(stats.ticketsByPriority['P1'], 1);
      expect(stats.ticketsByPriority['P2'], 1);
      expect(stats.ticketsByPriority['P3'], 1);
      expect(stats.ticketsByPriority['Unprioritized'], 1);
      expect(stats.ticketsByService['Network'], 2);
      expect(
        stats.activeTicketQueue.map((ticket) => ticket.id),
        ['assigned-p1', 'unassigned-p2', 'solved', 'open'],
      );
      expect(stats.myAssignedTickets.single.id, 'assigned-p1');
    });
  });

  group('admin dashboard parity', () {
    test(
        'preserves lifecycle totals, monthly groups, resolution average, and '
        'recent critical ordering', () {
      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month, 2, 8);
      final tickets = [
        _ticket(
          id: 'active',
          status: IncidentStatus.inProgress.value,
          priority: 'P2',
          createdAt: thisMonth,
          service: 'Network',
          category: 'Connection',
          department: 'DSI',
        ),
        _ticket(
          id: 'closed',
          status: IncidentStatus.closed.value,
          lifecycleState: IncidentLifecycleState.closed.value,
          priority: 'P1',
          createdAt: thisMonth.add(const Duration(hours: 1)),
          closedAt: thisMonth.add(const Duration(hours: 3)),
          service: 'Email',
          category: 'Messaging',
          department: 'Finance',
        ),
        _ticket(
          id: 'archived',
          status: IncidentStatus.archived.value,
          lifecycleState: IncidentLifecycleState.archived.value,
          priority: 'P4',
          createdAt: thisMonth.add(const Duration(hours: 2)),
        ),
        _ticket(
          id: 'deleted',
          status: IncidentStatus.open.value,
          createdAt: thisMonth,
          isDeleted: true,
        ),
      ];

      final stats = IncidentDashboardAggregator.buildAdminStats(tickets);

      expect(stats.totalThisMonthCount, 3);
      expect(stats.openCount, 1);
      expect(stats.closedCount, 1);
      expect(stats.archivedCount, 1);
      expect(stats.averageResolutionTimeMinutes, 120);
      expect(stats.ticketsByService['Network'], 1);
      expect(stats.ticketsByService['Email'], 1);
      expect(stats.ticketsByCategory['Connection'], 1);
      expect(stats.ticketsByDepartment['Finance'], 1);
      expect(
        stats.recentCriticalTickets.map((ticket) => ticket.id),
        ['closed', 'active'],
      );
      expect(stats.monthlyIncidentTrend, hasLength(6));
    });
  });
}

IncidentTicket _ticket({
  required String id,
  required String status,
  required DateTime createdAt,
  String lifecycleState = 'active',
  String priority = '',
  String assignedToUserId = '',
  String service = '',
  String category = '',
  String department = '',
  DateTime? closedAt,
  bool isDeleted = false,
}) {
  return IncidentTicket.empty().copyWith(
    id: id,
    ticketNumber: 'INC-$id',
    title: id,
    status: status,
    lifecycleState: lifecycleState,
    priority: priority,
    assignedToUserId: assignedToUserId,
    affectedServiceName: service,
    categoryName: category,
    createdByDepartmentName: department,
    createdAt: createdAt,
    closedAt: closedAt,
    isDeleted: isDeleted,
  );
}
