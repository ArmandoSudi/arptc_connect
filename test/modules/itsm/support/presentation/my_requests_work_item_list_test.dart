import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_shared_domain.dart';
import 'package:arptc_connect/modules/itsm/shared/presentation/itsm_work_item_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('My Requests renders cross-module summaries and filters',
      (tester) async {
    var selectedTypes = <ItsmWorkItemType>{};
    var loadMoreCalls = 0;
    await tester.pumpWidget(
      _app(
        ItsmWorkItemListView(
          items: [
            _summary(ItsmWorkItemType.incident, 'INC-1'),
            _summary(ItsmWorkItemType.serviceRequest, 'REQ-1'),
          ],
          searchQuery: '',
          selectedTypes: const {},
          selectedStatuses: const {},
          showHistory: false,
          hasMore: true,
          isLoadingMore: false,
          onSearchChanged: (_) {},
          onHistoryChanged: (_) {},
          onTypesChanged: (value) => selectedTypes = value,
          onStatusesChanged: (_) {},
          onDateRangeChanged: (_) {},
          onClearDateRange: () {},
          onSelected: (_) {},
          onLoadMore: () => loadMoreCalls++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilterChip, 'Incidents'));
    expect(selectedTypes, {ItsmWorkItemType.incident});

    await tester.scrollUntilVisible(
      find.text('REQ-1'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('INC-1'), findsOneWidget);
    expect(find.text('REQ-1'), findsOneWidget);
    expect(find.text('Service Requests'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('Load more'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Load more'));
    expect(loadMoreCalls, 1);
  });
}

ItsmWorkItemSummary _summary(ItsmWorkItemType type, String reference) {
  return ItsmWorkItemSummary(
    id: reference.toLowerCase(),
    reference: reference,
    type: type,
    title: 'Work item $reference',
    requesterId: 'user-1',
    status: type == ItsmWorkItemType.incident ? 'open' : 'submitted',
    lifecycleState: ItsmLifecycleState.active,
    createdAt: DateTime.utc(2026, 7, 1),
    createdBy: 'user-1',
    updatedAt: DateTime.utc(2026, 7, 2),
    updatedBy: 'user-1',
  );
}

Widget _app(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [S.delegate],
    supportedLocales: S.delegate.supportedLocales,
    home: Scaffold(body: child),
  );
}
