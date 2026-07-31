import 'dart:collection';

import '../data/itsm_work_item_repository.dart';
import '../domain/itsm_shared_domain.dart';

class ItsmSession {
  const ItsmSession({
    required this.sessionKey,
    required this.userId,
    required this.email,
    required this.displayName,
    required this.role,
  });

  final String sessionKey;
  final String userId;
  final String email;
  final String displayName;
  final ItsmRole role;

  ItsmPermissionPolicy get permissionPolicy => ItsmPermissionPolicy(role);

  ItsmQueryPrincipal get queryPrincipal => ItsmQueryPrincipal(
        sessionKey: sessionKey,
        userId: userId,
        email: email,
        role: role,
      );
}

class ItsmSessionResolver {
  const ItsmSessionResolver();

  static const Set<String> permissionAliases = {
    'ticketing',
    'itsm',
    'it_service_management',
    'support',
    'incident',
    'incidents',
    'incident_management',
    'incidentmanagement',
    'ticket',
    'tickets',
  };

  ItsmSession? resolve({
    required String? authUserId,
    required String? authEmail,
    required Map<String, Object?> profile,
  }) {
    final userId = authUserId?.trim() ?? '';
    final email = authEmail?.trim().toLowerCase() ?? '';
    if (userId.isEmpty || email.isEmpty || profile.isEmpty) return null;

    final profileEmail = _string(profile['email']).toLowerCase();
    final profileEmailLower = _string(profile['emailLower']).toLowerCase();
    final knownProfileEmails = {
      if (profileEmail.isNotEmpty) profileEmail,
      if (profileEmailLower.isNotEmpty) profileEmailLower,
    };
    if (knownProfileEmails.isNotEmpty && !knownProfileEmails.contains(email)) {
      return null;
    }

    final profileId = _string(profile['id']);
    if (profileId.isNotEmpty && profileId != userId) {
      return null;
    }

    final role = _roleFromProfile(profile);
    if (role == null) return null;

    final displayName = [
      _string(profile['firstName']),
      _string(profile['name']),
      _string(profile['postName']),
    ].where((part) => part.isNotEmpty).join(' ');

    return ItsmSession(
      sessionKey: '$userId|$email',
      userId: userId,
      email: email,
      displayName:
          displayName.isNotEmpty ? displayName : _string(profile['fullName']),
      role: role,
    );
  }

  ItsmRole? _roleFromProfile(Map<String, Object?> profile) {
    final permissions = _map(profile['modulePermissions']);
    for (final alias in permissionAliases) {
      final direct = ItsmRole.tryParse(permissions[alias]);
      if (direct != null) return direct;
    }

    for (final entry in permissions.entries) {
      final normalizedKey = entry.key
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
          .replaceAll(RegExp(r'^_|_$'), '');
      if (permissionAliases.contains(normalizedKey)) {
        final role = ItsmRole.tryParse(entry.value);
        if (role != null) return role;
      }
    }
    return null;
  }
}

class ItsmAccessPolicy {
  const ItsmAccessPolicy();

  void authorize(ItsmSession session, ItsmWorkItemScope scope) {
    final policy = session.permissionPolicy;
    final allowed = switch (scope) {
      ItsmWorkItemScope.myActive ||
      ItsmWorkItemScope.myHistory =>
        policy.canUseSelfService,
      ItsmWorkItemScope.managerActive ||
      ItsmWorkItemScope.managerClosed ||
      ItsmWorkItemScope.assignedToMe =>
        policy.canOperate,
      ItsmWorkItemScope.executiveSnapshot => policy.canReadExecutiveReporting,
    };
    if (!allowed) {
      throw ItsmAccessDeniedException(
        'Role ${session.role.value} cannot access ${scope.name}.',
      );
    }
  }
}

class ItsmAccessDeniedException implements Exception {
  const ItsmAccessDeniedException(this.message);

  final String message;

  @override
  String toString() => 'ItsmAccessDeniedException($message)';
}

class ItsmSessionRequiredException implements Exception {
  const ItsmSessionRequiredException();

  @override
  String toString() => 'ItsmSessionRequiredException()';
}

Map<String, Object?> _map(Object? value) {
  if (value is Map<String, Object?>) {
    return UnmodifiableMapView(value);
  }
  if (value is Map) {
    return UnmodifiableMapView(
      value.map((key, item) => MapEntry(key.toString(), item)),
    );
  }
  return const {};
}

String _string(Object? value) => value?.toString().trim() ?? '';
