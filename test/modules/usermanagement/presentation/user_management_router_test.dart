import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/authentication/application/authorized_session.dart';
import 'package:arptc_connect/modules/authentication/providers/authentication_provider.dart';
import 'package:arptc_connect/modules/authentication/providers/authorized_session_provider.dart';
import 'package:arptc_connect/modules/notifications/presentation/controllers/notification_providers.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_access.dart';
import 'package:arptc_connect/modules/usermanagement/domain/unplaced_agent_summary.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/controllers/management_providers.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/screens/agent_directory_screen.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/screens/organizations_screen.dart';
import 'package:arptc_connect/router.dart';
import 'package:arptc_connect/widgets/error_state_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';

final _testRoleProvider = StateProvider<UserManagementRole>(
  (ref) => UserManagementRole.none,
);

void main() {
  group('actual UserManagement GoRouter landing behavior', () {
    testWidgets('USER lands on the safe Agents directory', (tester) async {
      final harness = await _pumpRouter(
        tester,
        role: UserManagementRole.user,
        location: '/service/usermanagement',
      );

      expect(harness.router.location, '/service/usermanagement/agents');
      expect(find.byType(AgentDirectoryScreen), findsOneWidget);
      expect(find.byType(ErrorStateView), findsNothing);
    });

    testWidgets('MANAGER lands on Organizations with mutation controls',
        (tester) async {
      final harness = await _pumpRouter(
        tester,
        role: UserManagementRole.manager,
        location: '/service/usermanagement',
      );

      expect(harness.router.location, '/service/usermanagement/organizations');
      expect(find.byType(OrganizationsScreen), findsOneWidget);
      expect(find.byIcon(Icons.add_business_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);
    });

    testWidgets('ADMIN lands on Organizations in read-only mode',
        (tester) async {
      final harness = await _pumpRouter(
        tester,
        role: UserManagementRole.admin,
        location: '/service/usermanagement',
      );

      expect(harness.router.location, '/service/usermanagement/organizations');
      expect(find.byType(OrganizationsScreen), findsOneWidget);
      expect(find.byIcon(Icons.add_business_outlined), findsNothing);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });

    testWidgets('NONE is denied after the fail-closed Agents landing',
        (tester) async {
      final harness = await _pumpRouter(
        tester,
        role: UserManagementRole.none,
        location: '/service/usermanagement',
      );

      expect(harness.router.location, '/service/usermanagement/agents');
      expect(find.byType(ErrorStateView), findsOneWidget);
      expect(find.byType(AgentDirectoryScreen), findsNothing);
    });
  });

  testWidgets('USER deep links cannot build private UserManagement screens',
      (tester) async {
    final harness = await _pumpRouter(
      tester,
      role: UserManagementRole.user,
      location: '/service/usermanagement/organizations',
    );
    const privateLocations = [
      '/service/usermanagement/organizations',
      '/service/usermanagement/organizations/org-a',
      '/service/usermanagement/organizations/org-a/audit',
      '/service/usermanagement/structure',
      '/service/usermanagement/structure/unit-a?organizationId=org-a',
      '/service/usermanagement/agents/agent-b',
      '/service/usermanagement/modules',
      '/service/usermanagement/modules/module-a',
    ];

    for (final location in privateLocations) {
      harness.router.go(location);
      await tester.pumpAndSettle();

      expect(harness.router.location, location, reason: location);
      expect(find.byType(ErrorStateView), findsOneWidget, reason: location);
      expect(find.byType(OrganizationsScreen), findsNothing, reason: location);
    }
  });

  testWidgets('legacy and malformed UserManagement routes converge safely',
      (tester) async {
    final harness = await _pumpRouter(
      tester,
      role: UserManagementRole.user,
      location: '/service/usermanagement/departments',
    );

    expect(harness.router.location, '/service/usermanagement/structure');
    expect(find.byType(ErrorStateView), findsOneWidget);

    for (final legacy in const ['services', 'bureaux']) {
      harness.router.go('/service/usermanagement/$legacy');
      await tester.pumpAndSettle();
      expect(harness.router.location, '/service/usermanagement/structure');
      expect(find.byType(ErrorStateView), findsOneWidget);
    }

    harness.router.go('/service/usermanagement/structure/unit-a');
    await tester.pumpAndSettle();
    expect(harness.router.location, '/service/usermanagement/structure');
    expect(find.byType(ErrorStateView), findsOneWidget);

    harness.router.go('/service/usermanagement/agents/add');
    await tester.pumpAndSettle();
    expect(harness.router.location, '/service/usermanagement/agents');
    expect(find.byType(AgentDirectoryScreen), findsOneWidget);
  });

  testWidgets('a mounted private route fails closed after role revocation',
      (tester) async {
    final harness = await _pumpRouter(
      tester,
      role: UserManagementRole.manager,
      location: '/service/usermanagement/organizations',
    );

    expect(find.byType(OrganizationsScreen), findsOneWidget);
    harness.container.read(_testRoleProvider.notifier).state =
        UserManagementRole.user;
    await tester.pumpAndSettle();

    expect(
      harness.router.location,
      '/service/usermanagement/organizations',
    );
    expect(find.byType(ErrorStateView), findsOneWidget);
    expect(find.byType(OrganizationsScreen), findsNothing);
  });
}

Future<_RouterHarness> _pumpRouter(
  WidgetTester tester, {
  required UserManagementRole role,
  required String location,
}) async {
  tester.view.physicalSize =
      role == UserManagementRole.manager || role == UserManagementRole.admin
          ? const Size(1920, 1200)
          : const Size(800, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final roleValue = role.name.toUpperCase();
  final profile = <String, dynamic>{
    'id': 'agent-test',
    'email': 'agent@example.com',
    'emailLower': 'agent@example.com',
    'firstName': 'Test',
    'name': 'Agent',
    'isActive': true,
    'organizationId': 'org-a',
    'modulePermissions': {'usermanagement': roleValue},
  };
  final session = AuthorizedSession(
    sessionKey: 'agent-test|agent@example.com',
    userId: 'agent-test',
    email: 'agent@example.com',
    displayName: 'Test Agent',
    profile: profile,
    modulePermissions: {'usermanagement': roleValue},
  );
  final container = ProviderContainer(
    overrides: [
      _testRoleProvider.overrideWith((ref) => role),
      authStateProvider.overrideWith(
        (ref) => Stream<User?>.value(const _FakeFirebaseUser()),
      ),
      authorizedSessionProvider.overrideWithValue(
        AuthorizedSessionState.authenticated(session),
      ),
      authorizedAgentProfileProvider.overrideWithValue(
        AsyncValue.data(profile),
      ),
      userManagementAccessPolicyProvider.overrideWith(
        (ref) => UserManagementAccessPolicy(
          ref.watch(_testRoleProvider),
        ),
      ),
      notificationUnreadCountProvider.overrideWithValue(
        const AsyncValue.data(0),
      ),
      umOrganizationsProvider.overrideWith(
        (ref) => Stream.value(const <Organization>[]),
      ),
      umFilteredOrganizationsProvider.overrideWith(
        (ref, query) => Stream.value(const <Organization>[]),
      ),
      umUnplacedAgentsProvider.overrideWith(
        (ref) async => const UnplacedAgentPage(
          items: <UnplacedAgentSummary>[],
          nextCursor: null,
          scannedCount: 0,
        ),
      ),
    ],
  );
  await container.read(authStateProvider.future);
  final router = container.read(goRouterProvider);
  router.go(location);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: ResponsiveBreakpoints.builder(
        breakpoints: const [
          Breakpoint(start: 0, end: 450, name: 'MOBILE'),
          Breakpoint(start: 451, end: 960, name: 'TABLET'),
          Breakpoint(start: 961, end: double.infinity, name: 'DESKTOP'),
        ],
        child: MaterialApp.router(
          locale: const Locale('en'),
          localizationsDelegates: const [S.delegate],
          supportedLocales: S.delegate.supportedLocales,
          routerConfig: router,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(() {
    router.dispose();
    container.dispose();
  });
  return _RouterHarness(router, container);
}

class _RouterHarness {
  const _RouterHarness(this.router, this.container);

  final GoRouter router;
  final ProviderContainer container;
}

class _FakeFirebaseUser implements User {
  const _FakeFirebaseUser();

  @override
  String get uid => 'agent-test';

  @override
  String? get email => null;

  @override
  bool get emailVerified => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
