import 'package:cloud_firestore/cloud_firestore.dart';

import 'asset.dart';
import 'assets_configuration_serialization.dart';

enum AssetAssignmentStatus {
  current,
  returned,
  transferred,
  cancelled;

  static AssetAssignmentStatus fromValue(Object? value) => values.firstWhere(
        (status) => status.name == value?.toString().toLowerCase(),
        orElse: () => AssetAssignmentStatus.current,
      );
}

class AssetAssignment {
  AssetAssignment({
    required String id,
    required String assetId,
    required String assetTag,
    required String assetType,
    required String assetBrand,
    required String assetModel,
    required String assignedUserId,
    required String assignedUserName,
    required this.status,
    required DateTime assignedAt,
    required String assignedByUserId,
    this.assignmentReason = '',
    this.departmentId = '',
    this.departmentName = '',
    this.locationName = '',
    this.assetStatus = AssetStatus.assigned,
    this.assetCondition = AssetCondition.good,
    DateTime? returnedAt,
    this.returnedToUserId = '',
  })  : id = requireItsmAssetText(id, 'id'),
        assetId = requireItsmAssetText(assetId, 'assetId'),
        assetTag = requireItsmAssetText(assetTag, 'assetTag'),
        assetType = requireItsmAssetText(assetType, 'assetType'),
        assetBrand = assetBrand.trim(),
        assetModel = assetModel.trim(),
        assignedUserId = requireItsmAssetText(
          assignedUserId,
          'assignedUserId',
        ),
        assignedUserName = assignedUserName.trim(),
        assignedByUserId = requireItsmAssetText(
          assignedByUserId,
          'assignedByUserId',
        ),
        assignedAt = assignedAt.toUtc(),
        returnedAt = returnedAt?.toUtc() {
    if (status == AssetAssignmentStatus.current && returnedAt != null) {
      throw ArgumentError('A current assignment cannot have returnedAt.');
    }
    if (status != AssetAssignmentStatus.current && returnedAt == null) {
      throw ArgumentError('A completed assignment requires returnedAt.');
    }
  }

  final String id;
  final String assetId;
  final String assetTag;
  final String assetType;
  final String assetBrand;
  final String assetModel;
  final String assignedUserId;
  final String assignedUserName;
  final String assignedByUserId;
  final String assignmentReason;
  final String departmentId;
  final String departmentName;
  final String locationName;
  final AssetAssignmentStatus status;
  final AssetStatus assetStatus;
  final AssetCondition assetCondition;
  final DateTime assignedAt;
  final DateTime? returnedAt;
  final String returnedToUserId;

  bool get isCurrent => status == AssetAssignmentStatus.current;

  String get assetDisplayName => [assetBrand, assetModel]
      .where((part) => part.trim().isNotEmpty)
      .join(' ')
      .trim();

  factory AssetAssignment.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) =>
      AssetAssignment.fromMap(snapshot.id, snapshot.data() ?? const {});

  factory AssetAssignment.fromMap(
    String id,
    Map<String, Object?> data,
  ) =>
      AssetAssignment(
        id: id,
        assetId: itsmAssetString(data, 'assetId'),
        assetTag: itsmAssetString(data, 'assetTag'),
        assetType: itsmAssetString(data, 'assetType'),
        assetBrand: itsmAssetString(data, 'assetBrand'),
        assetModel: itsmAssetString(data, 'assetModel'),
        assignedUserId: itsmAssetString(data, 'assignedUserId'),
        assignedUserName: itsmAssetString(data, 'assignedUserName'),
        assignedByUserId: itsmAssetString(data, 'assignedByUserId'),
        assignmentReason: itsmAssetString(data, 'assignmentReason'),
        departmentId: itsmAssetString(data, 'departmentId'),
        departmentName: itsmAssetString(data, 'departmentName'),
        locationName: itsmAssetString(data, 'locationName'),
        status: AssetAssignmentStatus.fromValue(data['status']),
        assetStatus: AssetStatus.fromValue(data['assetStatus']),
        assetCondition: AssetCondition.fromValue(data['assetCondition']),
        assignedAt: itsmAssetDate(data['assignedAt']) ?? DateTime.utc(1970),
        returnedAt: itsmAssetDate(data['returnedAt']),
        returnedToUserId: itsmAssetString(data, 'returnedToUserId'),
      );

  Map<String, Object?> toFirestore() => {
        'assetId': assetId,
        'assetTag': assetTag,
        'assetType': assetType,
        'assetBrand': assetBrand,
        'assetModel': assetModel,
        'assignedUserId': assignedUserId,
        'assignedUserName': assignedUserName,
        'assignedByUserId': assignedByUserId,
        'assignmentReason': assignmentReason,
        'departmentId': departmentId,
        'departmentName': departmentName,
        'locationName': locationName,
        'status': status.name,
        'assetStatus': assetStatus.value,
        'assetCondition': assetCondition.value,
        'assignedAt': itsmAssetTimestamp(assignedAt),
        'returnedAt': itsmAssetTimestamp(returnedAt),
        'returnedToUserId': returnedToUserId,
      };
}
