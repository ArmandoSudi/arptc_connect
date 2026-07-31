import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/incident_management/presentation/widgets/incident_knowledge_suggestions.dart';
import 'package:arptc_connect/modules/itsm/knowledge/domain/knowledge_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../itsm/knowledge/knowledge_test_fixtures.dart';

void main() {
  Widget shell(Widget child) => MaterialApp(
        localizationsDelegates: const [S.delegate],
        supportedLocales: S.delegate.supportedLocales,
        home: Scaffold(body: child),
      );

  testWidgets('renders bounded knowledge suggestions and opens an article',
      (tester) async {
    KnowledgeArticle? selected;
    final article = knowledgeArticle(
      state: KnowledgeArticleState.published,
      publishedVersionNumber: 1,
    );

    await tester.pumpWidget(
      shell(
        IncidentKnowledgeSuggestionsView(
          articles: [article],
          onArticlePressed: (value) => selected = value,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Suggested knowledge'), findsOneWidget);
    expect(find.text('Reset a locked account'), findsOneWidget);
    await tester.tap(find.text('Reset a locked account'));
    expect(selected, same(article));
  });

  testWidgets('shows a localized retry state', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      shell(
        IncidentKnowledgeSuggestionsView(
          errorMessage: 'offline',
          onRetry: () => retried = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unable to load the knowledge base'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retried, isTrue);
  });

  testWidgets('does not reserve space for an empty suggestion set',
      (tester) async {
    await tester.pumpWidget(
      shell(const IncidentKnowledgeSuggestionsView()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Card), findsNothing);
  });
}
