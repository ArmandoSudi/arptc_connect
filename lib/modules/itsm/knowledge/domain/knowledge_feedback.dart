import 'package:cloud_firestore/cloud_firestore.dart';

import 'knowledge_serialization.dart';

class KnowledgeFeedback {
  factory KnowledgeFeedback({
    required String id,
    required String articleId,
    required String userId,
    required bool helpful,
    required DateTime createdAt,
    String comment = '',
  }) {
    if (id.trim().isEmpty ||
        articleId.trim().isEmpty ||
        userId.trim().isEmpty) {
      throw ArgumentError('Feedback, article, and user IDs are required.');
    }
    return KnowledgeFeedback._(
      id: id.trim(),
      articleId: articleId.trim(),
      userId: userId.trim(),
      helpful: helpful,
      comment: comment.trim(),
      createdAt: createdAt.toUtc(),
    );
  }

  const KnowledgeFeedback._({
    required this.id,
    required this.articleId,
    required this.userId,
    required this.helpful,
    required this.comment,
    required this.createdAt,
  });

  final String id;
  final String articleId;
  final String userId;
  final bool helpful;
  final String comment;
  final DateTime createdAt;

  factory KnowledgeFeedback.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, {
    required String articleId,
  }) {
    return KnowledgeFeedback.fromMap(
      id: snapshot.id,
      articleId: articleId,
      data: snapshot.data() ?? const {},
    );
  }

  factory KnowledgeFeedback.fromMap({
    required String id,
    required String articleId,
    required Map<String, dynamic> data,
  }) {
    return KnowledgeFeedback(
      id: id,
      articleId: articleId,
      userId: knowledgeString(data, 'userId'),
      helpful: knowledgeBool(data, 'helpful'),
      comment: knowledgeString(data, 'comment'),
      createdAt: knowledgeDate(data['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'helpful': helpful,
        'comment': comment,
        'createdAt': knowledgeTimestamp(createdAt),
      };
}
