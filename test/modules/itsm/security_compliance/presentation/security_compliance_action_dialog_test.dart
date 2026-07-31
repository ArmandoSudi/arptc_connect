import 'package:arptc_connect/modules/itsm/security_compliance/presentation/widgets/security_compliance_action_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('returns constrained choices and optional text fields',
      (tester) async {
    Map<String, String>? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showSecurityComplianceActionDialog(
                context,
                title: 'Validate',
                submitLabel: 'Save',
                cancelLabel: 'Cancel',
                requiredFieldLabel: 'Required',
                fields: const [
                  SecurityDialogField(
                    keyName: 'result',
                    label: 'Result',
                    options: [
                      SecurityDialogOption('passed', 'Passed'),
                      SecurityDialogOption('failed', 'Failed'),
                    ],
                  ),
                  SecurityDialogField(
                    keyName: 'comment',
                    label: 'Comment',
                    required: false,
                  ),
                ],
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Passed'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Failed').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(result, {'result': 'failed', 'comment': ''});
  });
}
