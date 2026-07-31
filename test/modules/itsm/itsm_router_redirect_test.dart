import 'package:arptc_connect/modules/itsm/presentation/navigation/itsm_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('GoRouter compatibility route preserves suffix and query',
      (tester) async {
    final router = GoRouter(
      initialLocation:
          '/service/incidents/manager/INC-42?source=notification&priority=P1',
      routes: [
        GoRoute(
          path: '/service',
          builder: (context, state) => const SizedBox.shrink(),
          routes: buildItsmCompatibilityRoutes(),
        ),
        GoRoute(
          path: ItsmRoutes.root,
          builder: (context, state) => Text(state.location),
          routes: [
            GoRoute(
              path: ':canonicalPath(.*)',
              builder: (context, state) => Text(state.location),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    const expected = '/services/itsm/support/incidents/manager/INC-42'
        '?source=notification&priority=P1';
    expect(router.location, expected);
    expect(find.text(expected), findsOneWidget);
  });

  testWidgets('legacy Incident dashboard redirects to Reporting verbatim',
      (tester) async {
    final router = GoRouter(
      initialLocation:
          '/service/ticketing/dashboard?period=month&service=network#critical',
      routes: [
        GoRoute(
          path: '/service',
          builder: (context, state) => const SizedBox.shrink(),
          routes: buildItsmCompatibilityRoutes(),
        ),
        GoRoute(
          path: ItsmRoutes.root,
          builder: (context, state) => Text(state.location),
          routes: [
            GoRoute(
              path: ':canonicalPath(.*)',
              builder: (context, state) => Text(state.location),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    const expected =
        '/services/itsm/reporting-administration/dashboards/incidents'
        '?period=month&service=network#critical';
    expect(router.location, expected);
    expect(find.text(expected), findsOneWidget);
  });
}
