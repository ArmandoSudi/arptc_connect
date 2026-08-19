enum UserManagementRole {
  none,
  user,
  manager,
  admin;

  static UserManagementRole parse(Object? value) {
    return switch (value?.toString().trim().toUpperCase()) {
      'USER' => UserManagementRole.user,
      'MANAGER' => UserManagementRole.manager,
      'ADMIN' => UserManagementRole.admin,
      _ => UserManagementRole.none,
    };
  }
}

class UserManagementAccessPolicy {
  const UserManagementAccessPolicy(this.role);

  final UserManagementRole role;

  bool get canOpenModule => role != UserManagementRole.none;
  bool get canReadDirectory => role != UserManagementRole.none;
  bool get canReadPrivateProfiles =>
      role == UserManagementRole.manager || role == UserManagementRole.admin;
  bool get canReadAudit =>
      role == UserManagementRole.manager || role == UserManagementRole.admin;
  bool get canManageOrganization => role == UserManagementRole.manager;
  bool get isReadOnlySupervisor => role == UserManagementRole.admin;

  static UserManagementAccessPolicy fromProfile(Map<String, dynamic> profile) {
    final rawPermissions = profile['modulePermissions'];
    final permissions = rawPermissions is Map
        ? Map<String, dynamic>.from(rawPermissions)
        : const <String, dynamic>{};
    return UserManagementAccessPolicy(
      UserManagementRole.parse(
        permissions['usermanagement'] ?? permissions['user_management'],
      ),
    );
  }
}
