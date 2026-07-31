import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/itsm/knowledge/domain/knowledge_domain.dart';
import 'package:flutter/material.dart';

class IncidentResolutionKnowledgeSelector extends StatelessWidget {
  const IncidentResolutionKnowledgeSelector({
    required this.articles,
    required this.selectedArticleIds,
    required this.onSelectionChanged,
    this.isLoading = false,
    this.errorMessage,
    this.enabled = true,
    super.key,
  });

  final List<KnowledgeArticle> articles;
  final Set<String> selectedArticleIds;
  final ValueChanged<Set<String>> onSelectionChanged;
  final bool isLoading;
  final String? errorMessage;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.suggestedKnowledge,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.suggestedKnowledgeDescription,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        if (isLoading)
          const LinearProgressIndicator()
        else if (errorMessage != null)
          Text(
            l10n.unableToLoadKnowledge,
            style: TextStyle(color: theme.colorScheme.error),
          )
        else if (articles.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final article in articles)
                FilterChip(
                  avatar: const Icon(Icons.menu_book_outlined, size: 18),
                  label: Text(article.title),
                  selected: selectedArticleIds.contains(article.id),
                  onSelected: enabled
                      ? (selected) {
                          final next = Set<String>.of(selectedArticleIds);
                          selected
                              ? next.add(article.id)
                              : next.remove(article.id);
                          onSelectionChanged(next);
                        }
                      : null,
                ),
            ],
          ),
      ],
    );
  }
}
