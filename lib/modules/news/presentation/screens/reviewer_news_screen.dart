import 'package:arptc_connect/modules/news/domain/news_post.dart';
import 'package:arptc_connect/modules/news/presentation/controllers/news_providers.dart';
import 'package:arptc_connect/modules/news/presentation/widgets/news_post_card.dart';
import 'package:arptc_connect/widgets/content_view.dart';
import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:arptc_connect/widgets/page_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ReviewerNewsScreen extends ConsumerWidget {
  const ReviewerNewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(pendingReviewNewsPostsProvider);

    return Scaffold(
      body: ContentView(
        maxWidth: 1100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(
              title: 'News Review',
              description:
                  'Validate or reject posts submitted for publication.',
            ),
            const SizedBox(height: 18),
            Expanded(
              child: postsAsync.when(
                data: (posts) => _PendingPostList(posts: posts),
                loading: () => const LoadingStateView(
                  message: 'Loading pending reviews...',
                ),
                error: (error, _) => ErrorStateView(
                  title: 'Unable to load pending reviews',
                  description: error.toString(),
                  onRetry: () => ref.invalidate(pendingReviewNewsPostsProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingPostList extends StatelessWidget {
  const _PendingPostList({required this.posts});

  final List<NewsPost> posts;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const EmptyStateView(
        icon: Icons.fact_check_outlined,
        title: 'No post pending review',
        description: 'Submitted posts will appear here.',
      );
    }

    return ListView.separated(
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return NewsPostCard(
          post: post,
          onTap: () => context.go('/service/news/review/${post.id}'),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
    );
  }
}
