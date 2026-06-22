import 'package:arptc_connect/modules/news/data/firestore_news_repository.dart';
import 'package:arptc_connect/modules/news/domain/news_enums.dart';
import 'package:arptc_connect/modules/news/domain/news_post.dart';
import 'package:arptc_connect/modules/news/presentation/controllers/news_providers.dart';
import 'package:arptc_connect/modules/news/presentation/widgets/news_status_badge.dart';
import 'package:arptc_connect/widgets/content_view.dart';
import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:arptc_connect/widgets/empty_state_view.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:arptc_connect/widgets/loading_state_view.dart';
import 'package:arptc_connect/widgets/page_header.dart';
import 'package:arptc_connect/widgets/yes_or_no_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class NewsEditorScreen extends ConsumerStatefulWidget {
  const NewsEditorScreen({
    this.postId,
    super.key,
  });

  final String? postId;

  @override
  ConsumerState<NewsEditorScreen> createState() => _NewsEditorScreenState();
}

class _NewsEditorScreenState extends ConsumerState<NewsEditorScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _imageUrlController = TextEditingController();

  String _hydratedPostId = '';
  bool _isSaving = false;
  bool _isSubmitting = false;
  bool _isPublishing = false;
  bool _isArchiving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postId = widget.postId;
    if (postId == null || postId.isEmpty) {
      return Scaffold(
        body: ContentView(
          maxWidth: 980,
          scrollable: true,
          child: _EditorContent(
            title: 'New News Post',
            subtitle: 'Create a draft before submitting it for review.',
            status: NewsPostStatus.draft.value,
            reviewComment: '',
            canEdit: true,
            titleController: _titleController,
            contentController: _contentController,
            imageUrlController: _imageUrlController,
            isSaving: _isSaving,
            isSubmitting: _isSubmitting,
            isPublishing: _isPublishing,
            isArchiving: _isArchiving,
            onSaveDraft: () => _saveDraft(null),
            onSubmit: null,
            onPublish: null,
            onArchive: null,
          ),
        ),
      );
    }

    final postAsync = ref.watch(newsPostProvider(postId));

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
            _hydrate(post);
            final status = NewsPostStatus.fromValue(post.status);
            final canEdit = status == NewsPostStatus.draft ||
                status == NewsPostStatus.rejected;

            return _EditorContent(
              title: 'Edit News Post',
              subtitle: 'Manage this post through review and publication.',
              status: post.status,
              reviewComment: post.reviewComment,
              canEdit: canEdit,
              titleController: _titleController,
              contentController: _contentController,
              imageUrlController: _imageUrlController,
              isSaving: _isSaving,
              isSubmitting: _isSubmitting,
              isPublishing: _isPublishing,
              isArchiving: _isArchiving,
              onSaveDraft: canEdit ? () => _saveDraft(post) : null,
              onSubmit: canEdit ? () => _submitForReview(post) : null,
              onPublish: status == NewsPostStatus.accepted
                  ? () => _publishPost(post)
                  : null,
              onArchive: status == NewsPostStatus.published
                  ? () => _archivePost(post)
                  : null,
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

  void _hydrate(NewsPost post) {
    if (_hydratedPostId == post.id) {
      return;
    }
    _hydratedPostId = post.id;
    _titleController.text = post.title;
    _contentController.text = post.content;
    _imageUrlController.text = post.imageUrl;
  }

  Future<void> _saveDraft(NewsPost? post) async {
    final actor = ref.read(currentNewsActorProvider).valueOrNull;
    if (actor == null || actor.isEmpty || !_hasRequiredFields()) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (post == null) {
        final postId = await ref.read(newsRepositoryProvider).createDraftPost(
              NewsPost.empty().copyWith(
                title: _titleController.text.trim(),
                content: _contentController.text.trim(),
                imageUrl: _imageUrlController.text.trim(),
              ),
              actor,
            );
        ref.invalidate(managerNewsPostsProvider);
        if (mounted) {
          context.go('/service/news/edit/$postId');
        }
      } else {
        await ref.read(newsRepositoryProvider).updateDraftPost(
              post.copyWith(
                title: _titleController.text.trim(),
                content: _contentController.text.trim(),
                imageUrl: _imageUrlController.text.trim(),
              ),
              actor,
            );
        ref.invalidate(managerNewsPostsProvider);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _submitForReview(NewsPost post) async {
    final actor = ref.read(currentNewsActorProvider).valueOrNull;
    if (actor == null || actor.isEmpty || !_hasRequiredFields()) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(newsRepositoryProvider).updateDraftPost(
            post.copyWith(
              title: _titleController.text.trim(),
              content: _contentController.text.trim(),
              imageUrl: _imageUrlController.text.trim(),
            ),
            actor,
          );
      await ref.read(newsRepositoryProvider).submitForReview(post.id, actor);
      ref.invalidate(managerNewsPostsProvider);
      ref.invalidate(pendingReviewNewsPostsProvider);
      if (mounted) {
        context.go('/service/news');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _publishPost(NewsPost post) async {
    final actor = ref.read(currentNewsActorProvider).valueOrNull;
    if (actor == null || actor.isEmpty) {
      return;
    }

    setState(() => _isPublishing = true);
    try {
      await ref.read(newsRepositoryProvider).publishPost(post.id, actor);
      ref.invalidate(managerNewsPostsProvider);
      ref.invalidate(publishedNewsPostsProvider);
      if (mounted) {
        context.go('/service/news');
      }
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }

  Future<void> _archivePost(NewsPost post) async {
    final actor = ref.read(currentNewsActorProvider).valueOrNull;
    if (actor == null || actor.isEmpty) {
      return;
    }

    final confirm = await showAdaptiveYesNoDialog(
      context,
      'Archive Post',
      'Archive "${post.title}"? It will no longer appear on the home feed.',
      confirmText: 'Archive',
      cancelText: 'Cancel',
    );
    if (confirm != true) {
      return;
    }

    setState(() => _isArchiving = true);
    try {
      await ref.read(newsRepositoryProvider).archivePost(post.id, actor);
      ref.invalidate(managerNewsPostsProvider);
      ref.invalidate(publishedNewsPostsProvider);
      if (mounted) {
        context.go('/service/news');
      }
    } finally {
      if (mounted) {
        setState(() => _isArchiving = false);
      }
    }
  }

  bool _hasRequiredFields() {
    return _titleController.text.trim().isNotEmpty &&
        _contentController.text.trim().isNotEmpty;
  }
}

class _EditorContent extends StatelessWidget {
  const _EditorContent({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.reviewComment,
    required this.canEdit,
    required this.titleController,
    required this.contentController,
    required this.imageUrlController,
    required this.isSaving,
    required this.isSubmitting,
    required this.isPublishing,
    required this.isArchiving,
    required this.onSaveDraft,
    required this.onSubmit,
    required this.onPublish,
    required this.onArchive,
  });

  final String title;
  final String subtitle;
  final String status;
  final String reviewComment;
  final bool canEdit;
  final TextEditingController titleController;
  final TextEditingController contentController;
  final TextEditingController imageUrlController;
  final bool isSaving;
  final bool isSubmitting;
  final bool isPublishing;
  final bool isArchiving;
  final VoidCallback? onSaveDraft;
  final VoidCallback? onSubmit;
  final VoidCallback? onPublish;
  final VoidCallback? onArchive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                title: title,
                description: subtitle,
              ),
            ),
            NewsStatusBadge(status: status),
          ],
        ),
        const SizedBox(height: 18),
        if (reviewComment.trim().isNotEmpty) ...[
          Card(
            elevation: 0,
            color: theme.colorScheme.errorContainer.withOpacity(0.5),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                'Reviewer comment: $reviewComment',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                CommonTextInput(
                  label: 'Title',
                  hintText: 'Important company information',
                  type: CommonTextInputType.text,
                  controller: titleController,
                  enabled: canEdit,
                ),
                const SizedBox(height: 14),
                CommonTextInput(
                  label: 'Image URL (optional)',
                  hintText: 'https://...',
                  type: CommonTextInputType.url,
                  controller: imageUrlController,
                  enabled: canEdit,
                ),
                const SizedBox(height: 14),
                CommonTextInput(
                  label: 'Content',
                  hintText: 'Write the news, article, or information...',
                  type: CommonTextInputType.text,
                  isMultiline: true,
                  controller: contentController,
                  enabled: canEdit,
                  minLines: 8,
                  maxLines: 16,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 12,
          runSpacing: 8,
          children: [
            if (onSaveDraft != null)
              OutlinedButton.icon(
                onPressed: isSaving ? null : onSaveDraft,
                icon: const Icon(Icons.save_outlined),
                label: Text(isSaving ? 'Saving...' : 'Save Draft'),
              ),
            if (onSubmit != null)
              FilledButton.icon(
                onPressed: isSubmitting ? null : onSubmit,
                icon: const Icon(Icons.send_outlined),
                label: Text(isSubmitting ? 'Submitting...' : 'Submit Review'),
              ),
            if (onPublish != null)
              FilledButton.icon(
                onPressed: isPublishing ? null : onPublish,
                icon: const Icon(Icons.publish_outlined),
                label: Text(isPublishing ? 'Publishing...' : 'Publish'),
              ),
            if (onArchive != null)
              OutlinedButton.icon(
                onPressed: isArchiving ? null : onArchive,
                icon: const Icon(Icons.archive_outlined),
                label: Text(isArchiving ? 'Archiving...' : 'Archive'),
              ),
          ],
        ),
      ],
    );
  }
}
