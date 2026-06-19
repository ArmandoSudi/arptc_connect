import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_model_helpers.dart';

class IncidentAuditLog {
  const IncidentAuditLog({
    required this.id,
    required this.ticketId,
    required this.action,
    required this.message,
    required this.actorUserId,
    required this.actorName,
    required this.actorRole,
    required this.changes,
    required this.createdAt,
  });

  final String id;
  final String ticketId;
  final String action;
  final String message;
  final String actorUserId;
  final String actorName;
  final String actorRole;
  final Map<String, dynamic> changes;
  final DateTime? createdAt;

  factory IncidentAuditLog.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, {
    required String ticketId,
  }) {
    final data = snapshot.data() ?? <String, dynamic>{};
    final rawChanges = data['changes'];
    return IncidentAuditLog(
      id: snapshot.id,
      ticketId: ticketId,
      action: stringFromFirestore(data, 'action'),
      message: stringFromFirestore(data, 'message'),
      actorUserId: stringFromFirestore(data, 'actorUserId'),
      actorName: stringFromFirestore(data, 'actorName'),
      actorRole: stringFromFirestore(data, 'actorRole'),
      changes: rawChanges is Map
          ? Map<String, dynamic>.from(rawChanges)
          : <String, dynamic>{},
      createdAt: dateTimeFromFirestore(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'action': action.trim(),
      'message': message.trim(),
      'actorUserId': actorUserId.trim(),
      'actorName': actorName.trim(),
      'actorRole': actorRole.trim(),
      'changes': changes,
      'createdAt': dateTimeToFirestore(createdAt),
    };
  }
}
