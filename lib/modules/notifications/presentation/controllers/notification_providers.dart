import 'package:arptc_connect/core/firebase_providers.dart';
import 'package:arptc_connect/modules/notifications/data/firestore_notification_repository.dart';
import 'package:arptc_connect/modules/notifications/domain/app_notification.dart';
import 'package:arptc_connect/modules/profile/presentation/controllers/profile_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final currentNotificationAgentIdProvider = Provider<AsyncValue<String>>((ref) {
  final profileAsync = ref.watch(liveAgentProfileProvider);
  return profileAsync.whenData((profile) {
    final profileId = _string(profile['id']);
    if (profileId.isNotEmpty) {
      return profileId;
    }
    return ref.read(firebaseAuthProvider).currentUser?.uid ?? '';
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
  return ref.read(notificationRepositoryProvider).watchGlobalNotifications();
});

final globalNotificationReadIdsProvider = StreamProvider<Set<String>>((ref) {
  final agentId = ref.watch(currentNotificationAgentIdProvider).valueOrNull;
  if (agentId == null || agentId.isEmpty) {
    return Stream.value(const <String>{});
  }
  return ref
      .read(notificationRepositoryProvider)
      .watchGlobalNotificationReadIds(agentId);
});

final notificationInboxProvider = Provider<AsyncValue<List<AppNotification>>>(
  (ref) {
    final personalAsync = ref.watch(personalNotificationsProvider);
    final globalAsync = ref.watch(globalNotificationsProvider);
    final readIdsAsync = ref.watch(globalNotificationReadIdsProvider);

    final error = _firstError([personalAsync, globalAsync, readIdsAsync]);
    if (error != null) {
      return AsyncValue.error(error.error, error.stackTrace);
    }

    final isLoading = personalAsync.isLoading ||
        globalAsync.isLoading ||
        readIdsAsync.isLoading;
    final personal = personalAsync.valueOrNull;
    final global = globalAsync.valueOrNull;
    final readIds = readIdsAsync.valueOrNull;

    if (isLoading && (personal == null || global == null || readIds == null)) {
      return const AsyncValue.loading();
    }

    final notifications = <AppNotification>[
      ...(personal ?? const <AppNotification>[]),
      ...(global ?? const <AppNotification>[]).map(
        (notification) => notification.copyWith(
          isRead: readIds?.contains(notification.id) ?? false,
        ),
      ),
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
