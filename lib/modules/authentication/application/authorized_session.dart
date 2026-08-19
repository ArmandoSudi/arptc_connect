import 'dart:collection';

import 'package:arptc_connect/modules/usermanagement/domain/modules.dart';

/// The application-level states built from Firebase identity and its agent
/// profile. A Firebase [User] alone is never enough to access app data.
enum AuthenticationStatus {
  initializing,
  unauthenticated,
  authenticating,
  registrationInProgress,
  emailVerificationRequired,
  initialPasswordChangeRequired,
  profileLoading,
  authenticated,
  accountDisabled,
  failure,
}

class AuthenticatedIdentity {
  const AuthenticatedIdentity({
    required this.uid,
    required this.email,
    required this.emailVerified,
  });

  final String uid;
  final String email;
  final bool emailVerified;

  String get normalizedUid => uid.trim();
  String get normalizedEmail => email.trim().toLowerCase();
}

class AuthorizedSession {
  AuthorizedSession({
    required this.sessionKey,
    required this.userId,
    required this.email,
    required this.displayName,
    required Map<String, Object?> profile,
    required Map<String, String> modulePermissions,
  })  : profile = UnmodifiableMapView(Map<String, Object?>.from(profile)),
        modulePermissions = UnmodifiableMapView(
          Map<String, String>.from(modulePermissions),
        );

  final String sessionKey;
  final String userId;
  final String email;
  final String displayName;
  final Map<String, Object?> profile;
  final Map<String, String> modulePermissions;
}

class AuthorizedSessionState {
  const AuthorizedSessionState._({
    required this.status,
    this.session,
    this.message,
  });

  const AuthorizedSessionState.initializing()
      : this._(status: AuthenticationStatus.initializing);

  const AuthorizedSessionState.unauthenticated()
      : this._(status: AuthenticationStatus.unauthenticated);

  const AuthorizedSessionState.emailVerificationRequired()
      : this._(status: AuthenticationStatus.emailVerificationRequired);

  const AuthorizedSessionState.initialPasswordChangeRequired()
      : this._(status: AuthenticationStatus.initialPasswordChangeRequired);

  const AuthorizedSessionState.profileLoading()
      : this._(status: AuthenticationStatus.profileLoading);

  const AuthorizedSessionState.accountDisabled()
      : this._(status: AuthenticationStatus.accountDisabled);

  const AuthorizedSessionState.failure(String message)
      : this._(status: AuthenticationStatus.failure, message: message);

  AuthorizedSessionState.authenticated(AuthorizedSession session)
      : this._(status: AuthenticationStatus.authenticated, session: session);

  final AuthenticationStatus status;
  final AuthorizedSession? session;
  final String? message;

  bool get isAuthorized => status == AuthenticationStatus.authenticated;
}

/// Resolves the trusted application session from a Firebase identity and the
/// corresponding `agents/{uid}` profile document. This is intentionally pure
/// Dart so its security contract is easy to test without Firebase.
class AuthorizedSessionResolver {
  const AuthorizedSessionResolver();

  AuthorizedSessionState resolve({
    required AuthenticatedIdentity? identity,
    required Map<String, dynamic>? profile,
    bool profileLoading = false,
    Object? profileError,
  }) {
    if (profileError != null) {
      return const AuthorizedSessionState.failure(
        'Unable to load the agent profile.',
      );
    }

    if (identity == null) {
      return const AuthorizedSessionState.unauthenticated();
    }

    final userId = identity.normalizedUid;
    final email = identity.normalizedEmail;
    if (userId.isEmpty || email.isEmpty) {
      return const AuthorizedSessionState.failure(
        'The authenticated account has no usable identity.',
      );
    }

    if (!identity.emailVerified) {
      return const AuthorizedSessionState.emailVerificationRequired();
    }

    if (profileLoading) {
      return const AuthorizedSessionState.profileLoading();
    }

    if (profile == null || profile.isEmpty) {
      return const AuthorizedSessionState.failure(
        'No agent profile is associated with this account.',
      );
    }

    final profileId = _string(profile['id']);
    if (profileId != userId) {
      return const AuthorizedSessionState.failure(
        'The agent profile does not match the authenticated account.',
      );
    }

    final profileEmail = _firstNonEmpty([
      profile['emailLower'],
      profile['email'],
    ]).toLowerCase();
    if (profileEmail.isEmpty || profileEmail != email) {
      return const AuthorizedSessionState.failure(
        'The agent profile email does not match the authenticated account.',
      );
    }

    if (profile['isActive'] == false) {
      return const AuthorizedSessionState.accountDisabled();
    }
    if (profile['isActive'] != true) {
      return const AuthorizedSessionState.failure(
        'The agent profile is missing its active-account status.',
      );
    }

    if (profile['mustChangePassword'] == true) {
      return const AuthorizedSessionState.initialPasswordChangeRequired();
    }

    final permissions = _permissions(profile['modulePermissions']);
    if (permissions == null) {
      return const AuthorizedSessionState.failure(
        'The agent profile is missing its module permissions.',
      );
    }

    final typedProfile = Map<String, Object?>.from(profile);
    final displayName = _displayName(typedProfile);
    return AuthorizedSessionState.authenticated(
      AuthorizedSession(
        sessionKey: '$userId|$email',
        userId: userId,
        email: email,
        displayName: displayName.isEmpty ? email : displayName,
        profile: typedProfile,
        modulePermissions: permissions,
      ),
    );
  }
}

Map<String, String>? _permissions(Object? raw) {
  if (raw is! Map) {
    return null;
  }

  return Modules.normalizePermissions(
    Map<String, dynamic>.from(raw),
    includeDefaultModules: false,
  );
}

String _displayName(Map<String, Object?> profile) {
  final parts = [
    _string(profile['firstName']),
    _string(profile['name']),
    _string(profile['postName']),
  ].where((part) => part.isNotEmpty).toList();
  if (parts.isNotEmpty) {
    return parts.join(' ');
  }
  return _string(profile['fullName']);
}

String _firstNonEmpty(Iterable<Object?> values) {
  for (final value in values) {
    final normalized = _string(value);
    if (normalized.isNotEmpty) {
      return normalized;
    }
  }
  return '';
}

String _string(Object? value) => value?.toString().trim() ?? '';
