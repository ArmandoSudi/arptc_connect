import 'package:arptc_connect/modules/itsm/knowledge/domain/knowledge_domain.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import '../knowledge_test_fixtures.dart';

void main() {
  test('category supports bilingual Firestore round trips', () {
    final category = KnowledgeCategory(
      id: 'network',
      nameEn: 'Network',
      nameFr: 'Réseau',
      descriptionEn: 'Connectivity help',
      descriptionFr: 'Aide à la connectivité',
      sortOrder: 2,
      createdAt: DateTime.utc(2026, 7, 1),
    );

    final restored = KnowledgeCategory.fromMap(
      id: category.id,
      data: category.toFirestore(),
    );

    expect(restored.localizedName('fr'), 'Réseau');
    expect(restored.localizedName('en'), 'Network');
    expect(restored.sortOrder, 2);
    expect(restored.createdAt, DateTime.utc(2026, 7, 1));
  });

  test('article serializes lifecycle, relationships, counters and suggestions',
      () {
    final article = knowledgeArticle(
      state: KnowledgeArticleState.published,
      publishedVersionNumber: 1,
      isFeatured: true,
    );

    final map = article.toFirestore();
    final restored = KnowledgeArticle.fromMap(id: article.id, data: map);

    expect(map['state'], 'published');
    expect(map['visibility'], 'employee');
    expect(map['authorId'], 'manager-1');
    expect(map['suggestionKeys'], contains('service:identity-service'));
    expect(map['searchTokens'], contains('reset'));
    expect(restored.relatedCatalogueItemIds, ['password-reset']);
    expect(restored.helpfulCount, 3);
    expect(restored.viewCount, 12);
    expect(restored.publishedVersionNumber, 1);
  });

  test('version preserves author, reviewer, attachments and Firestore dates',
      () {
    final reviewer = knowledgeActor(
      id: 'reviewer-1',
      email: 'reviewer@example.com',
    );
    final attachment = KnowledgeAttachment(
      id: 'attachment-1',
      fileName: 'guide.pdf',
      storagePath: 'knowledge/article-1/guide.pdf',
      contentType: 'application/pdf',
      sizeBytes: 2048,
      uploadedBy: knowledgeActor(),
      uploadedAt: DateTime.utc(2026, 6, 1),
    );
    final version = KnowledgeArticleVersion(
      articleId: 'article-1',
      versionNumber: 2,
      title: 'Account recovery',
      summary: 'Recovery guide',
      content: 'Follow the documented procedure.',
      languageCode: 'en',
      state: KnowledgeArticleState.published,
      author: knowledgeActor(),
      reviewer: reviewer,
      createdAt: DateTime.utc(2026, 6, 1),
      reviewedAt: DateTime.utc(2026, 6, 2),
      publishedAt: DateTime.utc(2026, 6, 3),
      attachments: [attachment],
    );

    final map = version.toFirestore();
    final restored = KnowledgeArticleVersion.fromMap(
      articleId: 'article-1',
      versionNumber: 2,
      data: map,
    );

    expect(map['publishedAt'], isA<Timestamp>());
    expect(restored.documentId, '000002');
    expect(restored.reviewer, reviewer);
    expect(restored.attachments.single.id, 'attachment-1');
    expect(restored.attachments.single.sizeBytes, 2048);
  });

  test('feedback round trips helpful state and comment', () {
    final feedback = KnowledgeFeedback(
      id: 'feedback-1',
      articleId: 'article-1',
      userId: 'user-1',
      helpful: false,
      comment: 'The last step is unclear.',
      createdAt: DateTime.utc(2026, 7, 31),
    );

    final restored = KnowledgeFeedback.fromMap(
      id: feedback.id,
      articleId: feedback.articleId,
      data: feedback.toFirestore(),
    );

    expect(restored.helpful, isFalse);
    expect(restored.comment, 'The last step is unclear.');
    expect(restored.createdAt, DateTime.utc(2026, 7, 31));
  });

  test('search token builder creates deterministic prefixes', () {
    final tokens = buildKnowledgeSearchTokens(
      const ['Password Reset', 'Locked account'],
    );

    expect(tokens, containsAll(['pa', 'pass', 'password', 'password reset']));
    expect(() => tokens.add('changed'), throwsUnsupportedError);
  });
}
