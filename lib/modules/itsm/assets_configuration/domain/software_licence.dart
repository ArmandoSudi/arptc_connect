import 'package:cloud_firestore/cloud_firestore.dart';

import 'assets_configuration_serialization.dart';

enum SoftwareLicenceType {
  perpetual,
  subscription,
  volume,
  concurrent,
  namedUser,
  device;

  String get value => this == namedUser ? 'named_user' : name;

  static SoftwareLicenceType fromValue(Object? value) => values.firstWhere(
        (type) => type.value == value?.toString().toLowerCase(),
        orElse: () => SoftwareLicenceType.subscription,
      );
}

enum LicenceComplianceStatus {
  compliant,
  warning,
  overAllocated,
  expired,
  unknown;

  String get value => this == overAllocated ? 'over_allocated' : name;

  static LicenceComplianceStatus fromValue(Object? value) => values.firstWhere(
        (status) => status.value == value?.toString().toLowerCase(),
        orElse: () => LicenceComplianceStatus.unknown,
      );
}

enum LicenceAssignmentStatus { active, released, revoked, expired }

enum LicenceHistoryEventType {
  purchased,
  renewed,
  quantityChanged,
  assigned,
  revoked,
  expired,
  complianceReviewed;

  String get value => switch (this) {
        LicenceHistoryEventType.quantityChanged => 'quantity_changed',
        LicenceHistoryEventType.complianceReviewed => 'compliance_reviewed',
        _ => name,
      };
}

class SoftwareLicence {
  SoftwareLicence({
    required String id,
    required String softwareProduct,
    required String vendor,
    required this.licenceType,
    required this.purchasedQuantity,
    required this.allocatedQuantity,
    required this.complianceStatus,
    required DateTime purchaseDate,
    required DateTime effectiveDate,
    required DateTime updatedAt,
    DateTime? expiryDate,
    DateTime? renewalDate,
    this.contractId = '',
    this.contractReference = '',
    this.cost,
    this.currencyCode = '',
    this.notes = '',
  })  : id = requireItsmAssetText(id, 'id'),
        softwareProduct = requireItsmAssetText(
          softwareProduct,
          'softwareProduct',
        ),
        vendor = requireItsmAssetText(vendor, 'vendor'),
        purchaseDate = purchaseDate.toUtc(),
        effectiveDate = effectiveDate.toUtc(),
        expiryDate = expiryDate?.toUtc(),
        renewalDate = renewalDate?.toUtc(),
        updatedAt = updatedAt.toUtc() {
    if (purchasedQuantity < 0 || allocatedQuantity < 0) {
      throw RangeError('Licence quantities cannot be negative.');
    }
    final licenceCost = cost;
    if (licenceCost != null && licenceCost < 0) {
      throw RangeError.value(licenceCost, 'cost');
    }
    if (expiryDate != null && expiryDate.isBefore(effectiveDate)) {
      throw ArgumentError('Licence expiry cannot precede its effective date.');
    }
  }

  final String id;
  final String softwareProduct;
  final String vendor;
  final SoftwareLicenceType licenceType;
  final int purchasedQuantity;
  final int allocatedQuantity;
  final DateTime purchaseDate;
  final DateTime effectiveDate;
  final DateTime? expiryDate;
  final DateTime? renewalDate;
  final String contractId;
  final String contractReference;
  final double? cost;
  final String currencyCode;
  final LicenceComplianceStatus complianceStatus;
  final String notes;
  final DateTime updatedAt;

  int get availableQuantity => purchasedQuantity - allocatedQuantity;
  bool get isOverAllocated => availableQuantity < 0;

  bool isExpiredAt(DateTime date) {
    final expiry = expiryDate;
    return expiry != null && !expiry.isAfter(date.toUtc());
  }

  bool canAllocate(int quantity, {DateTime? at}) =>
      quantity > 0 &&
      availableQuantity >= quantity &&
      !isExpiredAt(at ?? DateTime.now());

  factory SoftwareLicence.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) =>
      SoftwareLicence.fromMap(snapshot.id, snapshot.data() ?? const {});

  factory SoftwareLicence.fromMap(
    String id,
    Map<String, Object?> data,
  ) =>
      SoftwareLicence(
        id: id,
        softwareProduct: itsmAssetString(data, 'softwareProduct'),
        vendor: itsmAssetString(data, 'vendor'),
        licenceType: SoftwareLicenceType.fromValue(data['licenceType']),
        purchasedQuantity: itsmAssetInt(data, 'purchasedQuantity'),
        allocatedQuantity: itsmAssetInt(data, 'allocatedQuantity'),
        purchaseDate: itsmAssetDate(data['purchaseDate']) ?? DateTime.utc(1970),
        effectiveDate:
            itsmAssetDate(data['effectiveDate']) ?? DateTime.utc(1970),
        expiryDate: itsmAssetDate(data['expiryDate']),
        renewalDate: itsmAssetDate(data['renewalDate']),
        contractId: itsmAssetString(data, 'contractId'),
        contractReference: itsmAssetString(data, 'contractReference'),
        cost: data['cost'] == null ? null : itsmAssetDouble(data, 'cost'),
        currencyCode: itsmAssetString(data, 'currencyCode').isNotEmpty
            ? itsmAssetString(data, 'currencyCode')
            : itsmAssetString(data, 'currency'),
        complianceStatus:
            LicenceComplianceStatus.fromValue(data['complianceStatus']),
        notes: itsmAssetString(data, 'notes'),
        updatedAt: itsmAssetDate(data['updatedAt']) ?? DateTime.utc(1970),
      );

  Map<String, Object?> toFirestore() => {
        'softwareProduct': softwareProduct,
        'vendor': vendor,
        'licenceType': licenceType.value,
        'purchasedQuantity': purchasedQuantity,
        'allocatedQuantity': allocatedQuantity,
        'availableQuantity': availableQuantity,
        'purchaseDate': itsmAssetTimestamp(purchaseDate),
        'effectiveDate': itsmAssetTimestamp(effectiveDate),
        'expiryDate': itsmAssetTimestamp(expiryDate),
        'renewalDate': itsmAssetTimestamp(renewalDate),
        'contractId': contractId,
        'contractReference': contractReference,
        'cost': cost,
        'currencyCode': currencyCode,
        'complianceStatus': complianceStatus.value,
        'notes': notes,
        'updatedAt': itsmAssetTimestamp(updatedAt),
      };
}

class SoftwareLicenceAssignment {
  SoftwareLicenceAssignment({
    required String id,
    required String licenceId,
    required this.quantity,
    required this.status,
    required DateTime assignedAt,
    required String assignedByUserId,
    this.assignedUserId = '',
    this.assignedUserName = '',
    this.assignedAssetId = '',
    this.assignedAssetTag = '',
    DateTime? revokedAt,
    this.revokedByUserId = '',
  })  : id = requireItsmAssetText(id, 'id'),
        licenceId = requireItsmAssetText(licenceId, 'licenceId'),
        assignedByUserId = requireItsmAssetText(
          assignedByUserId,
          'assignedByUserId',
        ),
        assignedAt = assignedAt.toUtc(),
        revokedAt = revokedAt?.toUtc() {
    if (quantity < 1) throw RangeError.range(quantity, 1, null, 'quantity');
    if (assignedUserId.trim().isEmpty && assignedAssetId.trim().isEmpty) {
      throw ArgumentError('A licence assignment needs a user or asset.');
    }
    if (status == LicenceAssignmentStatus.active && revokedAt != null) {
      throw ArgumentError('An active licence assignment cannot be revoked.');
    }
  }

  final String id;
  final String licenceId;
  final String assignedUserId;
  final String assignedUserName;
  final String assignedAssetId;
  final String assignedAssetTag;
  final int quantity;
  final LicenceAssignmentStatus status;
  final DateTime assignedAt;
  final String assignedByUserId;
  final DateTime? revokedAt;
  final String revokedByUserId;

  factory SoftwareLicenceAssignment.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) =>
      SoftwareLicenceAssignment.fromMap(
        snapshot.id,
        snapshot.data() ?? const {},
      );

  factory SoftwareLicenceAssignment.fromMap(
    String id,
    Map<String, Object?> data,
  ) {
    final assignmentType = itsmAssetString(data, 'assignmentType');
    final assigneeId = itsmAssetString(data, 'assigneeId');
    final assigneeName = itsmAssetString(data, 'assigneeName');
    final allocatedBy = itsmAssetMap(data['allocatedBy']);
    final releasedBy = itsmAssetMap(data['releasedBy']);
    return SoftwareLicenceAssignment(
      id: id,
      licenceId: itsmAssetString(data, 'licenceId'),
      assignedUserId: itsmAssetString(data, 'assignedUserId').isNotEmpty
          ? itsmAssetString(data, 'assignedUserId')
          : assignmentType == 'user'
              ? assigneeId
              : '',
      assignedUserName: itsmAssetString(data, 'assignedUserName').isNotEmpty
          ? itsmAssetString(data, 'assignedUserName')
          : assignmentType == 'user'
              ? assigneeName
              : '',
      assignedAssetId: itsmAssetString(data, 'assignedAssetId').isNotEmpty
          ? itsmAssetString(data, 'assignedAssetId')
          : assignmentType == 'device'
              ? assigneeId
              : '',
      assignedAssetTag: itsmAssetString(data, 'assignedAssetTag'),
      quantity: itsmAssetInt(data, 'quantity'),
      status: LicenceAssignmentStatus.values.firstWhere(
        (status) => status.name == data['status']?.toString(),
        orElse: () => LicenceAssignmentStatus.active,
      ),
      assignedAt: itsmAssetDate(data['assignedAt'] ?? data['allocatedAt']) ??
          DateTime.utc(1970),
      assignedByUserId: itsmAssetString(data, 'assignedByUserId').isNotEmpty
          ? itsmAssetString(data, 'assignedByUserId')
          : itsmAssetString(allocatedBy, 'userId'),
      revokedAt: itsmAssetDate(data['revokedAt'] ?? data['releasedAt']),
      revokedByUserId: itsmAssetString(data, 'revokedByUserId').isNotEmpty
          ? itsmAssetString(data, 'revokedByUserId')
          : itsmAssetString(releasedBy, 'userId'),
    );
  }

  Map<String, Object?> toFirestore() => {
        'licenceId': licenceId,
        'assignedUserId': assignedUserId,
        'assignedUserName': assignedUserName,
        'assignedAssetId': assignedAssetId,
        'assignedAssetTag': assignedAssetTag,
        'quantity': quantity,
        'status': status.name,
        'assignedAt': itsmAssetTimestamp(assignedAt),
        'assignedByUserId': assignedByUserId,
        'revokedAt': itsmAssetTimestamp(revokedAt),
        'revokedByUserId': revokedByUserId,
      };
}

class LicenceHistoryEvent {
  LicenceHistoryEvent({
    required String id,
    required String licenceId,
    required this.type,
    required String actorUserId,
    required DateTime occurredAt,
    this.quantityDelta = 0,
    this.assignmentId = '',
    this.reason = '',
  })  : id = requireItsmAssetText(id, 'id'),
        licenceId = requireItsmAssetText(licenceId, 'licenceId'),
        actorUserId = requireItsmAssetText(actorUserId, 'actorUserId'),
        occurredAt = occurredAt.toUtc();

  final String id;
  final String licenceId;
  final LicenceHistoryEventType type;
  final String actorUserId;
  final DateTime occurredAt;
  final int quantityDelta;
  final String assignmentId;
  final String reason;

  factory LicenceHistoryEvent.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) =>
      LicenceHistoryEvent.fromMap(snapshot.id, {
        ...?snapshot.data(),
        'licenceId': snapshot.data()?['licenceId'] ??
            snapshot.reference.parent.parent?.id,
      });

  factory LicenceHistoryEvent.fromMap(
    String id,
    Map<String, Object?> data,
  ) {
    final actor = itsmAssetMap(data['actor']);
    final before = itsmAssetMap(data['before']);
    final after = itsmAssetMap(data['after']);
    return LicenceHistoryEvent(
      id: id,
      licenceId: itsmAssetString(data, 'licenceId'),
      type: _licenceHistoryEventType(data['type'] ?? data['action']),
      actorUserId: itsmAssetString(data, 'actorUserId').isNotEmpty
          ? itsmAssetString(data, 'actorUserId')
          : itsmAssetString(actor, 'userId'),
      occurredAt: itsmAssetDate(data['occurredAt']) ?? DateTime.utc(1970),
      quantityDelta: data.containsKey('quantityDelta')
          ? itsmAssetInt(data, 'quantityDelta')
          : itsmAssetInt(after, 'allocatedQuantity') -
              itsmAssetInt(before, 'allocatedQuantity'),
      assignmentId: itsmAssetString(data, 'assignmentId').isNotEmpty
          ? itsmAssetString(data, 'assignmentId')
          : itsmAssetString(after, 'allocationId'),
      reason: itsmAssetString(data, 'reason'),
    );
  }

  Map<String, Object?> toFirestore() => {
        'licenceId': licenceId,
        'type': type.value,
        'actorUserId': actorUserId,
        'occurredAt': itsmAssetTimestamp(occurredAt),
        'quantityDelta': quantityDelta,
        'assignmentId': assignmentId,
        'reason': reason,
      };
}

LicenceHistoryEventType _licenceHistoryEventType(Object? value) {
  final normalized = value?.toString().toLowerCase() ?? '';
  return switch (normalized) {
    'registered' => LicenceHistoryEventType.purchased,
    'allocated' => LicenceHistoryEventType.assigned,
    'released' => LicenceHistoryEventType.revoked,
    _ => LicenceHistoryEventType.values.firstWhere(
        (type) => type.value == normalized,
        orElse: () => LicenceHistoryEventType.purchased,
      ),
  };
}
