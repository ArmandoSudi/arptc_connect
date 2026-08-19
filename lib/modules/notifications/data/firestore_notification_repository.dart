import 'package:arptc_connect/core/firebase_providers.dart';
import 'package:arptc_connect/modules/notifications/data/notification_repository.dart';
import 'package:arptc_connect/modules/notifications/domain/app_notification.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return FirestoreNotificationRepository(ref.read(fireStoreProvider));
});

class FirestoreNotificationRepository implements NotificationRepository {
  FirestoreNotificationRepository(this.firestore);

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _globalNotifications =>
      firestore.collection('globalNotifications');

  CollectionReference<Map<String, dynamic>> get _agents =>
      firestore.collection('agents');

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
  Stream<Map<String, AppNotificationReadState>>
      watchGlobalNotificationReadStates(String agentId) {
    if (agentId.trim().isEmpty) {
      return Stream.value(const <String, AppNotificationReadState>{});
    }

    return _agents
        .doc(agentId.trim())
        .collection('notificationReads')
        .snapshots()
        .map(
          (snapshot) => {
            for (final doc in snapshot.docs)
              doc.id: AppNotificationReadState.fromFirestore(doc),
          },
        );
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
          _readData(),
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
          _readData(notificationId: notificationId.trim()),
          SetOptions(merge: true),
        );
  }

  @override
  Future<void> clearNotification({
    required String agentId,
    required AppNotification notification,
  }) async {
    await clearNotifications(
      agentId: agentId,
      notifications: [notification],
    );
  }

  @override
  Future<void> clearNotifications({
    required String agentId,
    required Iterable<AppNotification> notifications,
  }) async {
    final safeAgentId = agentId.trim();
    if (safeAgentId.isEmpty) {
      return;
    }

    final notificationList = notifications
        .where((notification) => notification.id.trim().isNotEmpty)
        .toList();
    if (notificationList.isEmpty) {
      return;
    }

    var batch = firestore.batch();
    var operationCount = 0;

    Future<void> commitCurrentBatchIfNeeded({bool force = false}) async {
      if (operationCount == 0 || (!force && operationCount < 450)) {
        return;
      }
      await batch.commit();
      batch = firestore.batch();
      operationCount = 0;
    }

    for (final notification in notificationList) {
      final notificationId = notification.id.trim();
      if (notification.isGlobal) {
        batch.set(
          _agents
              .doc(safeAgentId)
              .collection('notificationReads')
              .doc(notificationId),
          _clearData(notificationId: notificationId),
          SetOptions(merge: true),
        );
      } else {
        batch.set(
          _agents
              .doc(safeAgentId)
              .collection('notifications')
              .doc(notificationId),
          _clearData(),
          SetOptions(merge: true),
        );
      }
      operationCount += 1;
      await commitCurrentBatchIfNeeded();
    }

    await commitCurrentBatchIfNeeded(force: true);
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

Map<String, dynamic> _readData({String? notificationId}) {
  return {
    if (notificationId != null) 'notificationId': notificationId,
    'isRead': true,
    'readAt': FieldValue.serverTimestamp(),
  };
}

Map<String, dynamic> _clearData({String? notificationId}) {
  return {
    ..._readData(notificationId: notificationId),
    'isCleared': true,
    'clearedAt': FieldValue.serverTimestamp(),
  };
}
