import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/incident_management/presentation/widgets/incident_resolution_knowledge_selector.dart';
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

  testWidgets('manager can select an article for the resolution',
      (tester) async {
    Set<String> selected = {};
    final article = knowledgeArticle(
      state: KnowledgeArticleState.published,
      publishedVersionNumber: 1,
    );
    await tester.pumpWidget(
      shell(
        StatefulBuilder(
          builder: (context, setState) {
            return IncidentResolutionKnowledgeSelector(
              articles: [article],
              selectedArticleIds: selected,
              onSelectionChanged: (value) {
                setState(() => selected = value);
              },
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reset a locked account'));
    await tester.pump();
    expect(selected, {'article-1'});
    expect(
      tester.widget<FilterChip>(find.byType(FilterChip)).selected,
      isTrue,
    );
  });

  testWidgets('disabled selector keeps the existing link immutable',
      (tester) async {
    var changed = false;
    final article = knowledgeArticle(
      state: KnowledgeArticleState.published,
      publishedVersionNumber: 1,
    );
    await tester.pumpWidget(
      shell(
        IncidentResolutionKnowledgeSelector(
          articles: [article],
          selectedArticleIds: const {'article-1'},
          enabled: false,
          onSelectionChanged: (_) => changed = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reset a locked account'));
    expect(changed, isFalse);
  });
}
