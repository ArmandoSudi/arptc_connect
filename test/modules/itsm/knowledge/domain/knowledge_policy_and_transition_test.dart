import 'package:arptc_connect/modules/itsm/knowledge/domain/knowledge_domain.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_common.dart';
import 'package:flutter_test/flutter_test.dart';

import '../knowledge_test_fixtures.dart';

void main() {
  group('KnowledgeAccessPolicy', () {
    test('USER and ADMIN read only current employee-visible publications', () {
      final now = DateTime.utc(2026, 7, 31);
      final published = knowledgeArticle(
        state: KnowledgeArticleState.published,
        publishedVersionNumber: 1,
      );
      final dsiOnly = knowledgeArticle(
        state: KnowledgeArticleState.published,
        visibility: KnowledgeVisibility.dsiOnly,
        publishedVersionNumber: 1,
      );
      final expired = knowledgeArticle(
        state: KnowledgeArticleState.published,
        publishedVersionNumber: 1,
        expiresAt: DateTime.utc(2026, 7, 30),
      );
      final draft = knowledgeArticle();

      for (final role in [ItsmRole.user, ItsmRole.admin]) {
        final policy = KnowledgeAccessPolicy(role);
        expect(policy.canReadArticle(published, at: now), isTrue);
        expect(policy.canReadArticle(dsiOnly, at: now), isFalse);
        expect(policy.canReadArticle(expired, at: now), isFalse);
        expect(policy.canReadArticle(draft, at: now), isFalse);
        expect(policy.canManage, isFalse);
      }
    });

    test('MANAGER can read and manage every lifecycle and visibility', () {
      const policy = KnowledgeAccessPolicy(ItsmRole.manager);
      final article = knowledgeArticle(
        state: KnowledgeArticleState.draft,
        visibility: KnowledgeVisibility.dsiOnly,
      );

      expect(
        policy.canReadArticle(article, at: DateTime.utc(2026, 7, 31)),
        isTrue,
      );
      expect(policy.canAuthor, isTrue);
      expect(policy.canReview, isTrue);
      expect(policy.canPublish, isTrue);
      expect(policy.canRetire, isTrue);
      expect(policy.canArchive, isTrue);
    });
  });

  group('KnowledgeLifecycleService', () {
    const service = KnowledgeLifecycleService();
    const managerPolicy = KnowledgeAccessPolicy(ItsmRole.manager);
    const actor = KnowledgeActorContext(
      userId: 'reviewer-1',
      name: 'Reviewer One',
      email: 'reviewer@example.com',
    );

    test('supports the complete governed lifecycle', () {
      var article = knowledgeArticle();
      var version = knowledgeVersion();

      var result = service.transition(
        policy: managerPolicy,
        article: article,
        version: version,
        action: KnowledgeTransitionAction.submitForReview,
        actor: actor,
        at: DateTime.utc(2026, 7, 1),
      );
      expect(result.article.state, KnowledgeArticleState.review);
      expect(result.version.submittedAt, DateTime.utc(2026, 7, 1));

      article = result.article;
      version = result.version;
      result = service.transition(
        policy: managerPolicy,
        article: article,
        version: version,
        action: KnowledgeTransitionAction.publish,
        actor: actor,
        at: DateTime.utc(2026, 7, 2),
      );
      expect(result.article.state, KnowledgeArticleState.published);
      expect(result.article.publishedVersionNumber, 1);
      expect(result.version.reviewer?.userId, 'reviewer-1');
      expect(result.version.isImmutable, isTrue);

      article = result.article;
      version = result.version;
      result = service.transition(
        policy: managerPolicy,
        article: article,
        version: version,
        action: KnowledgeTransitionAction.retire,
        actor: actor,
        at: DateTime.utc(2026, 7, 3),
      );
      result = service.transition(
        policy: managerPolicy,
        article: result.article,
        version: result.version,
        action: KnowledgeTransitionAction.archive,
        actor: actor,
        at: DateTime.utc(2026, 7, 4),
      );
      expect(result.article.state, KnowledgeArticleState.archived);
      expect(result.article.archivedAt, DateTime.utc(2026, 7, 4));
    });

    test('rejection requires a comment and returns article to draft', () {
      final article = knowledgeArticle(state: KnowledgeArticleState.review);
      final version = knowledgeVersion(state: KnowledgeArticleState.review);

      expect(
        () => service.transition(
          policy: managerPolicy,
          article: article,
          version: version,
          action: KnowledgeTransitionAction.rejectToDraft,
          actor: actor,
          at: DateTime.utc(2026, 7, 2),
        ),
        throwsA(isA<KnowledgeTransitionException>()),
      );

      final result = service.transition(
        policy: managerPolicy,
        article: article,
        version: version,
        action: KnowledgeTransitionAction.rejectToDraft,
        actor: actor,
        at: DateTime.utc(2026, 7, 2),
        reviewComment: 'Clarify the recovery prerequisites.',
      );
      expect(result.article.state, KnowledgeArticleState.draft);
      expect(result.version.reviewComment, contains('prerequisites'));
    });

    test('denies invalid transitions and non-manager operations', () {
      final article = knowledgeArticle();
      final version = knowledgeVersion();

      expect(
        () => service.transition(
          policy: const KnowledgeAccessPolicy(ItsmRole.user),
          article: article,
          version: version,
          action: KnowledgeTransitionAction.submitForReview,
          actor: actor,
          at: DateTime.utc(2026, 7, 1),
        ),
        throwsA(isA<KnowledgeAccessDeniedException>()),
      );
      expect(
        () => service.transition(
          policy: managerPolicy,
          article: article,
          version: version,
          action: KnowledgeTransitionAction.publish,
          actor: actor,
          at: DateTime.utc(2026, 7, 1),
        ),
        throwsA(isA<KnowledgeTransitionException>()),
      );
    });
  });
}
