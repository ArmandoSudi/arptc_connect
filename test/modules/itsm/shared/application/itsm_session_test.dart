import 'package:arptc_connect/modules/itsm/shared/application/itsm_session.dart';
import 'package:arptc_connect/modules/itsm/shared/data/itsm_work_item_repository.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_shared_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const resolver = ItsmSessionResolver();

  test('resolves the canonical ticketing permission', () {
    final session = resolver.resolve(
      authUserId: 'user-1',
      authEmail: 'agent@example.com',
      profile: const {
        'id': 'user-1',
        'email': 'agent@example.com',
        'isActive': true,
        'firstName': 'Ada',
        'name': 'Lovelace',
        'modulePermissions': {'ticketing': 'MANAGER'},
      },
    );

    expect(session, isNotNull);
    expect(session?.role, ItsmRole.manager);
    expect(session?.displayName, 'Ada Lovelace');
    expect(session?.sessionKey, 'user-1|agent@example.com');
  });

  test('resolves normalized ITSM aliases', () {
    final session = resolver.resolve(
      authUserId: 'user-1',
      authEmail: 'agent@example.com',
      profile: const {
        'id': 'user-1',
        'emailLower': 'agent@example.com',
        'isActive': true,
        'modulePermissions': {'IT Service Management': 'ADMIN'},
      },
    );

    expect(session?.role, ItsmRole.admin);
  });

  test('rejects an agent profile whose document ID is not the Firebase UID',
      () {
    final session = resolver.resolve(
      authUserId: 'firebase-auth-uid',
      authEmail: 'agent@example.com',
      profile: const {
        'id': 'legacy-agent-document-id',
        'emailLower': 'agent@example.com',
        'modulePermissions': {'ticketing': 'USER'},
      },
    );

    expect(session, isNull);
  });

  test('rejects an inactive agent profile', () {
    final session = resolver.resolve(
      authUserId: 'user-1',
      authEmail: 'agent@example.com',
      profile: const {
        'id': 'user-1',
        'emailLower': 'agent@example.com',
        'isActive': false,
        'modulePermissions': {'ticketing': 'MANAGER'},
      },
    );

    expect(session, isNull);
  });

  test('rejects stale profile data from a previous account', () {
    final session = resolver.resolve(
      authUserId: 'user-2',
      authEmail: 'second@example.com',
      profile: const {
        'id': 'user-1',
        'email': 'first@example.com',
        'modulePermissions': {'ticketing': 'MANAGER'},
      },
    );

    expect(session, isNull);
  });

  group('ItsmAccessPolicy', () {
    const accessPolicy = ItsmAccessPolicy();

    test('USER is limited to self-service scopes', () {
      final session = _session(ItsmRole.user);

      expect(
        () => accessPolicy.authorize(session, ItsmWorkItemScope.myActive),
        returnsNormally,
      );
      expect(
        () => accessPolicy.authorize(
          session,
          ItsmWorkItemScope.managerActive,
        ),
        throwsA(isA<ItsmAccessDeniedException>()),
      );
    });

    test('MANAGER can operate but cannot read executive snapshots', () {
      final session = _session(ItsmRole.manager);

      expect(
        () => accessPolicy.authorize(
          session,
          ItsmWorkItemScope.assignedToMe,
        ),
        returnsNormally,
      );
      expect(
        () => accessPolicy.authorize(
          session,
          ItsmWorkItemScope.executiveSnapshot,
        ),
        throwsA(isA<ItsmAccessDeniedException>()),
      );
    });

    test('ADMIN is self-service plus read-only executive reporting', () {
      final session = _session(ItsmRole.admin);

      expect(
        () => accessPolicy.authorize(session, ItsmWorkItemScope.myHistory),
        returnsNormally,
      );
      expect(
        () => accessPolicy.authorize(
          session,
          ItsmWorkItemScope.executiveSnapshot,
        ),
        returnsNormally,
      );
      expect(
        () => accessPolicy.authorize(
          session,
          ItsmWorkItemScope.managerClosed,
        ),
        throwsA(isA<ItsmAccessDeniedException>()),
      );
    });
  });
}

ItsmSession _session(ItsmRole role) {
  return ItsmSession(
    sessionKey: 'user-1|agent@example.com',
    userId: 'user-1',
    email: 'agent@example.com',
    displayName: 'Agent',
    role: role,
  );
}
