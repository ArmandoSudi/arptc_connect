import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/usermanagement/data/user_management_repository.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/utils/user_management_command_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('command errors are logged and shown in a bottom snackbar',
      (tester) async {
    String? logMessage;
    Object? loggedError;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [S.delegate],
      supportedLocales: S.delegate.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => FilledButton(
            onPressed: () => reportUserManagementCommandError(
              context,
              operation: 'updateOrganizationUnit',
              error: StateError('write failed'),
              stackTrace: StackTrace.current,
              userMessage: 'Unable to update the unit.',
              logger: (message, {error, stackTrace}) {
                logMessage = message;
                loggedError = error;
              },
            ),
            child: const Text('Fail'),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Fail'));
    await tester.pump();

    expect(logMessage, contains('updateOrganizationUnit'));
    expect(loggedError, isA<StateError>());
    expect(find.text('Unable to update the unit.'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('internal callable errors use the localized service message',
      (tester) async {
    late String message;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [S.delegate],
      supportedLocales: S.delegate.supportedLocales,
      home: Builder(
        builder: (context) {
          message = userManagementCommandErrorMessage(
            S.of(context),
            const OrganizationCommandException(
              code: 'internal',
              message: 'internal',
            ),
          );
          return const SizedBox();
        },
      ),
    ));
    await tester.pump();

    expect(message, contains('Deploy the latest Firebase Functions'));
  });
}
