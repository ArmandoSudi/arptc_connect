import 'package:arptc_connect/core/theme.dart';
import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/itsm/presentation/screens/itsm_landing_screen.dart';
import 'package:arptc_connect/modules/itsm/presentation/widgets/itsm_access_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('landing renders exactly five localized section cards',
      (tester) async {
    await _pumpLanding(tester, const Size(1400, 900));

    expect(find.byKey(const ValueKey('itsm-navigation-grid')), findsOneWidget);
    expect(find.text('Support'), findsOneWidget);
    expect(find.text('Assets & Configuration'), findsOneWidget);
    expect(find.text('Changes'), findsOneWidget);
    expect(find.text('Security & Compliance'), findsOneWidget);
    expect(find.text('Reporting & Administration'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey('itsm-section-reportingAdministration'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('landing grid changes columns for mobile, tablet, and desktop',
      (tester) async {
    await _pumpLanding(tester, const Size(420, 1000));
    expect(_gridDelegate(tester).crossAxisCount, 1);

    await _pumpLanding(tester, const Size(800, 1000));
    expect(_gridDelegate(tester).crossAxisCount, 2);

    await _pumpLanding(tester, const Size(1400, 1000));
    expect(_gridDelegate(tester).crossAxisCount, 3);
  });

  testWidgets('access state explains unavailable destinations', (tester) async {
    await tester.pumpWidget(
      _localizedApp(
        const ItsmAccessState(
          title: 'Stock',
          description: 'No protected data has been loaded.',
          backLabel: 'Assets & Configuration',
          backRoute: '/services/itsm/assets-configuration',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Stock'), findsOneWidget);
    expect(find.text('No protected data has been loaded.'), findsOneWidget);
    expect(find.text('Assets & Configuration'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
  });
}

Future<void> _pumpLanding(WidgetTester tester, Size size) async {
  await tester.binding.setSurfaceSize(size);
  await tester.pumpWidget(_localizedApp(const ItsmLandingScreen()));
  await tester.pumpAndSettle();
}

SliverGridDelegateWithFixedCrossAxisCount _gridDelegate(WidgetTester tester) {
  final grid = tester.widget<GridView>(
    find.byKey(const ValueKey('itsm-navigation-grid')),
  );
  return grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
}

Widget _localizedApp(Widget home) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: const [S.delegate],
    supportedLocales: S.delegate.supportedLocales,
    theme: CorporateBlueTheme.light,
    home: Scaffold(body: home),
  );
}
