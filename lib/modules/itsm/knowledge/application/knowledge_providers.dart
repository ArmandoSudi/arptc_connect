import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/application/itsm_providers.dart';
import '../../shared/application/itsm_session.dart';
import '../../shared/domain/pagination.dart';
import '../data/knowledge_data.dart';
import '../domain/knowledge_domain.dart';
import 'knowledge_action_notifier.dart';
import 'knowledge_command_controller.dart';

final knowledgeRepositoryProvider = Provider<KnowledgeRepository>(
  (ref) => FirestoreKnowledgeRepository(FirebaseFirestore.instance),
);

final knowledgeLifecycleServiceProvider = Provider<KnowledgeLifecycleService>(
  (ref) => const KnowledgeLifecycleService(),
);

final knowledgeCommandGatewayProvider = Provider<KnowledgeCommandGateway>(
  (ref) => FirebaseKnowledgeCommandGateway(
    FirebaseKnowledgeCallableInvoker(FirebaseFunctions.instance),
  ),
);

final knowledgeCommandControllerProvider =
    FutureProvider.autoDispose<KnowledgeCommandController>((ref) async {
  final gateway = ref.watch(knowledgeCommandGatewayProvider);
  final lifecycleService = ref.watch(knowledgeLifecycleServiceProvider);
  final executor = ref.watch(itsmCommandExecutorProvider);
  final session = await _requireSession(ref);
  return KnowledgeCommandController(
    session: session,
    gateway: gateway,
    lifecycleService: lifecycleService,
    executor: executor,
  );
});

final knowledgeActionProvider = StateNotifierProvider.autoDispose.family<
    KnowledgeActionNotifier, AsyncValue<KnowledgeCommandReceipt?>, String>(
  (ref, scope) => KnowledgeActionNotifier(),
);

final knowledgeAccessPolicyProvider =
    Provider.autoDispose<AsyncValue<KnowledgeAccessPolicy?>>((ref) {
  return ref.watch(itsmSessionProvider).whenData(
        (session) =>
            session == null ? null : KnowledgeAccessPolicy(session.role),
      );
});

class KnowledgePublishedPageRequest {
  const KnowledgePublishedPageRequest({
    required this.query,
    required this.page,
  });

  final KnowledgePublishedQuery query;
  final PageRequest page;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is KnowledgePublishedPageRequest &&
            query == other.query &&
            page.limit == other.page.limit &&
            page.cursor == other.page.cursor &&
            page.direction == other.page.direction;
  }

  @override
  int get hashCode =>
      Object.hash(query, page.limit, page.cursor, page.direction);
}

final knowledgePublishedPageProvider = FutureProvider.autoDispose
    .family<PageResult<KnowledgeArticle>, KnowledgePublishedPageRequest>(
  (ref, request) async {
    final repository = ref.watch(knowledgeRepositoryProvider);
    final session = await _requireSession(ref);
    final policy = KnowledgeAccessPolicy(session.role);
    if (!policy.canBrowsePublished) {
      throw const KnowledgeAccessDeniedException(
        'Published knowledge is not available.',
      );
    }
    return repository.fetchPublishedPage(
      query: request.query,
      page: request.page,
    );
  },
);

class KnowledgeSuggestionPageRequest {
  const KnowledgeSuggestionPageRequest({
    required this.query,
    required this.page,
  });

  final KnowledgeSuggestionQuery query;
  final PageRequest page;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is KnowledgeSuggestionPageRequest &&
            query == other.query &&
            page.limit == other.page.limit &&
            page.cursor == other.page.cursor &&
            page.direction == other.page.direction;
  }

  @override
  int get hashCode =>
      Object.hash(query, page.limit, page.cursor, page.direction);
}

final knowledgeSuggestionPageProvider = FutureProvider.autoDispose
    .family<PageResult<KnowledgeArticle>, KnowledgeSuggestionPageRequest>(
  (ref, request) async {
    final repository = ref.watch(knowledgeRepositoryProvider);
    final session = await _requireSession(ref);
    if (!KnowledgeAccessPolicy(session.role).canBrowsePublished) {
      throw const KnowledgeAccessDeniedException(
        'Knowledge suggestions are not available.',
      );
    }
    return repository.fetchSuggestions(
      query: request.query,
      page: request.page,
    );
  },
);

class KnowledgeManagerPageRequest {
  const KnowledgeManagerPageRequest({
    required this.query,
    required this.page,
  });

  final KnowledgeManagerQuery query;
  final PageRequest page;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is KnowledgeManagerPageRequest &&
            query == other.query &&
            page.limit == other.page.limit &&
            page.cursor == other.page.cursor &&
            page.direction == other.page.direction;
  }

  @override
  int get hashCode =>
      Object.hash(query, page.limit, page.cursor, page.direction);
}

final knowledgeManagerPageProvider = FutureProvider.autoDispose
    .family<PageResult<KnowledgeArticle>, KnowledgeManagerPageRequest>(
  (ref, request) async {
    final repository = ref.watch(knowledgeRepositoryProvider);
    final session = await _requireSession(ref);
    KnowledgeAccessPolicy(session.role).requireManager('browse');
    return repository.fetchManagerPage(
      managerUserId: session.userId,
      query: request.query,
      page: request.page,
    );
  },
);

class KnowledgeArticleRequest {
  const KnowledgeArticleRequest({
    required this.articleId,
    required this.asOf,
  });

  final String articleId;
  final DateTime asOf;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is KnowledgeArticleRequest &&
            articleId.trim() == other.articleId.trim() &&
            asOf.toUtc() == other.asOf.toUtc();
  }

  @override
  int get hashCode => Object.hash(articleId.trim(), asOf.toUtc());
}

final knowledgeArticleProvider = StreamProvider.autoDispose
    .family<KnowledgeArticle?, KnowledgeArticleRequest>(
  (ref, request) {
    final repository = ref.watch(knowledgeRepositoryProvider);
    return ref.watch(itsmSessionProvider).when(
          loading: _pendingStream,
          error: (error, stackTrace) => Stream.error(error, stackTrace),
          data: (session) {
            if (session == null) {
              return Stream.error(const ItsmSessionRequiredException());
            }
            final policy = KnowledgeAccessPolicy(session.role);
            return repository.watchArticle(request.articleId).map((article) {
              if (article == null) return null;
              if (!policy.canReadArticle(article, at: request.asOf)) {
                throw const KnowledgeAccessDeniedException(
                  'This knowledge article is not visible to the current user.',
                );
              }
              return article;
            });
          },
        );
  },
);

class KnowledgeVersionRequest {
  const KnowledgeVersionRequest({
    required this.articleId,
    required this.versionNumber,
    required this.asOf,
  });

  final String articleId;
  final int versionNumber;
  final DateTime asOf;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is KnowledgeVersionRequest &&
            articleId.trim() == other.articleId.trim() &&
            versionNumber == other.versionNumber &&
            asOf.toUtc() == other.asOf.toUtc();
  }

  @override
  int get hashCode =>
      Object.hash(articleId.trim(), versionNumber, asOf.toUtc());
}

final knowledgeVersionProvider = FutureProvider.autoDispose
    .family<KnowledgeArticleVersion?, KnowledgeVersionRequest>(
  (ref, request) async {
    final repository = ref.watch(knowledgeRepositoryProvider);
    final session = await _requireSession(ref);
    final policy = KnowledgeAccessPolicy(session.role);
    final article = await repository.watchArticle(request.articleId).first;
    if (article == null) return null;
    if (!policy.canReadArticle(article, at: request.asOf)) {
      throw const KnowledgeAccessDeniedException(
        'This knowledge version is not visible to the current user.',
      );
    }
    if (!policy.canManage &&
        article.publishedVersionNumber != request.versionNumber) {
      throw const KnowledgeAccessDeniedException(
        'Only the published version is visible.',
      );
    }
    return repository.fetchVersion(
      articleId: request.articleId,
      versionNumber: request.versionNumber,
      includeInternalAttachments: policy.canManage,
    );
  },
);

class KnowledgeCategoryRequest {
  const KnowledgeCategoryRequest({
    this.activeOnly = true,
    this.limit = PageRequest.maximumLimit,
  });

  final bool activeOnly;
  final int limit;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is KnowledgeCategoryRequest &&
            activeOnly == other.activeOnly &&
            limit == other.limit;
  }

  @override
  int get hashCode => Object.hash(activeOnly, limit);
}

final knowledgeCategoriesProvider = StreamProvider.autoDispose
    .family<List<KnowledgeCategory>, KnowledgeCategoryRequest>(
  (ref, request) {
    final repository = ref.watch(knowledgeRepositoryProvider);
    return ref.watch(itsmSessionProvider).when(
          loading: _pendingStream,
          error: (error, stackTrace) => Stream.error(error, stackTrace),
          data: (session) {
            if (session == null) {
              return Stream.error(const ItsmSessionRequiredException());
            }
            if (!request.activeOnly) {
              KnowledgeAccessPolicy(session.role)
                  .requireManager('browse inactive');
            }
            return repository.watchCategories(
              activeOnly: request.activeOnly,
              limit: request.limit,
            );
          },
        );
  },
);

Future<ItsmSession> _requireSession(Ref ref) async {
  final session = await ref.watch(itsmSessionProvider.future);
  if (session == null) throw const ItsmSessionRequiredException();
  return session;
}

Stream<T> _pendingStream<T>() => Stream<T>.multi((_) {});
