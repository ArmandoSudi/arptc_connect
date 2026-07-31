import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/itsm/knowledge/application/knowledge_application.dart';
import 'package:arptc_connect/modules/itsm/knowledge/data/knowledge_data.dart';
import 'package:arptc_connect/modules/itsm/knowledge/domain/knowledge_domain.dart';
import 'package:arptc_connect/modules/itsm/shared/application/itsm_providers.dart';
import 'package:arptc_connect/modules/itsm/shared/application/itsm_session.dart';
import 'package:arptc_connect/modules/itsm/shared/data/trusted_command_gateways.dart';
import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/knowledge_layout.dart';
import '../widgets/knowledge_review_view.dart';
import 'knowledge_editor_screen.dart';

class KnowledgeManagerReviewScreen extends ConsumerStatefulWidget {
  const KnowledgeManagerReviewScreen({required this.articleId, super.key});

  final String articleId;

  @override
  ConsumerState<KnowledgeManagerReviewScreen> createState() =>
      _KnowledgeManagerReviewScreenState();
}

class _KnowledgeManagerReviewScreenState
    extends ConsumerState<KnowledgeManagerReviewScreen> {
  late final DateTime _asOf;

  @override
  void initState() {
    super.initState();
    _asOf = DateTime.now().toUtc();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final policy = ref.watch(knowledgeAccessPolicyProvider);
    if (policy.isLoading) {
      return _statePage(l10n.loading, loading: true);
    }
    if (!(policy.valueOrNull?.canManage ?? false)) {
      return _statePage(l10n.itsmAccessDeniedTitle, locked: true);
    }
    final articleRequest = KnowledgeArticleRequest(
      articleId: widget.articleId,
      asOf: _asOf,
    );
    final articleState = ref.watch(knowledgeArticleProvider(articleRequest));
    final actionState = ref.watch(
      knowledgeActionProvider('review:${widget.articleId}'),
    );
    return KnowledgePage(
      title: articleState.valueOrNull?.title ?? l10n.reviewPost,
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
          final versionRequest = KnowledgeVersionRequest(
            articleId: article.id,
            versionNumber: article.currentVersionNumber,
            asOf: _asOf,
          );
          final versionState = ref.watch(
            knowledgeVersionProvider(versionRequest),
          );
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
                : KnowledgeReviewView(
                    article: article,
                    version: version,
                    isExecuting: actionState.isLoading,
                    onEdit: () => _edit(article, version, versionRequest),
                    onAction: (action) => _transition(
                      article,
                      version,
                      versionRequest,
                      action,
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _statePage(
    String title, {
    bool loading = false,
    bool locked = false,
  }) {
    return KnowledgePage(
      title: S.of(context).itsmKnowledgeBase,
      onBack: () => Navigator.of(context).maybePop(),
      child: KnowledgeAsyncState(
        icon: locked ? Icons.lock_outline_rounded : Icons.hourglass_top_rounded,
        title: title,
        isLoading: loading,
      ),
    );
  }

  Future<void> _edit(
    KnowledgeArticle article,
    KnowledgeArticleVersion version,
    KnowledgeVersionRequest versionRequest,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => KnowledgeEditorScreen(
          article: article,
          version: version,
        ),
      ),
    );
    ref.invalidate(knowledgeVersionProvider(versionRequest));
  }

  Future<void> _transition(
    KnowledgeArticle article,
    KnowledgeArticleVersion version,
    KnowledgeVersionRequest versionRequest,
    KnowledgeTransitionAction action,
  ) async {
    final l10n = S.of(context);
    String reason = '';
    if (action == KnowledgeTransitionAction.rejectToDraft) {
      final result = await showDialog<String>(
        context: context,
        builder: (_) => const _RejectReasonDialog(),
      );
      if (result == null || result.trim().isEmpty) return;
      reason = result;
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.confirmation),
          content: Text(article.title),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.confirm),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    try {
      final session = await ref.read(itsmSessionProvider.future);
      if (session == null) return;
      final controller =
          await ref.read(knowledgeCommandControllerProvider.future);
      await ref
          .read(knowledgeActionProvider('review:${widget.articleId}').notifier)
          .run(
            () => controller.transition(
              command: KnowledgeLifecycleCommand(
                context: _context(session, action),
                article: article,
                version: version,
                action: action,
                reason: reason,
              ),
              at: DateTime.now().toUtc(),
            ),
          );
      ref.invalidate(knowledgeVersionProvider(versionRequest));
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

  ItsmCommandContext _context(
    ItsmSession session,
    KnowledgeTransitionAction action,
  ) {
    final now = DateTime.now().microsecondsSinceEpoch;
    return ItsmCommandContext(
      idempotencyKey: 'knowledge-${action.name}-${session.userId}-$now',
      correlationId: 'knowledge-${widget.articleId}-$now',
      actorUserId: session.userId,
      actorDisplayName: session.displayName,
      actorRole: session.role,
    );
  }
}

class _RejectReasonDialog extends StatefulWidget {
  const _RejectReasonDialog();

  @override
  State<_RejectReasonDialog> createState() => _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<_RejectReasonDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return AlertDialog(
      title: Text(l10n.rejectPost),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: CommonTextInput(
            label: l10n.rejectionComment,
            controller: _controller,
            isMultiline: true,
            autofocus: true,
            validator: (value) =>
                value == null || value.trim().isEmpty ? l10n.error : null,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.of(context).pop(_controller.text.trim());
            }
          },
          child: Text(l10n.confirm),
        ),
      ],
    );
  }
}
