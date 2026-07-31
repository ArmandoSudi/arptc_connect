import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'knowledge_actor.dart';
import 'knowledge_enums.dart';
import 'knowledge_serialization.dart';
import 'knowledge_suggestion.dart';

class KnowledgeArticle {
  factory KnowledgeArticle({
    required String id,
    required String reference,
    required String categoryId,
    required String title,
    required String summary,
    required String languageCode,
    required KnowledgeArticleState state,
    required KnowledgeVisibility visibility,
    required int currentVersionNumber,
    required KnowledgeActor author,
    required DateTime createdAt,
    required DateTime updatedAt,
    KnowledgeActor? reviewer,
    String reviewComment = '',
    bool isFeatured = false,
    int? publishedVersionNumber,
    DateTime? reviewDueAt,
    DateTime? expiresAt,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    DateTime? publishedAt,
    DateTime? retiredAt,
    DateTime? archivedAt,
    int helpfulCount = 0,
    int notHelpfulCount = 0,
    int viewCount = 0,
    int usageCount = 0,
    Iterable<String> relatedServiceIds = const [],
    Iterable<String> relatedCatalogueItemIds = const [],
    Iterable<String> relatedIncidentCategoryIds = const [],
    KnowledgeSuggestionCriteria? suggestionCriteria,
    Iterable<String>? searchTokens,
  }) {
    if (id.trim().isEmpty || reference.trim().isEmpty) {
      throw ArgumentError('Article ID and reference are required.');
    }
    if (currentVersionNumber < 1) {
      throw RangeError.range(
        currentVersionNumber,
        1,
        null,
        'currentVersionNumber',
      );
    }
    for (final count in [
      helpfulCount,
      notHelpfulCount,
      viewCount,
      usageCount,
    ]) {
      if (count < 0) throw RangeError.value(count, 'count');
    }
    final relatedServices = _ids(relatedServiceIds);
    final relatedCatalogue = _ids(relatedCatalogueItemIds);
    final relatedCategories = _ids(relatedIncidentCategoryIds);
    final criteria = suggestionCriteria ??
        KnowledgeSuggestionCriteria(
          serviceIds: relatedServices,
          catalogueItemIds: relatedCatalogue,
          incidentCategoryIds: relatedCategories,
        );
    return KnowledgeArticle._(
      id: id.trim(),
      reference: reference.trim(),
      categoryId: categoryId.trim(),
      title: title.trim(),
      summary: summary.trim(),
      languageCode: languageCode.trim().toLowerCase(),
      state: state,
      visibility: visibility,
      isFeatured: isFeatured,
      currentVersionNumber: currentVersionNumber,
      publishedVersionNumber: publishedVersionNumber,
      author: author,
      reviewer: reviewer,
      reviewComment: reviewComment.trim(),
      reviewDueAt: reviewDueAt?.toUtc(),
      expiresAt: expiresAt?.toUtc(),
      submittedAt: submittedAt?.toUtc(),
      reviewedAt: reviewedAt?.toUtc(),
      publishedAt: publishedAt?.toUtc(),
      retiredAt: retiredAt?.toUtc(),
      archivedAt: archivedAt?.toUtc(),
      createdAt: createdAt.toUtc(),
      updatedAt: updatedAt.toUtc(),
      helpfulCount: helpfulCount,
      notHelpfulCount: notHelpfulCount,
      viewCount: viewCount,
      usageCount: usageCount,
      relatedServiceIds: relatedServices,
      relatedCatalogueItemIds: relatedCatalogue,
      relatedIncidentCategoryIds: relatedCategories,
      suggestionCriteria: criteria,
      searchTokens: UnmodifiableListView(
        (searchTokens ??
                buildKnowledgeSearchTokens([title, summary, reference]))
            .toSet()
            .toList()
          ..sort(),
      ),
    );
  }

  const KnowledgeArticle._({
    required this.id,
    required this.reference,
    required this.categoryId,
    required this.title,
    required this.summary,
    required this.languageCode,
    required this.state,
    required this.visibility,
    required this.isFeatured,
    required this.currentVersionNumber,
    required this.publishedVersionNumber,
    required this.author,
    required this.reviewer,
    required this.reviewComment,
    required this.reviewDueAt,
    required this.expiresAt,
    required this.submittedAt,
    required this.reviewedAt,
    required this.publishedAt,
    required this.retiredAt,
    required this.archivedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.helpfulCount,
    required this.notHelpfulCount,
    required this.viewCount,
    required this.usageCount,
    required this.relatedServiceIds,
    required this.relatedCatalogueItemIds,
    required this.relatedIncidentCategoryIds,
    required this.suggestionCriteria,
    required this.searchTokens,
  });

  final String id;
  final String reference;
  final String categoryId;
  final String title;
  final String summary;
  final String languageCode;
  final KnowledgeArticleState state;
  final KnowledgeVisibility visibility;
  final bool isFeatured;
  final int currentVersionNumber;
  final int? publishedVersionNumber;
  final KnowledgeActor author;
  final KnowledgeActor? reviewer;
  final String reviewComment;
  final DateTime? reviewDueAt;
  final DateTime? expiresAt;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final DateTime? publishedAt;
  final DateTime? retiredAt;
  final DateTime? archivedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int helpfulCount;
  final int notHelpfulCount;
  final int viewCount;
  final int usageCount;
  final List<String> relatedServiceIds;
  final List<String> relatedCatalogueItemIds;
  final List<String> relatedIncidentCategoryIds;
  final KnowledgeSuggestionCriteria suggestionCriteria;
  final List<String> searchTokens;

  bool get isPublished => state == KnowledgeArticleState.published;

  bool isExpiredAt(DateTime at) {
    final expiry = expiresAt;
    return expiry != null && !expiry.isAfter(at.toUtc());
  }

  factory KnowledgeArticle.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return KnowledgeArticle.fromMap(
      id: snapshot.id,
      data: snapshot.data() ?? const {},
    );
  }

  factory KnowledgeArticle.fromMap({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final currentVersion = knowledgeInt(data, 'currentVersionNumber');
    final publishedVersion = knowledgeInt(data, 'publishedVersionNumber');
    final authorData = knowledgeMap(data['author']);
    final reviewerData = knowledgeMap(data['reviewer']);
    return KnowledgeArticle(
      id: id,
      reference: knowledgeString(data, 'reference'),
      categoryId: knowledgeString(data, 'categoryId'),
      title: knowledgeString(data, 'title'),
      summary: knowledgeString(data, 'summary'),
      languageCode: knowledgeString(data, 'languageCode').isEmpty
          ? 'en'
          : knowledgeString(data, 'languageCode'),
      state: KnowledgeArticleState.fromValue(data['state']),
      visibility: KnowledgeVisibility.fromValue(data['visibility']),
      isFeatured: knowledgeBool(data, 'isFeatured'),
      currentVersionNumber: currentVersion < 1 ? 1 : currentVersion,
      publishedVersionNumber: publishedVersion < 1 ? null : publishedVersion,
      author: KnowledgeActor.fromMap(authorData),
      reviewer: knowledgeString(reviewerData, 'userId').isEmpty
          ? null
          : KnowledgeActor.fromMap(reviewerData),
      reviewComment: knowledgeString(data, 'reviewComment'),
      reviewDueAt: knowledgeDate(data['reviewDueAt']),
      expiresAt: knowledgeDate(data['expiresAt']),
      submittedAt: knowledgeDate(data['submittedAt']),
      reviewedAt: knowledgeDate(data['reviewedAt']),
      publishedAt: knowledgeDate(data['publishedAt']),
      retiredAt: knowledgeDate(data['retiredAt']),
      archivedAt: knowledgeDate(data['archivedAt']),
      createdAt: knowledgeDate(data['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      updatedAt: knowledgeDate(data['updatedAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      helpfulCount: knowledgeInt(data, 'helpfulCount'),
      notHelpfulCount: knowledgeInt(data, 'notHelpfulCount'),
      viewCount: knowledgeInt(data, 'viewCount'),
      usageCount: knowledgeInt(data, 'usageCount'),
      relatedServiceIds: knowledgeStringList(data['relatedServiceIds']),
      relatedCatalogueItemIds:
          knowledgeStringList(data['relatedCatalogueItemIds']),
      relatedIncidentCategoryIds:
          knowledgeStringList(data['relatedIncidentCategoryIds']),
      suggestionCriteria: KnowledgeSuggestionCriteria.fromMap(
        knowledgeMap(data['suggestionCriteria']),
      ),
      searchTokens: knowledgeStringList(data['searchTokens']),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'reference': reference,
        'categoryId': categoryId,
        'title': title,
        'summary': summary,
        'languageCode': languageCode,
        'state': state.value,
        'visibility': visibility.value,
        'isFeatured': isFeatured,
        'currentVersionNumber': currentVersionNumber,
        'publishedVersionNumber': publishedVersionNumber,
        'author': author.toFirestore(),
        'authorId': author.userId,
        'reviewer': reviewer?.toFirestore(),
        'reviewerId': reviewer?.userId,
        'reviewComment': reviewComment,
        'reviewDueAt': knowledgeTimestamp(reviewDueAt),
        'expiresAt': knowledgeTimestamp(expiresAt),
        'submittedAt': knowledgeTimestamp(submittedAt),
        'reviewedAt': knowledgeTimestamp(reviewedAt),
        'publishedAt': knowledgeTimestamp(publishedAt),
        'retiredAt': knowledgeTimestamp(retiredAt),
        'archivedAt': knowledgeTimestamp(archivedAt),
        'createdAt': knowledgeTimestamp(createdAt),
        'updatedAt': knowledgeTimestamp(updatedAt),
        'helpfulCount': helpfulCount,
        'notHelpfulCount': notHelpfulCount,
        'viewCount': viewCount,
        'usageCount': usageCount,
        'relatedServiceIds': relatedServiceIds,
        'relatedCatalogueItemIds': relatedCatalogueItemIds,
        'relatedIncidentCategoryIds': relatedIncidentCategoryIds,
        'suggestionCriteria': suggestionCriteria.toFirestore(),
        'suggestionKeys': suggestionCriteria.indexKeys,
        'searchTokens': searchTokens,
      };

  KnowledgeArticle transitionForLifecycle({
    required KnowledgeArticleState nextState,
    required DateTime at,
    KnowledgeActor? reviewer,
    String reviewComment = '',
    int? publishedVersionNumber,
  }) {
    return KnowledgeArticle(
      id: id,
      reference: reference,
      categoryId: categoryId,
      title: title,
      summary: summary,
      languageCode: languageCode,
      state: nextState,
      visibility: visibility,
      isFeatured: isFeatured,
      currentVersionNumber: currentVersionNumber,
      publishedVersionNumber:
          publishedVersionNumber ?? this.publishedVersionNumber,
      author: author,
      reviewer: reviewer ?? this.reviewer,
      reviewComment: reviewComment,
      reviewDueAt: reviewDueAt,
      expiresAt: expiresAt,
      submittedAt: nextState == KnowledgeArticleState.review ? at : submittedAt,
      reviewedAt: nextState == KnowledgeArticleState.draft ||
              nextState == KnowledgeArticleState.published
          ? at
          : reviewedAt,
      publishedAt:
          nextState == KnowledgeArticleState.published ? at : publishedAt,
      retiredAt: nextState == KnowledgeArticleState.retired ? at : retiredAt,
      archivedAt: nextState == KnowledgeArticleState.archived ? at : archivedAt,
      createdAt: createdAt,
      updatedAt: at,
      helpfulCount: helpfulCount,
      notHelpfulCount: notHelpfulCount,
      viewCount: viewCount,
      usageCount: usageCount,
      relatedServiceIds: relatedServiceIds,
      relatedCatalogueItemIds: relatedCatalogueItemIds,
      relatedIncidentCategoryIds: relatedIncidentCategoryIds,
      suggestionCriteria: suggestionCriteria,
      searchTokens: searchTokens,
    );
  }
}

List<String> _ids(Iterable<String> values) {
  final result = values
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
  return UnmodifiableListView(result);
}
