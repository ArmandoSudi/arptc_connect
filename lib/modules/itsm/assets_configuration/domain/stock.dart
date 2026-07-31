import 'package:cloud_firestore/cloud_firestore.dart';

import 'assets_configuration_serialization.dart';

enum StockItemKind { serializedAsset, consumable }

enum StockMovementType {
  receipt,
  reservation,
  reservationRelease,
  issue,
  returnToStock,
  transfer,
  adjustmentIncrease,
  adjustmentDecrease,
  reconciliation;

  String get value => switch (this) {
        StockMovementType.reservationRelease => 'reservation_release',
        StockMovementType.returnToStock => 'return',
        StockMovementType.adjustmentIncrease => 'adjustment_increase',
        StockMovementType.adjustmentDecrease => 'adjustment_decrease',
        _ => name,
      };

  static StockMovementType fromValue(Object? value) => values.firstWhere(
        (type) => type.value == value?.toString().toLowerCase(),
        orElse: () => StockMovementType.receipt,
      );
}

class StockLocation {
  StockLocation({
    required String id,
    required String name,
    required String siteId,
    required String siteName,
    required this.isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.description = '',
    this.barcode = '',
  })  : id = requireItsmAssetText(id, 'id'),
        name = requireItsmAssetText(name, 'name'),
        siteId = siteId.trim(),
        siteName = siteName.trim(),
        createdAt = createdAt.toUtc(),
        updatedAt = updatedAt.toUtc();

  final String id;
  final String name;
  final String description;
  final String siteId;
  final String siteName;
  final String barcode;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory StockLocation.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) =>
      StockLocation.fromMap(snapshot.id, snapshot.data() ?? const {});

  factory StockLocation.fromMap(String id, Map<String, Object?> data) =>
      StockLocation(
        id: id,
        name: itsmAssetString(data, 'name'),
        description: itsmAssetString(data, 'description'),
        siteId: itsmAssetString(data, 'siteId'),
        siteName: itsmAssetString(data, 'siteName'),
        barcode: itsmAssetString(data, 'barcode'),
        isActive: itsmAssetBool(data, 'isActive'),
        createdAt: itsmAssetDate(data['createdAt']) ?? DateTime.utc(1970),
        updatedAt: itsmAssetDate(data['updatedAt']) ?? DateTime.utc(1970),
      );

  Map<String, Object?> toFirestore() => {
        'name': name,
        'description': description,
        'siteId': siteId,
        'siteName': siteName,
        'barcode': barcode,
        'isActive': isActive,
        'createdAt': itsmAssetTimestamp(createdAt),
        'updatedAt': itsmAssetTimestamp(updatedAt),
      };
}

class StockItem {
  StockItem({
    required String id,
    required String sku,
    required String name,
    required this.kind,
    required String locationId,
    required String locationName,
    required this.quantityOnHand,
    required this.quantityReserved,
    required this.minimumQuantity,
    required DateTime updatedAt,
    this.description = '',
    this.barcode = '',
    this.assetCategoryId = '',
    this.unitOfMeasure = 'unit',
  })  : id = requireItsmAssetText(id, 'id'),
        sku = requireItsmAssetText(sku, 'sku'),
        name = requireItsmAssetText(name, 'name'),
        locationId = locationId.trim(),
        locationName = locationName.trim(),
        updatedAt = updatedAt.toUtc() {
    if (quantityOnHand < 0 || quantityReserved < 0 || minimumQuantity < 0) {
      throw RangeError('Stock quantities cannot be negative.');
    }
    if (quantityReserved > quantityOnHand) {
      throw ArgumentError('Reserved quantity cannot exceed on-hand quantity.');
    }
  }

  final String id;
  final String sku;
  final String name;
  final String description;
  final StockItemKind kind;
  final String barcode;
  final String assetCategoryId;
  final String locationId;
  final String locationName;
  final String unitOfMeasure;
  final int quantityOnHand;
  final int quantityReserved;
  final int minimumQuantity;
  final DateTime updatedAt;

  int get quantityAvailable => quantityOnHand - quantityReserved;
  bool get isLowStock => quantityAvailable <= minimumQuantity;

  StockItem apply(StockMovementRequest request) {
    if (request.stockItemId != id) {
      throw ArgumentError('Movement targets a different stock item.');
    }
    final result = StockQuantityCalculator.apply(
      onHand: quantityOnHand,
      reserved: quantityReserved,
      request: request,
    );
    return StockItem(
      id: id,
      sku: sku,
      name: name,
      description: description,
      kind: kind,
      barcode: barcode,
      assetCategoryId: assetCategoryId,
      locationId: locationId,
      locationName: locationName,
      unitOfMeasure: unitOfMeasure,
      quantityOnHand: result.onHand,
      quantityReserved: result.reserved,
      minimumQuantity: minimumQuantity,
      updatedAt: request.requestedAt,
    );
  }

  factory StockItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) =>
      StockItem.fromMap(snapshot.id, snapshot.data() ?? const {});

  factory StockItem.fromMap(String id, Map<String, Object?> data) => StockItem(
        id: id,
        sku: itsmAssetString(data, 'sku'),
        name: itsmAssetString(data, 'name'),
        description: itsmAssetString(data, 'description'),
        kind: StockItemKind.values.firstWhere(
          (kind) => kind.name == data['kind']?.toString(),
          orElse: () => StockItemKind.consumable,
        ),
        barcode: itsmAssetString(data, 'barcode'),
        assetCategoryId: itsmAssetString(data, 'assetCategoryId'),
        locationId: itsmAssetString(data, 'locationId'),
        locationName: itsmAssetString(data, 'locationName'),
        unitOfMeasure: itsmAssetString(data, 'unitOfMeasure').isEmpty
            ? 'unit'
            : itsmAssetString(data, 'unitOfMeasure'),
        quantityOnHand: data.containsKey('quantityOnHand')
            ? itsmAssetInt(data, 'quantityOnHand')
            : itsmAssetInt(data, 'totalOnHand'),
        quantityReserved: data.containsKey('quantityReserved')
            ? itsmAssetInt(data, 'quantityReserved')
            : itsmAssetInt(data, 'totalReserved'),
        minimumQuantity: itsmAssetInt(data, 'minimumQuantity'),
        updatedAt: itsmAssetDate(data['updatedAt']) ?? DateTime.utc(1970),
      );

  Map<String, Object?> toFirestore() => {
        'sku': sku,
        'name': name,
        'description': description,
        'kind': kind.name,
        'barcode': barcode,
        'assetCategoryId': assetCategoryId,
        'locationId': locationId,
        'locationName': locationName,
        'unitOfMeasure': unitOfMeasure,
        'quantityOnHand': quantityOnHand,
        'quantityReserved': quantityReserved,
        'quantityAvailable': quantityAvailable,
        'minimumQuantity': minimumQuantity,
        'isLowStock': isLowStock,
        'updatedAt': itsmAssetTimestamp(updatedAt),
      };
}

class StockQuantity {
  const StockQuantity({required this.onHand, required this.reserved});

  final int onHand;
  final int reserved;

  int get available => onHand - reserved;
}

abstract final class StockQuantityCalculator {
  static StockQuantity apply({
    required int onHand,
    required int reserved,
    required StockMovementRequest request,
  }) {
    if (onHand < 0 || reserved < 0 || reserved > onHand) {
      throw const StockValidationException('Invalid opening quantities.');
    }
    var nextOnHand = onHand;
    var nextReserved = reserved;
    final quantity = request.quantity;
    switch (request.type) {
      case StockMovementType.receipt:
      case StockMovementType.returnToStock:
      case StockMovementType.adjustmentIncrease:
        nextOnHand += quantity;
      case StockMovementType.reservation:
        nextReserved += quantity;
      case StockMovementType.reservationRelease:
        nextReserved -= quantity;
      case StockMovementType.issue:
        nextOnHand -= quantity;
        nextReserved -= request.reservedQuantity > 0
            ? request.reservedQuantity
            : (request.consumeReservation ? quantity : 0);
      case StockMovementType.transfer:
      case StockMovementType.adjustmentDecrease:
        nextOnHand -= quantity;
      case StockMovementType.reconciliation:
        nextOnHand = request.targetOnHand ?? quantity;
        nextReserved = request.targetReserved;
        if (nextReserved > nextOnHand) {
          throw const StockValidationException(
            'Reconciliation cannot strand reserved stock.',
          );
        }
    }
    if (nextOnHand < 0 || nextReserved < 0 || nextReserved > nextOnHand) {
      throw const StockValidationException(
        'Movement would create impossible stock quantities.',
      );
    }
    return StockQuantity(onHand: nextOnHand, reserved: nextReserved);
  }
}

class StockMovementRequest {
  StockMovementRequest({
    required String idempotencyKey,
    required String stockItemId,
    required this.type,
    required this.quantity,
    required String actorUserId,
    required DateTime requestedAt,
    this.sourceLocationId = '',
    this.destinationLocationId = '',
    this.recipientUserId = '',
    this.relatedRequestId = '',
    this.supportingDocumentId = '',
    this.reason = '',
    this.consumeReservation = false,
    this.reservedQuantity = 0,
    this.adjustmentDelta,
    this.targetOnHand,
    this.targetReserved = 0,
  })  : idempotencyKey = requireItsmAssetText(
          idempotencyKey,
          'idempotencyKey',
        ),
        stockItemId = requireItsmAssetText(stockItemId, 'stockItemId'),
        actorUserId = requireItsmAssetText(actorUserId, 'actorUserId'),
        requestedAt = requestedAt.toUtc() {
    if ((type == StockMovementType.reconciliation && quantity < 0) ||
        (type != StockMovementType.reconciliation && quantity < 1)) {
      throw RangeError.value(quantity, 'quantity');
    }
    if (_requiresSource(type) && sourceLocationId.trim().isEmpty) {
      throw ArgumentError('Movement $type requires a source location.');
    }
    if (_requiresDestination(type) && destinationLocationId.trim().isEmpty) {
      throw ArgumentError('Movement $type requires a destination location.');
    }
    if (type == StockMovementType.transfer &&
        sourceLocationId.trim() == destinationLocationId.trim()) {
      throw ArgumentError('A transfer requires distinct locations.');
    }
    if (type == StockMovementType.issue && recipientUserId.trim().isEmpty) {
      throw ArgumentError('An issue requires a recipient.');
    }
    if ((type == StockMovementType.adjustmentIncrease ||
            type == StockMovementType.adjustmentDecrease ||
            type == StockMovementType.reconciliation) &&
        reason.trim().isEmpty) {
      throw ArgumentError('Adjustments and reconciliation require a reason.');
    }
    if (reservedQuantity < 0 || reservedQuantity > quantity) {
      throw RangeError.value(reservedQuantity, 'reservedQuantity');
    }
    if (type == StockMovementType.reconciliation &&
        ((targetOnHand ?? quantity) < 0 ||
            targetReserved < 0 ||
            targetReserved > (targetOnHand ?? quantity))) {
      throw ArgumentError('Invalid reconciliation targets.');
    }
    if (type == StockMovementType.adjustmentIncrease ||
        type == StockMovementType.adjustmentDecrease) {
      final delta = adjustmentDelta ??
          (type == StockMovementType.adjustmentDecrease ? -quantity : quantity);
      if (delta == 0 ||
          (type == StockMovementType.adjustmentIncrease && delta < 0) ||
          (type == StockMovementType.adjustmentDecrease && delta > 0)) {
        throw ArgumentError('The adjustment delta has an invalid sign.');
      }
    }
  }

  final String idempotencyKey;
  final String stockItemId;
  final StockMovementType type;
  final int quantity;
  final String sourceLocationId;
  final String destinationLocationId;
  final String actorUserId;
  final String recipientUserId;
  final String relatedRequestId;
  final String supportingDocumentId;
  final String reason;
  final bool consumeReservation;
  final int reservedQuantity;
  final int? adjustmentDelta;
  final int? targetOnHand;
  final int targetReserved;
  final DateTime requestedAt;

  Map<String, Object?> toCommandPayload() => {
        'stockItemId': stockItemId,
        'movementType': type.value,
        if (type == StockMovementType.adjustmentIncrease ||
            type == StockMovementType.adjustmentDecrease)
          'adjustmentDelta': adjustmentDelta ??
              (type == StockMovementType.adjustmentDecrease
                  ? -quantity
                  : quantity)
        else if (type == StockMovementType.reconciliation) ...{
          'targetOnHand': targetOnHand ?? quantity,
          'targetReserved': targetReserved,
        } else
          'quantity': quantity,
        'sourceLocationId': sourceLocationId,
        'destinationLocationId': destinationLocationId,
        'recipientUserId': recipientUserId,
        'relatedRequestId': relatedRequestId,
        'supportingDocumentId': supportingDocumentId,
        'reason': reason,
        if (type == StockMovementType.issue &&
            (reservedQuantity > 0 || consumeReservation))
          'reservedQuantity':
              reservedQuantity > 0 ? reservedQuantity : quantity,
        'requestedAt': requestedAt.toIso8601String(),
      };

  static bool _requiresSource(StockMovementType type) => switch (type) {
        StockMovementType.issue ||
        StockMovementType.transfer ||
        StockMovementType.adjustmentDecrease ||
        StockMovementType.reservation ||
        StockMovementType.reservationRelease =>
          true,
        _ => false,
      };

  static bool _requiresDestination(StockMovementType type) => switch (type) {
        StockMovementType.receipt ||
        StockMovementType.returnToStock ||
        StockMovementType.transfer ||
        StockMovementType.adjustmentIncrease =>
          true,
        _ => false,
      };
}

class StockMovement {
  StockMovement({
    required String id,
    required String stockItemId,
    required this.type,
    required this.quantity,
    required String actorUserId,
    required String actorName,
    required DateTime occurredAt,
    required this.resultingQuantityOnHand,
    required this.resultingQuantityReserved,
    this.sourceLocationId = '',
    this.destinationLocationId = '',
    this.recipientUserId = '',
    this.recipientName = '',
    this.relatedRequestId = '',
    this.supportingDocumentId = '',
    this.reason = '',
  })  : id = requireItsmAssetText(id, 'id'),
        stockItemId = requireItsmAssetText(stockItemId, 'stockItemId'),
        actorUserId = requireItsmAssetText(actorUserId, 'actorUserId'),
        actorName = actorName.trim(),
        occurredAt = occurredAt.toUtc() {
    if ((type == StockMovementType.reconciliation
            ? quantity < 0
            : quantity < 1) ||
        resultingQuantityOnHand < 0 ||
        resultingQuantityReserved < 0 ||
        resultingQuantityReserved > resultingQuantityOnHand) {
      throw RangeError('Invalid stock movement quantities.');
    }
  }

  final String id;
  final String stockItemId;
  final StockMovementType type;
  final int quantity;
  final String sourceLocationId;
  final String destinationLocationId;
  final String actorUserId;
  final String actorName;
  final String recipientUserId;
  final String recipientName;
  final String relatedRequestId;
  final String supportingDocumentId;
  final String reason;
  final DateTime occurredAt;
  final int resultingQuantityOnHand;
  final int resultingQuantityReserved;

  factory StockMovement.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) =>
      StockMovement.fromMap(snapshot.id, snapshot.data() ?? const {});

  factory StockMovement.fromMap(String id, Map<String, Object?> data) =>
      StockMovement(
        id: id,
        stockItemId: itsmAssetString(data, 'stockItemId'),
        type: _stockMovementType(data),
        quantity: itsmAssetInt(data, 'quantity'),
        sourceLocationId: itsmAssetString(data, 'sourceLocationId'),
        destinationLocationId: itsmAssetString(data, 'destinationLocationId'),
        actorUserId: itsmAssetString(data, 'actorUserId'),
        actorName: itsmAssetString(data, 'actorName').isNotEmpty
            ? itsmAssetString(data, 'actorName')
            : itsmAssetString(itsmAssetMap(data['actor']), 'name'),
        recipientUserId: itsmAssetString(data, 'recipientUserId'),
        recipientName: itsmAssetString(data, 'recipientName').isNotEmpty
            ? itsmAssetString(data, 'recipientName')
            : itsmAssetString(itsmAssetMap(data['recipient']), 'name'),
        relatedRequestId: itsmAssetString(data, 'relatedRequestId'),
        supportingDocumentId:
            itsmAssetString(data, 'supportingDocumentId').isNotEmpty
                ? itsmAssetString(data, 'supportingDocumentId')
                : itsmAssetString(
                    itsmAssetMap(data['supportingDocument']),
                    'attachmentId',
                  ),
        reason: itsmAssetString(data, 'reason'),
        occurredAt: itsmAssetDate(data['occurredAt']) ?? DateTime.utc(1970),
        resultingQuantityOnHand: data.containsKey('resultingQuantityOnHand')
            ? itsmAssetInt(data, 'resultingQuantityOnHand')
            : _movementTotal(data['after'], 'onHand'),
        resultingQuantityReserved: data.containsKey('resultingQuantityReserved')
            ? itsmAssetInt(data, 'resultingQuantityReserved')
            : _movementTotal(data['after'], 'reserved'),
      );

  Map<String, Object?> toFirestore() => {
        'stockItemId': stockItemId,
        'movementType': type.value,
        'quantity': quantity,
        'sourceLocationId': sourceLocationId,
        'destinationLocationId': destinationLocationId,
        'actorUserId': actorUserId,
        'actorName': actorName,
        'recipientUserId': recipientUserId,
        'recipientName': recipientName,
        'relatedRequestId': relatedRequestId,
        'supportingDocumentId': supportingDocumentId,
        'reason': reason,
        'occurredAt': itsmAssetTimestamp(occurredAt),
        'resultingQuantityOnHand': resultingQuantityOnHand,
        'resultingQuantityReserved': resultingQuantityReserved,
      };
}

int _movementTotal(Object? value, String field) {
  return itsmAssetMap(value).values.fold<int>(0, (total, balance) {
    final map = itsmAssetMap(balance);
    return total + itsmAssetInt(map, field);
  });
}

StockMovementType _stockMovementType(Map<String, Object?> data) {
  final value = data['movementType'] ?? data['type'];
  if (value?.toString().toLowerCase() != 'adjustment') {
    return StockMovementType.fromValue(value);
  }
  final delta = itsmAssetMap(data['quantityChanges']).values.fold<int>(
        0,
        (total, change) => total + itsmAssetInt(itsmAssetMap(change), 'onHand'),
      );
  return delta < 0
      ? StockMovementType.adjustmentDecrease
      : StockMovementType.adjustmentIncrease;
}

class StockValidationException implements Exception {
  const StockValidationException(this.message);

  final String message;

  @override
  String toString() => 'StockValidationException($message)';
}
