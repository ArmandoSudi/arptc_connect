import 'package:arptc_connect/modules/usermanagement/domain/organization.dart';

enum OrganizationUnitType {
  department('DEPARTMENT'),
  service('SERVICE'),
  bureau('BUREAU'),
  custom('CUSTOM');

  const OrganizationUnitType(this.value);

  final String value;

  static OrganizationUnitType parse(Object? value) {
    final normalized = value?.toString().trim().toUpperCase();
    return OrganizationUnitType.values.firstWhere(
      (type) => type.value == normalized,
      orElse: () => OrganizationUnitType.custom,
    );
  }
}

class OrganizationUnit {
  const OrganizationUnit({
    required this.id,
    required this.organizationId,
    required this.type,
    required this.code,
    required this.name,
    required this.description,
    required this.parentUnitId,
    required this.parentUnitType,
    required this.ancestorUnitIds,
    required this.pathUnitIds,
    required this.pathNames,
    required this.depth,
    required this.scopeKeys,
    required this.status,
    this.headUserId,
    this.headAssignmentId,
    this.actingHeadUserId,
    this.actingHeadAssignmentId,
    this.actingHeadEndsAt,
    this.schemaVersion = 2,
    this.createdAt,
    this.createdBy = '',
    this.updatedAt,
    this.updatedBy = '',
  });

  final String id;
  final String organizationId;
  final OrganizationUnitType type;
  final String code;
  final String name;
  final String description;
  final String? parentUnitId;
  final OrganizationUnitType? parentUnitType;
  final List<String> ancestorUnitIds;
  final List<String> pathUnitIds;
  final List<String> pathNames;
  final int depth;
  final List<String> scopeKeys;
  final OrganizationStatus status;
  final String? headUserId;
  final String? headAssignmentId;
  final String? actingHeadUserId;
  final String? actingHeadAssignmentId;
  final DateTime? actingHeadEndsAt;
  final int schemaVersion;
  final DateTime? createdAt;
  final String createdBy;
  final DateTime? updatedAt;
  final String updatedBy;

  String get nameLower => name.trim().toLowerCase();
  bool get isActive => status == OrganizationStatus.active;
  String get breadcrumb => pathNames.join(' / ');

  factory OrganizationUnit.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    final parentType = _nullableString(map['parentUnitType']);
    return OrganizationUnit(
      id: id,
      organizationId: (map['organizationId'] ?? '').toString().trim(),
      type: OrganizationUnitType.parse(map['type']),
      code: (map['code'] ?? '').toString().trim(),
      name: (map['name'] ?? '').toString().trim(),
      description: (map['description'] ?? '').toString().trim(),
      parentUnitId: _nullableString(map['parentUnitId']),
      parentUnitType:
          parentType == null ? null : OrganizationUnitType.parse(parentType),
      ancestorUnitIds: _stringList(map['ancestorUnitIds']),
      pathUnitIds: _stringList(map['pathUnitIds']),
      pathNames: _stringList(map['pathNames']),
      depth: _integer(map['depth']),
      scopeKeys: _stringList(map['scopeKeys']),
      status: OrganizationStatus.parse(map['status']),
      headUserId: _nullableString(map['headUserId']),
      headAssignmentId: _nullableString(map['headAssignmentId']),
      actingHeadUserId: _nullableString(map['actingHeadUserId']),
      actingHeadAssignmentId: _nullableString(map['actingHeadAssignmentId']),
      actingHeadEndsAt: organizationDateTime(map['actingHeadEndsAt']),
      schemaVersion: _integer(map['schemaVersion'], fallback: 2),
      createdAt: organizationDateTime(map['createdAt']),
      createdBy: (map['createdBy'] ?? '').toString().trim(),
      updatedAt: organizationDateTime(map['updatedAt']),
      updatedBy: (map['updatedBy'] ?? '').toString().trim(),
    );
  }
}

class OrganizationHierarchyPolicy {
  const OrganizationHierarchyPolicy();

  bool acceptsParent({
    required OrganizationUnitType childType,
    OrganizationUnitType? parentType,
  }) {
    return switch (childType) {
      OrganizationUnitType.department => parentType == null,
      OrganizationUnitType.service =>
        parentType == OrganizationUnitType.department,
      OrganizationUnitType.bureau => parentType == OrganizationUnitType.service,
      OrganizationUnitType.custom => parentType != null,
    };
  }

  OrganizationUnitType? requiredParentType(OrganizationUnitType type) {
    return switch (type) {
      OrganizationUnitType.department => null,
      OrganizationUnitType.service => OrganizationUnitType.department,
      OrganizationUnitType.bureau => OrganizationUnitType.service,
      OrganizationUnitType.custom => null,
    };
  }

  List<OrganizationUnitType> allowedChildTypes(OrganizationUnitType? parent) {
    return switch (parent) {
      null => const [OrganizationUnitType.department],
      OrganizationUnitType.department => const [OrganizationUnitType.service],
      OrganizationUnitType.service => const [OrganizationUnitType.bureau],
      OrganizationUnitType.bureau => const [],
      OrganizationUnitType.custom => const [OrganizationUnitType.custom],
    };
  }
}

List<String> _stringList(Object? value) {
  if (value is! Iterable) return const [];
  return List.unmodifiable(
    value
        .map((entry) => entry.toString().trim())
        .where((entry) => entry.isNotEmpty),
  );
}

String? _nullableString(Object? value) {
  final normalized = value?.toString().trim() ?? '';
  return normalized.isEmpty ? null : normalized;
}

int _integer(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
