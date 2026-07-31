import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/itsm/knowledge/application/knowledge_providers.dart';
import 'package:arptc_connect/modules/itsm/knowledge/data/knowledge_repository.dart';
import 'package:arptc_connect/modules/itsm/knowledge/domain/knowledge_domain.dart';
import 'package:arptc_connect/modules/itsm/presentation/navigation/itsm_navigation.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/pagination.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class IncidentKnowledgeSuggestions extends ConsumerWidget {
  const IncidentKnowledgeSuggestions({
    required this.suggestionContext,
    super.key,
  });

  final KnowledgeSuggestionContext suggestionContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = KnowledgeSuggestionPageRequest(
      query: KnowledgeSuggestionQuery(
        context: suggestionContext,
      ),
      page: PageRequest(limit: 3),
    );
    final state = ref.watch(knowledgeSuggestionPageProvider(request));

    return state.when(
      loading: () => const IncidentKnowledgeSuggestionsView(isLoading: true),
      error: (error, _) => IncidentKnowledgeSuggestionsView(
        errorMessage: error.toString(),
        onRetry: () => ref.invalidate(
          knowledgeSuggestionPageProvider(request),
        ),
      ),
      data: (page) => IncidentKnowledgeSuggestionsView(
        articles: page.items,
        onArticlePressed: (article) => context.push(
          '${ItsmRoutes.knowledge}/${article.id}',
        ),
      ),
    );
  }
}

class IncidentKnowledgeSuggestionsView extends StatelessWidget {
  const IncidentKnowledgeSuggestionsView({
    this.articles = const [],
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.onArticlePressed,
    super.key,
  });

  final List<KnowledgeArticle> articles;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final ValueChanged<KnowledgeArticle>? onArticlePressed;

  @override
  Widget build(BuildContext context) {
    if (!isLoading && errorMessage == null && articles.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = S.of(context);
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.secondaryContainer.withOpacity(0.42),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.suggestedKnowledge,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.suggestedKnowledgeDescription,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (isLoading) ...[
              const SizedBox(height: 14),
              const LinearProgressIndicator(),
            ] else if (errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                l10n.unableToLoadKnowledge,
                style: TextStyle(color: theme.colorScheme.error),
              ),
              if (onRetry != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(l10n.retry),
                  ),
                ),
            ] else ...[
              const SizedBox(height: 10),
              for (final article in articles)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.menu_book_outlined),
                  title: Text(article.title),
                  subtitle: Text(
                    article.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Tooltip(
                    message: l10n.viewArticle,
                    child: const Icon(Icons.arrow_forward_rounded),
                  ),
                  onTap: onArticlePressed == null
                      ? null
                      : () => onArticlePressed!(article),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
