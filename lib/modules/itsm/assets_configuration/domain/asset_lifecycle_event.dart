import 'package:cloud_firestore/cloud_firestore.dart';

import 'asset.dart';
import 'assets_configuration_serialization.dart';

enum AssetLifecycleEventType {
  created,
  ordered,
  received,
  configured,
  assigned,
  transferred,
  maintenanceStarted,
  maintenanceCompleted,
  returned,
  retired,
  disposed,
  reportedLost,
  reportedStolen,
  recovered;

  String get value => switch (this) {
        AssetLifecycleEventType.maintenanceStarted => 'maintenance_started',
        AssetLifecycleEventType.maintenanceCompleted => 'maintenance_completed',
        AssetLifecycleEventType.reportedLost => 'reported_lost',
        AssetLifecycleEventType.reportedStolen => 'reported_stolen',
        _ => name,
      };

  static AssetLifecycleEventType fromValue(Object? value) => values.firstWhere(
        (event) => event.value == value?.toString().toLowerCase(),
        orElse: () => AssetLifecycleEventType.created,
      );
}

class AssetLifecycleEvent {
  AssetLifecycleEvent({
    required String id,
    required String assetId,
    required this.type,
    required this.fromStatus,
    required this.toStatus,
    required String actorUserId,
    required String actorName,
    required DateTime occurredAt,
    this.reason = '',
    this.relatedRequestId = '',
    this.assignmentId = '',
    this.stockMovementId = '',
    Iterable<String> attachmentIds = const [],
  })  : id = requireItsmAssetText(id, 'id'),
        assetId = requireItsmAssetText(assetId, 'assetId'),
        actorUserId = requireItsmAssetText(actorUserId, 'actorUserId'),
        actorName = actorName.trim(),
        occurredAt = occurredAt.toUtc(),
        attachmentIds = immutableItsmAssetIds(attachmentIds);

  final String id;
  final String assetId;
  final AssetLifecycleEventType type;
  final AssetStatus fromStatus;
  final AssetStatus toStatus;
  final String actorUserId;
  final String actorName;
  final DateTime occurredAt;
  final String reason;
  final String relatedRequestId;
  final String assignmentId;
  final String stockMovementId;
  final List<String> attachmentIds;

  factory AssetLifecycleEvent.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) =>
      AssetLifecycleEvent.fromMap(snapshot.id, snapshot.data() ?? const {});

  factory AssetLifecycleEvent.fromMap(
    String id,
    Map<String, Object?> data,
  ) {
    final actor = itsmAssetMap(data['actor']);
    final fromStatus = AssetStatus.fromValue(data['fromStatus']);
    final toStatus = AssetStatus.fromValue(data['toStatus']);
    return AssetLifecycleEvent(
      id: id,
      assetId: itsmAssetString(data, 'assetId'),
      type: _assetLifecycleEventType(data['type'], fromStatus, toStatus),
      fromStatus: fromStatus,
      toStatus: toStatus,
      actorUserId: itsmAssetString(data, 'actorUserId').isNotEmpty
          ? itsmAssetString(data, 'actorUserId')
          : itsmAssetString(actor, 'userId'),
      actorName: itsmAssetString(data, 'actorName').isNotEmpty
          ? itsmAssetString(data, 'actorName')
          : itsmAssetString(actor, 'name'),
      occurredAt: itsmAssetDate(data['occurredAt']) ?? DateTime.utc(1970),
      reason: itsmAssetString(data, 'reason'),
      relatedRequestId: itsmAssetString(data, 'relatedRequestId'),
      assignmentId: itsmAssetString(data, 'assignmentId'),
      stockMovementId: itsmAssetString(data, 'stockMovementId'),
      attachmentIds: _assetLifecycleAttachmentIds(data),
    );
  }

  Map<String, Object?> toFirestore() => {
        'assetId': assetId,
        'type': type.value,
        'fromStatus': fromStatus.value,
        'toStatus': toStatus.value,
        'actorUserId': actorUserId,
        'actorName': actorName,
        'occurredAt': itsmAssetTimestamp(occurredAt),
        'reason': reason,
        'relatedRequestId': relatedRequestId,
        'assignmentId': assignmentId,
        'stockMovementId': stockMovementId,
        'attachmentIds': attachmentIds,
      };
}

AssetLifecycleEventType _assetLifecycleEventType(
  Object? explicitType,
  AssetStatus fromStatus,
  AssetStatus toStatus,
) {
  if (explicitType != null && explicitType.toString().trim().isNotEmpty) {
    return AssetLifecycleEventType.fromValue(explicitType);
  }
  if (toStatus == AssetStatus.inMaintenance) {
    return AssetLifecycleEventType.maintenanceStarted;
  }
  if (fromStatus == AssetStatus.inMaintenance) {
    return AssetLifecycleEventType.maintenanceCompleted;
  }
  if (toStatus == AssetStatus.lost) {
    return AssetLifecycleEventType.reportedLost;
  }
  if (toStatus == AssetStatus.stolen) {
    return AssetLifecycleEventType.reportedStolen;
  }
  if ((fromStatus == AssetStatus.lost || fromStatus == AssetStatus.stolen) &&
      toStatus == AssetStatus.returned) {
    return AssetLifecycleEventType.recovered;
  }
  return switch (toStatus) {
    AssetStatus.ordered => AssetLifecycleEventType.ordered,
    AssetStatus.received ||
    AssetStatus.inStock =>
      AssetLifecycleEventType.received,
    AssetStatus.configured => AssetLifecycleEventType.configured,
    AssetStatus.assigned => AssetLifecycleEventType.assigned,
    AssetStatus.returned => AssetLifecycleEventType.returned,
    AssetStatus.retired => AssetLifecycleEventType.retired,
    AssetStatus.disposed => AssetLifecycleEventType.disposed,
    _ => AssetLifecycleEventType.created,
  };
}

List<String> _assetLifecycleAttachmentIds(Map<String, Object?> data) {
  final attachmentIds = <String>{
    ...itsmAssetStrings(data['attachmentIds']),
  };
  final evidence = data['evidence'];
  if (evidence is Iterable) {
    for (final item in evidence) {
      final attachmentId = itsmAssetString(itsmAssetMap(item), 'attachmentId');
      if (attachmentId.isNotEmpty) attachmentIds.add(attachmentId);
    }
  }
  return List.unmodifiable(attachmentIds);
}
