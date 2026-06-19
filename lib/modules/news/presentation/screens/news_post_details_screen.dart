import 'package:arptc_connect/modules/news/presentation/controllers/news_providers.dart';
import 'package:arptc_connect/modules/news/presentation/widgets/news_status_badge.dart';
import 'package:arptc_connect/widgets/content_view.dart';
import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:arptc_connect/widgets/page_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class NewsPostDetailsScreen extends ConsumerWidget {
  const NewsPostDetailsScreen({
    required this.postId,
    this.showStatus = false,
    super.key,
  });

  final String postId;
  final bool showStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postAsync = ref.watch(newsPostProvider(postId));

    return Scaffold(
      body: ContentView(
        maxWidth: 900,
        scrollable: true,
        child: postAsync.when(
          data: (post) {
            if (post == null) {
              return const EmptyStateView(
                icon: Icons.article_outlined,
                title: 'News post not found',
              );
            }

            final imageUrl = post.imageUrl.trim();
            final publishedDate = post.publishedAt ?? post.updatedAt;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios),
                      onPressed: () => context.pop(),
                    ),
                    Expanded(
                      child: PageHeader(
                        title: post.title.isEmpty ? 'Company News' : post.title,
                        description: [
                          if (post.authorName.isNotEmpty) post.authorName,
                          if (publishedDate != null)
                            DateFormat('dd MMM yyyy HH:mm')
                                .format(publishedDate.toLocal()),
                        ].join(' • '),
                      ),
                    ),
                    if (showStatus) NewsStatusBadge(status: post.status),
                  ],
                ),
                const SizedBox(height: 18),
                if (imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 220,
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                if (imageUrl.isNotEmpty) const SizedBox(height: 20),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: SelectableText(
                      post.content,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.55,
                          ),
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () =>
              const LoadingStateView(message: 'Loading news post...'),
          error: (error, _) => ErrorStateView(
            title: 'Unable to load news post',
            description: error.toString(),
            onRetry: () => ref.invalidate(newsPostProvider(postId)),
          ),
        ),
      ),
    );
  }
}
