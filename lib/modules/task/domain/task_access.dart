import 'package:arptc_connect/modules/task/domain/task.dart';
import 'package:arptc_connect/modules/usermanagement/domain/modules.dart';

enum TaskRole {
  none('NONE'),
  user('USER'),
  manager('MANAGER'),
  admin('ADMIN');

  const TaskRole(this.value);

  final String value;

  static TaskRole fromValue(Object? value) {
    final normalized = value?.toString().trim().toUpperCase() ?? '';
    return TaskRole.values.firstWhere(
      (role) => role.value == normalized,
      orElse: () => TaskRole.none,
    );
  }
}

extension TaskRoleAccess on TaskRole {
  bool get canRead => this != TaskRole.none;
  bool get canViewAllDepartments => this == TaskRole.admin;
  bool get canCreate => this == TaskRole.user || this == TaskRole.manager;
  bool get canEdit => canCreate;
  bool get canDelete => canCreate;
  bool get isReadOnly => this == TaskRole.admin;
}

class TaskPrincipal {
  const TaskPrincipal({
    required this.userId,
    required this.profileId,
    required this.displayName,
    required this.email,
    required this.departmentId,
    required this.departmentName,
    required this.role,
  });

  final String userId;
  final String profileId;
  final String displayName;
  final String email;
  final String departmentId;
  final String departmentName;
  final TaskRole role;

  bool get hasDepartment => departmentId.trim().isNotEmpty;

  factory TaskPrincipal.fromProfile({
    required Map<String, dynamic> profile,
    required String authUserId,
    required String authEmail,
  }) {
    final rawPermissions = profile['modulePermissions'];
    final permissions = Modules.normalizePermissions(
      rawPermissions is Map<String, dynamic>
          ? rawPermissions
          : rawPermissions is Map
              ? Map<String, dynamic>.from(rawPermissions)
              : null,
      includeDefaultModules: false,
    );
    final displayName = [
      _string(profile['firstName']),
      _string(profile['name']),
      _string(profile['postName']),
    ].where((part) => part.isNotEmpty).join(' ');

    return TaskPrincipal(
      userId: authUserId,
      profileId: _string(profile['id']).isNotEmpty
          ? _string(profile['id'])
          : authUserId,
      displayName: displayName.isNotEmpty ? displayName : 'Agent',
      email: _string(profile['email']).isNotEmpty
          ? _string(profile['email'])
          : authEmail,
      departmentId: _firstString(
        profile,
        const ['departmentId', 'department', 'direction'],
      ),
      departmentName: _firstString(
        profile,
        const ['departmentName', 'department_name', 'directionName'],
      ),
      role: TaskRole.fromValue(
        permissions['tasks'] ?? permissions['task'],
      ),
    );
  }
}

abstract final class TaskAccessPolicy {
  static bool canViewTask(TaskPrincipal principal, Task task) {
    if (!principal.role.canRead) return false;
    return principal.role.canViewAllDepartments ||
        _belongsToPrincipalDepartment(principal, task);
  }

  static bool canMutateTask(TaskPrincipal principal, Task task) {
    return principal.role.canEdit &&
        _belongsToPrincipalDepartment(principal, task);
  }

  static bool canDeleteTask(TaskPrincipal principal, Task task) {
    return principal.role.canDelete &&
        _belongsToPrincipalDepartment(principal, task);
  }

  static bool _belongsToPrincipalDepartment(
    TaskPrincipal principal,
    Task task,
  ) {
    return principal.hasDepartment &&
        principal.departmentId == task.departmentId;
  }
}

String _string(Object? value) => value?.toString().trim() ?? '';

String _firstString(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = _string(map[key]);
    if (value.isNotEmpty) return value;
  }
  return '';
}
