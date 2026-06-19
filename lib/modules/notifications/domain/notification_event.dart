import 'package:cloud_firestore/cloud_firestore.dart';

import 'notification_target.dart';

class NotificationEvent {
  const NotificationEvent({
    required this.id,
    required this.eventType,
    required this.moduleKey,
    required this.title,
    required this.body,
    required this.entityType,
    required this.entityId,
    required this.route,
    required this.createdByUserId,
    required this.createdByName,
    required this.createdByEmail,
    required this.target,
    this.status = 'PENDING',
    this.createdAt,
    this.processedAt,
    this.errorMessage = '',
  });

  final String id;
  final String eventType;
  final String moduleKey;
  final String title;
  final String body;
  final String entityType;
  final String entityId;
  final String route;
  final String createdByUserId;
  final String createdByName;
  final String createdByEmail;
  final NotificationTarget target;
  final String status;
  final DateTime? createdAt;
  final DateTime? processedAt;
  final String errorMessage;

  factory NotificationEvent.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    final rawTarget = data['target'];
    return NotificationEvent(
      id: snapshot.id,
      eventType: _string(data['eventType']),
      moduleKey: _string(data['moduleKey']),
      title: _string(data['title']),
      body: _string(data['body']),
      entityType: _string(data['entityType']),
      entityId: _string(data['entityId']),
      route: _string(data['route']),
      createdByUserId: _string(data['createdByUserId']),
      createdByName: _string(data['createdByName']),
      createdByEmail: _string(data['createdByEmail']),
      target: NotificationTarget.fromMap(
        rawTarget is Map<String, dynamic>
            ? rawTarget
            : rawTarget is Map
                ? Map<String, dynamic>.from(rawTarget)
                : null,
      ),
      status: _string(data['status'], fallback: 'PENDING'),
      createdAt: _toDateTime(data['createdAt']),
      processedAt: _toDateTime(data['processedAt']),
      errorMessage: _string(data['errorMessage']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'eventType': eventType.trim(),
      'moduleKey': moduleKey.trim(),
      'title': title.trim(),
      'body': body.trim(),
      'entityType': entityType.trim(),
      'entityId': entityId.trim(),
      'route': route.trim(),
      'createdByUserId': createdByUserId.trim(),
      'createdByName': createdByName.trim(),
      'createdByEmail': createdByEmail.trim().toLowerCase(),
      'target': target.toFirestore(),
      'status': status.trim().isEmpty ? 'PENDING' : status.trim(),
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'processedAt':
          processedAt == null ? null : Timestamp.fromDate(processedAt!),
      'errorMessage': errorMessage.trim(),
    };
  }
}

String _string(dynamic value, {String fallback = ''}) {
  final string = value?.toString().trim() ?? '';
  return string.isEmpty ? fallback : string;
}

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
