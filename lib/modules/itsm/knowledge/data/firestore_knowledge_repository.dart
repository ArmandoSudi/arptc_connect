import 'package:cloud_firestore/cloud_firestore.dart';

import '../../shared/domain/pagination.dart';
import '../domain/knowledge_domain.dart';
import 'knowledge_repository.dart';

class FirestoreKnowledgeRepository implements KnowledgeRepository {
  FirestoreKnowledgeRepository(FirebaseFirestore firestore)
      : _articles = firestore.collection('knowledgeArticles'),
        _categories = firestore.collection('knowledgeCategories');

  final CollectionReference<Map<String, dynamic>> _articles;
  final CollectionReference<Map<String, dynamic>> _categories;

  @override
  Future<PageResult<KnowledgeArticle>> fetchPublishedPage({
    required KnowledgePublishedQuery query,
    required PageRequest page,
  }) {
    Query<Map<String, dynamic>> firestoreQuery = _articles
        .where('state', isEqualTo: KnowledgeArticleState.published.value)
        .where('visibility', isEqualTo: KnowledgeVisibility.employee.value);
    if (query.categoryId.trim().isNotEmpty) {
      firestoreQuery = firestoreQuery.where(
        'categoryId',
        isEqualTo: query.categoryId.trim(),
      );
    }
    if (query.languageCode.trim().isNotEmpty) {
      firestoreQuery = firestoreQuery.where(
        'languageCode',
        isEqualTo: query.languageCode.trim().toLowerCase(),
      );
    }
    if (query.view == KnowledgePublishedView.featured) {
      firestoreQuery = firestoreQuery.where('isFeatured', isEqualTo: true);
    }
    if (query.normalizedSearchTerm.isNotEmpty) {
      firestoreQuery = firestoreQuery.where(
        'searchTokens',
        arrayContains: query.normalizedSearchTerm,
      );
    }
    return _fetchPage(
      query: firestoreQuery,
      page: page,
      sortField: 'publishedAt',
      include: query.matches,
    );
  }

  @override
  Future<PageResult<KnowledgeArticle>> fetchSuggestions({
    required KnowledgeSuggestionQuery query,
    required PageRequest page,
  }) {
    final keys = query.context.indexKeys.take(30).toList(growable: false);
    if (keys.isEmpty) {
      return Future.value(PageResult(items: const [], hasMore: false));
    }
    final firestoreQuery = _articles
        .where('state', isEqualTo: KnowledgeArticleState.published.value)
        .where('visibility', isEqualTo: KnowledgeVisibility.employee.value)
        .where('suggestionKeys', arrayContainsAny: keys);
    return _fetchPage(
      query: firestoreQuery,
      page: page,
      sortField: 'publishedAt',
      include: query.matches,
      sortResult: (articles) => articles.sort((left, right) {
        final score = right.suggestionCriteria
            .score(query.context)
            .compareTo(left.suggestionCriteria.score(query.context));
        if (score != 0) return score;
        final usage = right.usageCount.compareTo(left.usageCount);
        if (usage != 0) return usage;
        return right.updatedAt.compareTo(left.updatedAt);
      }),
    );
  }

  @override
  Future<PageResult<KnowledgeArticle>> fetchManagerPage({
    required String managerUserId,
    required KnowledgeManagerQuery query,
    required PageRequest page,
  }) {
    Query<Map<String, dynamic>> firestoreQuery = _articles;
    switch (query.queue) {
      case KnowledgeManagerQueue.authoredByMe:
        firestoreQuery = firestoreQuery.where(
          'authorId',
          isEqualTo: managerUserId.trim(),
        );
      case KnowledgeManagerQueue.awaitingReview:
        firestoreQuery = firestoreQuery.where(
          'state',
          isEqualTo: KnowledgeArticleState.review.value,
        );
      case KnowledgeManagerQueue.drafts:
        firestoreQuery = firestoreQuery.where(
          'state',
          isEqualTo: KnowledgeArticleState.draft.value,
        );
      case KnowledgeManagerQueue.published:
        firestoreQuery = firestoreQuery.where(
          'state',
          isEqualTo: KnowledgeArticleState.published.value,
        );
      case KnowledgeManagerQueue.retired:
        firestoreQuery = firestoreQuery.where(
          'state',
          isEqualTo: KnowledgeArticleState.retired.value,
        );
      case KnowledgeManagerQueue.archived:
        firestoreQuery = firestoreQuery.where(
          'state',
          isEqualTo: KnowledgeArticleState.archived.value,
        );
      case KnowledgeManagerQueue.all:
        break;
    }
    if (query.categoryId.trim().isNotEmpty) {
      firestoreQuery = firestoreQuery.where(
        'categoryId',
        isEqualTo: query.categoryId.trim(),
      );
    }
    if (query.normalizedSearchTerm.isNotEmpty) {
      firestoreQuery = firestoreQuery.where(
        'searchTokens',
        arrayContains: query.normalizedSearchTerm,
      );
    }
    return _fetchPage(
      query: firestoreQuery,
      page: page,
      sortField: 'updatedAt',
      include: (article) => query.matches(
        article,
        managerUserId: managerUserId,
      ),
    );
  }

  @override
  Stream<KnowledgeArticle?> watchArticle(String articleId) {
    final normalizedId = articleId.trim();
    if (normalizedId.isEmpty) return Stream.value(null);
    return _articles.doc(normalizedId).snapshots().map(
          (snapshot) =>
              snapshot.exists ? KnowledgeArticle.fromFirestore(snapshot) : null,
        );
  }

  @override
  Future<KnowledgeArticleVersion?> fetchVersion({
    required String articleId,
    required int versionNumber,
    bool includeInternalAttachments = false,
  }) async {
    if (articleId.trim().isEmpty || versionNumber < 1) return null;
    final snapshot = await _articles
        .doc(articleId.trim())
        .collection('versions')
        .doc(versionNumber.toString().padLeft(6, '0'))
        .get();
    if (!snapshot.exists) return null;
    Query<Map<String, dynamic>> attachmentsQuery =
        snapshot.reference.collection('attachments');
    if (!includeInternalAttachments) {
      attachmentsQuery = attachmentsQuery.where('isInternal', isEqualTo: false);
    }
    final attachmentsSnapshot = await attachmentsQuery.limit(50).get();
    final attachments = attachmentsSnapshot.docs
        .map(KnowledgeAttachment.fromFirestore)
        .toList(growable: false);
    return KnowledgeArticleVersion.fromFirestore(
      snapshot,
      articleId: articleId,
    ).withAttachments(attachments);
  }

  @override
  Stream<List<KnowledgeCategory>> watchCategories({
    bool activeOnly = true,
    int limit = PageRequest.maximumLimit,
  }) {
    if (limit < 1 || limit > PageRequest.maximumLimit) {
      throw RangeError.range(limit, 1, PageRequest.maximumLimit, 'limit');
    }
    Query<Map<String, dynamic>> query = _categories;
    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }
    return query
        .orderBy('sortOrder')
        .orderBy('nameEn')
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(KnowledgeCategory.fromFirestore)
              .toList(growable: false),
        );
  }

  Future<PageResult<KnowledgeArticle>> _fetchPage({
    required Query<Map<String, dynamic>> query,
    required PageRequest page,
    required String sortField,
    required bool Function(KnowledgeArticle article) include,
    void Function(List<KnowledgeArticle> articles)? sortResult,
  }) async {
    if (page.direction != PageDirection.forward) {
      throw const KnowledgePaginationException(
        'Firestore Knowledge Base pagination supports forward cursors only.',
      );
    }
    var ordered = query
        .orderBy(sortField, descending: true)
        .orderBy(FieldPath.documentId)
        .limit(page.limit + 1);
    final cursor = page.cursor;
    if (cursor != null) {
      final date = knowledgeDate(cursor['sortAt']);
      final documentId = cursor['documentId']?.toString().trim() ?? '';
      if (date == null || documentId.isEmpty) {
        throw const KnowledgePaginationException(
          'Knowledge cursors require sortAt and documentId.',
        );
      }
      ordered = ordered.startAfter([
        Timestamp.fromDate(date),
        documentId,
      ]);
    }

    final snapshot = await ordered.get();
    final hasMore = snapshot.docs.length > page.limit;
    final pageDocuments =
        snapshot.docs.take(page.limit).toList(growable: false);
    final articles = pageDocuments
        .map(KnowledgeArticle.fromFirestore)
        .where(include)
        .toList(growable: true);
    sortResult?.call(articles);

    PageCursor? nextCursor;
    if (hasMore && pageDocuments.isNotEmpty) {
      final last = pageDocuments.last;
      final sortAt = knowledgeDate(last.data()[sortField]);
      if (sortAt == null) {
        throw KnowledgePaginationException(
          'Article ${last.id} has no $sortField cursor value.',
        );
      }
      nextCursor = PageCursor({
        'sortAt': sortAt,
        'documentId': last.id,
      });
    }
    return PageResult(
      items: articles,
      hasMore: hasMore,
      nextCursor: nextCursor,
    );
  }
}

class KnowledgePaginationException implements Exception {
  const KnowledgePaginationException(this.message);

  final String message;

  @override
  String toString() => 'KnowledgePaginationException($message)';
}
