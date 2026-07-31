import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/itsm/knowledge/domain/knowledge_domain.dart';
import 'package:arptc_connect/modules/itsm/knowledge/presentation/widgets/knowledge_article_view.dart';
import 'package:arptc_connect/modules/itsm/knowledge/presentation/widgets/knowledge_base_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../knowledge_test_fixtures.dart';

void main() {
  Widget shell(Widget child) {
    return MaterialApp(
      localizationsDelegates: const [S.delegate],
      supportedLocales: S.delegate.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(width: 1100, child: child),
        ),
      ),
    );
  }

  testWidgets('knowledge library renders filters and article cards',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final article = knowledgeArticle(
      state: KnowledgeArticleState.published,
      publishedVersionNumber: 1,
      isFeatured: true,
    );

    await tester.pumpWidget(
      shell(
        KnowledgeBaseView(
          articles: [article],
          categories: [
            KnowledgeCategory(
              id: 'identity',
              nameEn: 'Identity and access',
              nameFr: 'Identité et accès',
            ),
          ],
          selectedCategoryId: '',
          searchController: controller,
          onSearchChanged: (_) {},
          onCategoryChanged: (_) {},
          onArticlePressed: (_) {},
          onRetry: () {},
          onLoadMore: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Search the knowledge base'), findsOneWidget);
    expect(find.text('Reset a locked account'), findsOneWidget);
    expect(find.text('IDENTITY AND ACCESS'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
  });

  testWidgets('article view renders immutable version content and metadata',
      (tester) async {
    final article = knowledgeArticle(
      state: KnowledgeArticleState.published,
      publishedVersionNumber: 1,
    );
    final version = knowledgeVersion(
      state: KnowledgeArticleState.published,
      publishedAt: DateTime.utc(2026, 7, 1),
    );

    await tester.pumpWidget(
      shell(
        KnowledgeArticleView(
          article: article,
          version: version,
          categoryName: 'Identity and access',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Open the identity portal and follow the recovery process.'),
      findsOneWidget,
    );
    expect(find.text('Article version 1'), findsOneWidget);
    expect(find.text('Was this article helpful?'), findsOneWidget);
    expect(find.text('Helpful (3)'), findsOneWidget);
  });
}
