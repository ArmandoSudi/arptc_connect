import '../../shared/application/itsm_command_executor.dart';
import '../../shared/application/itsm_session.dart';
import '../../shared/data/trusted_command_gateways.dart';
import '../data/knowledge_command_gateway.dart';
import '../domain/knowledge_domain.dart';

class KnowledgeCommandController {
  KnowledgeCommandController({
    required ItsmSession session,
    required KnowledgeCommandGateway gateway,
    required KnowledgeLifecycleService lifecycleService,
    ItsmCommandExecutor? executor,
  })  : _session = session,
        _policy = KnowledgeAccessPolicy(session.role),
        _gateway = gateway,
        _lifecycleService = lifecycleService,
        _executor = executor ?? ItsmCommandExecutor();

  final ItsmSession _session;
  final KnowledgeAccessPolicy _policy;
  final KnowledgeCommandGateway _gateway;
  final KnowledgeLifecycleService _lifecycleService;
  final ItsmCommandExecutor _executor;

  Future<KnowledgeCommandReceipt> recordView(
    KnowledgeViewCommand command, {
    required DateTime at,
  }) {
    _validateContext(command.context);
    _requirePublishedRead(command.article, at: at);
    return _execute(command.context, () => _gateway.recordView(command));
  }

  Future<KnowledgeCommandReceipt> submitFeedback(
    KnowledgeFeedbackCommand command, {
    required DateTime at,
  }) {
    _validateContext(command.context);
    _requirePublishedRead(command.article, at: at);
    return _execute(
      command.context,
      () => _gateway.submitFeedback(command),
    );
  }

  Future<KnowledgeCommandReceipt> saveDraft({
    required SaveKnowledgeDraftCommand command,
    KnowledgeArticle? article,
    KnowledgeArticleVersion? version,
  }) {
    _validateContext(command.context);
    _policy.requireManager('save');
    _validateDraftTarget(command, article: article, version: version);
    return _execute(command.context, () => _gateway.saveDraft(command));
  }

  Future<KnowledgeCommandReceipt> transition({
    required KnowledgeLifecycleCommand command,
    required DateTime at,
  }) {
    _validateContext(command.context);
    _lifecycleService.transition(
      policy: _policy,
      article: command.article,
      version: command.version,
      action: command.action,
      actor: KnowledgeActorContext(
        userId: _session.userId,
        name: _session.displayName,
        email: _session.email,
      ),
      at: at,
      reviewComment: command.reason,
    );
    return _execute(command.context, () => _gateway.transition(command));
  }

  bool isExecuting(String idempotencyKey) {
    return _executor.isExecuting(idempotencyKey);
  }

  void _requirePublishedRead(
    KnowledgeArticle article, {
    required DateTime at,
  }) {
    if (!article.isPublished || !_policy.canReadArticle(article, at: at)) {
      throw const KnowledgeAccessDeniedException(
        'Only a visible published article can record reader activity.',
      );
    }
  }

  void _validateDraftTarget(
    SaveKnowledgeDraftCommand command, {
    required KnowledgeArticle? article,
    required KnowledgeArticleVersion? version,
  }) {
    if (command.createsArticle) {
      if (article != null || version != null) {
        throw const KnowledgeDraftValidationException(
          'A new article cannot reference an existing version.',
        );
      }
      return;
    }
    if (article == null || version == null) {
      throw const KnowledgeDraftValidationException(
        'An existing draft requires its article and current version.',
      );
    }
    if (command.articleId.trim() != article.id ||
        article.id != version.articleId ||
        article.currentVersionNumber != version.versionNumber ||
        command.expectedState != article.state ||
        command.expectedVersionNumber != version.versionNumber) {
      throw const KnowledgeDraftValidationException(
        'The draft command does not match the current article revision.',
      );
    }
    switch (article.state) {
      case KnowledgeArticleState.draft:
        if (version.state != KnowledgeArticleState.draft ||
            version.isImmutable) {
          throw const KnowledgeDraftValidationException(
            'The selected draft version is immutable.',
          );
        }
      case KnowledgeArticleState.published:
      case KnowledgeArticleState.retired:
        if (!version.isImmutable) {
          throw const KnowledgeDraftValidationException(
            'A published revision must start from an immutable version.',
          );
        }
      case KnowledgeArticleState.review:
        throw const KnowledgeDraftValidationException(
          'An article under review must be rejected before editing.',
        );
      case KnowledgeArticleState.archived:
        throw const KnowledgeDraftValidationException(
          'An archived article cannot be edited.',
        );
    }
  }

  void _validateContext(ItsmCommandContext context) {
    if (context.actorUserId != _session.userId ||
        context.actorRole != _session.role) {
      throw const KnowledgeAccessDeniedException(
        'The command actor does not match the active ITSM session.',
      );
    }
  }

  Future<KnowledgeCommandReceipt> _execute(
    ItsmCommandContext context,
    Future<KnowledgeCommandReceipt> Function() execute,
  ) async {
    final receipt = await _executor.executeOnce(context, execute);
    if (receipt is! KnowledgeCommandReceipt) {
      throw const KnowledgeGatewayException(
        'The Knowledge gateway returned an invalid receipt.',
      );
    }
    return receipt;
  }
}

class KnowledgeDraftValidationException implements Exception {
  const KnowledgeDraftValidationException(this.message);

  final String message;

  @override
  String toString() => 'KnowledgeDraftValidationException($message)';
}
