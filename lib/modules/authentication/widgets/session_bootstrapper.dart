import 'dart:async';

import 'package:arptc_connect/core/shared_preferences_provider.dart';
import 'package:arptc_connect/modules/authentication/providers/authentication_provider.dart';
import 'package:arptc_connect/modules/notifications/presentation/controllers/notification_providers.dart';
import 'package:arptc_connect/modules/profile/presentation/controllers/profile_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionBootstrapper extends ConsumerStatefulWidget {
  const SessionBootstrapper({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<SessionBootstrapper> createState() =>
      _SessionBootstrapperState();
}

class _SessionBootstrapperState extends ConsumerState<SessionBootstrapper> {
  ProviderSubscription<AsyncValue<User?>>? _authSubscription;
  String? _activeSessionKey;

  @override
  void initState() {
    super.initState();
    _authSubscription = ref.listenManual<AsyncValue<User?>>(
      authStateProvider,
      (_, next) => _handleAuthState(next),
      fireImmediately: true,
    );
  }

  void _handleAuthState(AsyncValue<User?> authState) {
    if (authState.isLoading && authState.valueOrNull == null) {
      return;
    }

    final user = authState.valueOrNull;
    final sessionKey = _sessionKey(user);
    if (sessionKey == _activeSessionKey) {
      return;
    }

    _activeSessionKey = sessionKey;
    _invalidateUserScopedProviders();

    if (user == null) {
      unawaited(ref.read(sharedPrefUtilityProvider).clearSession());
      return;
    }

    final email = user.email?.trim() ?? '';
    if (email.isEmpty) {
      return;
    }

    unawaited(_warmSession(email, sessionKey));
  }

  Future<void> _warmSession(String email, String? sessionKey) async {
    await ref.read(authServiceProvider).warmLocalSessionIfNeeded(email);
    if (!mounted || sessionKey != _activeSessionKey) {
      return;
    }
    _invalidateUserScopedProviders();
  }

  void _invalidateUserScopedProviders() {
    ref.invalidate(cachedAgentProfileProvider);
    ref.invalidate(liveAgentProfileProvider);
    ref.invalidate(currentNotificationAgentIdProvider);
    ref.invalidate(personalNotificationsProvider);
    ref.invalidate(globalNotificationsProvider);
    ref.invalidate(globalNotificationReadStatesProvider);
    ref.invalidate(notificationInboxProvider);
    ref.invalidate(notificationUnreadCountProvider);
  }

  @override
  void dispose() {
    _authSubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

String? _sessionKey(User? user) {
  if (user == null) {
    return null;
  }
  return '${user.uid}|${user.email?.trim().toLowerCase() ?? ''}';
}
