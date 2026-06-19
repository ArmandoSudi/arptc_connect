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

class ManagerNewsScreen extends ConsumerWidget {
  const ManagerNewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(managerNewsPostsProvider);

    return Scaffold(
      body: ContentView(
        maxWidth: 1100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () {
                    context.pop();
                  },
                ),
                const Expanded(
                  child: PageHeader(
                    title: 'News Management',
                    description:
                        'Draft, submit, publish, and archive company information.',
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => context.go('/service/news/new'),
                  icon: const Icon(Icons.add),
                  label: const Text('New Post'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Expanded(
              child: postsAsync.when(
                data: (posts) => _ManagerPostList(posts: posts),
                loading: () => const LoadingStateView(
                  message: 'Loading your news posts...',
                ),
                error: (error, _) => ErrorStateView(
                  title: 'Unable to load news posts',
                  description: error.toString(),
                  onRetry: () => ref.invalidate(managerNewsPostsProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManagerPostList extends StatelessWidget {
  const _ManagerPostList({required this.posts});

  final List<NewsPost> posts;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return EmptyStateView(
        icon: Icons.article_outlined,
        title: 'No news post yet',
        description: 'Create a draft and submit it for review when ready.',
        actionLabel: 'Create post',
        onAction: () => context.go('/service/news/new'),
      );
    }

    return ListView.separated(
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return NewsPostCard(
          post: post,
          onTap: () => context.go('/service/news/edit/${post.id}'),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
    );
  }
}
