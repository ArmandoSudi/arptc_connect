import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:arptc_connect/modules/usermanagement/domain/modules.dart';

class UserManagementAgent {
  final String id;
  final String firstName;
  final String name;
  final String postName;
  final String matricule;
  final String email;
  final String emailLower;
  final String? profilePictureUrl;
  final String position;
  final String departmentId;
  final String serviceId;
  final String bureauId;
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
    required this.email,
    required this.emailLower,
    this.profilePictureUrl,
    required this.position,
    required this.departmentId,
    required this.serviceId,
    required this.bureauId,
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
      email: (map['email'] as String?)?.trim() ?? '',
      emailLower: (map['emailLower'] as String?)?.trim() ??
          ((map['email'] as String?)?.trim().toLowerCase() ?? ''),
      profilePictureUrl: _extractProfilePictureUrl(map),
      position: (map['position'] as String?)?.trim() ?? 'BUREAU_ATTACHE',
      departmentId: (map['departmentId'] as String?)?.trim() ??
          (map['direction_ref'] as String?)?.trim() ??
          '',
      serviceId: (map['serviceId'] as String?)?.trim() ?? '',
      bureauId: (map['bureauId'] as String?)?.trim() ?? '',
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
      'email': email.trim(),
      'emailLower': email.trim().toLowerCase(),
      'profilePictureUrl': profilePictureUrl,
      'position': position.trim(),
      'departmentId': departmentId.trim(),
      'serviceId': serviceId.trim(),
      'bureauId': bureauId.trim(),
      'isActive': isActive,
      'modulePermissions': normalizedPermissions,
      'createdAt': createdAt == null ? now : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null ? now : Timestamp.fromDate(updatedAt!),

      // Legacy fields for backward compatibility with older screens/models.
      'genre': '',
      'dob': '',
      'category': '',
      'direction': departmentId.trim(),
      'service': serviceId.trim(),
      'bureau': bureauId.trim(),
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
