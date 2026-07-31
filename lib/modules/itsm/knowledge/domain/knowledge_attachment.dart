import 'package:cloud_firestore/cloud_firestore.dart';

import 'knowledge_actor.dart';
import 'knowledge_serialization.dart';

class KnowledgeAttachment {
  factory KnowledgeAttachment({
    required String id,
    required String fileName,
    required String storagePath,
    required String contentType,
    required int sizeBytes,
    required KnowledgeActor uploadedBy,
    required DateTime uploadedAt,
    String downloadUrl = '',
  }) {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) {
      throw ArgumentError.value(id, 'id', 'An attachment ID is required.');
    }
    if (sizeBytes < 0) {
      throw RangeError.value(sizeBytes, 'sizeBytes', 'Must not be negative.');
    }
    return KnowledgeAttachment._(
      id: normalizedId,
      fileName: fileName.trim(),
      storagePath: storagePath.trim(),
      contentType: contentType.trim(),
      sizeBytes: sizeBytes,
      uploadedBy: uploadedBy,
      uploadedAt: uploadedAt.toUtc(),
      downloadUrl: downloadUrl.trim(),
    );
  }

  const KnowledgeAttachment._({
    required this.id,
    required this.fileName,
    required this.storagePath,
    required this.contentType,
    required this.sizeBytes,
    required this.uploadedBy,
    required this.uploadedAt,
    required this.downloadUrl,
  });

  final String id;
  final String fileName;
  final String storagePath;
  final String contentType;
  final int sizeBytes;
  final KnowledgeActor uploadedBy;
  final DateTime uploadedAt;
  final String downloadUrl;

  factory KnowledgeAttachment.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return KnowledgeAttachment.fromMap(
      id: snapshot.id,
      data: snapshot.data() ?? const {},
    );
  }

  factory KnowledgeAttachment.fromMap({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final uploadedByMap = knowledgeMap(data['uploadedBy']);
    final uploadedByUserId = knowledgeString(data, 'uploadedByUserId');
    return KnowledgeAttachment(
      id: id,
      fileName: knowledgeString(data, 'fileName'),
      storagePath: knowledgeString(data, 'storagePath'),
      contentType: knowledgeString(data, 'contentType'),
      sizeBytes: knowledgeInt(data, 'sizeBytes'),
      uploadedBy: uploadedByMap.isNotEmpty
          ? KnowledgeActor.fromMap(uploadedByMap)
          : KnowledgeActor(
              userId: uploadedByUserId,
              name: knowledgeString(data, 'uploadedByName'),
              email: knowledgeString(data, 'uploadedByEmail'),
            ),
      uploadedAt: knowledgeDate(data['uploadedAt']) ??
          knowledgeDate(data['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      downloadUrl: knowledgeString(data, 'downloadUrl'),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'fileName': fileName,
        'storagePath': storagePath,
        'downloadUrl': downloadUrl,
        'contentType': contentType,
        'sizeBytes': sizeBytes,
        'uploadedBy': uploadedBy.toFirestore(),
        'uploadedAt': knowledgeTimestamp(uploadedAt),
      };
}
