import '../../shared/domain/pagination.dart';
import '../domain/knowledge_domain.dart';

class KnowledgePublishedQuery {
  const KnowledgePublishedQuery({
    this.view = KnowledgePublishedView.recent,
    this.searchTerm = '',
    this.categoryId = '',
    this.languageCode = '',
    this.asOf,
  });

  final KnowledgePublishedView view;
  final String searchTerm;
  final String categoryId;
  final String languageCode;
  final DateTime? asOf;

  String get normalizedSearchTerm => normalizeKnowledgeSearch(searchTerm);

  bool matches(KnowledgeArticle article) {
    final now = (asOf ?? DateTime.now()).toUtc();
    if (!article.isPublished ||
        article.visibility != KnowledgeVisibility.employee ||
        article.isExpiredAt(now)) {
      return false;
    }
    if (categoryId.trim().isNotEmpty &&
        article.categoryId != categoryId.trim()) {
      return false;
    }
    if (languageCode.trim().isNotEmpty &&
        article.languageCode != languageCode.trim().toLowerCase()) {
      return false;
    }
    if (view == KnowledgePublishedView.featured && !article.isFeatured) {
      return false;
    }
    final search = normalizedSearchTerm;
    return search.isEmpty || article.searchTokens.contains(search);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is KnowledgePublishedQuery &&
            view == other.view &&
            normalizedSearchTerm == other.normalizedSearchTerm &&
            categoryId.trim() == other.categoryId.trim() &&
            languageCode.trim().toLowerCase() ==
                other.languageCode.trim().toLowerCase() &&
            asOf?.toUtc() == other.asOf?.toUtc();
  }

  @override
  int get hashCode => Object.hash(
        view,
        normalizedSearchTerm,
        categoryId.trim(),
        languageCode.trim().toLowerCase(),
        asOf?.toUtc(),
      );
}

class KnowledgeManagerQuery {
  const KnowledgeManagerQuery({
    required this.queue,
    this.searchTerm = '',
    this.categoryId = '',
  });

  final KnowledgeManagerQueue queue;
  final String searchTerm;
  final String categoryId;

  String get normalizedSearchTerm => normalizeKnowledgeSearch(searchTerm);

  bool matches(KnowledgeArticle article, {required String managerUserId}) {
    final matchesQueue = switch (queue) {
      KnowledgeManagerQueue.all => true,
      KnowledgeManagerQueue.authoredByMe =>
        article.author.userId == managerUserId.trim(),
      KnowledgeManagerQueue.awaitingReview =>
        article.state == KnowledgeArticleState.review,
      KnowledgeManagerQueue.drafts =>
        article.state == KnowledgeArticleState.draft,
      KnowledgeManagerQueue.published =>
        article.state == KnowledgeArticleState.published,
      KnowledgeManagerQueue.retired =>
        article.state == KnowledgeArticleState.retired,
      KnowledgeManagerQueue.archived =>
        article.state == KnowledgeArticleState.archived,
    };
    if (!matchesQueue) return false;
    if (categoryId.trim().isNotEmpty &&
        article.categoryId != categoryId.trim()) {
      return false;
    }
    final search = normalizedSearchTerm;
    return search.isEmpty || article.searchTokens.contains(search);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is KnowledgeManagerQuery &&
            queue == other.queue &&
            normalizedSearchTerm == other.normalizedSearchTerm &&
            categoryId.trim() == other.categoryId.trim();
  }

  @override
  int get hashCode =>
      Object.hash(queue, normalizedSearchTerm, categoryId.trim());
}

class KnowledgeSuggestionQuery {
  const KnowledgeSuggestionQuery({
    required this.context,
    this.asOf,
  });

  final KnowledgeSuggestionContext context;
  final DateTime? asOf;

  bool matches(KnowledgeArticle article) {
    return KnowledgePublishedQuery(asOf: asOf).matches(article) &&
        article.suggestionCriteria.score(context) > 0;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is KnowledgeSuggestionQuery &&
            _listEquals(context.indexKeys, other.context.indexKeys) &&
            asOf?.toUtc() == other.asOf?.toUtc();
  }

  @override
  int get hashCode => Object.hashAll([...context.indexKeys, asOf?.toUtc()]);
}

abstract interface class KnowledgeRepository {
  Future<PageResult<KnowledgeArticle>> fetchPublishedPage({
    required KnowledgePublishedQuery query,
    required PageRequest page,
  });

  Future<PageResult<KnowledgeArticle>> fetchSuggestions({
    required KnowledgeSuggestionQuery query,
    required PageRequest page,
  });

  Future<PageResult<KnowledgeArticle>> fetchManagerPage({
    required String managerUserId,
    required KnowledgeManagerQuery query,
    required PageRequest page,
  });

  Stream<KnowledgeArticle?> watchArticle(String articleId);

  Future<KnowledgeArticleVersion?> fetchVersion({
    required String articleId,
    required int versionNumber,
    bool includeInternalAttachments = false,
  });

  Stream<List<KnowledgeCategory>> watchCategories({
    bool activeOnly = true,
    int limit = PageRequest.maximumLimit,
  });
}

bool _listEquals(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
