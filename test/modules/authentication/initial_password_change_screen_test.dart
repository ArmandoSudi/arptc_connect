import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/authentication/screens/initial_password_change_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('rejects temporary, short, and mismatched passwords',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: [S.delegate],
          supportedLocales: [Locale('en'), Locale('fr')],
          home: InitialPasswordChangeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'short');
    await tester.enterText(fields.at(1), 'different');
    await tester.tap(find.byKey(const Key('initial-password-submit')));
    await tester.pump();

    expect(find.text('Use at least 8 characters.'), findsOneWidget);
    expect(find.text('The passwords do not match.'), findsOneWidget);

    await tester.enterText(fields.at(0), 'Arptc@1234');
    await tester.enterText(fields.at(1), 'Arptc@1234');
    await tester.tap(find.byKey(const Key('initial-password-submit')));
    await tester.pump();

    expect(
      find.text('Choose a password different from the temporary password.'),
      findsOneWidget,
    );
  });
}
