import 'package:arptc_connect/modules/notifications/data/firestore_notification_repository.dart';
import 'package:arptc_connect/modules/notifications/domain/app_notification.dart';
import 'package:arptc_connect/modules/authentication/providers/authentication_provider.dart';
import 'package:arptc_connect/modules/profile/presentation/controllers/profile_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final currentNotificationAgentIdProvider = Provider<AsyncValue<String>>((ref) {
  final authState = ref.watch(authStateProvider);
  if (authState.isLoading) {
    return const AsyncValue.loading();
  }
  if (authState.valueOrNull == null) {
    return const AsyncValue.data('');
  }

  final profileAsync = ref.watch(liveAgentProfileProvider);
  return profileAsync.whenData((profile) {
    return _string(profile['id']);
  });
});

final personalNotificationsProvider =
    StreamProvider<List<AppNotification>>((ref) {
  final agentId = ref.watch(currentNotificationAgentIdProvider).valueOrNull;
  if (agentId == null || agentId.isEmpty) {
    return Stream.value(const <AppNotification>[]);
  }
  return ref
      .read(notificationRepositoryProvider)
      .watchPersonalNotifications(agentId);
});

final globalNotificationsProvider =
    StreamProvider<List<AppNotification>>((ref) {
  final authState = ref.watch(authStateProvider);
  if (authState.isLoading || authState.valueOrNull == null) {
    return Stream.value(const <AppNotification>[]);
  }

  return ref.read(notificationRepositoryProvider).watchGlobalNotifications();
});

final globalNotificationReadStatesProvider =
    StreamProvider<Map<String, AppNotificationReadState>>((ref) {
  final agentId = ref.watch(currentNotificationAgentIdProvider).valueOrNull;
  if (agentId == null || agentId.isEmpty) {
    return Stream.value(const <String, AppNotificationReadState>{});
  }
  return ref
      .read(notificationRepositoryProvider)
      .watchGlobalNotificationReadStates(agentId);
});

final notificationInboxProvider = Provider<AsyncValue<List<AppNotification>>>(
  (ref) {
    final personalAsync = ref.watch(personalNotificationsProvider);
    final globalAsync = ref.watch(globalNotificationsProvider);
    final readStatesAsync = ref.watch(globalNotificationReadStatesProvider);

    final error = _firstError([personalAsync, globalAsync, readStatesAsync]);
    if (error != null) {
      return AsyncValue.error(error.error, error.stackTrace);
    }

    final isLoading = personalAsync.isLoading ||
        globalAsync.isLoading ||
        readStatesAsync.isLoading;
    final personal = personalAsync.valueOrNull;
    final global = globalAsync.valueOrNull;
    final readStates = readStatesAsync.valueOrNull;

    if (isLoading &&
        (personal == null || global == null || readStates == null)) {
      return const AsyncValue.loading();
    }

    final notifications = <AppNotification>[
      ...(personal ?? const <AppNotification>[]).where(
        (notification) => !notification.isCleared,
      ),
      ...(global ?? const <AppNotification>[]).map(
        (notification) {
          final state = readStates?[notification.id];
          return notification.copyWith(
            isRead: state?.isRead ?? false,
            isCleared: state?.isCleared ?? false,
          );
        },
      ).where((notification) => !notification.isCleared),
    ]..sort(_compareNotifications);

    return AsyncValue.data(notifications);
  },
);

final notificationUnreadCountProvider = Provider<AsyncValue<int>>((ref) {
  final inboxAsync = ref.watch(notificationInboxProvider);
  return inboxAsync.whenData(
    (notifications) =>
        notifications.where((notification) => !notification.isRead).length,
  );
});

_AsyncError? _firstError(List<AsyncValue<Object?>> values) {
  for (final value in values) {
    if (value.hasError) {
      return _AsyncError(value.error!, value.stackTrace ?? StackTrace.current);
    }
  }
  return null;
}

int _compareNotifications(AppNotification left, AppNotification right) {
  final leftDate = left.createdAt ?? DateTime(1900);
  final rightDate = right.createdAt ?? DateTime(1900);
  return rightDate.compareTo(leftDate);
}

String _string(dynamic value) => value?.toString().trim() ?? '';

class _AsyncError {
  const _AsyncError(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;
}
