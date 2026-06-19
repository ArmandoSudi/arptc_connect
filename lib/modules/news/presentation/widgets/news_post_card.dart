import 'package:arptc_connect/modules/news/domain/news_post.dart';
import 'package:arptc_connect/modules/news/presentation/widgets/news_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NewsPostCard extends StatelessWidget {
  const NewsPostCard({
    required this.post,
    required this.onTap,
    this.showStatus = true,
    super.key,
  });

  final NewsPost post;
  final VoidCallback onTap;
  final bool showStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl = post.imageUrl.trim();
    final date = post.publishedAt ?? post.updatedAt ?? post.createdAt;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (imageUrl.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 7,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          post.title.isEmpty ? 'Untitled news' : post.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (showStatus) ...[
                        const SizedBox(width: 8),
                        NewsStatusBadge(status: post.status),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    children: [
                      _MetaItem(
                        icon: Icons.person_outline,
                        label: post.authorName,
                      ),
                      if (date != null)
                        _MetaItem(
                          icon: Icons.schedule,
                          label: DateFormat('dd MMM yyyy HH:mm')
                              .format(date.toLocal()),
                        ),
                    ],
                  ),
                  if (post.reviewComment.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.errorContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Reviewer comment: ${post.reviewComment}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (label.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
