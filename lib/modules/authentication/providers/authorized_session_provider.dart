import 'package:arptc_connect/modules/authentication/application/authorized_session.dart';
import 'package:arptc_connect/modules/authentication/providers/authentication_provider.dart';
import 'package:arptc_connect/modules/profile/presentation/controllers/profile_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authorizedSessionResolverProvider = Provider<AuthorizedSessionResolver>(
  (ref) => const AuthorizedSessionResolver(),
);

/// The only provider that converts Firebase authentication into application
/// authorization. Consumers must use this instead of trusting a Firebase user
/// or cached profile independently.
final authorizedSessionProvider = Provider<AuthorizedSessionState>((ref) {
  final authState = ref.watch(authStateProvider);
  final resolver = ref.watch(authorizedSessionResolverProvider);

  return authState.when(
    loading: AuthorizedSessionState.initializing,
    error: (_, __) => const AuthorizedSessionState.failure(
      'Unable to determine the authentication state.',
    ),
    data: (user) => _resolveAuthenticatedState(
      ref: ref,
      resolver: resolver,
      user: user,
    ),
  );
});

final currentAuthorizedSessionKeyProvider = Provider<String?>((ref) {
  return ref.watch(authorizedSessionProvider).session?.sessionKey;
});

final authorizedAgentProfileProvider =
    Provider<AsyncValue<Map<String, dynamic>>>((ref) {
  final state = ref.watch(authorizedSessionProvider);
  final session = state.session;
  if (session != null) {
    return AsyncValue.data(Map<String, dynamic>.from(session.profile));
  }

  if (state.status == AuthenticationStatus.initializing ||
      state.status == AuthenticationStatus.profileLoading) {
    return const AsyncValue.loading();
  }

  return AsyncValue.error(
    AuthorizedSessionException(state),
    StackTrace.current,
  );
});

AuthorizedSessionState _resolveAuthenticatedState({
  required Ref ref,
  required AuthorizedSessionResolver resolver,
  required User? user,
}) {
  if (user == null) {
    return resolver.resolve(identity: null, profile: const {});
  }

  final identity = AuthenticatedIdentity(
    uid: user.uid,
    email: user.email ?? '',
    emailVerified: user.emailVerified,
  );

  if (!identity.emailVerified) {
    return resolver.resolve(identity: identity, profile: const {});
  }

  final profileState = ref.watch(liveAgentProfileProvider);
  return profileState.when(
    loading: () => resolver.resolve(
      identity: identity,
      profile: null,
      profileLoading: true,
    ),
    error: (error, _) => resolver.resolve(
      identity: identity,
      profile: null,
      profileError: error,
    ),
    data: (profile) => resolver.resolve(
      identity: identity,
      profile: profile,
    ),
  );
}

class AuthorizedSessionException implements Exception {
  const AuthorizedSessionException(this.state);

  final AuthorizedSessionState state;

  @override
  String toString() => state.message ?? 'Application session is unavailable.';
}
