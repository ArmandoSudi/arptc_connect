import 'dart:async';

import 'package:arptc_connect/core/firebase_providers.dart';
import 'package:arptc_connect/modules/notifications/data/notification_messaging_service.dart';
import 'package:arptc_connect/modules/profile/presentation/controllers/profile_provider.dart';
import 'package:arptc_connect/router.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationBootstrapper extends ConsumerStatefulWidget {
  const NotificationBootstrapper({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<NotificationBootstrapper> createState() =>
      _NotificationBootstrapperState();
}

class _NotificationBootstrapperState
    extends ConsumerState<NotificationBootstrapper> {
  ProviderSubscription<AsyncValue<Map<String, dynamic>>>? _profileSubscription;

  @override
  void initState() {
    super.initState();
    _profileSubscription = ref.listenManual<AsyncValue<Map<String, dynamic>>>(
      liveAgentProfileProvider,
      (_, next) => _initializeMessaging(next),
      fireImmediately: true,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      unawaited(
        ref
            .read(notificationMessagingServiceProvider)
            .initializeInteractionHandlers(onRoute: _openNotificationRoute),
      );
    });
  }

  void _initializeMessaging(AsyncValue<Map<String, dynamic>> profileAsync) {
    profileAsync.whenData((profile) {
      final currentUser = ref.read(firebaseAuthProvider).currentUser;
      if (profile.isEmpty || currentUser == null) {
        return;
      }

      unawaited(
        ref.read(notificationMessagingServiceProvider).initializeForAgent(
              profile: profile,
              fallbackUserId: currentUser.uid,
            ),
      );
    });
  }

  void _openNotificationRoute(String route) {
    final normalizedRoute = _normalizeNotificationRoute(route);
    if (normalizedRoute.isEmpty) {
      return;
    }

    ref.read(goRouterProvider).go(normalizedRoute);
  }

  @override
  void dispose() {
    _profileSubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

String _normalizeNotificationRoute(String route) {
  var normalizedRoute = route.trim();
  if (normalizedRoute.isEmpty) {
    return '';
  }

  final parsed = Uri.tryParse(normalizedRoute);
  if (parsed != null && parsed.hasScheme) {
    normalizedRoute =
        parsed.fragment.isNotEmpty ? parsed.fragment : parsed.path;
  }

  if (normalizedRoute.startsWith('/#/')) {
    normalizedRoute = normalizedRoute.substring(2);
  } else if (normalizedRoute.startsWith('#/')) {
    normalizedRoute = normalizedRoute.substring(1);
  }

  if (!normalizedRoute.startsWith('/')) {
    normalizedRoute = '/$normalizedRoute';
  }

  return normalizedRoute;
}
