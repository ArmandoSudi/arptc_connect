import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_model_helpers.dart';

class IncidentAttachment {
  const IncidentAttachment({
    required this.id,
    required this.ticketId,
    required this.fileName,
    required this.fileUrl,
    required this.contentType,
    required this.sizeBytes,
    required this.uploadedByUserId,
    required this.uploadedByName,
    required this.createdAt,
  });

  final String id;
  final String ticketId;
  final String fileName;
  final String fileUrl;
  final String contentType;
  final int sizeBytes;
  final String uploadedByUserId;
  final String uploadedByName;
  final DateTime? createdAt;

  factory IncidentAttachment.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, {
    required String ticketId,
  }) {
    return IncidentAttachment.fromMap(
      id: snapshot.id,
      ticketId: ticketId,
      data: snapshot.data() ?? <String, dynamic>{},
    );
  }

  factory IncidentAttachment.fromMap({
    required String id,
    required String ticketId,
    required Map<String, dynamic> data,
  }) {
    return IncidentAttachment(
      id: id,
      ticketId: ticketId,
      fileName: stringFromFirestore(data, 'fileName'),
      fileUrl: stringFromFirestore(data, 'fileUrl'),
      contentType: stringFromFirestore(data, 'contentType'),
      sizeBytes: intFromFirestore(data, 'sizeBytes'),
      uploadedByUserId: stringFromFirestore(data, 'uploadedByUserId'),
      uploadedByName: stringFromFirestore(data, 'uploadedByName'),
      createdAt: dateTimeFromFirestore(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fileName': fileName.trim(),
      'fileUrl': fileUrl.trim(),
      'contentType': contentType.trim(),
      'sizeBytes': sizeBytes,
      'uploadedByUserId': uploadedByUserId.trim(),
      'uploadedByName': uploadedByName.trim(),
      'createdAt': dateTimeToFirestore(createdAt),
    };
  }
}
