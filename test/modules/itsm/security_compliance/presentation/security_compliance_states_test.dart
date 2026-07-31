import 'package:arptc_connect/modules/itsm/security_compliance/application/security_compliance_application.dart';
import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/itsm/security_compliance/presentation/screens/asset_compliance_screen.dart';
import 'package:arptc_connect/modules/itsm/security_compliance/presentation/screens/security_findings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';

void main() {
  testWidgets('findings screen denies non-MANAGER raw access', (tester) async {
    await tester.pumpWidget(
      _app(
        const SecurityFindingsScreen(),
        const SecurityComplianceAccessState(
          canUseSelfService: true,
          canOperate: false,
          canSubmitException: true,
          canViewOwnCompliance: true,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Access denied'), findsOneWidget);
    expect(
      find.text(
        'This operational view is available to ITSM MANAGER users only.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('ADMIN cannot open raw asset compliance assessments',
      (tester) async {
    await tester.pumpWidget(
      _app(
        const AssetComplianceScreen(),
        const SecurityComplianceAccessState(
          canUseSelfService: true,
          canOperate: false,
          canSubmitException: true,
          canViewOwnCompliance: false,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Access denied'), findsOneWidget);
    expect(
      find.text(
        'Own-device compliance is available to USER self-service only.',
      ),
      findsOneWidget,
    );
  });
}

Widget _app(Widget child, SecurityComplianceAccessState access) =>
    ResponsiveBreakpoints.builder(
      breakpoints: const [
        Breakpoint(start: 0, end: 450, name: 'MOBILE'),
        Breakpoint(start: 451, end: 960, name: 'TABLET'),
        Breakpoint(start: 961, end: double.infinity, name: 'DESKTOP'),
      ],
      child: ProviderScope(
        overrides: [
          securityComplianceAccessProvider.overrideWithValue(
            AsyncData(access),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: const [Locale('en'), Locale('fr')],
          localizationsDelegates: const [S.delegate],
          home: child,
        ),
      ),
    );
