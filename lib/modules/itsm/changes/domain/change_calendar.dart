import 'dart:collection';

import 'change_request.dart';
import 'change_serialization.dart';

class ChangeCalendarEntry {
  ChangeCalendarEntry({
    required String changeId,
    required String changeNumber,
    required String title,
    required this.type,
    required this.status,
    required this.risk,
    required String requesterUserId,
    required this.window,
    this.maintenancePublished = false,
    this.hasConflict = false,
    this.conflictCount = 0,
    Iterable<String> affectedServiceIds = const [],
    Iterable<String> affectedCiIds = const [],
    Iterable<String> affectedAssetIds = const [],
  })  : changeId = requireChangeText(changeId, 'changeId'),
        changeNumber = requireChangeText(changeNumber, 'changeNumber'),
        title = requireChangeText(title, 'title'),
        requesterUserId = requireChangeText(requesterUserId, 'requesterUserId'),
        affectedServiceIds = _immutableSet(affectedServiceIds),
        affectedCiIds = _immutableSet(affectedCiIds),
        affectedAssetIds = _immutableSet(affectedAssetIds);

  factory ChangeCalendarEntry.fromChange(ChangeRequest change) {
    final window = change.plannedWindow;
    if (window == null) {
      throw ArgumentError('A calendar entry requires a planned window.');
    }
    return ChangeCalendarEntry(
      changeId: change.id,
      changeNumber: change.changeNumber,
      title: change.title,
      type: change.type,
      status: change.status,
      risk: change.risk,
      requesterUserId: change.requester.userId,
      window: window,
      maintenancePublished: change.isMaintenancePublished,
      affectedServiceIds: change.affectedServices.map((service) => service.id),
      affectedCiIds: change.affectedCiIds,
      affectedAssetIds: change.affectedAssetIds,
    );
  }

  factory ChangeCalendarEntry.fromMap(String id, Map<String, Object?> map) =>
      ChangeCalendarEntry(
        changeId: id,
        changeNumber: changeString(map['changeNumber'], id),
        title: changeString(map['title']),
        type: ChangeType.fromValue(map['changeType']),
        status: ChangeStatus.fromValue(map['status']),
        risk: ChangeRiskLevel.fromValue(map['risk']),
        requesterUserId: changeString(
          map['requesterUserId'] ?? map['requesterId'],
        ),
        window: _calendarWindow(map),
        maintenancePublished: changeBool(
          map['maintenancePublished'] ?? map['publishMaintenance'],
        ),
        hasConflict: changeBool(map['hasConflict']),
        conflictCount: changeInt(map['conflictCount']),
        affectedServiceIds: changeStringList(map['affectedServiceIds']),
        affectedCiIds: changeStringList(map['affectedCiIds']),
        affectedAssetIds: changeStringList(map['affectedAssetIds']),
      );

  final String changeId;
  final String changeNumber;
  final String title;
  final ChangeType type;
  final ChangeStatus status;
  final ChangeRiskLevel risk;
  final String requesterUserId;
  final ChangeWindow window;
  final bool maintenancePublished;
  final bool hasConflict;
  final int conflictCount;
  final Set<String> affectedServiceIds;
  final Set<String> affectedCiIds;
  final Set<String> affectedAssetIds;

  bool get participatesInConflictDetection =>
      status != ChangeStatus.cancelled &&
      status != ChangeStatus.rejected &&
      status != ChangeStatus.closed;

  Map<String, Object?> toFirestore() => UnmodifiableMapView({
        'changeNumber': changeNumber,
        'title': title,
        'changeType': type.value,
        'status': status.value,
        'risk': risk.value,
        'requesterId': requesterUserId,
        'window': window.toFirestore(),
        'plannedStartAt': window.startsAt,
        'plannedEndAt': window.endsAt,
        'publishMaintenance': maintenancePublished,
        'hasConflict': hasConflict,
        'conflictCount': conflictCount,
        'affectedServiceIds': affectedServiceIds.toList(growable: false),
        'affectedCiIds': affectedCiIds.toList(growable: false),
        'affectedAssetIds': affectedAssetIds.toList(growable: false),
      });
}

enum ChangeCalendarConflictKind { service, configurationItem, asset }

class ChangeCalendarConflict {
  ChangeCalendarConflict({
    required this.firstChangeId,
    required this.secondChangeId,
    required Iterable<ChangeCalendarConflictKind> kinds,
    required Iterable<String> sharedResourceIds,
  })  : kinds = Set<ChangeCalendarConflictKind>.unmodifiable(kinds),
        sharedResourceIds = Set<String>.unmodifiable(sharedResourceIds);

  final String firstChangeId;
  final String secondChangeId;
  final Set<ChangeCalendarConflictKind> kinds;
  final Set<String> sharedResourceIds;
}

abstract final class ChangeCalendarConflictDetector {
  static List<ChangeCalendarConflict> detect(
    Iterable<ChangeCalendarEntry> entries,
  ) {
    final active = entries
        .where((entry) => entry.participatesInConflictDetection)
        .toList(growable: false);
    final conflicts = <ChangeCalendarConflict>[];

    for (var leftIndex = 0; leftIndex < active.length; leftIndex++) {
      final left = active[leftIndex];
      for (var rightIndex = leftIndex + 1;
          rightIndex < active.length;
          rightIndex++) {
        final right = active[rightIndex];
        if (!left.window.overlaps(right.window)) continue;

        final services = left.affectedServiceIds.intersection(
          right.affectedServiceIds,
        );
        final cis = left.affectedCiIds.intersection(right.affectedCiIds);
        final assets = left.affectedAssetIds.intersection(
          right.affectedAssetIds,
        );
        final kinds = <ChangeCalendarConflictKind>{
          if (services.isNotEmpty) ChangeCalendarConflictKind.service,
          if (cis.isNotEmpty) ChangeCalendarConflictKind.configurationItem,
          if (assets.isNotEmpty) ChangeCalendarConflictKind.asset,
        };
        if (kinds.isEmpty) continue;

        conflicts.add(
          ChangeCalendarConflict(
            firstChangeId: left.changeId,
            secondChangeId: right.changeId,
            kinds: kinds,
            sharedResourceIds: {...services, ...cis, ...assets},
          ),
        );
      }
    }

    return List<ChangeCalendarConflict>.unmodifiable(conflicts);
  }
}

Set<String> _immutableSet(Iterable<String> values) => Set<String>.unmodifiable(
      values.map((value) => value.trim()).where((value) => value.isNotEmpty),
    );

ChangeWindow _calendarWindow(Map<String, Object?> map) {
  final nested = changeMapFromValue(map['window']);
  if (nested.isNotEmpty) return ChangeWindow.fromMap(nested);
  return ChangeWindow(
    startsAt: requireChangeDate(map['plannedStartAt'], 'plannedStartAt'),
    endsAt: requireChangeDate(map['plannedEndAt'], 'plannedEndAt'),
    expectedDowntimeMinutes: changeInt(map['expectedDowntimeMinutes']),
  );
}
