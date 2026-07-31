import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/incident_management/presentation/widgets/incident_linked_records_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget subject(List<IncidentLinkedRecord> records) {
    return MaterialApp(
      localizationsDelegates: const [S.delegate],
      supportedLocales: S.delegate.supportedLocales,
      home: Scaffold(
        body: IncidentLinkedRecordsCard(records: records),
      ),
    );
  }

  testWidgets('does not render a panel without linked records', (tester) async {
    await tester.pumpWidget(subject(const []));
    await tester.pumpAndSettle();

    expect(find.byType(Card), findsNothing);
    expect(find.text('Linked records'), findsNothing);
  });

  testWidgets('presents each linked record with its type', (tester) async {
    await tester.pumpWidget(
      subject(
        const [
          IncidentLinkedRecord(
            type: IncidentLinkedRecordType.asset,
            id: 'AST-001',
          ),
          IncidentLinkedRecord(
            type: IncidentLinkedRecordType.knowledgeArticle,
            id: 'KB-0042',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Linked records'), findsOneWidget);
    expect(find.text('Related asset: AST-001'), findsOneWidget);
    expect(find.text('Suggested knowledge: KB-0042'), findsOneWidget);
  });

  test('builds canonical deep links for supported records', () {
    expect(
      incidentLinkedRecordLocation(
        const IncidentLinkedRecord(
          type: IncidentLinkedRecordType.serviceRequest,
          id: 'REQ 42',
        ),
      ),
      '/services/itsm/support/service-requests/REQ%2042',
    );
    expect(
      incidentLinkedRecordLocation(
        const IncidentLinkedRecord(
          type: IncidentLinkedRecordType.knowledgeArticle,
          id: 'kb-1',
        ),
      ),
      '/services/itsm/support/knowledge/kb-1',
    );
  });
}
