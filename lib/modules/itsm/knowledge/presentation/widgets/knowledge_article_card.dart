import 'package:arptc_connect/modules/itsm/knowledge/domain/knowledge_domain.dart';
import 'package:flutter/material.dart';

import 'knowledge_layout.dart';
import 'knowledge_state_badge.dart';

class KnowledgeArticleCard extends StatelessWidget {
  const KnowledgeArticleCard({
    required this.article,
    required this.onPressed,
    super.key,
    this.categoryName = '',
    this.showState = false,
  });

  final KnowledgeArticle article;
  final String categoryName;
  final bool showState;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return KnowledgePanel(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  const Spacer(),
                  if (article.isFeatured && !showState)
                    Icon(
                      Icons.star_rounded,
                      color: theme.colorScheme.tertiary,
                    ),
                  if (showState) KnowledgeStateBadge(state: article.state),
                ],
              ),
              const SizedBox(height: 16),
              if (categoryName.isNotEmpty) ...[
                Text(
                  categoryName.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Text(
                article.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                article.summary,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Icon(Icons.person_outline_rounded, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      article.author.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium,
                    ),
                  ),
                  Text(
                    MaterialLocalizations.of(context)
                        .formatMediumDate(article.updatedAt.toLocal()),
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
