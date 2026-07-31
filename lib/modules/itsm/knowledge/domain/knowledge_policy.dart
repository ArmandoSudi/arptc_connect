import '../../shared/domain/itsm_common.dart';
import 'knowledge_actor.dart';
import 'knowledge_article.dart';
import 'knowledge_article_version.dart';
import 'knowledge_enums.dart';

class KnowledgeAccessPolicy {
  const KnowledgeAccessPolicy(this.role);

  final ItsmRole role;

  bool get canBrowsePublished => true;
  bool get canManage => role == ItsmRole.manager;
  bool get canAuthor => canManage;
  bool get canReview => canManage;
  bool get canPublish => canManage;
  bool get canRetire => canManage;
  bool get canArchive => canManage;

  bool canReadArticle(
    KnowledgeArticle article, {
    required DateTime at,
  }) {
    if (role == ItsmRole.manager) return true;
    return article.state == KnowledgeArticleState.published &&
        article.visibility == KnowledgeVisibility.employee &&
        !article.isExpiredAt(at);
  }

  void requireManager(String action) {
    if (!canManage) {
      throw KnowledgeAccessDeniedException(
        'Role ${role.value} cannot $action knowledge articles.',
      );
    }
  }
}

class KnowledgeLifecycleService {
  const KnowledgeLifecycleService();

  KnowledgeTransitionResult transition({
    required KnowledgeAccessPolicy policy,
    required KnowledgeArticle article,
    required KnowledgeArticleVersion version,
    required KnowledgeTransitionAction action,
    required KnowledgeActorContext actor,
    required DateTime at,
    String reviewComment = '',
  }) {
    policy.requireManager(action.name);
    if (article.currentVersionNumber != version.versionNumber ||
        article.id != version.articleId ||
        article.state != version.state) {
      throw const KnowledgeTransitionException(
        'Article and current version are inconsistent.',
      );
    }

    final next = _nextState(article.state, action);
    if (action == KnowledgeTransitionAction.rejectToDraft &&
        reviewComment.trim().isEmpty) {
      throw const KnowledgeTransitionException(
        'A review comment is required when rejecting an article.',
      );
    }
    if (action == KnowledgeTransitionAction.publish &&
        (version.title.isEmpty || version.content.isEmpty)) {
      throw const KnowledgeTransitionException(
        'A title and content are required before publication.',
      );
    }

    final reviewer = action == KnowledgeTransitionAction.rejectToDraft ||
            action == KnowledgeTransitionAction.publish
        ? actor.toKnowledgeActor()
        : null;
    final transitionedArticle = article.transitionForLifecycle(
      nextState: next,
      at: at.toUtc(),
      reviewer: reviewer,
      reviewComment: reviewComment,
      publishedVersionNumber: action == KnowledgeTransitionAction.publish
          ? version.versionNumber
          : null,
    );
    final transitionedVersion = version.transitionForLifecycle(
      nextState: next,
      reviewer: reviewer,
      reviewComment: reviewComment,
      submittedAt: action == KnowledgeTransitionAction.submitForReview
          ? at.toUtc()
          : null,
      reviewedAt: action == KnowledgeTransitionAction.rejectToDraft ||
              action == KnowledgeTransitionAction.publish
          ? at.toUtc()
          : null,
      publishedAt:
          action == KnowledgeTransitionAction.publish ? at.toUtc() : null,
    );
    return KnowledgeTransitionResult(
      article: transitionedArticle,
      version: transitionedVersion,
    );
  }

  KnowledgeArticleState _nextState(
    KnowledgeArticleState current,
    KnowledgeTransitionAction action,
  ) {
    final valid = switch ((current, action)) {
      (
        KnowledgeArticleState.draft,
        KnowledgeTransitionAction.submitForReview
      ) =>
        KnowledgeArticleState.review,
      (KnowledgeArticleState.review, KnowledgeTransitionAction.rejectToDraft) =>
        KnowledgeArticleState.draft,
      (KnowledgeArticleState.review, KnowledgeTransitionAction.publish) =>
        KnowledgeArticleState.published,
      (KnowledgeArticleState.published, KnowledgeTransitionAction.retire) =>
        KnowledgeArticleState.retired,
      (KnowledgeArticleState.retired, KnowledgeTransitionAction.archive) =>
        KnowledgeArticleState.archived,
      _ => null,
    };
    if (valid == null) {
      throw KnowledgeTransitionException(
        'Cannot ${action.name} an article in ${current.value}.',
      );
    }
    return valid;
  }
}

class KnowledgeActorContext {
  const KnowledgeActorContext({
    required this.userId,
    required this.name,
    required this.email,
  });

  final String userId;
  final String name;
  final String email;

  KnowledgeActor toKnowledgeActor() => KnowledgeActor(
        userId: userId,
        name: name,
        email: email,
      );
}

class KnowledgeTransitionResult {
  const KnowledgeTransitionResult({
    required this.article,
    required this.version,
  });

  final KnowledgeArticle article;
  final KnowledgeArticleVersion version;
}

class KnowledgeAccessDeniedException implements Exception {
  const KnowledgeAccessDeniedException(this.message);

  final String message;

  @override
  String toString() => 'KnowledgeAccessDeniedException($message)';
}

class KnowledgeTransitionException implements Exception {
  const KnowledgeTransitionException(this.message);

  final String message;

  @override
  String toString() => 'KnowledgeTransitionException($message)';
}
