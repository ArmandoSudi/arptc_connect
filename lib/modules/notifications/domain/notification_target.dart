class NotificationTarget {
  const NotificationTarget({
    required this.type,
    this.moduleKey = '',
    this.roles = const <String>[],
    this.userIds = const <String>[],
    this.userEmails = const <String>[],
  });

  final NotificationTargetType type;
  final String moduleKey;
  final List<String> roles;
  final List<String> userIds;
  final List<String> userEmails;

  factory NotificationTarget.all() {
    return const NotificationTarget(type: NotificationTargetType.all);
  }

  factory NotificationTarget.moduleRole({
    required String moduleKey,
    required List<String> roles,
  }) {
    return NotificationTarget(
      type: NotificationTargetType.moduleRole,
      moduleKey: moduleKey.trim(),
      roles: roles
          .map((role) => role.trim().toUpperCase())
          .where((role) => role.isNotEmpty)
          .toList(),
    );
  }

  factory NotificationTarget.users({
    List<String> userIds = const <String>[],
    List<String> userEmails = const <String>[],
  }) {
    return NotificationTarget(
      type: NotificationTargetType.users,
      userIds: userIds
          .map((userId) => userId.trim())
          .where((userId) => userId.isNotEmpty)
          .toList(),
      userEmails: userEmails
          .map((email) => email.trim().toLowerCase())
          .where((email) => email.isNotEmpty)
          .toList(),
    );
  }

  factory NotificationTarget.fromMap(Map<String, dynamic>? map) {
    final data = map ?? const <String, dynamic>{};
    return NotificationTarget(
      type: NotificationTargetType.fromValue(data['type']?.toString()),
      moduleKey: data['moduleKey']?.toString().trim() ?? '',
      roles:
          _stringList(data['roles']).map((role) => role.toUpperCase()).toList(),
      userIds: _stringList(data['userIds']),
      userEmails: _stringList(data['userEmails'])
          .map((email) => email.toLowerCase())
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type.value,
      'moduleKey': moduleKey.trim(),
      'roles': roles
          .map((role) => role.trim().toUpperCase())
          .where((role) => role.isNotEmpty)
          .toList(),
      'userIds': userIds
          .map((userId) => userId.trim())
          .where((userId) => userId.isNotEmpty)
          .toList(),
      'userEmails': userEmails
          .map((email) => email.trim().toLowerCase())
          .where((email) => email.isNotEmpty)
          .toList(),
    };
  }
}

enum NotificationTargetType {
  all('ALL'),
  moduleRole('MODULE_ROLE'),
  users('USERS');

  const NotificationTargetType(this.value);

  final String value;

  static NotificationTargetType fromValue(String? value) {
    final normalized = (value ?? '').trim().toUpperCase();
    for (final type in NotificationTargetType.values) {
      if (type.value == normalized) {
        return type;
      }
    }
    return NotificationTargetType.users;
  }
}

List<String> _stringList(dynamic value) {
  if (value is Iterable) {
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList();
  }
  return const <String>[];
}
