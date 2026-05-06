import 'package:arptc_connect/modules/usermanagement/domain/modules.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserManagementModule {
  final String id;
  final String key;
  final String name;
  final String nameLower;
  final String description;
  final List<String> availableRoles;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserManagementModule({
    required this.id,
    required this.key,
    required this.name,
    required this.nameLower,
    required this.description,
    required this.availableRoles,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory UserManagementModule.fromMap(Map<String, dynamic> map,
      {required String id}) {
    final rawRoles = (map['availableRoles'] as List<dynamic>? ?? const []);
    final normalizedRoles = rawRoles
        .map((role) => ModuleAccessRole.fromValue(role.toString()).value)
        .where((value) => value != ModuleAccessRole.none.value)
        .toSet()
        .toList()
      ..sort();

    return UserManagementModule(
      id: id,
      key: (map['key'] as String?)?.trim().toLowerCase() ?? '',
      name: (map['name'] as String?)?.trim() ?? '',
      nameLower: (map['nameLower'] as String?)?.trim() ??
          ((map['name'] as String?)?.trim().toLowerCase() ?? ''),
      description: (map['description'] as String?)?.trim() ?? '',
      availableRoles: normalizedRoles,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: _toDateTime(map['createdAt']),
      updatedAt: _toDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    final now = Timestamp.now();
    final roles = availableRoles
        .map((role) => ModuleAccessRole.fromValue(role).value)
        .where((value) => value != ModuleAccessRole.none.value)
        .toSet()
        .toList()
      ..sort();

    return {
      'key': key.trim().toLowerCase(),
      'name': name.trim(),
      'nameLower': name.trim().toLowerCase(),
      'description': description.trim(),
      'availableRoles': roles,
      'isActive': isActive,
      'createdAt': createdAt == null ? now : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null ? now : Timestamp.fromDate(updatedAt!),
    };
  }

  List<ModuleAccessRole> get accessRoles {
    final roles = availableRoles
        .map((role) => ModuleAccessRole.fromValue(role))
        .where((role) => role != ModuleAccessRole.none)
        .toSet()
        .toList();

    if (roles.isEmpty) {
      return const [ModuleAccessRole.user];
    }

    return roles;
  }

  List<ModuleAccessRole> get accessRolesWithNone {
    return [ModuleAccessRole.none, ...accessRoles];
  }
}

DateTime? _toDateTime(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  return null;
}
