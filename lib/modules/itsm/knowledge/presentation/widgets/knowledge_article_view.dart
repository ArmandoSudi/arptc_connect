import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/itsm/knowledge/domain/knowledge_domain.dart';
import 'package:flutter/material.dart';

import 'knowledge_layout.dart';

class KnowledgeArticleView extends StatelessWidget {
  const KnowledgeArticleView({
    required this.article,
    required this.version,
    super.key,
    this.categoryName = '',
    this.onHelpful,
    this.onNotHelpful,
    this.feedbackPending = false,
  });

  final KnowledgeArticle article;
  final KnowledgeArticleVersion version;
  final String categoryName;
  final VoidCallback? onHelpful;
  final VoidCallback? onNotHelpful;
  final bool feedbackPending;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (categoryName.isNotEmpty) Chip(label: Text(categoryName)),
            Chip(label: Text(version.languageCode.toUpperCase())),
            Chip(
              label: Text('${l10n.articleVersion} ${version.versionNumber}'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        KnowledgePanel(
          child: SelectableText(
            version.content,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.65),
          ),
        ),
        const SizedBox(height: 16),
        KnowledgeResponsiveGrid(
          maximumColumns: 2,
          children: [
            KnowledgePanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.createdBy, style: theme.textTheme.labelMedium),
                  const SizedBox(height: 4),
                  Text(
                    article.author.name,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (article.reviewer != null) ...[
                    const SizedBox(height: 14),
                    Text(l10n.reviewer, style: theme.textTheme.labelMedium),
                    const SizedBox(height: 4),
                    Text(article.reviewer!.name),
                  ],
                ],
              ),
            ),
            KnowledgePanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.wasThisHelpful,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: feedbackPending ? null : onHelpful,
                          icon: const Icon(Icons.thumb_up_alt_outlined),
                          label: Text(
                            '${l10n.helpful} (${article.helpfulCount})',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: feedbackPending ? null : onNotHelpful,
                          icon: const Icon(Icons.thumb_down_alt_outlined),
                          label: Text(
                            '${l10n.notHelpful} '
                            '(${article.notHelpfulCount})',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
