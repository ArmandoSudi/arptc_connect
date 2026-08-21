import 'package:arptc_connect/modules/authentication/application/authorized_session.dart';
import 'package:arptc_connect/modules/authentication/providers/authorized_session_provider.dart';
import 'package:arptc_connect/modules/inventory/application/inventory_providers.dart';
import 'package:arptc_connect/modules/inventory/application/inventory_session.dart';
import 'package:arptc_connect/modules/inventory/domain/inventory_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('authorized profile maps Inventory role and organization snapshot', () {
    final session = _authorizedSession('MANAGER');

    final inventorySession = InventorySession.fromAuthorizedSession(session);

    expect(inventorySession.sessionKey, session.sessionKey);
    expect(inventorySession.role, InventoryRole.manager);
    expect(inventorySession.actor.userId, 'agent-1');
    expect(inventorySession.actor.organizationId, 'org-1');
    expect(inventorySession.actor.departmentName, 'Finance');
    expect(inventorySession.actor.serviceName, 'Accounting');
    expect(inventorySession.actor.bureauName, 'Payments');
  });

  test('providers derive the live role and access policy from the session', () {
    final container = ProviderContainer(
      overrides: [
        authorizedSessionProvider.overrideWithValue(
          AuthorizedSessionState.authenticated(_authorizedSession('ADMIN')),
        ),
      ],
    );
    addTearDown(container.dispose);

    final session = container.read(inventorySessionProvider);
    final policy = container.read(inventoryAccessPolicyProvider);

    expect(session.valueOrNull?.role, InventoryRole.admin);
    expect(container.read(currentInventoryRoleProvider), InventoryRole.admin);
    expect(policy.canReadExactStock, isTrue);
    expect(policy.isReadOnlyAdmin, isTrue);
    expect(policy.canManageInventory, isFalse);
  });

  test('providers fail closed when no authorized application session exists',
      () {
    final container = ProviderContainer(
      overrides: [
        authorizedSessionProvider.overrideWithValue(
          const AuthorizedSessionState.unauthenticated(),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(inventorySessionProvider).hasError, isTrue);
    expect(container.read(currentInventoryRoleProvider), InventoryRole.none);
    expect(container.read(inventoryAccessPolicyProvider).canAccess, isFalse);
  });
}

AuthorizedSession _authorizedSession(String role) => AuthorizedSession(
      sessionKey: 'agent-1|agent@example.com',
      userId: 'agent-1',
      email: 'agent@example.com',
      displayName: 'Sarah Agent',
      profile: const {
        'id': 'agent-1',
        'organizationId': 'org-1',
        'departmentId': 'department-1',
        'department': 'Finance',
        'serviceId': 'service-1',
        'service': 'Accounting',
        'bureauId': 'bureau-1',
        'bureau': 'Payments',
      },
      modulePermissions: {'inventory': role},
    );
