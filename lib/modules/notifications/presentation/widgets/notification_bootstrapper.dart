import 'dart:async';

import 'package:arptc_connect/modules/authentication/application/authorized_session.dart';
import 'package:arptc_connect/modules/authentication/providers/authorized_session_provider.dart';
import 'package:arptc_connect/modules/notifications/data/notification_messaging_service.dart';
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
  ProviderSubscription<AuthorizedSessionState>? _sessionSubscription;

  @override
  void initState() {
    super.initState();
    _sessionSubscription = ref.listenManual<AuthorizedSessionState>(
      authorizedSessionProvider,
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

  void _initializeMessaging(AuthorizedSessionState sessionState) {
    final session = sessionState.session;
    if (session == null) {
      return;
    }

    unawaited(
      ref.read(notificationMessagingServiceProvider).initializeForAgent(
            profile: Map<String, dynamic>.from(session.profile),
            fallbackUserId: session.userId,
          ),
    );
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
    _sessionSubscription?.close();
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
        parsed.fragment.isNotEmpty ? parsed.fragment : _pathWithQuery(parsed);
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

String _pathWithQuery(Uri uri) {
  final query = uri.query.trim();
  if (query.isEmpty) {
    return uri.path;
  }
  return '${uri.path}?$query';
}
