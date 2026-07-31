import 'dart:async';

import 'package:arptc_connect/modules/itsm/knowledge/application/knowledge_application.dart';
import 'package:arptc_connect/modules/itsm/knowledge/data/knowledge_data.dart';
import 'package:arptc_connect/modules/itsm/knowledge/domain/knowledge_domain.dart';
import 'package:arptc_connect/modules/itsm/shared/application/itsm_providers.dart';
import 'package:arptc_connect/modules/itsm/shared/application/itsm_session.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_common.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/pagination.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../knowledge_test_fixtures.dart';

void main() {
  test('USER and ADMIN providers load only the published repository path',
      () async {
    for (final role in [ItsmRole.user, ItsmRole.admin]) {
      final repository = _RecordingKnowledgeRepository();
      final container = _container(role: role, repository: repository);
      addTearDown(container.dispose);
      final request = KnowledgePublishedPageRequest(
        query: KnowledgePublishedQuery(
          asOf: DateTime.utc(2026, 7, 31),
        ),
        page: PageRequest(limit: 10),
      );

      await container.read(knowledgePublishedPageProvider(request).future);

      expect(repository.publishedCalls, 1);
      expect(repository.managerCalls, 0);
      expect(repository.lastPage?.limit, 10);
    }
  });

  test('USER cannot load manager queue and repository is not called', () async {
    final repository = _RecordingKnowledgeRepository();
    final container = _container(role: ItsmRole.user, repository: repository);
    addTearDown(container.dispose);
    final request = KnowledgeManagerPageRequest(
      query: const KnowledgeManagerQuery(
        queue: KnowledgeManagerQueue.awaitingReview,
      ),
      page: PageRequest(),
    );

    await expectLater(
      container.read(knowledgeManagerPageProvider(request).future),
      throwsA(isA<KnowledgeAccessDeniedException>()),
    );
    expect(repository.managerCalls, 0);
  });

  test('MANAGER queue is scoped to the current session user ID', () async {
    final repository = _RecordingKnowledgeRepository();
    final container = _container(
      role: ItsmRole.manager,
      userId: 'manager-22',
      repository: repository,
    );
    addTearDown(container.dispose);
    final request = KnowledgeManagerPageRequest(
      query: const KnowledgeManagerQuery(
        queue: KnowledgeManagerQueue.authoredByMe,
      ),
      page: PageRequest(),
    );

    await container.read(knowledgeManagerPageProvider(request).future);

    expect(repository.lastManagerUserId, 'manager-22');
    expect(repository.managerCalls, 1);
  });

  test('public article provider rejects DSI-only content for ADMIN', () async {
    final repository = _RecordingKnowledgeRepository(
      watchedArticle: knowledgeArticle(
        state: KnowledgeArticleState.published,
        visibility: KnowledgeVisibility.dsiOnly,
        publishedVersionNumber: 1,
      ),
    );
    final container = _container(role: ItsmRole.admin, repository: repository);
    addTearDown(container.dispose);
    final request = KnowledgeArticleRequest(
      articleId: 'article-1',
      asOf: DateTime.utc(2026, 7, 31),
    );
    final provider = knowledgeArticleProvider(request);
    final subscription = container.listen(provider, (_, __) {});
    addTearDown(subscription.close);

    await expectLater(
      container.read(provider.future),
      throwsA(isA<KnowledgeAccessDeniedException>()),
    );
  });

  test('non-manager can fetch only the published version', () async {
    final repository = _RecordingKnowledgeRepository(
      watchedArticle: knowledgeArticle(
        state: KnowledgeArticleState.published,
        publishedVersionNumber: 2,
        currentVersionNumber: 3,
      ),
    );
    final container = _container(role: ItsmRole.user, repository: repository);
    addTearDown(container.dispose);

    await expectLater(
      container.read(
        knowledgeVersionProvider(
          KnowledgeVersionRequest(
            articleId: 'article-1',
            versionNumber: 3,
            asOf: DateTime.utc(2026, 7, 31),
          ),
        ).future,
      ),
      throwsA(isA<KnowledgeAccessDeniedException>()),
    );
    expect(repository.versionCalls, 0);
  });

  test('inactive categories are manager-only', () async {
    final repository = _RecordingKnowledgeRepository();
    final userContainer =
        _container(role: ItsmRole.user, repository: repository);
    addTearDown(userContainer.dispose);
    final provider = knowledgeCategoriesProvider(
      const KnowledgeCategoryRequest(activeOnly: false),
    );
    final subscription = userContainer.listen(provider, (_, __) {});
    addTearDown(subscription.close);

    await expectLater(
      userContainer.read(provider.future),
      throwsA(isA<KnowledgeAccessDeniedException>()),
    );
    expect(repository.categoryCalls, 0);
  });

  test('live article provider resubscribes when the session changes', () async {
    final sessions = StreamController<ItsmSession?>();
    final repository = _RecordingKnowledgeRepository();
    final container = ProviderContainer(
      overrides: [
        itsmSessionProvider.overrideWith((ref) => sessions.stream),
        knowledgeRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await sessions.close();
    });
    final provider = knowledgeArticleProvider(
      KnowledgeArticleRequest(
        articleId: 'article-1',
        asOf: DateTime.utc(2026, 7, 31),
      ),
    );
    final subscription = container.listen(provider, (_, __) {});
    addTearDown(subscription.close);

    sessions.add(_session(userId: 'user-1', role: ItsmRole.user));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    sessions.add(_session(userId: 'manager-2', role: ItsmRole.manager));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(repository.watchArticleCalls, greaterThanOrEqualTo(2));
  });

  test('provider request equality keeps pagination families stable', () {
    final first = KnowledgeManagerPageRequest(
      query: const KnowledgeManagerQuery(
        queue: KnowledgeManagerQueue.drafts,
        searchTerm: ' ACCESS ',
      ),
      page: PageRequest(limit: 20),
    );
    final second = KnowledgeManagerPageRequest(
      query: const KnowledgeManagerQuery(
        queue: KnowledgeManagerQueue.drafts,
        searchTerm: 'access',
      ),
      page: PageRequest(limit: 20),
    );

    expect(first, second);
    expect(first.hashCode, second.hashCode);
  });
}

ProviderContainer _container({
  required ItsmRole role,
  required _RecordingKnowledgeRepository repository,
  String userId = 'user-1',
}) {
  return ProviderContainer(
    overrides: [
      itsmSessionProvider.overrideWith(
        (ref) => Stream.value(
          ItsmSession(
            sessionKey: '$userId|agent@example.com',
            userId: userId,
            email: 'agent@example.com',
            displayName: 'Agent',
            role: role,
          ),
        ),
      ),
      knowledgeRepositoryProvider.overrideWithValue(repository),
    ],
  );
}

ItsmSession _session({required String userId, required ItsmRole role}) {
  return ItsmSession(
    sessionKey: '$userId|agent@example.com',
    userId: userId,
    email: 'agent@example.com',
    displayName: 'Agent',
    role: role,
  );
}

class _RecordingKnowledgeRepository implements KnowledgeRepository {
  _RecordingKnowledgeRepository({KnowledgeArticle? watchedArticle})
      : watchedArticle = watchedArticle ??
            knowledgeArticle(
              state: KnowledgeArticleState.published,
              publishedVersionNumber: 1,
            );

  final KnowledgeArticle watchedArticle;
  int publishedCalls = 0;
  int managerCalls = 0;
  int versionCalls = 0;
  int categoryCalls = 0;
  int watchArticleCalls = 0;
  String? lastManagerUserId;
  PageRequest? lastPage;

  @override
  Future<PageResult<KnowledgeArticle>> fetchPublishedPage({
    required KnowledgePublishedQuery query,
    required PageRequest page,
  }) async {
    publishedCalls++;
    lastPage = page;
    return PageResult(items: const [], hasMore: false);
  }

  @override
  Future<PageResult<KnowledgeArticle>> fetchSuggestions({
    required KnowledgeSuggestionQuery query,
    required PageRequest page,
  }) async {
    lastPage = page;
    return PageResult(items: const [], hasMore: false);
  }

  @override
  Future<PageResult<KnowledgeArticle>> fetchManagerPage({
    required String managerUserId,
    required KnowledgeManagerQuery query,
    required PageRequest page,
  }) async {
    managerCalls++;
    lastManagerUserId = managerUserId;
    lastPage = page;
    return PageResult(items: const [], hasMore: false);
  }

  @override
  Future<KnowledgeArticleVersion?> fetchVersion({
    required String articleId,
    required int versionNumber,
    bool includeInternalAttachments = false,
  }) async {
    versionCalls++;
    return knowledgeVersion(
      state: KnowledgeArticleState.published,
      versionNumber: versionNumber,
      publishedAt: DateTime.utc(2026, 7, 1),
    );
  }

  @override
  Stream<KnowledgeArticle?> watchArticle(String articleId) {
    watchArticleCalls++;
    return Stream.value(watchedArticle);
  }

  @override
  Stream<List<KnowledgeCategory>> watchCategories({
    bool activeOnly = true,
    int limit = PageRequest.maximumLimit,
  }) {
    categoryCalls++;
    return Stream.value(const []);
  }
}
