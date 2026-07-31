import 'dart:async';

import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/itsm/knowledge/application/knowledge_application.dart';
import 'package:arptc_connect/modules/itsm/knowledge/data/knowledge_data.dart';
import 'package:arptc_connect/modules/itsm/knowledge/domain/knowledge_domain.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/pagination.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/knowledge_layout.dart';
import '../widgets/knowledge_manager_queue_view.dart';
import 'knowledge_editor_screen.dart';
import 'knowledge_manager_review_screen.dart';

class KnowledgeManagerQueueScreen extends ConsumerStatefulWidget {
  const KnowledgeManagerQueueScreen({super.key});

  @override
  ConsumerState<KnowledgeManagerQueueScreen> createState() =>
      _KnowledgeManagerQueueScreenState();
}

class _KnowledgeManagerQueueScreenState
    extends ConsumerState<KnowledgeManagerQueueScreen> {
  final _searchController = TextEditingController();
  KnowledgeManagerQueue _queue = KnowledgeManagerQueue.awaitingReview;
  String _searchTerm = '';
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final policyState = ref.watch(knowledgeAccessPolicyProvider);
    if (policyState.isLoading) {
      return KnowledgePage(
        title: l10n.itsmKnowledgeBase,
        onBack: () => Navigator.of(context).maybePop(),
        child: KnowledgeAsyncState(
          icon: Icons.hourglass_top_rounded,
          title: l10n.loading,
          isLoading: true,
        ),
      );
    }
    if (!(policyState.valueOrNull?.canManage ?? false)) {
      return KnowledgePage(
        title: l10n.itsmKnowledgeBase,
        onBack: () => Navigator.of(context).maybePop(),
        child: KnowledgeAsyncState(
          icon: Icons.lock_outline_rounded,
          title: l10n.itsmAccessDeniedTitle,
        ),
      );
    }
    final request = KnowledgeManagerPageRequest(
      query: KnowledgeManagerQuery(
        queue: _queue,
        searchTerm: _searchTerm,
      ),
      page: PageRequest(limit: 50),
    );
    final pageState = ref.watch(knowledgeManagerPageProvider(request));
    final categories = ref
            .watch(
              knowledgeCategoriesProvider(
                const KnowledgeCategoryRequest(activeOnly: false),
              ),
            )
            .valueOrNull ??
        const [];

    return KnowledgePage(
      title: l10n.itsmKnowledgeBase,
      onBack: () => Navigator.of(context).maybePop(),
      child: KnowledgeManagerQueueView(
        articles: pageState.valueOrNull?.items ?? const [],
        categories: categories,
        queue: _queue,
        searchController: _searchController,
        isLoading: pageState.isLoading,
        error: pageState.error,
        onQueueChanged: (value) {
          if (value != null) setState(() => _queue = value);
        },
        onSearchChanged: _scheduleSearch,
        onArticlePressed: (article) async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => KnowledgeManagerReviewScreen(
                articleId: article.id,
              ),
            ),
          );
          ref.invalidate(knowledgeManagerPageProvider(request));
        },
        onCreatePressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const KnowledgeEditorScreen(),
            ),
          );
          ref.invalidate(knowledgeManagerPageProvider(request));
        },
        onRetry: () => ref.invalidate(knowledgeManagerPageProvider(request)),
      ),
    );
  }

  void _scheduleSearch(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _searchTerm = value);
    });
  }
}
