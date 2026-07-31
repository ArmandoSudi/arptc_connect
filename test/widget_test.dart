import 'package:arptc_connect/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('application localization loads without Firebase',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [S.delegate],
        supportedLocales: S.delegate.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Text(S.of(context).appName),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ARPTC Connect'), findsOneWidget);
  });
}
