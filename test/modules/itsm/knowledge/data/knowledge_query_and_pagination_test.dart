import 'package:arptc_connect/modules/itsm/knowledge/data/knowledge_data.dart';
import 'package:arptc_connect/modules/itsm/knowledge/domain/knowledge_domain.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/pagination.dart';
import 'package:flutter_test/flutter_test.dart';

import '../knowledge_test_fixtures.dart';

void main() {
  group('published query filtering', () {
    final now = DateTime.utc(2026, 7, 31);

    test('search filters published employee-visible articles', () {
      final query = KnowledgePublishedQuery(
        view: KnowledgePublishedView.search,
        searchTerm: 'reset',
        asOf: now,
      );

      expect(
        query.matches(
          knowledgeArticle(
            state: KnowledgeArticleState.published,
            publishedVersionNumber: 1,
          ),
        ),
        isTrue,
      );
      expect(
        query.matches(
          knowledgeArticle(
            state: KnowledgeArticleState.published,
            visibility: KnowledgeVisibility.dsiOnly,
            publishedVersionNumber: 1,
          ),
        ),
        isFalse,
      );
      expect(query.matches(knowledgeArticle()), isFalse);
    });

    test('featured, expiry, category, and language filters are enforced', () {
      final query = KnowledgePublishedQuery(
        view: KnowledgePublishedView.featured,
        categoryId: 'identity',
        languageCode: 'en',
        asOf: now,
      );
      final article = knowledgeArticle(
        state: KnowledgeArticleState.published,
        publishedVersionNumber: 1,
        isFeatured: true,
      );

      expect(query.matches(article), isTrue);
      expect(
        query.matches(
          knowledgeArticle(
            state: KnowledgeArticleState.published,
            publishedVersionNumber: 1,
            isFeatured: false,
          ),
        ),
        isFalse,
      );
      expect(
        query.matches(
          knowledgeArticle(
            state: KnowledgeArticleState.published,
            publishedVersionNumber: 1,
            isFeatured: true,
            expiresAt: DateTime.utc(2026, 7, 30),
          ),
        ),
        isFalse,
      );
    });
  });

  test('manager queues isolate author and lifecycle filters', () {
    const authored =
        KnowledgeManagerQuery(queue: KnowledgeManagerQueue.authoredByMe);
    const review =
        KnowledgeManagerQuery(queue: KnowledgeManagerQueue.awaitingReview);

    expect(
      authored.matches(knowledgeArticle(), managerUserId: 'manager-1'),
      isTrue,
    );
    expect(
      authored.matches(knowledgeArticle(), managerUserId: 'manager-2'),
      isFalse,
    );
    expect(
      review.matches(
        knowledgeArticle(state: KnowledgeArticleState.review),
        managerUserId: 'manager-2',
      ),
      isTrue,
    );
  });

  test('suggestions score exact relationships before keyword-only matches', () {
    final article = knowledgeArticle(
      state: KnowledgeArticleState.published,
      publishedVersionNumber: 1,
    );
    const exact = KnowledgeSuggestionContext(
      serviceId: 'identity-service',
      text: 'password',
    );
    const keywordOnly = KnowledgeSuggestionContext(text: 'password');

    expect(article.suggestionCriteria.score(exact), 10);
    expect(article.suggestionCriteria.score(keywordOnly), 2);
    expect(
      KnowledgeSuggestionQuery(
        context: exact,
        asOf: DateTime.utc(2026, 7, 31),
      ).matches(article),
      isTrue,
    );
  });

  test('query and cursor requests have stable value equality', () {
    final first = KnowledgePublishedQuery(
      view: KnowledgePublishedView.search,
      searchTerm: '  RESET ',
      asOf: DateTime.utc(2026, 7, 31),
    );
    final second = KnowledgePublishedQuery(
      view: KnowledgePublishedView.search,
      searchTerm: 'reset',
      asOf: DateTime.utc(2026, 7, 31),
    );
    final firstCursor = PageCursor({
      'sortAt': DateTime.utc(2026, 7, 1),
      'documentId': 'article-1',
    });
    final secondCursor = PageCursor({
      'documentId': 'article-1',
      'sortAt': DateTime.utc(2026, 7, 1),
    });

    expect(first, second);
    expect(first.hashCode, second.hashCode);
    expect(firstCursor, secondCursor);
    expect(PageRequest(limit: 25, cursor: firstCursor).limit, 25);
    expect(() => PageRequest(limit: 101), throwsRangeError);
  });
}
