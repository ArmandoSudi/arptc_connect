import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/itsm/knowledge/domain/knowledge_domain.dart';
import 'package:flutter/material.dart';

import 'knowledge_article_view.dart';
import 'knowledge_state_badge.dart';

class KnowledgeReviewView extends StatelessWidget {
  const KnowledgeReviewView({
    required this.article,
    required this.version,
    required this.onEdit,
    required this.onAction,
    super.key,
    this.isExecuting = false,
  });

  final KnowledgeArticle article;
  final KnowledgeArticleVersion version;
  final VoidCallback onEdit;
  final ValueChanged<KnowledgeTransitionAction> onAction;
  final bool isExecuting;

  @override
  Widget build(BuildContext context) {
    final actions = _actions(article.state);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            KnowledgeStateBadge(state: article.state),
            const Spacer(),
            if (_canEdit(article.state))
              OutlinedButton.icon(
                onPressed: isExecuting ? null : onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: Text(S.of(context).edit),
              ),
          ],
        ),
        const SizedBox(height: 18),
        KnowledgeArticleView(article: article, version: version),
        if (article.reviewComment.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.comment_outlined),
              title: Text(S.of(context).rejectionComment),
              subtitle: Text(article.reviewComment),
            ),
          ),
        ],
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final action in actions)
                FilledButton.icon(
                  onPressed: isExecuting ? null : () => onAction(action),
                  icon: Icon(_icon(action)),
                  label: Text(_label(S.of(context), action)),
                ),
            ],
          ),
        ],
      ],
    );
  }

  bool _canEdit(KnowledgeArticleState state) =>
      state == KnowledgeArticleState.draft ||
      state == KnowledgeArticleState.published ||
      state == KnowledgeArticleState.retired;

  List<KnowledgeTransitionAction> _actions(KnowledgeArticleState state) {
    return switch (state) {
      KnowledgeArticleState.draft => const [
          KnowledgeTransitionAction.submitForReview,
        ],
      KnowledgeArticleState.review => const [
          KnowledgeTransitionAction.rejectToDraft,
          KnowledgeTransitionAction.publish,
        ],
      KnowledgeArticleState.published => const [
          KnowledgeTransitionAction.retire,
        ],
      KnowledgeArticleState.retired => const [
          KnowledgeTransitionAction.archive,
        ],
      KnowledgeArticleState.archived => const [],
    };
  }

  String _label(S l10n, KnowledgeTransitionAction action) => switch (action) {
        KnowledgeTransitionAction.submitForReview => l10n.submitForReview,
        KnowledgeTransitionAction.rejectToDraft => l10n.rejectPost,
        KnowledgeTransitionAction.publish => l10n.publishPost,
        KnowledgeTransitionAction.retire => l10n.close,
        KnowledgeTransitionAction.archive => l10n.archive,
      };

  IconData _icon(KnowledgeTransitionAction action) => switch (action) {
        KnowledgeTransitionAction.submitForReview => Icons.send_outlined,
        KnowledgeTransitionAction.rejectToDraft => Icons.undo_rounded,
        KnowledgeTransitionAction.publish => Icons.publish_outlined,
        KnowledgeTransitionAction.retire => Icons.unpublished_outlined,
        KnowledgeTransitionAction.archive => Icons.archive_outlined,
      };
}
