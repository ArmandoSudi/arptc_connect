import 'package:arptc_connect/modules/incident_management/domain/incident_ticket.dart';

class ChartPoint {
  const ChartPoint({
    required this.label,
    required this.value,
  });

  final String label;
  final num value;
}

class IncidentDashboardStats {
  const IncidentDashboardStats({
    this.totalOpenCount = 0,
    this.unassignedCount = 0,
    this.assignedToMeCount = 0,
    this.criticalCount = 0,
    this.solvedCount = 0,
    this.closedThisWeekCount = 0,
    this.totalThisMonthCount = 0,
    this.openCount = 0,
    this.closedCount = 0,
    this.archivedCount = 0,
    this.averageResolutionTimeMinutes = 0,
    this.ticketsByPriority = const <String, num>{},
    this.ticketsByStatus = const <String, num>{},
    this.ticketsByService = const <String, num>{},
    this.ticketsByAgeBucket = const <String, num>{},
    this.ticketsByCategory = const <String, num>{},
    this.ticketsByDepartment = const <String, num>{},
    this.monthlyIncidentTrend = const <ChartPoint>[],
    this.openTickets = const <IncidentTicket>[],
    this.unassignedTickets = const <IncidentTicket>[],
    this.solvedTickets = const <IncidentTicket>[],
    this.activeTicketQueue = const <IncidentTicket>[],
    this.myAssignedTickets = const <IncidentTicket>[],
    this.recentCriticalTickets = const <IncidentTicket>[],
  });

  final int totalOpenCount;
  final int unassignedCount;
  final int assignedToMeCount;
  final int criticalCount;
  final int solvedCount;
  final int closedThisWeekCount;

  final int totalThisMonthCount;
  final int openCount;
  final int closedCount;
  final int archivedCount;
  final double averageResolutionTimeMinutes;

  final Map<String, num> ticketsByPriority;
  final Map<String, num> ticketsByStatus;
  final Map<String, num> ticketsByService;
  final Map<String, num> ticketsByAgeBucket;
  final Map<String, num> ticketsByCategory;
  final Map<String, num> ticketsByDepartment;
  final List<ChartPoint> monthlyIncidentTrend;

  final List<IncidentTicket> openTickets;
  final List<IncidentTicket> unassignedTickets;
  final List<IncidentTicket> solvedTickets;
  final List<IncidentTicket> activeTicketQueue;
  final List<IncidentTicket> myAssignedTickets;
  final List<IncidentTicket> recentCriticalTickets;
}
