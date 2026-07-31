enum ModuleAccessRole {
  none('NONE', 'No access'),
  admin('ADMIN', 'Admin'),
  manager('MANAGER', 'Manager'),
  reviewer('REVIEWER', 'Reviewer'),
  user('USER', 'User');

  const ModuleAccessRole(this.value, this.label);

  final String value;
  final String label;

  static ModuleAccessRole fromValue(String? value) {
    final normalized = (value ?? '').trim().toUpperCase();
    for (final role in ModuleAccessRole.values) {
      if (role.value == normalized) {
        return role;
      }
    }
    return ModuleAccessRole.none;
  }

  static ModuleAccessRole fromDynamic(dynamic value) {
    if (value is String) {
      return fromValue(value);
    }
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      for (final key in const ['role', 'permission', 'access', 'value']) {
        if (!map.containsKey(key)) {
          continue;
        }
        final resolved = fromDynamic(map[key]);
        if (resolved != ModuleAccessRole.none) {
          return resolved;
        }
      }
      return ModuleAccessRole.none;
    }
    if (value is Iterable) {
      for (final item in value) {
        final resolved = fromDynamic(item);
        if (resolved != ModuleAccessRole.none) {
          return resolved;
        }
      }
      return ModuleAccessRole.none;
    }
    return fromValue(value?.toString());
  }
}

class ModuleDefinition {
  final String key;
  final String name;
  final List<ModuleAccessRole> availableRoles;

  const ModuleDefinition({
    required this.key,
    required this.name,
    this.availableRoles = const [
      ModuleAccessRole.none,
      ModuleAccessRole.admin,
      ModuleAccessRole.manager,
      ModuleAccessRole.user,
    ],
  });
}

class Modules {
  static const List<ModuleDefinition> all = [
    ModuleDefinition(
      key: 'tasks',
      name: 'Tasks',
    ),
    ModuleDefinition(
      key: 'courriers',
      name: 'Mails Management',
    ),
    ModuleDefinition(
      key: 'social',
      name: 'Social',
    ),
    ModuleDefinition(
      key: 'news',
      name: 'Company News',
      availableRoles: [
        ModuleAccessRole.none,
        ModuleAccessRole.manager,
        ModuleAccessRole.reviewer,
        ModuleAccessRole.user,
      ],
    ),
    ModuleDefinition(
      key: 'inventory',
      name: 'Inventory',
    ),
    ModuleDefinition(
      key: 'ticketing',
      name: 'IT Service Management',
    ),
    ModuleDefinition(
      key: 'meetinghall',
      name: 'Meeting Hall',
    ),
    ModuleDefinition(
      key: 'usermanagement',
      name: 'User Management',
    ),
  ];

  static Map<String, String> emptyPermissions() {
    return {
      for (final module in all) module.key: ModuleAccessRole.none.value,
    };
  }

  static Map<String, String> defaultUserPermissions() {
    return {
      for (final module in all) module.key: ModuleAccessRole.user.value,
    };
  }

  static String normalizeModuleKey(String candidate) {
    return _normalizeModuleKey(candidate) ?? _sanitizeKey(candidate);
  }

  static Map<String, String> normalizePermissions(
    Map<String, dynamic>? raw, {
    bool includeDefaultModules = true,
  }) {
    final normalized =
        includeDefaultModules ? emptyPermissions() : <String, String>{};
    if (raw == null) {
      return normalized;
    }

    raw.forEach((moduleKey, roleValue) {
      var effectiveModuleKey = moduleKey.toString();
      if (roleValue is Map) {
        final roleMap = Map<String, dynamic>.from(roleValue);
        final nestedKey = _extractNestedModuleKey(roleMap);
        if (nestedKey != null && nestedKey.trim().isNotEmpty) {
          effectiveModuleKey = nestedKey;
        }
      }
      final resolvedKey = normalizeModuleKey(effectiveModuleKey);
      if (resolvedKey.isEmpty) {
        return;
      }
      normalized[resolvedKey] = ModuleAccessRole.fromDynamic(roleValue).value;
    });

    return normalized;
  }

  static String moduleName(String key) {
    for (final module in all) {
      if (module.key == key) {
        return module.name;
      }
    }
    return key;
  }

  static String roleLabel(String roleValue) {
    return ModuleAccessRole.fromValue(roleValue).label;
  }

  static String? _normalizeModuleKey(String candidate) {
    final normalized = _sanitizeKey(candidate);
    if (normalized.isEmpty) {
      return null;
    }

    const aliases = <String, String>{
      'task': 'tasks',
      'tasks': 'tasks',
      'courrier': 'courriers',
      'courriers': 'courriers',
      'mail': 'courriers',
      'mails': 'courriers',
      'social': 'social',
      'news': 'news',
      'company_news': 'news',
      'communication': 'news',
      'communications': 'news',
      'feed': 'news',
      'inventory': 'inventory',
      'inventaire': 'inventory',
      'it_support': 'ticketing',
      'itsm': 'ticketing',
      'it_service_management': 'ticketing',
      'it_service_mgmt': 'ticketing',
      'service_management': 'ticketing',
      'support_it': 'ticketing',
      'support': 'ticketing',
      'helpdesk': 'ticketing',
      'incident': 'ticketing',
      'incidents': 'ticketing',
      'incident_management': 'ticketing',
      'incidentmanagement': 'ticketing',
      'ticket': 'ticketing',
      'tickets': 'ticketing',
      'ticketing': 'ticketing',
      'meeting': 'meetinghall',
      'meeting_hall': 'meetinghall',
      'meetinghall': 'meetinghall',
      'usermanagement': 'usermanagement',
      'user_management': 'usermanagement',
      'user': 'usermanagement',
      'users': 'usermanagement',
      'agent': 'usermanagement',
      'agents': 'usermanagement',
    };

    if (aliases.containsKey(normalized)) {
      return aliases[normalized];
    }

    for (final module in all) {
      if (module.key == normalized) {
        return module.key;
      }
    }

    return null;
  }

  static String _sanitizeKey(String candidate) {
    final normalized = candidate.trim().toLowerCase();
    if (normalized.isEmpty) {
      return '';
    }
    final withUnderscores = normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return withUnderscores.replaceAll(RegExp(r'_+'), '_').replaceAll(
          RegExp(r'^_|_$'),
          '',
        );
  }

  static String? _extractNestedModuleKey(Map<String, dynamic> value) {
    for (final key in const ['moduleKey', 'key', 'module', 'moduleName']) {
      final candidate = value[key]?.toString().trim() ?? '';
      if (candidate.isNotEmpty) {
        return candidate;
      }
    }
    return null;
  }
}
