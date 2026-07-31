import 'package:cloud_firestore/cloud_firestore.dart';

import 'asset.dart';
import 'assets_configuration_serialization.dart';

/// Read model intentionally limited to fields safe for an asset custodian.
///
/// Firestore cannot hide fields within an authoritative asset document, so
/// USER and ADMIN self-service reads must use this projection exclusively.
class AssetSelfServiceProjection {
  AssetSelfServiceProjection({
    required String id,
    required String assetId,
    required String assignedUserId,
    required String assetTag,
    required String assetName,
    required String assetType,
    required this.status,
    required this.condition,
    required DateTime updatedAt,
    this.categoryName = '',
    this.brand = '',
    this.model = '',
    this.serialNumber = '',
    this.barcode = '',
    this.description = '',
    this.locationName = '',
    this.departmentName = '',
    this.assignedUserName = '',
    this.complianceState = 'assessment_pending',
    this.photoUrl,
    this.isCurrent = true,
  })  : id = requireItsmAssetText(id, 'id'),
        assetId = requireItsmAssetText(assetId, 'assetId'),
        assignedUserId = requireItsmAssetText(
          assignedUserId,
          'assignedUserId',
        ),
        assetTag = requireItsmAssetText(assetTag, 'assetTag'),
        assetName = assetName.trim(),
        assetType = requireItsmAssetText(assetType, 'assetType'),
        updatedAt = updatedAt.toUtc();

  final String id;
  final String assetId;
  final String assignedUserId;
  final String assetTag;
  final String assetName;
  final String assetType;
  final String categoryName;
  final String brand;
  final String model;
  final String serialNumber;
  final String barcode;
  final String description;
  final String locationName;
  final String departmentName;
  final String assignedUserName;
  final AssetStatus status;
  final AssetCondition condition;
  final String complianceState;
  final String? photoUrl;
  final bool isCurrent;
  final DateTime updatedAt;

  factory AssetSelfServiceProjection.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) =>
      AssetSelfServiceProjection.fromMap(
        snapshot.id,
        snapshot.data() ?? const {},
      );

  factory AssetSelfServiceProjection.fromMap(
    String id,
    Map<String, Object?> data,
  ) =>
      AssetSelfServiceProjection(
        id: id,
        assetId: itsmAssetString(data, 'assetId'),
        assignedUserId: itsmAssetString(data, 'assignedUserId'),
        assetTag: itsmAssetString(data, 'assetTag'),
        assetName: itsmAssetString(data, 'assetName').isNotEmpty
            ? itsmAssetString(data, 'assetName')
            : itsmAssetString(data, 'displayName'),
        assetType: itsmAssetString(data, 'assetType').isNotEmpty
            ? itsmAssetString(data, 'assetType')
            : itsmAssetString(data, 'type'),
        categoryName: itsmAssetString(data, 'categoryName'),
        brand: itsmAssetString(data, 'brand'),
        model: itsmAssetString(data, 'model'),
        serialNumber: itsmAssetString(data, 'serialNumber'),
        barcode: itsmAssetString(data, 'barcode'),
        description: itsmAssetString(data, 'description'),
        locationName: itsmAssetString(data, 'locationName'),
        departmentName: itsmAssetString(data, 'departmentName'),
        assignedUserName: itsmAssetString(data, 'assignedUserName'),
        status: AssetStatus.fromValue(data['status']),
        condition: AssetCondition.fromValue(data['condition']),
        complianceState: itsmAssetString(data, 'complianceState').isNotEmpty
            ? itsmAssetString(data, 'complianceState')
            : 'assessment_pending',
        photoUrl: itsmAssetString(data, 'photoUrl').isEmpty
            ? null
            : itsmAssetString(data, 'photoUrl'),
        isCurrent:
            data['isCurrent'] == null ? true : itsmAssetBool(data, 'isCurrent'),
        updatedAt: itsmAssetDate(data['updatedAt']) ?? DateTime.utc(1970),
      );
}
