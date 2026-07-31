import 'package:arptc_connect/modules/itsm/knowledge/domain/knowledge_domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../knowledge_test_fixtures.dart';

void main() {
  test('only draft versions can be revised', () {
    final draft = knowledgeVersion();
    final revised = draft.reviseDraft(
      title: 'Updated recovery guide',
      summary: 'Updated summary',
      content: 'Updated content',
      languageCode: 'en',
    );

    expect(revised.versionNumber, 1);
    expect(revised.title, 'Updated recovery guide');
    expect(draft.title, 'Reset a locked account');

    for (final state in [
      KnowledgeArticleState.review,
      KnowledgeArticleState.published,
      KnowledgeArticleState.retired,
      KnowledgeArticleState.archived,
    ]) {
      final version = knowledgeVersion(
        state: state,
        publishedAt: state == KnowledgeArticleState.published
            ? DateTime.utc(2026, 7, 1)
            : null,
      );
      expect(
        () => version.reviseDraft(
          title: 'Changed',
          summary: 'Changed',
          content: 'Changed',
          languageCode: 'en',
        ),
        throwsA(isA<KnowledgeVersionImmutableException>()),
      );
    }
  });

  test('a published version creates a new monotonically increasing draft', () {
    final published = knowledgeVersion(
      state: KnowledgeArticleState.published,
      versionNumber: 3,
      publishedAt: DateTime.utc(2026, 7, 1),
    );

    final next = published.createNextDraft(
      newAuthor: knowledgeActor(id: 'manager-2'),
      createdAt: DateTime.utc(2026, 7, 31),
    );

    expect(next.versionNumber, 4);
    expect(next.state, KnowledgeArticleState.draft);
    expect(next.author.userId, 'manager-2');
    expect(next.publishedAt, isNull);
  });

  test('article relationship and version attachment collections are immutable',
      () {
    final services = <String>['identity-service'];
    final article = KnowledgeArticle(
      id: 'article-1',
      reference: 'KB-0001',
      categoryId: 'identity',
      title: 'Account access',
      summary: 'Help',
      languageCode: 'en',
      state: KnowledgeArticleState.draft,
      visibility: KnowledgeVisibility.employee,
      currentVersionNumber: 1,
      author: knowledgeActor(),
      createdAt: DateTime.utc(2026, 7, 1),
      updatedAt: DateTime.utc(2026, 7, 1),
      relatedServiceIds: services,
    );
    services.add('another-service');

    expect(article.relatedServiceIds, ['identity-service']);
    expect(
      () => article.relatedServiceIds.add('changed'),
      throwsUnsupportedError,
    );
  });
}
