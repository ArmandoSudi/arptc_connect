import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'assets_configuration_serialization.dart';

enum AssetStatus {
  planned,
  ordered,
  received,
  inStock,
  configured,
  assigned,
  inMaintenance,
  returned,
  retired,
  disposed,
  lost,
  stolen;

  String get value => switch (this) {
        AssetStatus.inStock => 'in_stock',
        AssetStatus.inMaintenance => 'in_maintenance',
        _ => name,
      };

  static AssetStatus fromValue(Object? value) => values.firstWhere(
        (status) => status.value == value?.toString().toLowerCase(),
        orElse: () => AssetStatus.planned,
      );
}

enum AssetCondition {
  newAsset,
  good,
  fair,
  damaged,
  unusable;

  String get value => this == newAsset ? 'new' : name;

  static AssetCondition fromValue(Object? value) => values.firstWhere(
        (condition) => condition.value == value?.toString().toLowerCase(),
        orElse: () => AssetCondition.good,
      );
}

enum AssetTransitionIssue { transitionNotAllowed, assigneeRequired }

abstract final class AssetLifecyclePolicy {
  static const Map<AssetStatus, Set<AssetStatus>> _allowed = {
    AssetStatus.planned: {AssetStatus.ordered},
    AssetStatus.ordered: {AssetStatus.received},
    AssetStatus.received: {AssetStatus.inStock, AssetStatus.configured},
    AssetStatus.inStock: {AssetStatus.configured, AssetStatus.assigned},
    AssetStatus.configured: {AssetStatus.assigned, AssetStatus.inStock},
    AssetStatus.assigned: {
      AssetStatus.inMaintenance,
      AssetStatus.returned,
      AssetStatus.lost,
      AssetStatus.stolen,
    },
    AssetStatus.inMaintenance: {
      AssetStatus.assigned,
      AssetStatus.returned,
      AssetStatus.retired,
    },
    AssetStatus.returned: {
      AssetStatus.inStock,
      AssetStatus.configured,
      AssetStatus.retired,
    },
    AssetStatus.retired: {AssetStatus.disposed},
    AssetStatus.lost: {AssetStatus.returned, AssetStatus.retired},
    AssetStatus.stolen: {AssetStatus.returned, AssetStatus.retired},
    AssetStatus.disposed: {},
  };

  static List<AssetTransitionIssue> validate({
    required AssetStatus from,
    required AssetStatus to,
    String assignedUserId = '',
  }) {
    final issues = <AssetTransitionIssue>[];
    if (!(_allowed[from]?.contains(to) ?? false)) {
      issues.add(AssetTransitionIssue.transitionNotAllowed);
    }
    if (to == AssetStatus.assigned && assignedUserId.trim().isEmpty) {
      issues.add(AssetTransitionIssue.assigneeRequired);
    }
    return List.unmodifiable(issues);
  }

  static bool canTransition({
    required AssetStatus from,
    required AssetStatus to,
    String assignedUserId = '',
  }) =>
      validate(from: from, to: to, assignedUserId: assignedUserId).isEmpty;
}

class Asset {
  Asset({
    required String id,
    required String assetTag,
    required String categoryId,
    required String categoryName,
    required String type,
    required String brand,
    required String model,
    required this.status,
    required this.condition,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.qrBarcode = '',
    this.serialNumber = '',
    this.description = '',
    this.acquisitionDate,
    this.acquisitionCost,
    this.currencyCode = '',
    this.supplierId = '',
    this.supplierName = '',
    this.warrantyId = '',
    this.siteId = '',
    this.siteName = '',
    this.locationId = '',
    this.locationName = '',
    this.departmentId = '',
    this.departmentName = '',
    this.assignedUserId = '',
    this.assignedUserName = '',
    this.stockLocationId = '',
    this.securityBaselineId = '',
    Iterable<String> attachmentIds = const [],
    Iterable<String> photographIds = const [],
  })  : id = requireItsmAssetText(id, 'id'),
        assetTag = requireItsmAssetText(assetTag, 'assetTag'),
        categoryId = categoryId.trim(),
        categoryName = categoryName.trim(),
        type = requireItsmAssetText(type, 'type'),
        brand = brand.trim(),
        model = model.trim(),
        createdAt = createdAt.toUtc(),
        updatedAt = updatedAt.toUtc(),
        attachmentIds = UnmodifiableListView(
          immutableItsmAssetIds(attachmentIds),
        ),
        photographIds = UnmodifiableListView(
          immutableItsmAssetIds(photographIds),
        ) {
    final cost = acquisitionCost;
    if (cost != null && cost < 0) {
      throw RangeError.value(cost, 'acquisitionCost');
    }
    if (status == AssetStatus.assigned && assignedUserId.trim().isEmpty) {
      throw ArgumentError('Assigned assets require assignedUserId.');
    }
  }

  final String id;
  final String assetTag;
  final String qrBarcode;
  final String categoryId;
  final String categoryName;
  final String type;
  final String brand;
  final String model;
  final String serialNumber;
  final String description;
  final DateTime? acquisitionDate;
  final double? acquisitionCost;
  final String currencyCode;
  final String supplierId;
  final String supplierName;
  final String warrantyId;
  final AssetStatus status;
  final AssetCondition condition;
  final String siteId;
  final String siteName;
  final String locationId;
  final String locationName;
  final String departmentId;
  final String departmentName;
  final String assignedUserId;
  final String assignedUserName;
  final String stockLocationId;
  final String securityBaselineId;
  final List<String> attachmentIds;
  final List<String> photographIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Asset.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) =>
      Asset.fromMap(snapshot.id, snapshot.data() ?? const {});

  factory Asset.fromMap(String id, Map<String, Object?> data) => Asset(
        id: id,
        assetTag: itsmAssetString(data, 'assetTag'),
        qrBarcode: itsmAssetString(data, 'qrBarcode').isNotEmpty
            ? itsmAssetString(data, 'qrBarcode')
            : itsmAssetString(data, 'barcode'),
        categoryId: itsmAssetString(data, 'categoryId'),
        categoryName: itsmAssetString(data, 'categoryName'),
        type: itsmAssetString(data, 'type'),
        brand: itsmAssetString(data, 'brand'),
        model: itsmAssetString(data, 'model'),
        serialNumber: itsmAssetString(data, 'serialNumber'),
        description: itsmAssetString(data, 'description'),
        acquisitionDate: itsmAssetDate(data['acquisitionDate']),
        acquisitionCost: data['acquisitionCost'] == null
            ? null
            : itsmAssetDouble(data, 'acquisitionCost'),
        currencyCode: itsmAssetString(data, 'currencyCode').isNotEmpty
            ? itsmAssetString(data, 'currencyCode')
            : itsmAssetString(data, 'currency'),
        supplierId: itsmAssetString(data, 'supplierId'),
        supplierName: itsmAssetString(data, 'supplierName'),
        warrantyId: itsmAssetString(data, 'warrantyId'),
        status: AssetStatus.fromValue(data['status']),
        condition: AssetCondition.fromValue(data['condition']),
        siteId: itsmAssetString(data, 'siteId'),
        siteName: itsmAssetString(data, 'siteName'),
        locationId: itsmAssetString(data, 'locationId'),
        locationName: itsmAssetString(data, 'locationName'),
        departmentId: itsmAssetString(data, 'departmentId'),
        departmentName: itsmAssetString(data, 'departmentName'),
        assignedUserId: itsmAssetString(data, 'assignedUserId'),
        assignedUserName: itsmAssetString(data, 'assignedUserName'),
        stockLocationId: itsmAssetString(data, 'stockLocationId'),
        securityBaselineId: itsmAssetString(data, 'securityBaselineId'),
        attachmentIds: itsmAssetStrings(data['attachmentIds']),
        photographIds: itsmAssetStrings(
          data['photographIds'] ?? data['photoAttachmentIds'],
        ),
        createdAt: itsmAssetDate(data['createdAt']) ?? DateTime.utc(1970),
        updatedAt: itsmAssetDate(data['updatedAt']) ?? DateTime.utc(1970),
      );

  Map<String, Object?> toFirestore() => {
        'assetTag': assetTag,
        'qrBarcode': qrBarcode,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'type': type,
        'brand': brand,
        'model': model,
        'serialNumber': serialNumber,
        'description': description,
        'acquisitionDate': itsmAssetTimestamp(acquisitionDate),
        'acquisitionCost': acquisitionCost,
        'currencyCode': currencyCode,
        'supplierId': supplierId,
        'supplierName': supplierName,
        'warrantyId': warrantyId,
        'status': status.value,
        'condition': condition.value,
        'siteId': siteId,
        'siteName': siteName,
        'locationId': locationId,
        'locationName': locationName,
        'departmentId': departmentId,
        'departmentName': departmentName,
        'assignedUserId': assignedUserId,
        'assignedUserName': assignedUserName,
        'stockLocationId': stockLocationId,
        'securityBaselineId': securityBaselineId,
        'attachmentIds': attachmentIds,
        'photographIds': photographIds,
        'createdAt': itsmAssetTimestamp(createdAt),
        'updatedAt': itsmAssetTimestamp(updatedAt),
      };
}
