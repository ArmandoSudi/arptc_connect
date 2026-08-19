import 'package:arptc_connect/modules/usermanagement/domain/organization.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization_unit.dart';

enum OrganizationAssignmentType {
  member('MEMBER'),
  head('HEAD');

  const OrganizationAssignmentType(this.value);
  final String value;

  static OrganizationAssignmentType parse(Object? value) {
    final normalized = value?.toString().trim().toUpperCase();
    return normalized == head.value ? head : member;
  }
}

enum OrganizationAssignmentStatus {
  active('ACTIVE'),
  ended('ENDED'),
  cancelled('CANCELLED');

  const OrganizationAssignmentStatus(this.value);
  final String value;

  static OrganizationAssignmentStatus parse(Object? value) {
    final normalized = value?.toString().trim().toUpperCase();
    return OrganizationAssignmentStatus.values.firstWhere(
      (status) => status.value == normalized,
      orElse: () => active,
    );
  }
}

class OrganizationAssignment {
  const OrganizationAssignment({
    required this.id,
    required this.organizationId,
    required this.agentId,
    required this.unitId,
    required this.unitType,
    required this.unitName,
    required this.ancestorUnitIds,
    required this.pathUnitIds,
    required this.pathNames,
    required this.scopeKeys,
    required this.assignmentType,
    required this.isPrimary,
    required this.isActing,
    required this.status,
    required this.startsAt,
    this.endsAt,
    required this.reason,
    this.createdAt,
    this.createdBy = '',
    this.updatedAt,
    this.updatedBy = '',
    this.endedAt,
    this.endedBy,
  });

  final String id;
  final String organizationId;
  final String agentId;
  final String unitId;
  final OrganizationUnitType unitType;
  final String unitName;
  final List<String> ancestorUnitIds;
  final List<String> pathUnitIds;
  final List<String> pathNames;
  final List<String> scopeKeys;
  final OrganizationAssignmentType assignmentType;
  final bool isPrimary;
  final bool isActing;
  final OrganizationAssignmentStatus status;
  final DateTime startsAt;
  final DateTime? endsAt;
  final String reason;
  final DateTime? createdAt;
  final String createdBy;
  final DateTime? updatedAt;
  final String updatedBy;
  final DateTime? endedAt;
  final String? endedBy;

  bool get isCurrent => status == OrganizationAssignmentStatus.active;

  factory OrganizationAssignment.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    return OrganizationAssignment(
      id: id,
      organizationId: (map['organizationId'] ?? '').toString().trim(),
      agentId: (map['agentId'] ?? '').toString().trim(),
      unitId: (map['unitId'] ?? '').toString().trim(),
      unitType: OrganizationUnitType.parse(map['unitType']),
      unitName: (map['unitName'] ?? '').toString().trim(),
      ancestorUnitIds: _stringList(map['ancestorUnitIds']),
      pathUnitIds: _stringList(map['pathUnitIds']),
      pathNames: _stringList(map['pathNames']),
      scopeKeys: _stringList(map['scopeKeys']),
      assignmentType: OrganizationAssignmentType.parse(map['assignmentType']),
      isPrimary: map['isPrimary'] == true,
      isActing: map['isActing'] == true,
      status: OrganizationAssignmentStatus.parse(map['status']),
      startsAt: organizationDateTime(map['startsAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      endsAt: organizationDateTime(map['endsAt']),
      reason: (map['reason'] ?? '').toString().trim(),
      createdAt: organizationDateTime(map['createdAt']),
      createdBy: (map['createdBy'] ?? '').toString().trim(),
      updatedAt: organizationDateTime(map['updatedAt']),
      updatedBy: (map['updatedBy'] ?? '').toString().trim(),
      endedAt: organizationDateTime(map['endedAt']),
      endedBy: _nullableString(map['endedBy']),
    );
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
