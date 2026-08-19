import 'package:arptc_connect/modules/authentication/application/authorized_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const resolver = AuthorizedSessionResolver();

  const identity = AuthenticatedIdentity(
    uid: 'agent-uid',
    email: 'agent@example.com',
    emailVerified: true,
  );

  test('requires email verification before granting an application session',
      () {
    final state = resolver.resolve(
      identity: const AuthenticatedIdentity(
        uid: 'agent-uid',
        email: 'agent@example.com',
        emailVerified: false,
      ),
      profile: _profile(),
    );

    expect(state.status, AuthenticationStatus.emailVerificationRequired);
    expect(state.session, isNull);
  });

  test('rejects a Firebase account without an agent profile', () {
    final state = resolver.resolve(
      identity: identity,
      profile: const {},
    );

    expect(state.status, AuthenticationStatus.failure);
    expect(state.session, isNull);
  });

  test('rejects an inactive agent profile', () {
    final state = resolver.resolve(
      identity: identity,
      profile: _profile(isActive: false),
    );

    expect(state.status, AuthenticationStatus.accountDisabled);
    expect(state.session, isNull);
  });

  test('rejects a profile that belongs to a different Firebase user', () {
    final state = resolver.resolve(
      identity: identity,
      profile: _profile(id: 'other-agent-uid'),
    );

    expect(state.status, AuthenticationStatus.failure);
    expect(state.session, isNull);
  });

  test('requires the profile to contain a loaded permission map', () {
    final state = resolver.resolve(
      identity: identity,
      profile: _profile()..remove('modulePermissions'),
    );

    expect(state.status, AuthenticationStatus.failure);
    expect(state.session, isNull);
  });

  test('requires a replacement password before granting an app session', () {
    final state = resolver.resolve(
      identity: identity,
      profile: _profile(mustChangePassword: true),
    );

    expect(
      state.status,
      AuthenticationStatus.initialPasswordChangeRequired,
    );
    expect(state.session, isNull);
  });

  test('creates an authorized session only for a verified active UID profile',
      () {
    final state = resolver.resolve(
      identity: identity,
      profile: _profile(),
    );

    expect(state.status, AuthenticationStatus.authenticated);
    expect(state.session?.userId, 'agent-uid');
    expect(state.session?.email, 'agent@example.com');
    expect(state.session?.sessionKey, 'agent-uid|agent@example.com');
    expect(state.session?.modulePermissions, {'ticketing': 'MANAGER'});
  });

  test('returns unauthenticated when Firebase has no user', () {
    final state = resolver.resolve(identity: null, profile: const {});

    expect(state.status, AuthenticationStatus.unauthenticated);
    expect(state.session, isNull);
  });
}

Map<String, dynamic> _profile({
  String id = 'agent-uid',
  bool isActive = true,
  bool? mustChangePassword,
}) =>
    {
      'id': id,
      'email': 'agent@example.com',
      'emailLower': 'agent@example.com',
      'firstName': 'Ada',
      'name': 'Lovelace',
      'isActive': isActive,
      if (mustChangePassword != null) 'mustChangePassword': mustChangePassword,
      'modulePermissions': {'ticketing': 'MANAGER'},
    };
