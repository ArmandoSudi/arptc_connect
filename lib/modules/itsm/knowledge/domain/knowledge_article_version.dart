import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'knowledge_actor.dart';
import 'knowledge_attachment.dart';
import 'knowledge_enums.dart';
import 'knowledge_serialization.dart';

class KnowledgeArticleVersion {
  factory KnowledgeArticleVersion({
    required String articleId,
    required int versionNumber,
    required String title,
    required String summary,
    required String content,
    required String languageCode,
    required KnowledgeArticleState state,
    required KnowledgeActor author,
    required DateTime createdAt,
    KnowledgeActor? reviewer,
    String reviewComment = '',
    DateTime? submittedAt,
    DateTime? reviewedAt,
    DateTime? publishedAt,
    Iterable<KnowledgeAttachment> attachments = const [],
    Iterable<String> attachmentIds = const [],
  }) {
    if (articleId.trim().isEmpty) {
      throw ArgumentError.value(articleId, 'articleId', 'Required.');
    }
    if (versionNumber < 1) {
      throw RangeError.range(versionNumber, 1, null, 'versionNumber');
    }
    if (title.trim().isEmpty || content.trim().isEmpty) {
      throw ArgumentError('A version requires a title and content.');
    }
    return KnowledgeArticleVersion._(
      articleId: articleId.trim(),
      versionNumber: versionNumber,
      title: title.trim(),
      summary: summary.trim(),
      content: content.trim(),
      languageCode: languageCode.trim().toLowerCase(),
      state: state,
      author: author,
      reviewer: reviewer,
      reviewComment: reviewComment.trim(),
      createdAt: createdAt.toUtc(),
      submittedAt: submittedAt?.toUtc(),
      reviewedAt: reviewedAt?.toUtc(),
      publishedAt: publishedAt?.toUtc(),
      attachments: UnmodifiableListView(
        List<KnowledgeAttachment>.from(attachments),
      ),
      attachmentIds: UnmodifiableListView(
        attachmentIds
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList(growable: false),
      ),
    );
  }

  const KnowledgeArticleVersion._({
    required this.articleId,
    required this.versionNumber,
    required this.title,
    required this.summary,
    required this.content,
    required this.languageCode,
    required this.state,
    required this.author,
    required this.reviewer,
    required this.reviewComment,
    required this.createdAt,
    required this.submittedAt,
    required this.reviewedAt,
    required this.publishedAt,
    required this.attachments,
    required this.attachmentIds,
  });

  final String articleId;
  final int versionNumber;
  final String title;
  final String summary;
  final String content;
  final String languageCode;
  final KnowledgeArticleState state;
  final KnowledgeActor author;
  final KnowledgeActor? reviewer;
  final String reviewComment;
  final DateTime createdAt;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final DateTime? publishedAt;
  final List<KnowledgeAttachment> attachments;
  final List<String> attachmentIds;

  bool get isImmutable =>
      state == KnowledgeArticleState.published ||
      state == KnowledgeArticleState.retired ||
      state == KnowledgeArticleState.archived ||
      publishedAt != null;

  String get documentId => versionNumber.toString().padLeft(6, '0');

  factory KnowledgeArticleVersion.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, {
    required String articleId,
  }) {
    return KnowledgeArticleVersion.fromMap(
      articleId: articleId,
      versionNumber: int.tryParse(snapshot.id) ?? 0,
      data: snapshot.data() ?? const {},
    );
  }

  factory KnowledgeArticleVersion.fromMap({
    required String articleId,
    required int versionNumber,
    required Map<String, dynamic> data,
  }) {
    final storedVersion = knowledgeInt(data, 'versionNumber');
    return KnowledgeArticleVersion(
      articleId: articleId,
      versionNumber: storedVersion > 0 ? storedVersion : versionNumber,
      title: knowledgeString(data, 'title'),
      summary: knowledgeString(data, 'summary'),
      content: knowledgeString(data, 'content'),
      languageCode: knowledgeString(data, 'languageCode').isEmpty
          ? 'en'
          : knowledgeString(data, 'languageCode'),
      state: KnowledgeArticleState.fromValue(data['state']),
      author: KnowledgeActor.fromMap(knowledgeMap(data['author'])),
      reviewer: _actorOrNull(data['reviewer']),
      reviewComment: knowledgeString(data, 'reviewComment'),
      createdAt: knowledgeDate(data['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      submittedAt: knowledgeDate(data['submittedAt']),
      reviewedAt: knowledgeDate(data['reviewedAt']),
      publishedAt: knowledgeDate(data['publishedAt']),
      attachments: _attachments(data['attachments']),
      attachmentIds: _stringList(data['attachmentIds']),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'versionNumber': versionNumber,
        'title': title,
        'summary': summary,
        'content': content,
        'languageCode': languageCode,
        'state': state.value,
        'author': author.toFirestore(),
        'reviewer': reviewer?.toFirestore(),
        'reviewComment': reviewComment,
        'createdAt': knowledgeTimestamp(createdAt),
        'submittedAt': knowledgeTimestamp(submittedAt),
        'reviewedAt': knowledgeTimestamp(reviewedAt),
        'publishedAt': knowledgeTimestamp(publishedAt),
        'attachments':
            attachments.map((attachment) => attachment.toFirestore()).toList(),
        'attachmentIds': attachmentIds,
      };

  KnowledgeArticleVersion reviseDraft({
    required String title,
    required String summary,
    required String content,
    required String languageCode,
    Iterable<KnowledgeAttachment>? attachments,
  }) {
    if (state != KnowledgeArticleState.draft || isImmutable) {
      throw const KnowledgeVersionImmutableException();
    }
    return KnowledgeArticleVersion(
      articleId: articleId,
      versionNumber: versionNumber,
      title: title,
      summary: summary,
      content: content,
      languageCode: languageCode,
      state: state,
      author: author,
      reviewer: reviewer,
      reviewComment: reviewComment,
      createdAt: createdAt,
      submittedAt: submittedAt,
      reviewedAt: reviewedAt,
      publishedAt: publishedAt,
      attachments: attachments ?? this.attachments,
      attachmentIds: attachmentIds,
    );
  }

  KnowledgeArticleVersion withAttachments(
    Iterable<KnowledgeAttachment> values,
  ) {
    final hydrated = List<KnowledgeAttachment>.from(values);
    return KnowledgeArticleVersion(
      articleId: articleId,
      versionNumber: versionNumber,
      title: title,
      summary: summary,
      content: content,
      languageCode: languageCode,
      state: state,
      author: author,
      reviewer: reviewer,
      reviewComment: reviewComment,
      createdAt: createdAt,
      submittedAt: submittedAt,
      reviewedAt: reviewedAt,
      publishedAt: publishedAt,
      attachments: hydrated,
      attachmentIds: hydrated.isEmpty
          ? attachmentIds
          : hydrated.map((attachment) => attachment.id),
    );
  }

  KnowledgeArticleVersion createNextDraft({
    required KnowledgeActor newAuthor,
    required DateTime createdAt,
  }) {
    if (state != KnowledgeArticleState.published &&
        state != KnowledgeArticleState.retired) {
      throw StateError('Only a published or retired version can be revised.');
    }
    return KnowledgeArticleVersion(
      articleId: articleId,
      versionNumber: versionNumber + 1,
      title: title,
      summary: summary,
      content: content,
      languageCode: languageCode,
      state: KnowledgeArticleState.draft,
      author: newAuthor,
      createdAt: createdAt,
      attachments: attachments,
      attachmentIds: attachmentIds,
    );
  }

  KnowledgeArticleVersion transitionForLifecycle({
    required KnowledgeArticleState nextState,
    KnowledgeActor? reviewer,
    String reviewComment = '',
    DateTime? submittedAt,
    DateTime? reviewedAt,
    DateTime? publishedAt,
  }) {
    return KnowledgeArticleVersion(
      articleId: articleId,
      versionNumber: versionNumber,
      title: title,
      summary: summary,
      content: content,
      languageCode: languageCode,
      state: nextState,
      author: author,
      reviewer: reviewer ?? this.reviewer,
      reviewComment: reviewComment,
      createdAt: createdAt,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      publishedAt: publishedAt ?? this.publishedAt,
      attachments: attachments,
      attachmentIds: attachmentIds,
    );
  }
}

class KnowledgeVersionImmutableException implements Exception {
  const KnowledgeVersionImmutableException();

  @override
  String toString() => 'KnowledgeVersionImmutableException()';
}

KnowledgeActor? _actorOrNull(Object? value) {
  final map = knowledgeMap(value);
  return knowledgeString(map, 'userId').isEmpty
      ? null
      : KnowledgeActor.fromMap(map);
}

List<KnowledgeAttachment> _attachments(Object? value) {
  if (value is! Iterable) return const [];
  var index = 0;
  return value.map((item) {
    final data = knowledgeMap(item);
    final id = knowledgeString(data, 'id');
    index++;
    return KnowledgeAttachment.fromMap(
      id: id.isEmpty ? 'attachment-$index' : id,
      data: data,
    );
  }).toList(growable: false);
}

List<String> _stringList(Object? value) {
  if (value is! Iterable) return const [];
  return value
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toSet()
      .toList(growable: false);
}
