import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:arptc_connect/modules/usermanagement/domain/modules.dart';

enum AgentSex {
  male('male'),
  female('female');

  const AgentSex(this.value);

  final String value;

  static AgentSex? fromValue(Object? value) {
    final normalized = value?.toString().trim().toLowerCase();
    for (final sex in values) {
      if (sex.value == normalized) return sex;
    }
    return null;
  }
}

class UserManagementAgent {
  final String id;
  final String firstName;
  final String name;
  final String postName;
  final String matricule;
  final AgentSex? sex;
  final String email;
  final String emailLower;
  final String? profilePictureUrl;
  final String jobTitle;
  final String department;
  final String departmentId;
  final String service;
  final String serviceId;
  final String bureau;
  final String bureauId;
  final int organizationSchemaVersion;
  final String organizationId;
  final String organizationName;
  final String primaryOrganizationUnitId;
  final String primaryOrganizationUnitName;
  final String primaryOrganizationUnitType;
  final String primaryAssignmentId;
  final List<String> organizationAncestorUnitIds;
  final List<String> organizationPathUnitIds;
  final List<String> organizationPathNames;
  final List<String> scopeKeys;
  final bool isActive;
  final Map<String, String> modulePermissions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserManagementAgent({
    required this.id,
    required this.firstName,
    required this.name,
    required this.postName,
    required this.matricule,
    this.sex,
    required this.email,
    required this.emailLower,
    this.profilePictureUrl,
    this.jobTitle = '',
    required this.department,
    required this.departmentId,
    required this.service,
    required this.serviceId,
    required this.bureau,
    required this.bureauId,
    this.organizationSchemaVersion = 2,
    this.organizationId = '',
    this.organizationName = '',
    this.primaryOrganizationUnitId = '',
    this.primaryOrganizationUnitName = '',
    this.primaryOrganizationUnitType = '',
    this.primaryAssignmentId = '',
    this.organizationAncestorUnitIds = const [],
    this.organizationPathUnitIds = const [],
    this.organizationPathNames = const [],
    this.scopeKeys = const [],
    required this.isActive,
    required this.modulePermissions,
    this.createdAt,
    this.updatedAt,
  });

  factory UserManagementAgent.fromMap(Map<String, dynamic> map,
      {required String id}) {
    final parsedName = _parseNames(map);
    final legacyFullName = (map['fullName'] as String?)?.trim() ?? '';
    final postNameFromMap = (map['postName'] as String?)?.trim() ?? '';
    final rawModulePermissions =
        map['modulePermissions'] is Map<String, dynamic>
            ? map['modulePermissions'] as Map<String, dynamic>
            : map['modulePermissions'] is Map
                ? Map<String, dynamic>.from(map['modulePermissions'] as Map)
                : null;
    final modulePermissions =
        Modules.normalizePermissions(rawModulePermissions);

    return UserManagementAgent(
      id: id,
      firstName: parsedName.firstName,
      name: parsedName.lastName,
      postName: postNameFromMap.isNotEmpty
          ? postNameFromMap
          : _fallbackPostName(
              legacyFullName: legacyFullName,
              firstName: parsedName.firstName,
              name: parsedName.lastName,
            ),
      matricule: (map['matricule'] as String?)?.trim() ?? '',
      sex: AgentSex.fromValue(map['sex'] ?? map['genre']),
      email: (map['email'] as String?)?.trim() ?? '',
      emailLower: (map['emailLower'] as String?)?.trim() ??
          ((map['email'] as String?)?.trim().toLowerCase() ?? ''),
      profilePictureUrl: _extractProfilePictureUrl(map),
      jobTitle: (map['jobTitle'] as String?)?.trim().isNotEmpty == true
          ? (map['jobTitle'] as String).trim()
          : (map['position'] as String?)?.trim() ?? '',
      department: (map['department'] as String?)?.trim() ?? '',
      departmentId: (map['departmentId'] as String?)?.trim() ?? '',
      service: (map['service'] as String?)?.trim() ?? '',
      serviceId: (map['serviceId'] as String?)?.trim() ?? '',
      bureau: (map['bureau'] as String?)?.trim() ?? '',
      bureauId: (map['bureauId'] as String?)?.trim() ?? '',
      organizationSchemaVersion:
          _toInt(map['organizationSchemaVersion'], fallback: 2),
      organizationId: (map['organizationId'] as String?)?.trim() ?? '',
      organizationName: (map['organizationName'] as String?)?.trim() ?? '',
      primaryOrganizationUnitId:
          (map['primaryOrganizationUnitId'] as String?)?.trim() ?? '',
      primaryOrganizationUnitName:
          (map['primaryOrganizationUnitName'] as String?)?.trim() ?? '',
      primaryOrganizationUnitType:
          (map['primaryOrganizationUnitType'] as String?)?.trim() ?? '',
      primaryAssignmentId:
          (map['primaryAssignmentId'] as String?)?.trim() ?? '',
      organizationAncestorUnitIds:
          _toStringList(map['organizationAncestorUnitIds']),
      organizationPathUnitIds: _toStringList(map['organizationPathUnitIds']),
      organizationPathNames: _toStringList(map['organizationPathNames']),
      scopeKeys: _toStringList(map['scopeKeys']),
      isActive: map['isActive'] as bool? ?? true,
      modulePermissions: modulePermissions,
      createdAt: _toDateTime(map['createdAt']),
      updatedAt: _toDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    final now = Timestamp.now();
    final normalizedPermissions = Modules.normalizePermissions(
      modulePermissions,
      includeDefaultModules: false,
    );

    return {
      'firstName': firstName.trim(),
      'name': name.trim(),
      'postName': postName.trim(),
      'matricule': matricule.trim(),
      'sex': sex?.value,
      'email': email.trim(),
      'emailLower': email.trim().toLowerCase(),
      'profilePictureUrl': profilePictureUrl,
      'jobTitle': jobTitle.trim(),
      'department': department.trim(),
      'departmentId': departmentId.trim(),
      'service': service.trim(),
      'serviceId': serviceId.trim(),
      'bureau': bureau.trim(),
      'bureauId': bureauId.trim(),
      'organizationSchemaVersion': organizationSchemaVersion,
      'organizationId': organizationId.trim(),
      'organizationName': organizationName.trim(),
      'primaryOrganizationUnitId': primaryOrganizationUnitId.trim(),
      'primaryOrganizationUnitName': primaryOrganizationUnitName.trim(),
      'primaryOrganizationUnitType': primaryOrganizationUnitType.trim(),
      'primaryAssignmentId': primaryAssignmentId.trim(),
      'organizationAncestorUnitIds': organizationAncestorUnitIds,
      'organizationPathUnitIds': organizationPathUnitIds,
      'organizationPathNames': organizationPathNames,
      'scopeKeys': scopeKeys,
      'isActive': isActive,
      'modulePermissions': normalizedPermissions,
      'createdAt': createdAt == null ? now : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null ? now : Timestamp.fromDate(updatedAt!),
    };
  }

  String get displayName {
    final chunks = [
      firstName.trim(),
      name.trim(),
      postName.trim(),
    ].where((chunk) => chunk.isNotEmpty).toList();
    return chunks.join(' ');
  }

  String get displayNameLower => displayName.toLowerCase();

  /// Temporary source compatibility for screens being migrated to job titles.
  /// Leadership authority lives in organization assignments, not this value.
  String get position => jobTitle;
}

class _NameParts {
  final String firstName;
  final String lastName;

  const _NameParts(this.firstName, this.lastName);
}

_NameParts _parseNames(Map<String, dynamic> map) {
  final firstName = (map['firstName'] as String?)?.trim();
  final lastName = (map['name'] as String?)?.trim();

  if (firstName != null &&
      firstName.isNotEmpty &&
      lastName != null &&
      lastName.isNotEmpty) {
    return _NameParts(firstName, lastName);
  }

  final fullNameFromMap =
      ((map['fullName'] as String?)?.trim().isNotEmpty == true)
          ? (map['fullName'] as String).trim()
          : ((map['name'] as String?)?.trim() ?? '');

  if (fullNameFromMap.isEmpty) {
    return const _NameParts('', '');
  }

  final parts = fullNameFromMap
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) {
    return const _NameParts('', '');
  }
  if (parts.length == 1) {
    return _NameParts(parts.first, '');
  }

  return _NameParts(parts.first, parts.sublist(1).join(' '));
}

String? _extractProfilePictureUrl(Map<String, dynamic> map) {
  final candidates = [
    map['profilePictureUrl'],
    map['photoUrl'],
    map['photoURL'],
    map['avatarUrl'],
    map['imageUrl'],
  ];

  for (final candidate in candidates) {
    if (candidate is String && candidate.trim().isNotEmpty) {
      return candidate.trim();
    }
  }

  return null;
}

DateTime? _toDateTime(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  return null;
}

List<String> _toStringList(dynamic value) {
  if (value is! Iterable) return const [];
  return List.unmodifiable(
    value
        .map((entry) => entry.toString().trim())
        .where((entry) => entry.isNotEmpty),
  );
}

int _toInt(dynamic value, {required int fallback}) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

String _fallbackPostName({
  required String legacyFullName,
  required String firstName,
  required String name,
}) {
  if (legacyFullName.isEmpty) {
    return '';
  }

  final normalizedLegacy = legacyFullName.toLowerCase();
  final normalizedFromNames = '$firstName $name'.trim().toLowerCase();
  if (normalizedLegacy == normalizedFromNames) {
    return '';
  }

  return legacyFullName;
}
