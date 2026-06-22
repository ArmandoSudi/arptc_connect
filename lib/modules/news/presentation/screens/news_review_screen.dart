import 'package:arptc_connect/modules/news/data/firestore_news_repository.dart';
import 'package:arptc_connect/modules/news/domain/news_enums.dart';
import 'package:arptc_connect/modules/news/presentation/controllers/news_providers.dart';
import 'package:arptc_connect/modules/news/presentation/widgets/news_status_badge.dart';
import 'package:arptc_connect/widgets/content_view.dart';
import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:arptc_connect/widgets/page_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class NewsReviewScreen extends ConsumerStatefulWidget {
  const NewsReviewScreen({
    required this.postId,
    super.key,
  });

  final String postId;

  @override
  ConsumerState<NewsReviewScreen> createState() => _NewsReviewScreenState();
}

class _NewsReviewScreenState extends ConsumerState<NewsReviewScreen> {
  final _commentController = TextEditingController();
  bool _isAccepting = false;
  bool _isRejecting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(newsPostProvider(widget.postId));

    return Scaffold(
      body: ContentView(
        maxWidth: 980,
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
            final canReview =
                NewsPostStatus.fromValue(post.status) == NewsPostStatus.pending;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios),
                      onPressed: () => context.go('/service/news'),
                    ),
                    Expanded(
                      child: PageHeader(
                        title: post.title.isEmpty ? 'Review Post' : post.title,
                        description: [
                          if (post.authorName.isNotEmpty)
                            'Author: ${post.authorName}',
                          if (post.submittedAt != null)
                            'Submitted: ${DateFormat('dd MMM yyyy HH:mm').format(post.submittedAt!.toLocal())}',
                        ].join(' • '),
                      ),
                    ),
                    NewsStatusBadge(status: post.status),
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
                if (imageUrl.isNotEmpty) const SizedBox(height: 18),
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
                const SizedBox(height: 18),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Review decision',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        CommonTextInput(
                          label: 'Reject comment',
                          hintText: 'Required only when rejecting the post...',
                          type: CommonTextInputType.text,
                          isMultiline: true,
                          controller: _commentController,
                          minLines: 3,
                          maxLines: 6,
                          enabled: canReview,
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          alignment: WrapAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              onPressed: !canReview || _isRejecting
                                  ? null
                                  : () => _rejectPost(post.id),
                              icon: const Icon(Icons.close_outlined),
                              label: Text(
                                  _isRejecting ? 'Rejecting...' : 'Reject'),
                            ),
                            FilledButton.icon(
                              onPressed: !canReview || _isAccepting
                                  ? null
                                  : () => _acceptPost(post.id),
                              icon: const Icon(Icons.check_outlined),
                              label: Text(
                                  _isAccepting ? 'Accepting...' : 'Accept'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const LoadingStateView(message: 'Loading review...'),
          error: (error, _) => ErrorStateView(
            title: 'Unable to load review',
            description: error.toString(),
            onRetry: () => ref.invalidate(newsPostProvider(widget.postId)),
          ),
        ),
      ),
    );
  }

  Future<void> _acceptPost(String postId) async {
    final actor = ref.read(currentNewsActorProvider).valueOrNull;
    if (actor == null || actor.isEmpty) {
      return;
    }
    setState(() => _isAccepting = true);
    try {
      await ref.read(newsRepositoryProvider).acceptPost(postId, actor);
      ref.invalidate(pendingReviewNewsPostsProvider);
      ref.invalidate(managerNewsPostsProvider);
      if (mounted) {
        context.go('/service/news');
      }
    } finally {
      if (mounted) {
        setState(() => _isAccepting = false);
      }
    }
  }

  Future<void> _rejectPost(String postId) async {
    final actor = ref.read(currentNewsActorProvider).valueOrNull;
    final comment = _commentController.text.trim();
    if (actor == null || actor.isEmpty || comment.isEmpty) {
      return;
    }
    setState(() => _isRejecting = true);
    try {
      await ref.read(newsRepositoryProvider).rejectPost(
            postId: postId,
            comment: comment,
            actor: actor,
          );
      ref.invalidate(pendingReviewNewsPostsProvider);
      ref.invalidate(managerNewsPostsProvider);
      if (mounted) {
        context.go('/service/news');
      }
    } finally {
      if (mounted) {
        setState(() => _isRejecting = false);
      }
    }
  }
}
