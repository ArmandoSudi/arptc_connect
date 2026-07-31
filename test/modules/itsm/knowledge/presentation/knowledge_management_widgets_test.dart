import 'dart:typed_data';

import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/itsm/knowledge/data/knowledge_data.dart';
import 'package:arptc_connect/modules/itsm/knowledge/domain/knowledge_domain.dart';
import 'package:arptc_connect/modules/itsm/knowledge/presentation/knowledge_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../knowledge_test_fixtures.dart';

void main() {
  testWidgets('manager queue handles loading, empty, and compact layouts',
      (tester) async {
    final search = TextEditingController();
    addTearDown(search.dispose);

    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 360,
          child: KnowledgeManagerQueueView(
            articles: const [],
            categories: const [],
            queue: KnowledgeManagerQueue.awaitingReview,
            searchController: search,
            onQueueChanged: (_) {},
            onSearchChanged: (_) {},
            onArticlePressed: (_) {},
            onCreatePressed: () {},
            onRetry: () {},
            isLoading: true,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 360,
          child: KnowledgeManagerQueueView(
            articles: const [],
            categories: const [],
            queue: KnowledgeManagerQueue.drafts,
            searchController: search,
            onQueueChanged: (_) {},
            onSearchChanged: (_) {},
            onArticlePressed: (_) {},
            onCreatePressed: () {},
            onRetry: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('manager queue exposes article selection and create action',
      (tester) async {
    final search = TextEditingController();
    addTearDown(search.dispose);
    var created = false;
    KnowledgeArticle? selected;
    final article = knowledgeArticle();

    await tester.pumpWidget(
      _app(
        KnowledgeManagerQueueView(
          articles: [article],
          categories: [
            KnowledgeCategory(
              id: 'identity',
              nameEn: 'Identity',
              nameFr: 'Identite',
            ),
          ],
          queue: KnowledgeManagerQueue.all,
          searchController: search,
          onQueueChanged: (_) {},
          onSearchChanged: (_) {},
          onArticlePressed: (value) => selected = value,
          onCreatePressed: () => created = true,
          onRetry: () {},
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Create'));
    expect(created, isTrue);
    await tester.tap(find.text(article.title));
    expect(selected, article);
  });

  testWidgets('article view wires helpful and not-helpful actions',
      (tester) async {
    var helpful = 0;
    var notHelpful = 0;
    final article = knowledgeArticle(
      state: KnowledgeArticleState.published,
      publishedVersionNumber: 1,
    );
    final version = knowledgeVersion(
      state: KnowledgeArticleState.published,
      publishedAt: DateTime.utc(2026, 7, 1),
    );

    await tester.pumpWidget(
      _app(
        SingleChildScrollView(
          child: KnowledgeArticleView(
            article: article,
            version: version,
            onHelpful: () => helpful++,
            onNotHelpful: () => notHelpful++,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.thumb_up_alt_outlined));
    await tester.tap(find.byIcon(Icons.thumb_down_alt_outlined));
    expect(helpful, 1);
    expect(notHelpful, 1);
  });

  testWidgets('review view exposes only valid lifecycle actions',
      (tester) async {
    KnowledgeTransitionAction? selected;
    await tester.pumpWidget(
      _app(
        SingleChildScrollView(
          child: KnowledgeReviewView(
            article: knowledgeArticle(state: KnowledgeArticleState.review),
            version: knowledgeVersion(state: KnowledgeArticleState.review),
            onEdit: () {},
            onAction: (action) => selected = action,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Reject post'), findsOneWidget);
    expect(find.text('Publish post'), findsOneWidget);
    expect(find.text('Edit'), findsNothing);
    await tester.tap(find.text('Reject post'));
    expect(selected, KnowledgeTransitionAction.rejectToDraft);
  });

  testWidgets('editor form remains usable on a narrow screen', (tester) async {
    final title = TextEditingController();
    final summary = TextEditingController();
    final content = TextEditingController();
    addTearDown(title.dispose);
    addTearDown(summary.dispose);
    addTearDown(content.dispose);
    var saved = false;
    var picked = false;
    String? removedAttachmentId;

    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: KnowledgeEditorForm(
              formKey: GlobalKey<FormState>(),
              titleController: title,
              summaryController: summary,
              contentController: content,
              categories: [
                KnowledgeCategory(
                  id: 'identity',
                  nameEn: 'Identity',
                  nameFr: 'Identite',
                ),
              ],
              categoryId: 'identity',
              languageCode: 'en',
              visibility: KnowledgeVisibility.employee,
              isFeatured: false,
              pendingAttachments: [
                KnowledgeDraftAttachment(
                  id: 'pending-1',
                  fileName: 'guide.pdf',
                  contentType: 'application/pdf',
                  bytes: Uint8List.fromList([1, 2, 3]),
                ),
              ],
              onPickAttachment: () => picked = true,
              onRemovePendingAttachment: (value) => removedAttachmentId = value,
              onCategoryChanged: (_) {},
              onLanguageChanged: (_) {},
              onVisibilityChanged: (_) {},
              onFeaturedChanged: (_) {},
              onSave: () => saved = true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('guide.pdf'), findsOneWidget);

    await tester.ensureVisible(find.text('Select file'));
    await tester.tap(find.text('Select file'));
    expect(picked, isTrue);
    await tester.tap(find.byTooltip('Remove'));
    expect(removedAttachmentId, 'pending-1');

    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    expect(saved, isTrue);
  });
}

Widget _app(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: const [S.delegate],
    supportedLocales: S.delegate.supportedLocales,
    home: Scaffold(body: child),
  );
}
