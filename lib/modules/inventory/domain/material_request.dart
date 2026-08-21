import 'package:cloud_firestore/cloud_firestore.dart';

import 'inventory_entities.dart';
import 'inventory_quantity.dart';

enum MaterialRequestStatus {
  submitted,
  underReview('under_review'),
  adjusted,
  readyForIssue('ready_for_issue'),
  partiallyFulfilled('partially_fulfilled'),
  awaitingConfirmation('awaiting_confirmation'),
  fulfilled,
  closedShort('closed_short'),
  cancelled,
  rejected;

  const MaterialRequestStatus([String? value]) : value = value ?? '';
  final String value;

  String get firestoreValue => value.isEmpty ? name : value;

  static MaterialRequestStatus fromValue(Object? value) => values.firstWhere(
        (entry) =>
            entry.firestoreValue == value?.toString().trim().toLowerCase(),
        orElse: () => MaterialRequestStatus.submitted,
      );

  bool get isTerminal => switch (this) {
        MaterialRequestStatus.fulfilled ||
        MaterialRequestStatus.closedShort ||
        MaterialRequestStatus.cancelled ||
        MaterialRequestStatus.rejected =>
          true,
        _ => false,
      };
}

enum MaterialRequestLineStatus {
  requested,
  approved,
  adjusted,
  declined,
  reserved,
  partiallyFulfilled('partially_fulfilled'),
  issued,
  closedShort('closed_short');

  const MaterialRequestLineStatus([String? value]) : value = value ?? '';
  final String value;
  String get firestoreValue => value.isEmpty ? name : value;

  static MaterialRequestLineStatus fromValue(Object? value) =>
      values.firstWhere(
        (entry) =>
            entry.firestoreValue == value?.toString().trim().toLowerCase(),
        orElse: () => MaterialRequestLineStatus.requested,
      );
}

class MaterialRequest {
  const MaterialRequest({
    required this.id,
    required this.requestNumber,
    required this.status,
    required this.submittedBy,
    required this.requestedFor,
    required this.hasAdjustments,
    required this.hasIssuedStock,
    required this.lineCount,
    required this.createdAt,
    required this.updatedAt,
    this.justification = '',
    this.deliveryDestination = '',
    this.assignedManager,
    this.recipient,
    this.submittedAt,
    this.fulfilledAt,
    this.confirmedAt,
    this.rejectedReason = '',
    this.cancelledReason = '',
    this.shortfallReason = '',
  });

  final String id;
  final String requestNumber;
  final MaterialRequestStatus status;
  final InventoryAgentSnapshot submittedBy;
  final InventoryAgentSnapshot requestedFor;
  final InventoryAgentSnapshot? assignedManager;
  final InventoryAgentSnapshot? recipient;
  final String justification;
  final String deliveryDestination;
  final bool hasAdjustments;
  final bool hasIssuedStock;
  final int lineCount;
  final String rejectedReason;
  final String cancelledReason;
  final String shortfallReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? submittedAt;
  final DateTime? fulfilledAt;
  final DateTime? confirmedAt;

  bool canBeCancelledBy(String userId) =>
      requestedFor.userId == userId && !hasIssuedStock && !status.isTerminal;

  bool canBeConfirmedBy(String userId) =>
      requestedFor.userId == userId &&
      status == MaterialRequestStatus.awaitingConfirmation;

  factory MaterialRequest.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final map = snapshot.data() ?? const <String, dynamic>{};
    return MaterialRequest(
      id: snapshot.id,
      requestNumber: _string(map['requestNumber']),
      status: MaterialRequestStatus.fromValue(map['status']),
      submittedBy: InventoryAgentSnapshot.fromMap(map['submittedBy']),
      requestedFor: InventoryAgentSnapshot.fromMap(map['requestedFor']),
      assignedManager: map['assignedManager'] is Map
          ? InventoryAgentSnapshot.fromMap(map['assignedManager'])
          : null,
      recipient: map['recipient'] is Map
          ? InventoryAgentSnapshot.fromMap(map['recipient'])
          : null,
      justification: _string(map['justification']),
      deliveryDestination: _string(map['deliveryDestination']),
      hasAdjustments: map['hasAdjustments'] == true,
      hasIssuedStock: map['hasIssuedStock'] == true,
      lineCount: (map['lineCount'] as num?)?.toInt() ?? 0,
      rejectedReason: _string(map['rejectedReason']),
      cancelledReason: _string(map['cancelledReason']),
      shortfallReason: _string(map['shortfallReason']),
      createdAt: inventoryDate(map['createdAt']),
      updatedAt: inventoryDate(map['updatedAt']),
      submittedAt: inventoryDate(map['submittedAt']),
      fulfilledAt: inventoryDate(map['fulfilledAt']),
      confirmedAt: inventoryDate(map['confirmedAt']),
    );
  }
}

class MaterialRequestLine {
  const MaterialRequestLine({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.unitOfMeasureName,
    required this.status,
    required this.requested,
    required this.approved,
    required this.reserved,
    required this.issued,
    this.adjustmentReason = '',
    this.declineReason = '',
  });

  final String id;
  final String itemId;
  final String itemName;
  final String unitOfMeasureName;
  final MaterialRequestLineStatus status;
  final InventoryQuantity requested;
  final InventoryQuantity approved;
  final InventoryQuantity reserved;
  final InventoryQuantity issued;
  final String adjustmentReason;
  final String declineReason;

  InventoryQuantity get outstanding => (approved - issued).clampToZero();

  factory MaterialRequestLine.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final map = snapshot.data() ?? const <String, dynamic>{};
    return MaterialRequestLine(
      id: snapshot.id,
      itemId: _string(map['itemId']),
      itemName: _string(map['itemName']),
      unitOfMeasureName: _string(map['unitOfMeasureName']),
      status: MaterialRequestLineStatus.fromValue(map['status']),
      requested: InventoryQuantity.fromFirestore(map['requestedMilli']),
      approved: InventoryQuantity.fromFirestore(map['approvedMilli']),
      reserved: InventoryQuantity.fromFirestore(map['reservedMilli']),
      issued: InventoryQuantity.fromFirestore(map['issuedMilli']),
      adjustmentReason: _string(map['adjustmentReason']),
      declineReason: _string(map['declineReason']),
    );
  }
}

class MaterialRequestAllocation {
  const MaterialRequestAllocation({
    required this.id,
    required this.lineId,
    required this.balanceId,
    required this.warehouseId,
    required this.warehouseName,
    required this.locationId,
    required this.locationName,
    required this.reserved,
    required this.issued,
  });

  final String id;
  final String lineId;
  final String balanceId;
  final String warehouseId;
  final String warehouseName;
  final String locationId;
  final String locationName;
  final InventoryQuantity reserved;
  final InventoryQuantity issued;

  factory MaterialRequestAllocation.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final map = snapshot.data() ?? const <String, dynamic>{};
    return MaterialRequestAllocation(
      id: snapshot.id,
      lineId: _string(map['lineId']),
      balanceId: _string(map['balanceId']),
      warehouseId: _string(map['warehouseId']),
      warehouseName: _string(map['warehouseName']),
      locationId: _string(map['locationId']),
      locationName: _string(map['locationName']),
      reserved: InventoryQuantity.fromFirestore(map['reservedMilli']),
      issued: InventoryQuantity.fromFirestore(map['issuedMilli']),
    );
  }
}

abstract final class MaterialRequestWorkflow {
  static final Map<MaterialRequestStatus, Set<MaterialRequestStatus>> _allowed =
      {
    MaterialRequestStatus.submitted: {
      MaterialRequestStatus.underReview,
      MaterialRequestStatus.cancelled,
      MaterialRequestStatus.rejected,
    },
    MaterialRequestStatus.underReview: {
      MaterialRequestStatus.adjusted,
      MaterialRequestStatus.readyForIssue,
      MaterialRequestStatus.cancelled,
      MaterialRequestStatus.rejected,
    },
    MaterialRequestStatus.adjusted: {
      MaterialRequestStatus.readyForIssue,
      MaterialRequestStatus.cancelled,
      MaterialRequestStatus.rejected,
    },
    MaterialRequestStatus.readyForIssue: {
      MaterialRequestStatus.partiallyFulfilled,
      MaterialRequestStatus.awaitingConfirmation,
      MaterialRequestStatus.cancelled,
    },
    MaterialRequestStatus.partiallyFulfilled: {
      MaterialRequestStatus.partiallyFulfilled,
      MaterialRequestStatus.awaitingConfirmation,
    },
    MaterialRequestStatus.awaitingConfirmation: {
      MaterialRequestStatus.fulfilled,
      MaterialRequestStatus.closedShort,
    },
  };

  static bool canTransition(
    MaterialRequestStatus from,
    MaterialRequestStatus to,
  ) =>
      _allowed[from]?.contains(to) ?? false;

  static void requireTransition(
    MaterialRequestStatus from,
    MaterialRequestStatus to,
  ) {
    if (!canTransition(from, to)) {
      throw StateError(
        'Cannot move a material request from ${from.firestoreValue} '
        'to ${to.firestoreValue}.',
      );
    }
  }
}

String _string(Object? value) => value?.toString().trim() ?? '';
