import 'package:cloud_firestore/cloud_firestore.dart';

import 'assets_configuration_serialization.dart';

enum ContractStatus { draft, active, expired, terminated }

enum WarrantyStatus { active, expired, voided }

enum WarrantyClaimStatus {
  submitted,
  acknowledged,
  inProgress,
  approved,
  rejected,
  resolved,
  closed,
  cancelled;

  String get value => this == inProgress ? 'in_progress' : name;
}

class SupplierContact {
  SupplierContact({
    required String name,
    required String email,
    this.phone = '',
    this.role = '',
    this.isPrimary = false,
  })  : name = requireItsmAssetText(name, 'name'),
        email = email.trim().toLowerCase();

  final String name;
  final String email;
  final String phone;
  final String role;
  final bool isPrimary;

  factory SupplierContact.fromMap(Map<String, Object?> data) => SupplierContact(
        name: itsmAssetString(data, 'name'),
        email: itsmAssetString(data, 'email'),
        phone: itsmAssetString(data, 'phone'),
        role: itsmAssetString(data, 'role'),
        isPrimary: itsmAssetBool(data, 'isPrimary'),
      );

  Map<String, Object?> toFirestore() => {
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'isPrimary': isPrimary,
      };
}

class Supplier {
  Supplier({
    required String id,
    required String name,
    required this.isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.registrationNumber = '',
    this.address = '',
    this.supportEmail = '',
    this.supportPhone = '',
    this.supportTerms = '',
    this.slaPolicyId = '',
    Iterable<String> suppliedAssetCategoryIds = const [],
    Iterable<SupplierContact> contacts = const [],
  })  : id = requireItsmAssetText(id, 'id'),
        name = requireItsmAssetText(name, 'name'),
        suppliedAssetCategoryIds =
            immutableItsmAssetIds(suppliedAssetCategoryIds),
        contacts = List.unmodifiable(contacts),
        createdAt = createdAt.toUtc(),
        updatedAt = updatedAt.toUtc();

  final String id;
  final String name;
  final String registrationNumber;
  final String address;
  final String supportEmail;
  final String supportPhone;
  final String supportTerms;
  final String slaPolicyId;
  final List<String> suppliedAssetCategoryIds;
  final List<SupplierContact> contacts;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Supplier.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) =>
      Supplier.fromMap(snapshot.id, snapshot.data() ?? const {});

  factory Supplier.fromMap(String id, Map<String, Object?> data) => Supplier(
        id: id,
        name: itsmAssetString(data, 'name'),
        registrationNumber:
            itsmAssetString(data, 'registrationNumber').isNotEmpty
                ? itsmAssetString(data, 'registrationNumber')
                : itsmAssetString(data, 'supplierCode'),
        address: itsmAssetString(data, 'address'),
        supportEmail: itsmAssetString(data, 'supportEmail').isNotEmpty
            ? itsmAssetString(data, 'supportEmail')
            : itsmAssetString(data, 'contactEmail'),
        supportPhone: itsmAssetString(data, 'supportPhone').isNotEmpty
            ? itsmAssetString(data, 'supportPhone')
            : itsmAssetString(data, 'contactPhone'),
        supportTerms: itsmAssetString(data, 'supportTerms'),
        slaPolicyId: itsmAssetString(data, 'slaPolicyId').isNotEmpty
            ? itsmAssetString(data, 'slaPolicyId')
            : itsmAssetString(data, 'slaSummary'),
        suppliedAssetCategoryIds: itsmAssetStrings(
          data['suppliedAssetCategoryIds'] ?? data['assetCategoryIds'],
        ),
        contacts: _supplierContacts(data),
        isActive: itsmAssetBool(data, 'isActive'),
        createdAt: itsmAssetDate(data['createdAt']) ?? DateTime.utc(1970),
        updatedAt: itsmAssetDate(data['updatedAt']) ?? DateTime.utc(1970),
      );

  Map<String, Object?> toFirestore() => {
        'name': name,
        'registrationNumber': registrationNumber,
        'address': address,
        'supportEmail': supportEmail,
        'supportPhone': supportPhone,
        'supportTerms': supportTerms,
        'slaPolicyId': slaPolicyId,
        'suppliedAssetCategoryIds': suppliedAssetCategoryIds,
        'contacts': contacts.map((contact) => contact.toFirestore()).toList(),
        'isActive': isActive,
        'createdAt': itsmAssetTimestamp(createdAt),
        'updatedAt': itsmAssetTimestamp(updatedAt),
      };
}

class SupplierContract {
  SupplierContract({
    required String id,
    required String reference,
    required String name,
    required String supplierId,
    required String supplierName,
    required this.status,
    required DateTime startsAt,
    required DateTime endsAt,
    required DateTime updatedAt,
    this.supportTerms = '',
    this.slaPolicyId = '',
    this.cost,
    this.currencyCode = '',
    Iterable<String> attachmentIds = const [],
  })  : id = requireItsmAssetText(id, 'id'),
        reference = requireItsmAssetText(reference, 'reference'),
        name = requireItsmAssetText(name, 'name'),
        supplierId = requireItsmAssetText(supplierId, 'supplierId'),
        supplierName = supplierName.trim(),
        startsAt = startsAt.toUtc(),
        endsAt = endsAt.toUtc(),
        updatedAt = updatedAt.toUtc(),
        attachmentIds = immutableItsmAssetIds(attachmentIds) {
    if (!endsAt.isAfter(startsAt)) {
      throw ArgumentError('Contract end must be after its start.');
    }
    final contractCost = cost;
    if (contractCost != null && contractCost < 0) {
      throw RangeError.value(contractCost, 'cost');
    }
  }

  final String id;
  final String reference;
  final String name;
  final String supplierId;
  final String supplierName;
  final ContractStatus status;
  final DateTime startsAt;
  final DateTime endsAt;
  final String supportTerms;
  final String slaPolicyId;
  final double? cost;
  final String currencyCode;
  final List<String> attachmentIds;
  final DateTime updatedAt;

  bool isActiveAt(DateTime at) =>
      status == ContractStatus.active &&
      !at.toUtc().isBefore(startsAt) &&
      at.toUtc().isBefore(endsAt);

  factory SupplierContract.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) =>
      SupplierContract.fromMap(snapshot.id, snapshot.data() ?? const {});

  factory SupplierContract.fromMap(
    String id,
    Map<String, Object?> data,
  ) =>
      SupplierContract(
        id: id,
        reference: itsmAssetString(data, 'reference').isNotEmpty
            ? itsmAssetString(data, 'reference')
            : itsmAssetString(data, 'contractNumber'),
        name: itsmAssetString(data, 'name'),
        supplierId: itsmAssetString(data, 'supplierId'),
        supplierName: itsmAssetString(data, 'supplierName'),
        status: ContractStatus.values.firstWhere(
          (status) => status.name == data['status']?.toString(),
          orElse: () => ContractStatus.draft,
        ),
        startsAt: itsmAssetDate(data['startsAt'] ?? data['startDate']) ??
            DateTime.utc(1970),
        endsAt: itsmAssetDate(data['endsAt'] ?? data['endDate']) ??
            DateTime.utc(1970, 1, 2),
        supportTerms: itsmAssetString(data, 'supportTerms'),
        slaPolicyId: itsmAssetString(data, 'slaPolicyId'),
        cost: data['cost'] == null ? null : itsmAssetDouble(data, 'cost'),
        currencyCode: itsmAssetString(data, 'currencyCode'),
        attachmentIds: itsmAssetStrings(data['attachmentIds']),
        updatedAt: itsmAssetDate(data['updatedAt']) ?? DateTime.utc(1970),
      );

  Map<String, Object?> toFirestore() => {
        'reference': reference,
        'name': name,
        'supplierId': supplierId,
        'supplierName': supplierName,
        'status': status.name,
        'startsAt': itsmAssetTimestamp(startsAt),
        'endsAt': itsmAssetTimestamp(endsAt),
        'supportTerms': supportTerms,
        'slaPolicyId': slaPolicyId,
        'cost': cost,
        'currencyCode': currencyCode,
        'attachmentIds': attachmentIds,
        'updatedAt': itsmAssetTimestamp(updatedAt),
      };
}

class Warranty {
  Warranty({
    required String id,
    required String reference,
    required String supplierId,
    required this.status,
    required DateTime startsAt,
    required DateTime expiresAt,
    this.coverage = '',
    this.contractId = '',
    Iterable<String> linkedAssetIds = const [],
    Iterable<String> coveredAssetCategoryIds = const [],
    Iterable<String> attachmentIds = const [],
  })  : id = requireItsmAssetText(id, 'id'),
        reference = requireItsmAssetText(reference, 'reference'),
        supplierId = requireItsmAssetText(supplierId, 'supplierId'),
        startsAt = startsAt.toUtc(),
        expiresAt = expiresAt.toUtc(),
        linkedAssetIds = immutableItsmAssetIds(linkedAssetIds),
        coveredAssetCategoryIds =
            immutableItsmAssetIds(coveredAssetCategoryIds),
        attachmentIds = immutableItsmAssetIds(attachmentIds) {
    if (!expiresAt.isAfter(startsAt)) {
      throw ArgumentError('Warranty expiry must be after its start.');
    }
  }

  final String id;
  final String reference;
  final String supplierId;
  final String contractId;
  final WarrantyStatus status;
  final String coverage;
  final DateTime startsAt;
  final DateTime expiresAt;
  final List<String> linkedAssetIds;
  final List<String> coveredAssetCategoryIds;
  final List<String> attachmentIds;

  bool isActiveAt(DateTime at) {
    final instant = at.toUtc();
    return status == WarrantyStatus.active &&
        !instant.isBefore(startsAt) &&
        instant.isBefore(expiresAt);
  }

  bool coversAsset({required String assetId, required String categoryId}) =>
      linkedAssetIds.contains(assetId.trim()) ||
      coveredAssetCategoryIds.contains(categoryId.trim());

  factory Warranty.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) =>
      Warranty.fromMap(snapshot.id, snapshot.data() ?? const {});

  factory Warranty.fromMap(String id, Map<String, Object?> data) => Warranty(
        id: id,
        reference: itsmAssetString(data, 'reference').isNotEmpty
            ? itsmAssetString(data, 'reference')
            : itsmAssetString(data, 'warrantyNumber'),
        supplierId: itsmAssetString(data, 'supplierId'),
        contractId: itsmAssetString(data, 'contractId'),
        status: WarrantyStatus.values.firstWhere(
          (status) => status.name == data['status']?.toString(),
          orElse: () => WarrantyStatus.active,
        ),
        coverage: itsmAssetString(data, 'coverage'),
        startsAt: itsmAssetDate(data['startsAt'] ?? data['startDate']) ??
            DateTime.utc(1970),
        expiresAt: itsmAssetDate(data['expiresAt'] ?? data['expirationDate']) ??
            DateTime.utc(1970, 1, 2),
        linkedAssetIds:
            itsmAssetStrings(data['linkedAssetIds'] ?? data['assetIds']),
        coveredAssetCategoryIds:
            itsmAssetStrings(data['coveredAssetCategoryIds']),
        attachmentIds: itsmAssetStrings(data['attachmentIds']),
      );

  Map<String, Object?> toFirestore() => {
        'reference': reference,
        'supplierId': supplierId,
        'contractId': contractId,
        'status': status.name,
        'coverage': coverage,
        'startsAt': itsmAssetTimestamp(startsAt),
        'expiresAt': itsmAssetTimestamp(expiresAt),
        'linkedAssetIds': linkedAssetIds,
        'coveredAssetCategoryIds': coveredAssetCategoryIds,
        'attachmentIds': attachmentIds,
      };
}

Iterable<SupplierContact> _supplierContacts(Map<String, Object?> data) {
  if (data['contacts'] is Iterable) {
    return (data['contacts'] as Iterable)
        .map(itsmAssetMap)
        .map(SupplierContact.fromMap);
  }
  final email = itsmAssetString(data, 'contactEmail');
  final rawName = itsmAssetString(data, 'contactName');
  if (email.isEmpty && rawName.isEmpty) return const [];
  return [
    SupplierContact(
      name: rawName.isEmpty ? email : rawName,
      email: email,
      phone: itsmAssetString(data, 'contactPhone'),
      isPrimary: true,
    ),
  ];
}

class WarrantyClaim {
  WarrantyClaim({
    required String id,
    required String warrantyId,
    required String assetId,
    required this.status,
    required String issueSummary,
    required String submittedByUserId,
    required DateTime submittedAt,
    required DateTime updatedAt,
    this.supplierReference = '',
    this.description = '',
    this.resolution = '',
    DateTime? resolvedAt,
    Iterable<String> attachmentIds = const [],
  })  : id = requireItsmAssetText(id, 'id'),
        warrantyId = requireItsmAssetText(warrantyId, 'warrantyId'),
        assetId = requireItsmAssetText(assetId, 'assetId'),
        issueSummary = requireItsmAssetText(issueSummary, 'issueSummary'),
        submittedByUserId = requireItsmAssetText(
          submittedByUserId,
          'submittedByUserId',
        ),
        submittedAt = submittedAt.toUtc(),
        updatedAt = updatedAt.toUtc(),
        resolvedAt = resolvedAt?.toUtc(),
        attachmentIds = immutableItsmAssetIds(attachmentIds) {
    if (status == WarrantyClaimStatus.resolved && resolvedAt == null) {
      throw ArgumentError('Resolved warranty claims require resolvedAt.');
    }
  }

  final String id;
  final String warrantyId;
  final String assetId;
  final WarrantyClaimStatus status;
  final String issueSummary;
  final String supplierReference;
  final String description;
  final String submittedByUserId;
  final DateTime submittedAt;
  final DateTime updatedAt;
  final String resolution;
  final DateTime? resolvedAt;
  final List<String> attachmentIds;

  factory WarrantyClaim.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) =>
      WarrantyClaim.fromMap(snapshot.id, snapshot.data() ?? const {});

  factory WarrantyClaim.fromMap(
    String id,
    Map<String, Object?> data,
  ) {
    final actor = itsmAssetMap(data['actor']);
    final status = WarrantyClaimStatus.values.firstWhere(
      (status) => status.value == data['status']?.toString(),
      orElse: () => WarrantyClaimStatus.submitted,
    );
    final updatedAt = itsmAssetDate(data['updatedAt']) ?? DateTime.utc(1970);
    final resolvedAt = itsmAssetDate(data['resolvedAt']) ??
        ((status == WarrantyClaimStatus.resolved ||
                status == WarrantyClaimStatus.closed)
            ? updatedAt
            : null);
    return WarrantyClaim(
      id: id,
      warrantyId: itsmAssetString(data, 'warrantyId'),
      assetId: itsmAssetString(data, 'assetId'),
      status: status,
      issueSummary: itsmAssetString(data, 'issueSummary').isNotEmpty
          ? itsmAssetString(data, 'issueSummary')
          : itsmAssetString(data, 'title'),
      supplierReference: itsmAssetString(data, 'supplierReference'),
      description: itsmAssetString(data, 'description'),
      submittedByUserId: itsmAssetString(data, 'submittedByUserId').isNotEmpty
          ? itsmAssetString(data, 'submittedByUserId')
          : itsmAssetString(actor, 'userId'),
      submittedAt: itsmAssetDate(data['submittedAt'] ?? data['createdAt']) ??
          DateTime.utc(1970),
      updatedAt: updatedAt,
      resolution: itsmAssetString(data, 'resolution').isNotEmpty
          ? itsmAssetString(data, 'resolution')
          : itsmAssetString(data, 'transitionReason'),
      resolvedAt: resolvedAt,
      attachmentIds: _warrantyClaimAttachmentIds(data),
    );
  }

  Map<String, Object?> toFirestore() => {
        'warrantyId': warrantyId,
        'assetId': assetId,
        'status': status.value,
        'issueSummary': issueSummary,
        'description': description,
        'supplierReference': supplierReference,
        'submittedByUserId': submittedByUserId,
        'submittedAt': itsmAssetTimestamp(submittedAt),
        'updatedAt': itsmAssetTimestamp(updatedAt),
        'resolution': resolution,
        'resolvedAt': itsmAssetTimestamp(resolvedAt),
        'attachmentIds': attachmentIds,
      };
}

List<String> _warrantyClaimAttachmentIds(Map<String, Object?> data) {
  final attachmentIds = <String>{
    ...itsmAssetStrings(data['attachmentIds']),
  };
  final supportingDocument = itsmAssetMap(data['supportingDocument']);
  final supportingDocumentId =
      itsmAssetString(supportingDocument, 'attachmentId');
  if (supportingDocumentId.isNotEmpty) {
    attachmentIds.add(supportingDocumentId);
  }
  final evidence = data['evidence'];
  if (evidence is Iterable) {
    for (final item in evidence) {
      final attachmentId = itsmAssetString(itsmAssetMap(item), 'attachmentId');
      if (attachmentId.isNotEmpty) attachmentIds.add(attachmentId);
    }
  }
  return List.unmodifiable(attachmentIds);
}
