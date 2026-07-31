import 'dart:async';

import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/itsm/knowledge/application/knowledge_application.dart';
import 'package:arptc_connect/modules/itsm/knowledge/data/knowledge_data.dart';
import 'package:arptc_connect/modules/itsm/knowledge/domain/knowledge_domain.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/pagination.dart';
import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/knowledge_article_card.dart';
import '../widgets/knowledge_layout.dart';
import 'knowledge_article_screen.dart';
import 'knowledge_manager_queue_screen.dart';

class KnowledgeBaseScreen extends ConsumerStatefulWidget {
  const KnowledgeBaseScreen({super.key});

  @override
  ConsumerState<KnowledgeBaseScreen> createState() =>
      _KnowledgeBaseScreenState();
}

class _KnowledgeBaseScreenState extends ConsumerState<KnowledgeBaseScreen> {
  final _searchController = TextEditingController();
  String _searchTerm = '';
  String _categoryId = '';
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
    final policy = ref.watch(knowledgeAccessPolicyProvider).valueOrNull;
    final categoriesState = ref.watch(
      knowledgeCategoriesProvider(const KnowledgeCategoryRequest()),
    );
    final request = KnowledgePublishedPageRequest(
      query: KnowledgePublishedQuery(
        searchTerm: _searchTerm,
        categoryId: _categoryId,
        languageCode: Localizations.localeOf(context).languageCode,
      ),
      page: PageRequest(limit: 30),
    );
    final articlesState = ref.watch(knowledgePublishedPageProvider(request));
    final categories = categoriesState.valueOrNull ?? const [];

    return KnowledgePage(
      title: l10n.itsmKnowledgeBase,
      actions: [
        if (policy?.canManage ?? false)
          IconButton(
            tooltip: l10n.reviewPost,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const KnowledgeManagerQueueScreen(),
              ),
            ),
            icon: const Icon(Icons.admin_panel_settings_outlined),
          ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KnowledgePanel(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final search = CommonTextInput(
                  label: l10n.search,
                  controller: _searchController,
                  prefixIcon: const Icon(Icons.search_rounded),
                  onChanged: _scheduleSearch,
                );
                final category = DropdownButtonFormField<String>(
                  value: _categoryId,
                  decoration: InputDecoration(labelText: l10n.category),
                  items: [
                    DropdownMenuItem(value: '', child: Text(l10n.all)),
                    for (final item in categories)
                      DropdownMenuItem(
                        value: item.id,
                        child: Text(
                          item.localizedName(
                            Localizations.localeOf(context).languageCode,
                          ),
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() {
                    _categoryId = value ?? '';
                  }),
                );
                if (constraints.maxWidth < 620) {
                  return Column(
                    children: [
                      search,
                      const SizedBox(height: 14),
                      category,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(flex: 2, child: search),
                    const SizedBox(width: 16),
                    Expanded(child: category),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          articlesState.when(
            loading: () => KnowledgeAsyncState(
              icon: Icons.hourglass_top_rounded,
              title: l10n.loading,
              isLoading: true,
            ),
            error: (error, stackTrace) => KnowledgeAsyncState(
              icon: Icons.error_outline_rounded,
              title: l10n.unableToLoad,
              error: error,
              onRetry: () => ref.invalidate(
                knowledgePublishedPageProvider(request),
              ),
            ),
            data: (page) => page.items.isEmpty
                ? KnowledgeAsyncState(
                    icon: Icons.menu_book_outlined,
                    title: l10n.noDataAvailable,
                  )
                : KnowledgeResponsiveGrid(
                    children: [
                      for (final article in page.items)
                        KnowledgeArticleCard(
                          article: article,
                          categoryName: _categoryName(
                            categories,
                            article.categoryId,
                            Localizations.localeOf(context).languageCode,
                          ),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => KnowledgeArticleScreen(
                                articleId: article.id,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
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

String _categoryName(
  List<KnowledgeCategory> categories,
  String id,
  String languageCode,
) {
  for (final category in categories) {
    if (category.id == id) return category.localizedName(languageCode);
  }
  return '';
}
