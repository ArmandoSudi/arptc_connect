import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/itsm/knowledge/domain/knowledge_domain.dart';
import 'package:arptc_connect/modules/itsm/support/presentation/widgets/support_widgets.dart';
import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:flutter/material.dart';

import 'knowledge_article_card.dart';

class KnowledgeBaseView extends StatelessWidget {
  const KnowledgeBaseView({
    required this.articles,
    required this.categories,
    required this.selectedCategoryId,
    required this.searchController,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onArticlePressed,
    required this.onRetry,
    required this.onLoadMore,
    super.key,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.error,
  });

  final List<KnowledgeArticle> articles;
  final List<KnowledgeCategory> categories;
  final String selectedCategoryId;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<KnowledgeArticle> onArticlePressed;
  final VoidCallback onRetry;
  final VoidCallback onLoadMore;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SupportPanel(
          child: SupportFilterBar(
            searchLabel: l10n.search,
            searchHint: l10n.knowledgeSearchHint,
            searchController: searchController,
            onSearchChanged: onSearchChanged,
            filters: [
              SupportDropdownFilter(
                label: l10n.category,
                value: selectedCategoryId,
                options: [
                  SupportFilterOption(
                    value: '',
                    label: l10n.allCatalogueCategories,
                  ),
                  for (final category in categories)
                    SupportFilterOption(
                      value: category.id,
                      label: category.localizedName(languageCode),
                    ),
                ],
                onChanged: onCategoryChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (isLoading)
          LoadingStateView(message: l10n.loadingKnowledge)
        else if (error != null)
          ErrorStateView(
            title: l10n.unableToLoadKnowledge,
            description: error.toString(),
            onRetry: onRetry,
          )
        else if (articles.isEmpty)
          EmptyStateView(
            icon: Icons.menu_book_outlined,
            title: l10n.noKnowledgeArticles,
            description: l10n.noKnowledgeArticlesDescription,
          )
        else ...[
          SupportResponsiveGrid(
            minimumItemWidth: 300,
            maximumColumns: 3,
            children: [
              for (final article in articles)
                SizedBox(
                  height: 272,
                  child: KnowledgeArticleCard(
                    article: article,
                    categoryName: _categoryName(
                      categories,
                      article.categoryId,
                      languageCode,
                    ),
                    onPressed: () => onArticlePressed(article),
                  ),
                ),
            ],
          ),
          if (hasMore) ...[
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.center,
              child: OutlinedButton.icon(
                onPressed: isLoadingMore ? null : onLoadMore,
                icon: isLoadingMore
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.expand_more_rounded),
                label: Text(
                  isLoadingMore ? l10n.loadingMore : l10n.loadMore,
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

String _categoryName(
  List<KnowledgeCategory> categories,
  String categoryId,
  String languageCode,
) {
  for (final category in categories) {
    if (category.id == categoryId) {
      return category.localizedName(languageCode);
    }
  }
  return '';
}
