import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/itsm/knowledge/application/knowledge_application.dart';
import 'package:arptc_connect/modules/itsm/knowledge/data/knowledge_data.dart';
import 'package:arptc_connect/modules/itsm/knowledge/domain/knowledge_domain.dart';
import 'package:arptc_connect/modules/itsm/shared/application/itsm_providers.dart';
import 'package:arptc_connect/modules/itsm/shared/application/itsm_session.dart';
import 'package:arptc_connect/modules/itsm/shared/data/trusted_command_gateways.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/knowledge_article_view.dart';
import '../widgets/knowledge_layout.dart';

class KnowledgeArticleScreen extends ConsumerStatefulWidget {
  const KnowledgeArticleScreen({required this.articleId, super.key});

  final String articleId;

  @override
  ConsumerState<KnowledgeArticleScreen> createState() =>
      _KnowledgeArticleScreenState();
}

class _KnowledgeArticleScreenState
    extends ConsumerState<KnowledgeArticleScreen> {
  late final DateTime _asOf;
  bool _viewRecorded = false;

  @override
  void initState() {
    super.initState();
    _asOf = DateTime.now().toUtc();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final articleRequest = KnowledgeArticleRequest(
      articleId: widget.articleId,
      asOf: _asOf,
    );
    final articleState = ref.watch(knowledgeArticleProvider(articleRequest));
    final actionState = ref.watch(
      knowledgeActionProvider('article:${widget.articleId}'),
    );
    return KnowledgePage(
      title: articleState.valueOrNull?.title ?? l10n.article,
      onBack: () => Navigator.of(context).maybePop(),
      child: articleState.when(
        loading: () => KnowledgeAsyncState(
          icon: Icons.hourglass_top_rounded,
          title: l10n.loading,
          isLoading: true,
        ),
        error: (error, stackTrace) => KnowledgeAsyncState(
          icon: Icons.error_outline_rounded,
          title: l10n.unableToLoad,
          error: error,
          onRetry: () => ref.invalidate(
            knowledgeArticleProvider(articleRequest),
          ),
        ),
        data: (article) {
          if (article == null) {
            return KnowledgeAsyncState(
              icon: Icons.menu_book_outlined,
              title: l10n.noDataAvailable,
            );
          }
          final policy = ref.watch(knowledgeAccessPolicyProvider).valueOrNull;
          final versionNumber = policy?.canManage ?? false
              ? article.currentVersionNumber
              : article.publishedVersionNumber;
          if (versionNumber == null) {
            return KnowledgeAsyncState(
              icon: Icons.menu_book_outlined,
              title: l10n.noDataAvailable,
            );
          }
          final versionRequest = KnowledgeVersionRequest(
            articleId: article.id,
            versionNumber: versionNumber,
            asOf: _asOf,
          );
          final versionState = ref.watch(
            knowledgeVersionProvider(versionRequest),
          );
          if (article.isPublished && !_viewRecorded) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_viewRecorded) {
                _viewRecorded = true;
                _recordView(article);
              }
            });
          }
          return versionState.when(
            loading: () => KnowledgeAsyncState(
              icon: Icons.hourglass_top_rounded,
              title: l10n.loading,
              isLoading: true,
            ),
            error: (error, stackTrace) => KnowledgeAsyncState(
              icon: Icons.error_outline_rounded,
              title: l10n.unableToLoad,
              error: error,
              onRetry: () => ref.invalidate(
                knowledgeVersionProvider(versionRequest),
              ),
            ),
            data: (version) => version == null
                ? KnowledgeAsyncState(
                    icon: Icons.menu_book_outlined,
                    title: l10n.noDataAvailable,
                  )
                : KnowledgeArticleView(
                    article: article,
                    version: version,
                    feedbackPending: actionState.isLoading,
                    onHelpful: article.isPublished
                        ? () => _submitFeedback(article, true)
                        : null,
                    onNotHelpful: article.isPublished
                        ? () => _submitFeedback(article, false)
                        : null,
                  ),
          );
        },
      ),
    );
  }

  Future<void> _recordView(KnowledgeArticle article) async {
    try {
      final session = await ref.read(itsmSessionProvider.future);
      if (session == null || !mounted) return;
      final controller =
          await ref.read(knowledgeCommandControllerProvider.future);
      await controller.recordView(
        KnowledgeViewCommand(
          context: _context(session, 'view'),
          article: article,
        ),
        at: _asOf,
      );
    } catch (_) {
      // View analytics must never interrupt article reading.
    }
  }

  Future<void> _submitFeedback(
    KnowledgeArticle article,
    bool helpful,
  ) async {
    final l10n = S.of(context);
    try {
      final session = await ref.read(itsmSessionProvider.future);
      if (session == null) return;
      final controller =
          await ref.read(knowledgeCommandControllerProvider.future);
      await ref
          .read(knowledgeActionProvider('article:${widget.articleId}').notifier)
          .run(
            () => controller.submitFeedback(
              KnowledgeFeedbackCommand(
                context: _context(session, helpful ? 'helpful' : 'unhelpful'),
                article: article,
                helpful: helpful,
              ),
              at: DateTime.now().toUtc(),
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.confirmation)),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $error')),
        );
      }
    }
  }

  ItsmCommandContext _context(ItsmSession session, String operation) {
    final now = DateTime.now().microsecondsSinceEpoch;
    return ItsmCommandContext(
      idempotencyKey: 'knowledge-$operation-${session.userId}-$now',
      correlationId: 'knowledge-${widget.articleId}-$now',
      actorUserId: session.userId,
      actorDisplayName: session.displayName,
      actorRole: session.role,
    );
  }
}
