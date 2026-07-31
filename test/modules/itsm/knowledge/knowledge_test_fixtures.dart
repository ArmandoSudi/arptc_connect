import 'package:arptc_connect/modules/itsm/knowledge/domain/knowledge_domain.dart';

KnowledgeActor knowledgeActor({
  String id = 'manager-1',
  String name = 'Manager One',
  String email = 'manager@example.com',
}) {
  return KnowledgeActor(userId: id, name: name, email: email);
}

KnowledgeArticle knowledgeArticle({
  String id = 'article-1',
  KnowledgeArticleState state = KnowledgeArticleState.draft,
  KnowledgeVisibility visibility = KnowledgeVisibility.employee,
  String title = 'Reset a locked account',
  String summary = 'Steps for restoring account access',
  String categoryId = 'identity',
  String authorId = 'manager-1',
  bool isFeatured = false,
  DateTime? expiresAt,
  int currentVersionNumber = 1,
  int? publishedVersionNumber,
  KnowledgeActor? reviewer,
}) {
  return KnowledgeArticle(
    id: id,
    reference: 'KB-0001',
    categoryId: categoryId,
    title: title,
    summary: summary,
    languageCode: 'en',
    state: state,
    visibility: visibility,
    currentVersionNumber: currentVersionNumber,
    publishedVersionNumber: publishedVersionNumber,
    author: knowledgeActor(id: authorId),
    reviewer: reviewer,
    isFeatured: isFeatured,
    expiresAt: expiresAt,
    publishedAt: state == KnowledgeArticleState.published
        ? DateTime.utc(2026, 7, 1)
        : null,
    retiredAt: state == KnowledgeArticleState.retired
        ? DateTime.utc(2026, 7, 15)
        : null,
    archivedAt: state == KnowledgeArticleState.archived
        ? DateTime.utc(2026, 7, 20)
        : null,
    createdAt: DateTime.utc(2026, 6, 1),
    updatedAt: DateTime.utc(2026, 7, 1),
    relatedServiceIds: const ['identity-service'],
    relatedCatalogueItemIds: const ['password-reset'],
    relatedIncidentCategoryIds: const ['account-access'],
    suggestionCriteria: KnowledgeSuggestionCriteria(
      serviceIds: const ['identity-service'],
      catalogueItemIds: const ['password-reset'],
      incidentCategoryIds: const ['account-access'],
      keywords: const ['password', 'locked'],
    ),
    viewCount: 12,
    usageCount: 4,
    helpfulCount: 3,
    notHelpfulCount: 1,
  );
}

KnowledgeArticleVersion knowledgeVersion({
  KnowledgeArticleState state = KnowledgeArticleState.draft,
  int versionNumber = 1,
  KnowledgeActor? reviewer,
  String reviewComment = '',
  DateTime? publishedAt,
}) {
  return KnowledgeArticleVersion(
    articleId: 'article-1',
    versionNumber: versionNumber,
    title: 'Reset a locked account',
    summary: 'Steps for restoring account access',
    content: 'Open the identity portal and follow the recovery process.',
    languageCode: 'en',
    state: state,
    author: knowledgeActor(),
    reviewer: reviewer,
    reviewComment: reviewComment,
    createdAt: DateTime.utc(2026, 6, 1),
    submittedAt:
        state == KnowledgeArticleState.review ? DateTime.utc(2026, 6, 2) : null,
    reviewedAt: state == KnowledgeArticleState.published
        ? DateTime.utc(2026, 6, 3)
        : null,
    publishedAt: publishedAt,
  );
}
