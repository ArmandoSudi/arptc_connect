import 'package:arptc_connect/modules/incident_management/domain/incident_dashboard_stats.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_enums.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_ticket.dart';
import 'package:intl/intl.dart';

class IncidentDashboardAggregator {
  const IncidentDashboardAggregator._();

  static IncidentDashboardStats buildUserStats(
    List<IncidentTicket> tickets,
    String currentUserId,
  ) {
    final scopedTickets = tickets
        .where((ticket) =>
            _notDeleted(ticket) &&
            (ticket.createdByUserId == currentUserId ||
                ticket.affectedUserId == currentUserId))
        .toList();
    final activeTickets = scopedTickets.where(_isActive).toList();

    return IncidentDashboardStats(
      totalOpenCount: activeTickets.length,
      ticketsByPriority: _priorityBuckets(activeTickets),
      ticketsByStatus: _statusBuckets(activeTickets),
      ticketsByService: _topGrouped(
        activeTickets,
        (ticket) => _labelOrFallback(ticket.affectedServiceName, 'No service'),
        limit: 8,
      ),
      ticketsByAgeBucket: _ageBuckets(activeTickets),
      activeTicketQueue: _sortOperationalQueue(activeTickets),
    );
  }

  static IncidentDashboardStats buildManagerStats(
    List<IncidentTicket> tickets,
    String currentUserId,
  ) {
    final cleanTickets = tickets.where(_notDeleted).toList();
    final activeTickets = cleanTickets.where(_isActive).toList();
    final closedTickets = cleanTickets.where(_isClosed).toList();
    final openTickets = activeTickets.where(_isOpen).toList()
      ..sort(_compareCreatedAscending);
    final unassignedTickets = activeTickets
        .where(_isAwaitingAssignment)
        .toList()
      ..sort(_compareCreatedAscending);
    final myAssignedTickets = activeTickets
        .where((ticket) =>
            currentUserId.trim().isNotEmpty &&
            ticket.assignedToUserId.trim() == currentUserId.trim())
        .toList()
      ..sort(_compareCreatedAscending);
    final solvedTickets = activeTickets.where(_isResolved).toList()
      ..sort(_compareCreatedAscending);

    return IncidentDashboardStats(
      totalOpenCount: openTickets.length,
      unassignedCount: unassignedTickets.length,
      assignedToMeCount: myAssignedTickets.length,
      criticalCount: activeTickets.where(_isCriticalPriority).length,
      solvedCount: solvedTickets.length,
      closedThisWeekCount: closedTickets
          .where((ticket) => _isWithinCurrentWeek(ticket.closedAt))
          .length,
      ticketsByPriority: _priorityBuckets(activeTickets),
      ticketsByStatus: _statusBuckets(activeTickets),
      ticketsByService: _topGrouped(
        activeTickets,
        (ticket) => _labelOrFallback(ticket.affectedServiceName, 'No service'),
        limit: 8,
      ),
      ticketsByAgeBucket: _ageBuckets(activeTickets),
      openTickets: openTickets,
      unassignedTickets: unassignedTickets,
      solvedTickets: solvedTickets,
      activeTicketQueue: _sortOperationalQueue(activeTickets),
      myAssignedTickets: myAssignedTickets,
    );
  }

  static IncidentDashboardStats buildAdminStats(List<IncidentTicket> tickets) {
    final cleanTickets = tickets.where(_notDeleted).toList();
    final currentMonthTickets =
        cleanTickets.where(_isWithinCurrentMonth).toList();
    final closedTickets = cleanTickets.where(_isClosed).toList();
    final recentCriticalTickets = cleanTickets
        .where(_isCriticalPriority)
        .toList()
      ..sort(_compareCreatedDescending);

    return IncidentDashboardStats(
      totalThisMonthCount: currentMonthTickets.length,
      openCount: cleanTickets.where(_isActive).length,
      closedCount: closedTickets.length,
      archivedCount: cleanTickets.where(_isArchived).length,
      averageResolutionTimeMinutes:
          _averageResolutionTimeMinutes(closedTickets),
      monthlyIncidentTrend: _monthlyTrend(cleanTickets),
      ticketsByService: _topGrouped(
        currentMonthTickets,
        (ticket) => _labelOrFallback(ticket.affectedServiceName, 'No service'),
        limit: 10,
      ),
      ticketsByCategory: _topGrouped(
        currentMonthTickets,
        (ticket) => _labelOrFallback(ticket.categoryName, 'Uncategorized'),
        limit: 10,
      ),
      ticketsByDepartment: _topGrouped(
        currentMonthTickets,
        (ticket) => _labelOrFallback(
          ticket.createdByDepartmentName,
          'No department',
        ),
        limit: 10,
      ),
      ticketsByPriority: _priorityBuckets(currentMonthTickets),
      recentCriticalTickets: recentCriticalTickets.take(5).toList(),
    );
  }

  static bool _notDeleted(IncidentTicket ticket) => !ticket.isDeleted;

  static bool _isActive(IncidentTicket ticket) =>
      ticket.lifecycleState == IncidentLifecycleState.active.value;

  static bool _isClosed(IncidentTicket ticket) =>
      ticket.lifecycleState == IncidentLifecycleState.closed.value;

  static bool _isArchived(IncidentTicket ticket) =>
      ticket.lifecycleState == IncidentLifecycleState.archived.value;

  static bool _isOpen(IncidentTicket ticket) =>
      ticket.status == IncidentStatus.open.value;

  static bool _isResolved(IncidentTicket ticket) =>
      ticket.status == IncidentStatus.resolved.value;

  static bool _isAwaitingAssignment(IncidentTicket ticket) {
    if (ticket.assignedToUserId.trim().isNotEmpty || !_isActive(ticket)) {
      return false;
    }
    return ticket.status == IncidentStatus.inProgress.value ||
        ticket.status == IncidentStatus.categorized.value;
  }

  static bool _isCriticalPriority(IncidentTicket ticket) {
    final priority = IncidentPriority.fromValue(ticket.priority);
    return priority == IncidentPriority.p1 || priority == IncidentPriority.p2;
  }

  static Map<String, num> _priorityBuckets(List<IncidentTicket> tickets) {
    final buckets = <String, num>{
      'P1': 0,
      'P2': 0,
      'P3': 0,
      'P4': 0,
      'Unprioritized': 0,
    };

    for (final ticket in tickets) {
      final label = _priorityLabel(ticket.priority);
      buckets[label] = (buckets[label] ?? 0) + 1;
    }
    return buckets;
  }

  static Map<String, num> _statusBuckets(List<IncidentTicket> tickets) {
    final buckets = <String, num>{
      IncidentStatus.open.value: 0,
      IncidentStatus.categorized.value: 0,
      IncidentStatus.assigned.value: 0,
      IncidentStatus.inProgress.value: 0,
      IncidentStatus.resolved.value: 0,
    };

    for (final ticket in tickets) {
      if (buckets.containsKey(ticket.status)) {
        buckets[ticket.status] = (buckets[ticket.status] ?? 0) + 1;
      }
    }
    return buckets;
  }

  static Map<String, num> _ageBuckets(List<IncidentTicket> tickets) {
    final now = DateTime.now();
    final buckets = <String, num>{
      '0-4h': 0,
      '4-24h': 0,
      '1-2d': 0,
      '3-7d': 0,
      '>7d': 0,
    };

    for (final ticket in tickets) {
      final createdAt = ticket.createdAt?.toLocal() ?? now;
      final age = now.difference(createdAt);
      final label = age.inHours < 4
          ? '0-4h'
          : age.inHours < 24
              ? '4-24h'
              : age.inDays <= 2
                  ? '1-2d'
                  : age.inDays <= 7
                      ? '3-7d'
                      : '>7d';
      buckets[label] = (buckets[label] ?? 0) + 1;
    }
    return buckets;
  }

  static Map<String, num> _topGrouped(
    List<IncidentTicket> tickets,
    String Function(IncidentTicket ticket) labelFor, {
    required int limit,
  }) {
    final grouped = <String, num>{};
    for (final ticket in tickets) {
      final label = labelFor(ticket);
      grouped[label] = (grouped[label] ?? 0) + 1;
    }

    final entries = grouped.entries.toList()
      ..sort((left, right) {
        final countCompare = right.value.compareTo(left.value);
        if (countCompare != 0) {
          return countCompare;
        }
        return left.key.toLowerCase().compareTo(right.key.toLowerCase());
      });

    if (entries.length <= limit) {
      return Map<String, num>.fromEntries(entries);
    }

    final visible = entries.take(limit).toList();
    final otherTotal = entries.skip(limit).fold<num>(
          0,
          (sum, entry) => sum + entry.value,
        );
    return Map<String, num>.fromEntries([
      ...visible,
      if (otherTotal > 0) MapEntry('Other', otherTotal),
    ]);
  }

  static List<ChartPoint> _monthlyTrend(List<IncidentTicket> tickets) {
    final now = DateTime.now();
    final months = List.generate(
      6,
      (index) => DateTime(now.year, now.month - 5 + index),
    );
    final counts = <String, int>{
      for (final month in months) _monthKey(month): 0,
    };

    for (final ticket in tickets) {
      final createdAt = ticket.createdAt?.toLocal();
      if (createdAt == null) {
        continue;
      }
      final key = _monthKey(createdAt);
      if (counts.containsKey(key)) {
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }

    final formatter = DateFormat('MMM');
    return months
        .map(
          (month) => ChartPoint(
            label: formatter.format(month),
            value: counts[_monthKey(month)] ?? 0,
          ),
        )
        .toList();
  }

  static List<IncidentTicket> _sortOperationalQueue(
    List<IncidentTicket> tickets,
  ) {
    return [...tickets]..sort((left, right) {
        final priorityCompare = _priorityRank(left.priority)
            .compareTo(_priorityRank(right.priority));
        if (priorityCompare != 0) {
          return priorityCompare;
        }
        return _compareCreatedAscending(left, right);
      });
  }

  static bool _isWithinCurrentWeek(DateTime? date) {
    if (date == null) {
      return false;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    final value = date.toLocal();
    return !value.isBefore(startOfWeek) && value.isBefore(endOfWeek);
  }

  static bool _isWithinCurrentMonth(IncidentTicket ticket) {
    final createdAt = ticket.createdAt?.toLocal();
    if (createdAt == null) {
      return false;
    }
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final nextMonthStart = DateTime(now.year, now.month + 1);
    return !createdAt.isBefore(monthStart) &&
        createdAt.isBefore(nextMonthStart);
  }

  static double _averageResolutionTimeMinutes(List<IncidentTicket> tickets) {
    final durations = tickets
        .where((ticket) => ticket.createdAt != null && ticket.closedAt != null)
        .map((ticket) =>
            ticket.closedAt!.difference(ticket.createdAt!).inMinutes)
        .where((minutes) => minutes >= 0)
        .toList();

    if (durations.isEmpty) {
      return 0;
    }

    final total = durations.fold<int>(0, (sum, minutes) => sum + minutes);
    return total / durations.length;
  }

  static int _compareCreatedAscending(
    IncidentTicket left,
    IncidentTicket right,
  ) {
    final leftDate = left.createdAt;
    final rightDate = right.createdAt;
    if (leftDate == null && rightDate == null) {
      return 0;
    }
    if (leftDate == null) {
      return 1;
    }
    if (rightDate == null) {
      return -1;
    }
    return leftDate.compareTo(rightDate);
  }

  static int _compareCreatedDescending(
    IncidentTicket left,
    IncidentTicket right,
  ) {
    final leftDate = left.createdAt;
    final rightDate = right.createdAt;
    if (leftDate == null && rightDate == null) {
      return 0;
    }
    if (leftDate == null) {
      return 1;
    }
    if (rightDate == null) {
      return -1;
    }
    return rightDate.compareTo(leftDate);
  }

  static int _priorityRank(String priority) {
    switch (IncidentPriority.fromValue(priority)) {
      case IncidentPriority.p1:
        return 0;
      case IncidentPriority.p2:
        return 1;
      case IncidentPriority.p3:
        return 2;
      case IncidentPriority.p4:
        return 3;
      case IncidentPriority.none:
        return 4;
    }
  }

  static String _priorityLabel(String priority) {
    switch (IncidentPriority.fromValue(priority)) {
      case IncidentPriority.p1:
        return 'P1';
      case IncidentPriority.p2:
        return 'P2';
      case IncidentPriority.p3:
        return 'P3';
      case IncidentPriority.p4:
        return 'P4';
      case IncidentPriority.none:
        return 'Unprioritized';
    }
  }

  static String _labelOrFallback(String value, String fallback) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }

  static String _monthKey(DateTime date) => '${date.year}-${date.month}';
}
