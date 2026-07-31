import 'dart:convert';
import 'dart:io';

import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/itsm/security_compliance/presentation/security_compliance_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('English and French ARB files expose the complete Phase 5 key set', () {
    Map<String, Object?> read(String locale) =>
        (jsonDecode(File('lib/l10n/intl_$locale.arb').readAsStringSync())
                as Map)
            .map((key, value) => MapEntry(key.toString(), value));
    final english = read('en');
    final french = read('fr');
    final englishKeys = english.keys.where((key) => key.startsWith('itsmSc'));
    final frenchKeys = french.keys.where((key) => key.startsWith('itsmSc'));

    expect(englishKeys.toSet(), frenchKeys.toSet());
    expect(englishKeys.length, greaterThanOrEqualTo(146));
    expect(englishKeys.map((key) => english[key]), everyElement(isNotEmpty));
    expect(frenchKeys.map((key) => french[key]), everyElement(isNotEmpty));
  });

  testWidgets('selects French values from the active locale', (tester) async {
    late String title;
    await tester.pumpWidget(
      Localizations(
        locale: const Locale('fr'),
        delegates: const [S.delegate, DefaultWidgetsLocalizations.delegate],
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (context) {
              title = SecurityComplianceStrings.of(context)
                  .value('securityComplianceTitle');
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(title, 'Sécurité et conformité');
  });
}
