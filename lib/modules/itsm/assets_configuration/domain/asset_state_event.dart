import 'package:cloud_firestore/cloud_firestore.dart';

import 'assets_configuration_serialization.dart';

class AssetStateEvent {
  AssetStateEvent({
    required String id,
    required String assetId,
    required String toStateId,
    required String toStateName,
    required String observation,
    required String actorUserId,
    required String actorName,
    required DateTime changedAt,
    required this.revision,
    this.fromStateId = '',
    this.fromStateName = '',
  })  : id = requireItsmAssetText(id, 'id'),
        assetId = requireItsmAssetText(assetId, 'assetId'),
        toStateId = requireItsmAssetText(toStateId, 'toStateId'),
        toStateName = requireItsmAssetText(toStateName, 'toStateName'),
        observation = requireItsmAssetText(observation, 'observation'),
        actorUserId = requireItsmAssetText(actorUserId, 'actorUserId'),
        actorName = actorName.trim(),
        changedAt = changedAt.toUtc();

  final String id;
  final String assetId;
  final String fromStateId;
  final String fromStateName;
  final String toStateId;
  final String toStateName;
  final String observation;
  final String actorUserId;
  final String actorName;
  final DateTime changedAt;
  final int revision;

  factory AssetStateEvent.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) =>
      AssetStateEvent.fromMap(snapshot.id, snapshot.data() ?? const {});

  factory AssetStateEvent.fromMap(
    String id,
    Map<String, Object?> data,
  ) {
    final actor = itsmAssetMap(data['actor']);
    return AssetStateEvent(
      id: id,
      assetId: itsmAssetString(data, 'assetId'),
      fromStateId: itsmAssetString(data, 'fromStateId'),
      fromStateName: itsmAssetString(data, 'fromStateName'),
      toStateId: itsmAssetString(data, 'toStateId'),
      toStateName: itsmAssetString(data, 'toStateName'),
      observation: itsmAssetString(data, 'observation'),
      actorUserId: itsmAssetString(actor, 'userId'),
      actorName: itsmAssetString(actor, 'name'),
      changedAt: itsmAssetDate(data['changedAt']) ?? DateTime.utc(1970),
      revision: itsmAssetInt(data, 'revision'),
    );
  }

  Map<String, Object?> toFirestore() => {
        'assetId': assetId,
        'fromStateId': fromStateId.isEmpty ? null : fromStateId,
        'fromStateName': fromStateName.isEmpty ? null : fromStateName,
        'toStateId': toStateId,
        'toStateName': toStateName,
        'observation': observation,
        'actor': {
          'userId': actorUserId,
          'name': actorName,
        },
        'changedAt': itsmAssetTimestamp(changedAt),
        'revision': revision,
      };
}
