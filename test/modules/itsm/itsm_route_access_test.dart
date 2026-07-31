import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_enums.dart';
import 'package:arptc_connect/modules/incident_management/presentation/controllers/incident_providers.dart';
import 'package:arptc_connect/modules/itsm/presentation/navigation/itsm_navigation.dart';
import 'package:arptc_connect/modules/itsm/presentation/navigation/itsm_route_access.dart';
import 'package:arptc_connect/modules/itsm/presentation/widgets/itsm_route_guard.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ITSM route access policy', () {
    test('keeps operational features manager-only', () {
      expect(
        ItsmRouteAccessPolicy.canAccess(
          role: ItsmRole.user,
          section: ItsmSection.assetsConfiguration,
          feature: ItsmFeature.stock,
        ),
        isFalse,
      );
      expect(
        ItsmRouteAccessPolicy.canAccess(
          role: ItsmRole.admin,
          section: ItsmSection.securityCompliance,
          feature: ItsmFeature.securityFindings,
        ),
        isFalse,
      );
      expect(
        ItsmRouteAccessPolicy.canAccess(
          role: ItsmRole.manager,
          section: ItsmSection.assetsConfiguration,
          feature: ItsmFeature.stock,
        ),
        isTrue,
      );
    });

    test('allows manager administration and read-only executive reporting', () {
      for (final role in [ItsmRole.manager, ItsmRole.admin]) {
        expect(
          ItsmRouteAccessPolicy.canAccess(
            role: role,
            section: ItsmSection.reportingAdministration,
          ),
          isTrue,
        );
      }
      expect(
        ItsmRouteAccessPolicy.canAccess(
          role: ItsmRole.user,
          section: ItsmSection.reportingAdministration,
        ),
        isFalse,
      );
      expect(
        ItsmRouteAccessPolicy.isReadOnly(
          role: ItsmRole.admin,
          section: ItsmSection.reportingAdministration,
        ),
        isTrue,
      );
      expect(
        ItsmRouteAccessPolicy.isReadOnly(
          role: ItsmRole.manager,
          section: ItsmSection.reportingAdministration,
        ),
        isFalse,
      );
    });

    test('distinguishes self-service, operational, and executive deep links',
        () {
      expect(
        ItsmRouteAccessPolicy.canAccess(
          role: ItsmRole.admin,
          requirement: ItsmRouteRequirement.selfService,
        ),
        isTrue,
      );
      expect(
        ItsmRouteAccessPolicy.canAccess(
          role: ItsmRole.user,
          requirement: ItsmRouteRequirement.operational,
        ),
        isFalse,
      );
      expect(
        ItsmRouteAccessPolicy.canAccess(
          role: ItsmRole.manager,
          requirement: ItsmRouteRequirement.executive,
        ),
        isFalse,
      );
    });
  });

  testWidgets('route guard blocks a USER before protected content builds',
      (tester) async {
    await tester.pumpWidget(
      _guardedApp(
        role: IncidentRole.user,
        requirement: ItsmRouteRequirement.operational,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ITSM access restricted'), findsOneWidget);
    expect(find.text('Protected operational content'), findsNothing);
  });

  testWidgets('route guard renders operational content for a MANAGER',
      (tester) async {
    await tester.pumpWidget(
      _guardedApp(
        role: IncidentRole.manager,
        requirement: ItsmRouteRequirement.operational,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Protected operational content'), findsOneWidget);
    expect(find.text('ITSM access restricted'), findsNothing);
  });
}

Widget _guardedApp({
  required IncidentRole role,
  required ItsmRouteRequirement requirement,
}) {
  return ProviderScope(
    overrides: [
      currentUserIncidentRoleProvider.overrideWith(
        (ref) => AsyncValue.data(role),
      ),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [S.delegate],
      supportedLocales: S.delegate.supportedLocales,
      home: Scaffold(
        body: ItsmRouteGuard(
          requirement: requirement,
          child: const Text('Protected operational content'),
        ),
      ),
    ),
  );
}
