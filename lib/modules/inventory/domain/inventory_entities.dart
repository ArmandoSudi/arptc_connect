import 'package:cloud_firestore/cloud_firestore.dart';

import 'inventory_quantity.dart';

enum InventoryAvailability {
  available,
  limited,
  unavailable;

  static InventoryAvailability fromValue(Object? value) => values.firstWhere(
        (entry) => entry.name == value?.toString().trim().toLowerCase(),
        orElse: () => InventoryAvailability.unavailable,
      );
}

enum InventoryParameterType {
  category,
  unitOfMeasure,
  itemType,
  movementReason,
  adjustmentReason,
  rejectionReason,
  shortfallReason;

  String get value => switch (this) {
        InventoryParameterType.unitOfMeasure => 'unit_of_measure',
        InventoryParameterType.itemType => 'item_type',
        InventoryParameterType.movementReason => 'movement_reason',
        InventoryParameterType.adjustmentReason => 'adjustment_reason',
        InventoryParameterType.rejectionReason => 'rejection_reason',
        InventoryParameterType.shortfallReason => 'shortfall_reason',
        _ => name,
      };

  static InventoryParameterType fromValue(Object? value) => values.firstWhere(
        (entry) => entry.value == value?.toString().trim().toLowerCase(),
        orElse: () => InventoryParameterType.category,
      );
}

enum InventoryMovementType {
  openingBalance('opening_balance'),
  receipt('receipt'),
  reservation('reservation'),
  reservationRelease('reservation_release'),
  issue('issue'),
  returnToStock('return_to_stock'),
  transferOut('transfer_out'),
  transferIn('transfer_in'),
  adjustmentIncrease('adjustment_increase'),
  adjustmentDecrease('adjustment_decrease'),
  reconciliation('reconciliation');

  const InventoryMovementType(this.value);
  final String value;

  static InventoryMovementType fromValue(Object? value) => values.firstWhere(
        (entry) => entry.value == value?.toString().trim().toLowerCase(),
        orElse: () => InventoryMovementType.receipt,
      );
}

class InventoryAgentSnapshot {
  const InventoryAgentSnapshot({
    required this.userId,
    required this.name,
    required this.email,
    this.organizationId = '',
    this.departmentId = '',
    this.departmentName = '',
    this.serviceId = '',
    this.serviceName = '',
    this.bureauId = '',
    this.bureauName = '',
  });

  final String userId;
  final String name;
  final String email;
  final String organizationId;
  final String departmentId;
  final String departmentName;
  final String serviceId;
  final String serviceName;
  final String bureauId;
  final String bureauName;

  factory InventoryAgentSnapshot.fromMap(Object? value) {
    final map = _map(value);
    return InventoryAgentSnapshot(
      userId: _string(map['userId']),
      name: _string(map['name']),
      email: _string(map['email']),
      organizationId: _string(map['organizationId']),
      departmentId: _string(map['departmentId']),
      departmentName: _string(map['departmentName']),
      serviceId: _string(map['serviceId']),
      serviceName: _string(map['serviceName']),
      bureauId: _string(map['bureauId']),
      bureauName: _string(map['bureauName']),
    );
  }

  Map<String, Object?> toMap() => {
        'userId': userId,
        'name': name,
        'email': email,
        'organizationId': organizationId,
        'departmentId': departmentId,
        'departmentName': departmentName,
        'serviceId': serviceId,
        'serviceName': serviceName,
        'bureauId': bureauId,
        'bureauName': bureauName,
      };
}

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.sku,
    required this.name,
    required this.nameLower,
    required this.categoryId,
    required this.categoryName,
    required this.unitOfMeasureId,
    required this.unitOfMeasureName,
    required this.itemTypeId,
    required this.itemTypeName,
    required this.isRequestable,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.description = '',
    this.imageUrl = '',
  });

  final String id;
  final String sku;
  final String name;
  final String nameLower;
  final String description;
  final String categoryId;
  final String categoryName;
  final String unitOfMeasureId;
  final String unitOfMeasureName;
  final String itemTypeId;
  final String itemTypeName;
  final String imageUrl;
  final bool isRequestable;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory InventoryItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) =>
      InventoryItem.fromMap(snapshot.id, snapshot.data() ?? const {});

  factory InventoryItem.fromMap(String id, Map<String, Object?> map) =>
      InventoryItem(
        id: id,
        sku: _string(map['sku']),
        name: _string(map['name']),
        nameLower: _string(map['nameLower']),
        description: _string(map['description']),
        categoryId: _string(map['categoryId']),
        categoryName: _string(map['categoryName']),
        unitOfMeasureId: _string(map['unitOfMeasureId']),
        unitOfMeasureName: _string(map['unitOfMeasureName']),
        itemTypeId: _string(map['itemTypeId']),
        itemTypeName: _string(map['itemTypeName']),
        imageUrl: _string(map['imageUrl']),
        isRequestable: _bool(map['isRequestable'], fallback: true),
        isActive: _bool(map['isActive'], fallback: true),
        createdAt: inventoryDate(map['createdAt']),
        updatedAt: inventoryDate(map['updatedAt']),
      );

  Map<String, Object?> toFirestore() => {
        'sku': sku,
        'name': name,
        'nameLower': name.toLowerCase(),
        'description': description,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'unitOfMeasureId': unitOfMeasureId,
        'unitOfMeasureName': unitOfMeasureName,
        'itemTypeId': itemTypeId,
        'itemTypeName': itemTypeName,
        'imageUrl': imageUrl,
        'isRequestable': isRequestable,
        'isActive': isActive,
      };
}

class InventoryCatalogueItem {
  const InventoryCatalogueItem({
    required this.id,
    required this.sku,
    required this.name,
    required this.nameLower,
    required this.description,
    required this.categoryId,
    required this.categoryName,
    required this.unitOfMeasureName,
    required this.availability,
    required this.isRequestable,
    required this.isActive,
    this.imageUrl = '',
  });

  final String id;
  final String sku;
  final String name;
  final String nameLower;
  final String description;
  final String categoryId;
  final String categoryName;
  final String unitOfMeasureName;
  final InventoryAvailability availability;
  final bool isRequestable;
  final bool isActive;
  final String imageUrl;

  factory InventoryCatalogueItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final map = snapshot.data() ?? const <String, dynamic>{};
    return InventoryCatalogueItem(
      id: snapshot.id,
      sku: _string(map['sku']),
      name: _string(map['name']),
      nameLower: _string(map['nameLower']),
      description: _string(map['description']),
      categoryId: _string(map['categoryId']),
      categoryName: _string(map['categoryName']),
      unitOfMeasureName: _string(map['unitOfMeasureName']),
      availability: InventoryAvailability.fromValue(map['availability']),
      isRequestable: _bool(map['isRequestable'], fallback: true),
      isActive: _bool(map['isActive'], fallback: true),
      imageUrl: _string(map['imageUrl']),
    );
  }
}

class InventoryWarehouse {
  const InventoryWarehouse({
    required this.id,
    required this.code,
    required this.name,
    required this.isActive,
    this.address = '',
  });

  final String id;
  final String code;
  final String name;
  final String address;
  final bool isActive;

  factory InventoryWarehouse.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final map = snapshot.data() ?? const <String, dynamic>{};
    return InventoryWarehouse(
      id: snapshot.id,
      code: _string(map['code']),
      name: _string(map['name']),
      address: _string(map['address']),
      isActive: _bool(map['isActive'], fallback: true),
    );
  }
}

class InventoryLocation {
  const InventoryLocation({
    required this.id,
    required this.warehouseId,
    required this.warehouseName,
    required this.code,
    required this.name,
    required this.isActive,
  });

  final String id;
  final String warehouseId;
  final String warehouseName;
  final String code;
  final String name;
  final bool isActive;

  factory InventoryLocation.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final map = snapshot.data() ?? const <String, dynamic>{};
    return InventoryLocation(
      id: snapshot.id,
      warehouseId: _string(map['warehouseId']),
      warehouseName: _string(map['warehouseName']),
      code: _string(map['code']),
      name: _string(map['name']),
      isActive: _bool(map['isActive'], fallback: true),
    );
  }
}

class InventoryBalance {
  const InventoryBalance({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.warehouseId,
    required this.warehouseName,
    required this.locationId,
    required this.locationName,
    required this.onHand,
    required this.reserved,
    required this.threshold,
    required this.updatedAt,
  });

  final String id;
  final String itemId;
  final String itemName;
  final String warehouseId;
  final String warehouseName;
  final String locationId;
  final String locationName;
  final InventoryQuantity onHand;
  final InventoryQuantity reserved;
  final InventoryQuantity threshold;
  final DateTime? updatedAt;

  InventoryQuantity get available => onHand - reserved;
  bool get isLowStock => available <= threshold;
  bool get isOutOfStock => available.isZero || available.isNegative;

  factory InventoryBalance.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final map = snapshot.data() ?? const <String, dynamic>{};
    return InventoryBalance(
      id: snapshot.id,
      itemId: _string(map['itemId']),
      itemName: _string(map['itemName']),
      warehouseId: _string(map['warehouseId']),
      warehouseName: _string(map['warehouseName']),
      locationId: _string(map['locationId']),
      locationName: _string(map['locationName']),
      onHand: InventoryQuantity.fromFirestore(map['onHandMilli']),
      reserved: InventoryQuantity.fromFirestore(map['reservedMilli']),
      threshold: InventoryQuantity.fromFirestore(map['thresholdMilli']),
      updatedAt: inventoryDate(map['updatedAt']),
    );
  }
}

class InventoryParameter {
  const InventoryParameter({
    required this.id,
    required this.type,
    required this.name,
    required this.isActive,
  });

  final String id;
  final InventoryParameterType type;
  final String name;
  final bool isActive;

  factory InventoryParameter.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final map = snapshot.data() ?? const <String, dynamic>{};
    return InventoryParameter(
      id: snapshot.id,
      type: InventoryParameterType.fromValue(map['type']),
      name: _string(map['name']),
      isActive: _bool(map['isActive'], fallback: true),
    );
  }
}

class InventoryStockMovement {
  const InventoryStockMovement({
    required this.id,
    required this.movementNumber,
    required this.type,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.beforeOnHand,
    required this.afterOnHand,
    required this.beforeReserved,
    required this.afterReserved,
    required this.actor,
    required this.createdAt,
    this.warehouseId = '',
    this.warehouseName = '',
    this.locationId = '',
    this.locationName = '',
    this.relatedRequestId = '',
    this.reason = '',
    this.reference = '',
  });

  final String id;
  final String movementNumber;
  final InventoryMovementType type;
  final String itemId;
  final String itemName;
  final InventoryQuantity quantity;
  final InventoryQuantity beforeOnHand;
  final InventoryQuantity afterOnHand;
  final InventoryQuantity beforeReserved;
  final InventoryQuantity afterReserved;
  final String warehouseId;
  final String warehouseName;
  final String locationId;
  final String locationName;
  final String relatedRequestId;
  final String reason;
  final String reference;
  final InventoryAgentSnapshot actor;
  final DateTime? createdAt;

  factory InventoryStockMovement.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final map = snapshot.data() ?? const <String, dynamic>{};
    return InventoryStockMovement(
      id: snapshot.id,
      movementNumber: _string(map['movementNumber']),
      type: InventoryMovementType.fromValue(map['type']),
      itemId: _string(map['itemId']),
      itemName: _string(map['itemName']),
      quantity: InventoryQuantity.fromFirestore(map['quantityMilli']),
      beforeOnHand: InventoryQuantity.fromFirestore(map['beforeOnHandMilli']),
      afterOnHand: InventoryQuantity.fromFirestore(map['afterOnHandMilli']),
      beforeReserved:
          InventoryQuantity.fromFirestore(map['beforeReservedMilli']),
      afterReserved: InventoryQuantity.fromFirestore(map['afterReservedMilli']),
      warehouseId: _string(map['warehouseId']),
      warehouseName: _string(map['warehouseName']),
      locationId: _string(map['locationId']),
      locationName: _string(map['locationName']),
      relatedRequestId: _string(map['relatedRequestId']),
      reason: _string(map['reason']),
      reference: _string(map['reference']),
      actor: InventoryAgentSnapshot.fromMap(map['actor']),
      createdAt: inventoryDate(map['createdAt']),
    );
  }
}

class InventoryAlert {
  const InventoryAlert({
    required this.id,
    required this.balanceId,
    required this.itemId,
    required this.itemName,
    required this.warehouseId,
    required this.warehouseName,
    required this.available,
    required this.threshold,
    required this.isActive,
    required this.triggeredAt,
    this.resolvedAt,
  });

  final String id;
  final String balanceId;
  final String itemId;
  final String itemName;
  final String warehouseId;
  final String warehouseName;
  final InventoryQuantity available;
  final InventoryQuantity threshold;
  final bool isActive;
  final DateTime? triggeredAt;
  final DateTime? resolvedAt;

  factory InventoryAlert.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final map = snapshot.data() ?? const <String, dynamic>{};
    return InventoryAlert(
      id: snapshot.id,
      balanceId: _string(map['balanceId']),
      itemId: _string(map['itemId']),
      itemName: _string(map['itemName']),
      warehouseId: _string(map['warehouseId']),
      warehouseName: _string(map['warehouseName']),
      available: InventoryQuantity.fromFirestore(map['availableMilli']),
      threshold: InventoryQuantity.fromFirestore(map['thresholdMilli']),
      isActive: _bool(map['isActive']),
      triggeredAt: inventoryDate(map['triggeredAt']),
      resolvedAt: inventoryDate(map['resolvedAt']),
    );
  }
}

class InventoryAuditEvent {
  const InventoryAuditEvent({
    required this.id,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.actor,
    required this.createdAt,
    this.reason = '',
  });

  final String id;
  final String action;
  final String entityType;
  final String entityId;
  final InventoryAgentSnapshot actor;
  final String reason;
  final DateTime? createdAt;

  factory InventoryAuditEvent.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final map = snapshot.data() ?? const <String, dynamic>{};
    return InventoryAuditEvent(
      id: snapshot.id,
      action: _string(map['action']),
      entityType: _string(map['entityType']),
      entityId: _string(map['entityId']),
      actor: InventoryAgentSnapshot.fromMap(map['actor']),
      reason: _string(map['reason']),
      createdAt: inventoryDate(map['createdAt']),
    );
  }
}

DateTime? inventoryDate(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.tryParse(value?.toString() ?? '');
}

Map<String, Object?> _map(Object? value) =>
    value is Map ? Map<String, Object?>.from(value) : const <String, Object?>{};

String _string(Object? value) => value?.toString().trim() ?? '';

bool _bool(Object? value, {bool fallback = false}) =>
    value is bool ? value : fallback;
