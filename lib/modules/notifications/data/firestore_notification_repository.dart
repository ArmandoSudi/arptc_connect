import 'package:arptc_connect/core/firebase_providers.dart';
import 'package:arptc_connect/modules/notifications/data/notification_repository.dart';
import 'package:arptc_connect/modules/notifications/domain/app_notification.dart';
import 'package:arptc_connect/modules/notifications/domain/notification_event.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return FirestoreNotificationRepository(ref.read(fireStoreProvider));
});

class FirestoreNotificationRepository implements NotificationRepository {
  FirestoreNotificationRepository(this.firestore);

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _events =>
      firestore.collection('notificationEvents');

  CollectionReference<Map<String, dynamic>> get _globalNotifications =>
      firestore.collection('globalNotifications');

  CollectionReference<Map<String, dynamic>> get _agents =>
      firestore.collection('agents');

  @override
  Future<void> emitEvent(NotificationEvent event) async {
    final doc = event.id.trim().isEmpty ? _events.doc() : _events.doc(event.id);
    await doc.set(event.toFirestore());
  }

  @override
  Stream<List<AppNotification>> watchPersonalNotifications(String agentId) {
    if (agentId.trim().isEmpty) {
      return Stream.value(const <AppNotification>[]);
    }

    return _agents
        .doc(agentId.trim())
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(80)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => AppNotification.fromFirestore(
                  doc,
                  isGlobal: false,
                ),
              )
              .toList(),
        );
  }

  @override
  Stream<List<AppNotification>> watchGlobalNotifications() {
    return _globalNotifications
        .orderBy('createdAt', descending: true)
        .limit(80)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => AppNotification.fromFirestore(
                  doc,
                  isGlobal: true,
                ),
              )
              .toList(),
        );
  }

  @override
  Stream<Set<String>> watchGlobalNotificationReadIds(String agentId) {
    if (agentId.trim().isEmpty) {
      return Stream.value(const <String>{});
    }

    return _agents
        .doc(agentId.trim())
        .collection('notificationReads')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
  }

  @override
  Future<void> markPersonalNotificationRead({
    required String agentId,
    required String notificationId,
  }) async {
    if (agentId.trim().isEmpty || notificationId.trim().isEmpty) {
      return;
    }

    await _agents
        .doc(agentId.trim())
        .collection('notifications')
        .doc(notificationId.trim())
        .set(
      {
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> markGlobalNotificationRead({
    required String agentId,
    required String notificationId,
  }) async {
    if (agentId.trim().isEmpty || notificationId.trim().isEmpty) {
      return;
    }

    await _agents
        .doc(agentId.trim())
        .collection('notificationReads')
        .doc(notificationId.trim())
        .set(
      {
        'notificationId': notificationId.trim(),
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> registerDeviceToken({
    required String agentId,
    required String token,
    required String platform,
    required String email,
    required String displayName,
  }) async {
    final safeAgentId = agentId.trim();
    final safeToken = token.trim();
    if (safeAgentId.isEmpty || safeToken.isEmpty) {
      return;
    }

    await _agents
        .doc(safeAgentId)
        .collection('deviceTokens')
        .doc(Uri.encodeComponent(safeToken))
        .set(
      {
        'token': safeToken,
        'agentId': safeAgentId,
        'email': email.trim().toLowerCase(),
        'displayName': displayName.trim(),
        'platform': platform.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> removeDeviceToken({
    required String agentId,
    required String token,
  }) async {
    final safeAgentId = agentId.trim();
    final safeToken = token.trim();
    if (safeAgentId.isEmpty || safeToken.isEmpty) {
      return;
    }

    await _agents
        .doc(safeAgentId)
        .collection('deviceTokens')
        .doc(Uri.encodeComponent(safeToken))
        .delete();
  }
}
