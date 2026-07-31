import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/itsm/security_compliance/presentation/widgets/security_compliance_paged_list.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/pagination.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('uses a single list column on a phone', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(find.byType(GridView), findsNothing);
    expect(find.text('Item 1'), findsOneWidget);
  });

  testWidgets('uses a responsive grid on a desktop', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(find.byType(GridView), findsOneWidget);
  });

  testWidgets('renders the localized empty state', (tester) async {
    await tester.pumpWidget(_app(items: const []));
    await tester.pumpAndSettle();
    expect(find.text('No records found'), findsOneWidget);
  });

  testWidgets('renders localized loading and error states', (tester) async {
    await tester.pumpWidget(_app(firstPage: const AsyncLoading()));
    await tester.pump();
    expect(find.text('Loading security data…'), findsOneWidget);

    await tester.pumpWidget(
      _app(firstPage: AsyncError(StateError('failed'), StackTrace.empty)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Security data could not be loaded.'), findsOneWidget);
  });
}

Widget _app({
  List<int> items = const [1, 2],
  AsyncValue<List<int>>? firstPage,
}) =>
    MaterialApp(
      locale: const Locale('en'),
      supportedLocales: const [Locale('en'), Locale('fr')],
      localizationsDelegates: const [S.delegate],
      home: Scaffold(
        body: SecurityCompliancePagedList<int>(
          firstPage: firstPage ?? AsyncData(items),
          loadPage: (_) async => PageResult(
            items: const [],
            hasMore: false,
          ),
          cursorOf: (item) => PageCursor({'sortAt': item, 'id': '$item'}),
          onRetry: () {},
          itemBuilder: (_, item) => Card(child: Text('Item $item')),
        ),
      ),
    );
