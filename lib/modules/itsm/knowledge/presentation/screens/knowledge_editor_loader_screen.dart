import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/itsm/knowledge/application/knowledge_application.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/knowledge_layout.dart';
import 'knowledge_editor_screen.dart';

class KnowledgeEditorLoaderScreen extends ConsumerStatefulWidget {
  const KnowledgeEditorLoaderScreen({required this.articleId, super.key});

  final String articleId;

  @override
  ConsumerState<KnowledgeEditorLoaderScreen> createState() =>
      _KnowledgeEditorLoaderScreenState();
}

class _KnowledgeEditorLoaderScreenState
    extends ConsumerState<KnowledgeEditorLoaderScreen> {
  late final DateTime _asOf;

  @override
  void initState() {
    super.initState();
    _asOf = DateTime.now().toUtc();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final articleRequest = KnowledgeArticleRequest(
      articleId: widget.articleId,
      asOf: _asOf,
    );
    final articleState = ref.watch(knowledgeArticleProvider(articleRequest));

    return articleState.when(
      loading: () => _statePage(l10n.loading, isLoading: true),
      error: (error, stackTrace) => _statePage(
        l10n.unableToLoad,
        error: error,
        onRetry: () => ref.invalidate(
          knowledgeArticleProvider(articleRequest),
        ),
      ),
      data: (article) {
        if (article == null) return _statePage(l10n.noDataAvailable);
        final versionRequest = KnowledgeVersionRequest(
          articleId: article.id,
          versionNumber: article.currentVersionNumber,
          asOf: _asOf,
        );
        final versionState = ref.watch(
          knowledgeVersionProvider(versionRequest),
        );
        return versionState.when(
          loading: () => _statePage(l10n.loading, isLoading: true),
          error: (error, stackTrace) => _statePage(
            l10n.unableToLoad,
            error: error,
            onRetry: () => ref.invalidate(
              knowledgeVersionProvider(versionRequest),
            ),
          ),
          data: (version) => version == null
              ? _statePage(l10n.noDataAvailable)
              : KnowledgeEditorScreen(article: article, version: version),
        );
      },
    );
  }

  Widget _statePage(
    String title, {
    bool isLoading = false,
    Object? error,
    VoidCallback? onRetry,
  }) {
    return KnowledgePage(
      title: S.of(context).edit,
      onBack: () => Navigator.of(context).maybePop(),
      child: KnowledgeAsyncState(
        icon: error == null
            ? Icons.hourglass_top_rounded
            : Icons.error_outline_rounded,
        title: title,
        isLoading: isLoading,
        error: error,
        onRetry: onRetry,
      ),
    );
  }
}
