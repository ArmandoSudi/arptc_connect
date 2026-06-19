import 'package:arptc_connect/modules/notifications/domain/app_notification.dart';
import 'package:arptc_connect/modules/notifications/domain/notification_event.dart';

abstract class NotificationRepository {
  Future<void> emitEvent(NotificationEvent event);

  Stream<List<AppNotification>> watchPersonalNotifications(String agentId);

  Stream<List<AppNotification>> watchGlobalNotifications();

  Stream<Set<String>> watchGlobalNotificationReadIds(String agentId);

  Future<void> markPersonalNotificationRead({
    required String agentId,
    required String notificationId,
  });

  Future<void> markGlobalNotificationRead({
    required String agentId,
    required String notificationId,
  });

  Future<void> registerDeviceToken({
    required String agentId,
    required String token,
    required String platform,
    required String email,
    required String displayName,
  });

  Future<void> removeDeviceToken({
    required String agentId,
    required String token,
  });
}
