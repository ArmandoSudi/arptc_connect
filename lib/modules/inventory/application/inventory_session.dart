import 'package:arptc_connect/modules/authentication/application/authorized_session.dart';

import '../domain/inventory_domain.dart';

class InventorySession {
  const InventorySession({
    required this.sessionKey,
    required this.userId,
    required this.email,
    required this.displayName,
    required this.role,
    required this.profile,
  });

  final String sessionKey;
  final String userId;
  final String email;
  final String displayName;
  final InventoryRole role;
  final Map<String, Object?> profile;

  factory InventorySession.fromAuthorizedSession(AuthorizedSession session) =>
      InventorySession(
        sessionKey: session.sessionKey,
        userId: session.userId,
        email: session.email,
        displayName: session.displayName,
        role: InventoryRole.fromValue(session.modulePermissions['inventory']),
        profile: session.profile,
      );

  InventoryAgentSnapshot get actor => InventoryAgentSnapshot(
        userId: userId,
        name: displayName,
        email: email,
        organizationId: _string(profile['organizationId']),
        departmentId: _string(profile['departmentId']),
        departmentName: _string(profile['department']),
        serviceId: _string(profile['serviceId']),
        serviceName: _string(profile['service']),
        bureauId: _string(profile['bureauId']),
        bureauName: _string(profile['bureau']),
      );
}

class InventorySessionRequired implements Exception {
  const InventorySessionRequired();

  @override
  String toString() => 'An authorized Inventory session is required.';
}

String _string(Object? value) => value?.toString().trim() ?? '';
