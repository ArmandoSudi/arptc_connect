import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.moduleKey,
    required this.eventType,
    required this.entityType,
    required this.entityId,
    required this.route,
    required this.isRead,
    required this.isGlobal,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String moduleKey;
  final String eventType;
  final String entityType;
  final String entityId;
  final String route;
  final bool isRead;
  final bool isGlobal;
  final DateTime? createdAt;

  factory AppNotification.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, {
    required bool isGlobal,
    bool? overrideReadState,
  }) {
    final data = snapshot.data() ?? <String, dynamic>{};
    return AppNotification(
      id: snapshot.id,
      title: _string(data['title']),
      body: _string(data['body']),
      moduleKey: _string(data['moduleKey']),
      eventType: _string(data['eventType']),
      entityType: _string(data['entityType']),
      entityId: _string(data['entityId']),
      route: _string(data['route']),
      isRead: overrideReadState ?? (data['isRead'] as bool? ?? false),
      isGlobal: isGlobal,
      createdAt: _toDateTime(data['createdAt']),
    );
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      moduleKey: moduleKey,
      eventType: eventType,
      entityType: entityType,
      entityId: entityId,
      route: route,
      isRead: isRead ?? this.isRead,
      isGlobal: isGlobal,
      createdAt: createdAt,
    );
  }
}

String _string(dynamic value) => value?.toString().trim() ?? '';

DateTime? _toDateTime(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}
