import 'dart:collection';

import 'itsm_common.dart';

class BusinessHoursWindow {
  BusinessHoursWindow({
    required this.start,
    required this.end,
  }) {
    if (start.isNegative ||
        end.isNegative ||
        start >= const Duration(days: 1) ||
        end > const Duration(days: 1) ||
        start >= end) {
      throw ArgumentError('Business-hours windows must be within one day.');
    }
  }

  final Duration start;
  final Duration end;
}

class BusinessCalendar {
  BusinessCalendar({
    required Map<int, Iterable<BusinessHoursWindow>> weeklyWindows,
    Iterable<DateTime> holidays = const [],
  })  : weeklyWindows = UnmodifiableMapView(
          weeklyWindows.map(
            (weekday, windows) {
              if (weekday < DateTime.monday || weekday > DateTime.sunday) {
                throw RangeError.range(
                  weekday,
                  DateTime.monday,
                  DateTime.sunday,
                  'weekday',
                );
              }
              final sorted = windows.toList()
                ..sort((left, right) => left.start.compareTo(right.start));
              for (var index = 1; index < sorted.length; index++) {
                if (sorted[index].start < sorted[index - 1].end) {
                  throw ArgumentError(
                    'Business-hours windows cannot overlap.',
                  );
                }
              }
              return MapEntry(
                weekday,
                List<BusinessHoursWindow>.unmodifiable(sorted),
              );
            },
          ),
        ),
        holidayKeys = Set<String>.unmodifiable(holidays.map(_dateKey)) {
    if (this.weeklyWindows.values.every((windows) => windows.isEmpty)) {
      throw ArgumentError('A business calendar needs working hours.');
    }
  }

  factory BusinessCalendar.standardWeek({
    Duration start = const Duration(hours: 8),
    Duration end = const Duration(hours: 17),
    Iterable<DateTime> holidays = const [],
  }) {
    return BusinessCalendar(
      weeklyWindows: {
        for (var day = DateTime.monday; day <= DateTime.friday; day++)
          day: [BusinessHoursWindow(start: start, end: end)],
      },
      holidays: holidays,
    );
  }

  final Map<int, List<BusinessHoursWindow>> weeklyWindows;
  final Set<String> holidayKeys;

  bool isHoliday(DateTime date) => holidayKeys.contains(_dateKey(date));

  DateTime addWorkingDuration(DateTime start, Duration duration) {
    if (duration.isNegative) {
      throw ArgumentError.value(
        duration,
        'duration',
        'Working duration cannot be negative.',
      );
    }
    if (duration == Duration.zero) return start;

    var remaining = duration;
    var cursor = start;
    for (var dayGuard = 0; dayGuard < 36600; dayGuard++) {
      if (!isHoliday(cursor)) {
        final windows =
            weeklyWindows[cursor.weekday] ?? const <BusinessHoursWindow>[];
        for (final window in windows) {
          final windowStart = _atTime(cursor, window.start);
          final windowEnd = _atTime(cursor, window.end);
          final candidate = cursor.isAfter(windowStart) ? cursor : windowStart;
          if (!candidate.isBefore(windowEnd)) continue;

          final available = windowEnd.difference(candidate);
          if (remaining <= available) return candidate.add(remaining);
          remaining -= available;
        }
      }
      cursor = _nextDay(cursor);
    }
    throw StateError('Unable to calculate an SLA date within 100 years.');
  }

  Duration workingDurationBetween(DateTime start, DateTime end) {
    if (!end.isAfter(start)) return Duration.zero;

    var total = Duration.zero;
    var day = _startOfDay(start);
    final lastDay = _startOfDay(end);
    while (!day.isAfter(lastDay)) {
      if (!isHoliday(day)) {
        final windows =
            weeklyWindows[day.weekday] ?? const <BusinessHoursWindow>[];
        for (final window in windows) {
          final windowStart = _atTime(day, window.start);
          final windowEnd = _atTime(day, window.end);
          final overlapStart = start.isAfter(windowStart) ? start : windowStart;
          final overlapEnd = end.isBefore(windowEnd) ? end : windowEnd;
          if (overlapEnd.isAfter(overlapStart)) {
            total += overlapEnd.difference(overlapStart);
          }
        }
      }
      day = _nextDay(day);
    }
    return total;
  }
}

class SlaEscalationRule {
  const SlaEscalationRule({
    required this.eventName,
    this.assignmentGroupId,
  });

  final String eventName;
  final String? assignmentGroupId;
}

class SlaPolicy {
  SlaPolicy({
    required this.id,
    required this.name,
    required this.workItemType,
    required this.version,
    required this.publicationState,
    required this.responseTarget,
    required this.resolutionTarget,
    required this.calendar,
    this.priority,
    this.serviceId,
    this.warningThreshold = 0.8,
    Iterable<String> pauseStatuses = const [],
    this.escalationRule,
  }) : pauseStatuses = Set<String>.unmodifiable(pauseStatuses) {
    if (id.trim().isEmpty || name.trim().isEmpty) {
      throw ArgumentError('SLA policy ID and name are required.');
    }
    if (version < 1) throw RangeError.value(version, 'version');
    if (responseTarget <= Duration.zero ||
        resolutionTarget <= Duration.zero ||
        resolutionTarget < responseTarget) {
      throw ArgumentError(
        'SLA targets must be positive and resolution cannot precede response.',
      );
    }
    if (warningThreshold <= 0 || warningThreshold >= 1) {
      throw RangeError.range(warningThreshold, 0, 1, 'warningThreshold');
    }
  }

  final String id;
  final String name;
  final ItsmWorkItemType workItemType;
  final int version;
  final ItsmPublicationState publicationState;
  final ItsmPriority? priority;
  final String? serviceId;
  final Duration responseTarget;
  final Duration resolutionTarget;
  final BusinessCalendar calendar;
  final double warningThreshold;
  final Set<String> pauseStatuses;
  final SlaEscalationRule? escalationRule;
}

enum SlaComplianceStatus { onTrack, atRisk, breached, paused, met }

class SlaMeasurement {
  const SlaMeasurement({
    required this.status,
    required this.dueAt,
    required this.elapsed,
    required this.remaining,
  });

  final SlaComplianceStatus status;
  final DateTime dueAt;
  final Duration elapsed;
  final Duration remaining;
}

class SlaState {
  const SlaState({
    required this.startedAt,
    required this.responseDueAt,
    required this.resolutionDueAt,
    this.pausedAt,
    this.accumulatedPausedBusinessTime = Duration.zero,
    this.respondedAt,
    this.resolvedAt,
  });

  final DateTime startedAt;
  final DateTime responseDueAt;
  final DateTime resolutionDueAt;
  final DateTime? pausedAt;
  final Duration accumulatedPausedBusinessTime;
  final DateTime? respondedAt;
  final DateTime? resolvedAt;

  bool get isPaused => pausedAt != null;
  bool get isResolved => resolvedAt != null;
}

abstract final class SlaCalculator {
  static SlaState start({
    required SlaPolicy policy,
    required DateTime startedAt,
  }) {
    return SlaState(
      startedAt: startedAt,
      responseDueAt:
          policy.calendar.addWorkingDuration(startedAt, policy.responseTarget),
      resolutionDueAt: policy.calendar
          .addWorkingDuration(startedAt, policy.resolutionTarget),
    );
  }

  static SlaState pause(SlaState state, DateTime pausedAt) {
    if (state.isResolved) {
      throw StateError('A resolved SLA cannot be paused.');
    }
    if (state.isPaused) return state;
    if (pausedAt.isBefore(state.startedAt)) {
      throw ArgumentError('Pause time cannot precede SLA start.');
    }
    return _copyState(state, pausedAt: pausedAt);
  }

  static SlaState resume({
    required SlaPolicy policy,
    required SlaState state,
    required DateTime resumedAt,
  }) {
    final pausedAt = state.pausedAt;
    if (pausedAt == null) return state;
    if (resumedAt.isBefore(pausedAt)) {
      throw ArgumentError('Resume time cannot precede pause time.');
    }

    final pausedBusinessTime =
        policy.calendar.workingDurationBetween(pausedAt, resumedAt);
    return SlaState(
      startedAt: state.startedAt,
      responseDueAt: state.respondedAt == null
          ? policy.calendar
              .addWorkingDuration(state.responseDueAt, pausedBusinessTime)
          : state.responseDueAt,
      resolutionDueAt: policy.calendar
          .addWorkingDuration(state.resolutionDueAt, pausedBusinessTime),
      accumulatedPausedBusinessTime:
          state.accumulatedPausedBusinessTime + pausedBusinessTime,
      respondedAt: state.respondedAt,
      resolvedAt: state.resolvedAt,
    );
  }

  static SlaState recordResponse(SlaState state, DateTime respondedAt) {
    if (respondedAt.isBefore(state.startedAt)) {
      throw ArgumentError('Response time cannot precede SLA start.');
    }
    return _copyState(state, respondedAt: respondedAt);
  }

  static SlaState recordResolution(SlaState state, DateTime resolvedAt) {
    if (resolvedAt.isBefore(state.startedAt)) {
      throw ArgumentError('Resolution time cannot precede SLA start.');
    }
    return _copyState(state, resolvedAt: resolvedAt);
  }

  static SlaMeasurement responseMeasurement({
    required SlaPolicy policy,
    required SlaState state,
    required DateTime now,
  }) {
    return _measure(
      policy: policy,
      state: state,
      now: now,
      dueAt: state.responseDueAt,
      target: policy.responseTarget,
      completedAt: state.respondedAt,
    );
  }

  static SlaMeasurement resolutionMeasurement({
    required SlaPolicy policy,
    required SlaState state,
    required DateTime now,
  }) {
    return _measure(
      policy: policy,
      state: state,
      now: now,
      dueAt: state.resolutionDueAt,
      target: policy.resolutionTarget,
      completedAt: state.resolvedAt,
    );
  }

  static SlaMeasurement _measure({
    required SlaPolicy policy,
    required SlaState state,
    required DateTime now,
    required DateTime dueAt,
    required Duration target,
    required DateTime? completedAt,
  }) {
    final effectiveAt = completedAt ?? state.pausedAt ?? now;
    final rawElapsed =
        policy.calendar.workingDurationBetween(state.startedAt, effectiveAt);
    final elapsed = rawElapsed > state.accumulatedPausedBusinessTime
        ? rawElapsed - state.accumulatedPausedBusinessTime
        : Duration.zero;
    final remaining = elapsed < target ? target - elapsed : Duration.zero;

    late final SlaComplianceStatus status;
    if (completedAt != null) {
      status = completedAt.isAfter(dueAt)
          ? SlaComplianceStatus.breached
          : SlaComplianceStatus.met;
    } else if (state.isPaused) {
      status = SlaComplianceStatus.paused;
    } else if (!now.isBefore(dueAt)) {
      status = SlaComplianceStatus.breached;
    } else {
      final progress = elapsed.inMicroseconds / target.inMicroseconds;
      status = progress >= policy.warningThreshold
          ? SlaComplianceStatus.atRisk
          : SlaComplianceStatus.onTrack;
    }

    return SlaMeasurement(
      status: status,
      dueAt: dueAt,
      elapsed: elapsed,
      remaining: remaining,
    );
  }
}

SlaState _copyState(
  SlaState state, {
  DateTime? pausedAt,
  DateTime? respondedAt,
  DateTime? resolvedAt,
}) {
  return SlaState(
    startedAt: state.startedAt,
    responseDueAt: state.responseDueAt,
    resolutionDueAt: state.resolutionDueAt,
    pausedAt: pausedAt ?? state.pausedAt,
    accumulatedPausedBusinessTime: state.accumulatedPausedBusinessTime,
    respondedAt: respondedAt ?? state.respondedAt,
    resolvedAt: resolvedAt ?? state.resolvedAt,
  );
}

String _dateKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

DateTime _startOfDay(DateTime date) {
  return date.isUtc
      ? DateTime.utc(date.year, date.month, date.day)
      : DateTime(date.year, date.month, date.day);
}

DateTime _atTime(DateTime date, Duration time) {
  return _startOfDay(date).add(time);
}

DateTime _nextDay(DateTime date) {
  final start = _startOfDay(date);
  return start.isUtc
      ? DateTime.utc(start.year, start.month, start.day + 1)
      : DateTime(start.year, start.month, start.day + 1);
}
