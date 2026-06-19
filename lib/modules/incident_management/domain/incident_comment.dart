import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_model_helpers.dart';

class IncidentComment {
  const IncidentComment({
    required this.id,
    required this.ticketId,
    required this.body,
    required this.createdByUserId,
    required this.createdByName,
    required this.createdByRole,
    required this.isInternal,
    required this.createdAt,
  });

  final String id;
  final String ticketId;
  final String body;
  final String createdByUserId;
  final String createdByName;
  final String createdByRole;
  final bool isInternal;
  final DateTime? createdAt;

  factory IncidentComment.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, {
    required String ticketId,
  }) {
    final data = snapshot.data() ?? <String, dynamic>{};
    return IncidentComment(
      id: snapshot.id,
      ticketId: ticketId,
      body: stringFromFirestore(data, 'body'),
      createdByUserId: stringFromFirestore(data, 'createdByUserId'),
      createdByName: stringFromFirestore(data, 'createdByName'),
      createdByRole: stringFromFirestore(data, 'createdByRole'),
      isInternal: boolFromFirestore(data, 'isInternal'),
      createdAt: dateTimeFromFirestore(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'body': body.trim(),
      'createdByUserId': createdByUserId.trim(),
      'createdByName': createdByName.trim(),
      'createdByRole': createdByRole.trim(),
      'isInternal': isInternal,
      'createdAt': dateTimeToFirestore(createdAt),
    };
  }
}
