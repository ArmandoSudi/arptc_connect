import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/itsm/knowledge/domain/knowledge_domain.dart';
import 'package:flutter/material.dart';

class KnowledgeStateBadge extends StatelessWidget {
  const KnowledgeStateBadge({required this.state, super.key});

  final KnowledgeArticleState state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = switch (state) {
      KnowledgeArticleState.draft => colors.secondary,
      KnowledgeArticleState.review => colors.tertiary,
      KnowledgeArticleState.published => colors.primary,
      KnowledgeArticleState.retired => colors.outline,
      KnowledgeArticleState.archived => colors.error,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        child: Text(
          knowledgeStateLabel(S.of(context), state),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}

String knowledgeStateLabel(S l10n, KnowledgeArticleState state) {
  return switch (state) {
    KnowledgeArticleState.draft => l10n.draft,
    KnowledgeArticleState.review => l10n.pending,
    KnowledgeArticleState.published => l10n.published,
    KnowledgeArticleState.retired => l10n.inactive,
    KnowledgeArticleState.archived => l10n.archived,
  };
}
