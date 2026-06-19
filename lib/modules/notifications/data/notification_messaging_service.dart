import 'dart:async';

import 'package:arptc_connect/firebase_options.dart';
import 'package:arptc_connect/modules/notifications/data/firestore_notification_repository.dart';
import 'package:arptc_connect/modules/notifications/data/notification_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _webVapidKey = String.fromEnvironment('FIREBASE_WEB_PUSH_VAPID_KEY');

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

final firebaseMessagingProvider = Provider<FirebaseMessaging>((ref) {
  return FirebaseMessaging.instance;
});

final notificationMessagingServiceProvider =
    Provider<NotificationMessagingService>((ref) {
  return NotificationMessagingService(
    messaging: ref.read(firebaseMessagingProvider),
    repository: ref.read(notificationRepositoryProvider),
  );
});

class NotificationMessagingService {
  NotificationMessagingService({
    required FirebaseMessaging messaging,
    required NotificationRepository repository,
  })  : _messaging = messaging,
        _repository = repository;

  final FirebaseMessaging _messaging;
  final NotificationRepository _repository;

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedSubscription;
  String _registeredAgentId = '';
  String _lastToken = '';
  bool _isInitializing = false;
  bool _foregroundListenerRegistered = false;
  bool _initialMessageHandled = false;

  bool get hasRequiredConfiguration {
    return !kIsWeb || _webVapidKey.trim().isNotEmpty;
  }

  NotificationClientPlatform get clientPlatform =>
      NotificationClientPlatform.current();

  Future<AuthorizationStatus> currentAuthorizationStatus() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus;
  }

  Future<void> initializeForAgent({
    required Map<String, dynamic> profile,
    required String fallbackUserId,
  }) async {
    if (_isInitializing) {
      return;
    }

    final agentId = _string(profile['id']).isNotEmpty
        ? _string(profile['id'])
        : fallbackUserId.trim();
    if (agentId.isEmpty) {
      return;
    }

    _isInitializing = true;
    try {
      _registerForegroundListenerOnce();

      if (kIsWeb && _webVapidKey.trim().isEmpty) {
        debugPrint(
          'FCM web token registration skipped. Provide '
          'FIREBASE_WEB_PUSH_VAPID_KEY as a dart-define.',
        );
        return;
      }

      final settings = await _messaging.getNotificationSettings();
      if (!_canRegisterWithStatus(settings.authorizationStatus)) {
        debugPrint(
          'FCM token registration skipped because notification permission '
          'has not been granted yet.',
        );
        return;
      }

      await _registerCurrentDevice(
        profile: profile,
        agentId: agentId,
      );
    } catch (error, stackTrace) {
      debugPrint('Unable to initialize FCM notifications: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _isInitializing = false;
    }
  }

  Future<AuthorizationStatus> requestPermissionAndRegisterForAgent({
    required Map<String, dynamic> profile,
    required String fallbackUserId,
  }) async {
    if (_isInitializing) {
      return currentAuthorizationStatus();
    }

    final agentId = _string(profile['id']).isNotEmpty
        ? _string(profile['id'])
        : fallbackUserId.trim();
    if (agentId.isEmpty) {
      return AuthorizationStatus.notDetermined;
    }

    if (!hasRequiredConfiguration) {
      throw StateError(
        'Missing FIREBASE_WEB_PUSH_VAPID_KEY. Rebuild or run the web app with '
        '--dart-define=FIREBASE_WEB_PUSH_VAPID_KEY=YOUR_PUBLIC_KEY.',
      );
    }

    _isInitializing = true;
    try {
      _registerForegroundListenerOnce();

      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final status = settings.authorizationStatus;
      if (!_canRegisterWithStatus(status)) {
        return status;
      }

      await _registerCurrentDevice(
        profile: profile,
        agentId: agentId,
      );

      return status;
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> initializeInteractionHandlers({
    required void Function(String route) onRoute,
  }) async {
    if (kIsWeb) {
      return;
    }

    _messageOpenedSubscription ??=
        FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleMessageRoute(message, onRoute);
    });

    if (_initialMessageHandled) {
      return;
    }
    _initialMessageHandled = true;

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageRoute(initialMessage, onRoute);
    }
  }

  Future<void> _registerCurrentDevice({
    required Map<String, dynamic> profile,
    required String agentId,
  }) async {
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await _getToken();
    if (token == null || token.isEmpty) {
      return;
    }

    await _registerToken(
      profile: profile,
      agentId: agentId,
      token: token,
    );

    if (_registeredAgentId == agentId && _lastToken == token) {
      return;
    }

    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen(
      (freshToken) {
        unawaited(
          _registerToken(
            profile: profile,
            agentId: agentId,
            token: freshToken,
          ),
        );
      },
    );

    _registeredAgentId = agentId;
    _lastToken = token;
  }

  Future<void> _registerToken({
    required Map<String, dynamic> profile,
    required String agentId,
    required String token,
  }) async {
    await _repository.registerDeviceToken(
      agentId: agentId,
      token: token,
      platform: _platformLabel(),
      email: _string(profile['email']),
      displayName: _displayNameFromProfile(profile),
    );
  }

  Future<String?> _getToken() async {
    if (kIsWeb) {
      if (_webVapidKey.trim().isEmpty) {
        debugPrint(
          'FCM web token registration skipped. Provide '
          'FIREBASE_WEB_PUSH_VAPID_KEY as a dart-define.',
        );
        return null;
      }
      return _messaging.getToken(vapidKey: _webVapidKey.trim());
    }

    return _messaging.getToken();
  }

  void _registerForegroundListenerOnce() {
    if (_foregroundListenerRegistered) {
      return;
    }
    _foregroundListenerRegistered = true;

    FirebaseMessaging.onMessage.listen((message) {
      debugPrint(
        'Foreground notification received: '
        '${message.notification?.title ?? message.data['title'] ?? ''}',
      );
    });
  }

  void _handleMessageRoute(
    RemoteMessage message,
    void Function(String route) onRoute,
  ) {
    final route = _normalizeNotificationRoute(message.data['route']);
    if (route.isEmpty) {
      return;
    }

    onRoute(route);
  }
}

bool _canRegisterWithStatus(AuthorizationStatus status) {
  return status == AuthorizationStatus.authorized ||
      status == AuthorizationStatus.provisional;
}

String _displayNameFromProfile(Map<String, dynamic> profile) {
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

String _platformLabel() {
  return NotificationClientPlatform.current().tokenPlatformLabel;
}

String _string(dynamic value) => value?.toString().trim() ?? '';

String _normalizeNotificationRoute(dynamic value) {
  var route = _string(value);
  if (route.isEmpty) {
    return '';
  }

  final parsed = Uri.tryParse(route);
  if (parsed != null && parsed.hasScheme) {
    route = parsed.fragment.isNotEmpty ? parsed.fragment : parsed.path;
  }

  if (route.startsWith('/#/')) {
    route = route.substring(2);
  } else if (route.startsWith('#/')) {
    route = route.substring(1);
  }

  if (!route.startsWith('/')) {
    route = '/$route';
  }

  return route;
}

class NotificationClientPlatform {
  const NotificationClientPlatform._({
    required this.isWeb,
    required this.targetPlatform,
  });

  factory NotificationClientPlatform.current() {
    return NotificationClientPlatform._(
      isWeb: kIsWeb,
      targetPlatform: defaultTargetPlatform,
    );
  }

  final bool isWeb;
  final TargetPlatform targetPlatform;

  bool get isWindows => targetPlatform == TargetPlatform.windows;
  bool get isMacOS => targetPlatform == TargetPlatform.macOS;

  String get displayName {
    if (isWeb && isWindows) {
      return 'Windows browser or installed PWA';
    }
    if (isWeb && isMacOS) {
      return 'macOS browser or installed PWA';
    }
    if (isWeb) {
      return 'web browser or installed PWA';
    }

    switch (targetPlatform) {
      case TargetPlatform.android:
        return 'Android device';
      case TargetPlatform.iOS:
        return 'iOS device';
      case TargetPlatform.macOS:
        return 'macOS app';
      case TargetPlatform.windows:
        return 'Windows app';
      case TargetPlatform.linux:
        return 'Linux app';
      case TargetPlatform.fuchsia:
        return 'Fuchsia app';
    }
  }

  String get tokenPlatformLabel {
    final platform = targetPlatform.name.toLowerCase();
    return isWeb ? 'web_$platform' : platform;
  }
}
