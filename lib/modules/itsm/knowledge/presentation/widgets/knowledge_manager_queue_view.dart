import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/itsm/knowledge/domain/knowledge_domain.dart';
import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:flutter/material.dart';

import 'knowledge_article_card.dart';
import 'knowledge_layout.dart';

class KnowledgeManagerQueueView extends StatelessWidget {
  const KnowledgeManagerQueueView({
    required this.articles,
    required this.categories,
    required this.queue,
    required this.searchController,
    required this.onQueueChanged,
    required this.onSearchChanged,
    required this.onArticlePressed,
    required this.onCreatePressed,
    required this.onRetry,
    super.key,
    this.isLoading = false,
    this.error,
  });

  final List<KnowledgeArticle> articles;
  final List<KnowledgeCategory> categories;
  final KnowledgeManagerQueue queue;
  final TextEditingController searchController;
  final ValueChanged<KnowledgeManagerQueue?> onQueueChanged;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<KnowledgeArticle> onArticlePressed;
  final VoidCallback onCreatePressed;
  final VoidCallback onRetry;
  final bool isLoading;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: onCreatePressed,
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.create),
          ),
        ),
        const SizedBox(height: 16),
        KnowledgePanel(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 620;
              final search = CommonTextInput(
                label: l10n.search,
                controller: searchController,
                prefixIcon: const Icon(Icons.search_rounded),
                onChanged: onSearchChanged,
              );
              final filter = DropdownButtonFormField<KnowledgeManagerQueue>(
                value: queue,
                decoration: InputDecoration(labelText: l10n.status),
                items: [
                  for (final option in KnowledgeManagerQueue.values)
                    DropdownMenuItem(
                      value: option,
                      child: Text(_queueLabel(l10n, option)),
                    ),
                ],
                onChanged: onQueueChanged,
              );
              if (compact) {
                return Column(
                  children: [
                    search,
                    const SizedBox(height: 14),
                    filter,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(flex: 2, child: search),
                  const SizedBox(width: 16),
                  Expanded(child: filter),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        if (isLoading)
          KnowledgeAsyncState(
            icon: Icons.hourglass_top_rounded,
            title: l10n.loading,
            isLoading: true,
          )
        else if (error != null)
          KnowledgeAsyncState(
            icon: Icons.error_outline_rounded,
            title: l10n.unableToLoad,
            error: error,
            onRetry: onRetry,
          )
        else if (articles.isEmpty)
          KnowledgeAsyncState(
            icon: Icons.inbox_outlined,
            title: l10n.noDataAvailable,
          )
        else
          KnowledgeResponsiveGrid(
            children: [
              for (final article in articles)
                KnowledgeArticleCard(
                  article: article,
                  categoryName: _categoryName(
                    categories,
                    article.categoryId,
                    languageCode,
                  ),
                  showState: true,
                  onPressed: () => onArticlePressed(article),
                ),
            ],
          ),
      ],
    );
  }
}

String _queueLabel(S l10n, KnowledgeManagerQueue queue) {
  return switch (queue) {
    KnowledgeManagerQueue.all => l10n.all,
    KnowledgeManagerQueue.authoredByMe => l10n.createdBy,
    KnowledgeManagerQueue.awaitingReview => l10n.reviewPost,
    KnowledgeManagerQueue.drafts => l10n.draft,
    KnowledgeManagerQueue.published => l10n.published,
    KnowledgeManagerQueue.retired => l10n.inactive,
    KnowledgeManagerQueue.archived => l10n.archived,
  };
}

String _categoryName(
  List<KnowledgeCategory> categories,
  String id,
  String languageCode,
) {
  for (final category in categories) {
    if (category.id == id) return category.localizedName(languageCode);
  }
  return '';
}
