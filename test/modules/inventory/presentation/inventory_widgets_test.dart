import 'package:arptc_connect/core/theme.dart';
import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/inventory/application/inventory_providers.dart';
import 'package:arptc_connect/modules/inventory/application/inventory_contracts.dart';
import 'package:arptc_connect/modules/inventory/application/inventory_session.dart';
import 'package:arptc_connect/modules/inventory/domain/inventory_domain.dart';
import 'package:arptc_connect/modules/inventory/presentation/screens/admin_inventory_dashboard_screen.dart';
import 'package:arptc_connect/modules/inventory/presentation/screens/inventory_dashboard_router.dart';
import 'package:arptc_connect/modules/inventory/presentation/screens/manager_inventory_dashboard_screen.dart';
import 'package:arptc_connect/modules/inventory/presentation/screens/user_inventory_home_screen.dart';
import 'package:arptc_connect/modules/inventory/presentation/widgets/inventory_bar_chart.dart';
import 'package:arptc_connect/modules/inventory/presentation/widgets/inventory_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';

void main() {
  testWidgets(
      'request status badges expose localized labels and distinct icons',
      (tester) async {
    const expectations = <MaterialRequestStatus, (String, IconData)>{
      MaterialRequestStatus.submitted: ('Submitted', Icons.send_rounded),
      MaterialRequestStatus.underReview: (
        'Under review',
        Icons.manage_search_rounded
      ),
      MaterialRequestStatus.adjusted: ('Adjusted', Icons.tune_rounded),
      MaterialRequestStatus.readyForIssue: (
        'Ready for issue',
        Icons.inventory_2_outlined
      ),
      MaterialRequestStatus.partiallyFulfilled: (
        'Partially fulfilled',
        Icons.pending_actions_rounded
      ),
      MaterialRequestStatus.awaitingConfirmation: (
        'Awaiting receipt confirmation',
        Icons.fact_check_outlined
      ),
      MaterialRequestStatus.fulfilled: (
        'Fulfilled',
        Icons.check_circle_rounded
      ),
      MaterialRequestStatus.closedShort: (
        'Closed short',
        Icons.remove_circle_outline_rounded
      ),
      MaterialRequestStatus.cancelled: ('Cancelled', Icons.cancel_outlined),
      MaterialRequestStatus.rejected: ('Rejected', Icons.block_rounded),
    };

    for (final entry in expectations.entries) {
      await tester.pumpWidget(
        _app(InventoryRequestStatusBadge(entry.key)),
      );
      await tester.pumpAndSettle();

      expect(find.text(entry.value.$1), findsOneWidget, reason: entry.key.name);
      expect(find.byIcon(entry.value.$2), findsOneWidget,
          reason: entry.key.name);
    }
  });

  testWidgets('availability badges communicate all safe catalogue states',
      (tester) async {
    await tester.pumpWidget(
      _app(
        const Wrap(
          children: [
            InventoryAvailabilityBadge(InventoryAvailability.available),
            InventoryAvailabilityBadge(InventoryAvailability.limited),
            InventoryAvailabilityBadge(InventoryAvailability.unavailable),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Available'), findsOneWidget);
    expect(find.text('Limited availability'), findsOneWidget);
    expect(find.text('Currently unavailable'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
  });

  testWidgets('bar chart handles empty and zero-only data', (tester) async {
    await tester.pumpWidget(
      _app(
        const SizedBox(
          width: 500,
          child: InventoryBarChart(
            title: 'Requests by status',
            data: {'submitted': 0, 'fulfilled': 0},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Requests by status'), findsOneWidget);
    expect(find.text('No data available'), findsOneWidget);
    expect(find.text('submitted'), findsNothing);
  });

  testWidgets('bar chart renders positive values and ignores zero values',
      (tester) async {
    await tester.pumpWidget(
      _app(
        const SizedBox(
          width: 500,
          child: InventoryBarChart(
            title: 'Requests by status',
            data: {'submitted': 4, 'fulfilled': 2, 'cancelled': 0},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('submitted'), findsOneWidget);
    expect(find.text('fulfilled'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('cancelled'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard router fails closed for a missing Inventory role',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventorySessionProvider.overrideWithValue(
            const AsyncData(
              InventorySession(
                sessionKey: 'agent-1|agent@example.com',
                userId: 'agent-1',
                email: 'agent@example.com',
                displayName: 'Test Agent',
                role: InventoryRole.none,
                profile: {},
              ),
            ),
          ),
        ],
        child: _app(const InventoryDashboardRouter()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(InventoryAccessDeniedScreen), findsOneWidget);
    expect(find.text('You do not have access to Inventory.'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
  });

  for (final scenario in const [
    (InventoryRole.user, UserInventoryHomeScreen),
    (InventoryRole.manager, ManagerInventoryDashboardScreen),
    (InventoryRole.admin, AdminInventoryDashboardScreen),
  ]) {
    testWidgets('dashboard router selects the ${scenario.$1.value} screen',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inventorySessionProvider.overrideWithValue(
              AsyncData(_session(scenario.$1)),
            ),
            inventoryRepositoryProvider.overrideWithValue(
              const _EmptyInventoryRepository(),
            ),
          ],
          child: _app(const InventoryDashboardRouter()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(scenario.$2), findsOneWidget);
      expect(find.byType(InventoryAccessDeniedScreen), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}

Widget _app(Widget child) => ResponsiveBreakpoints.builder(
      breakpoints: const [
        Breakpoint(start: 0, end: 450, name: 'MOBILE'),
        Breakpoint(start: 451, end: 960, name: 'TABLET'),
        Breakpoint(start: 961, end: double.infinity, name: 'DESKTOP'),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('en'), Locale('fr')],
        localizationsDelegates: const [S.delegate],
        theme: CorporateBlueTheme.light,
        home: Scaffold(body: Center(child: child)),
      ),
    );

InventorySession _session(InventoryRole role) => InventorySession(
      sessionKey: 'agent-1|agent@example.com',
      userId: 'agent-1',
      email: 'agent@example.com',
      displayName: 'Test Agent',
      role: role,
      profile: const {},
    );

class _EmptyInventoryRepository implements InventoryReadRepository {
  const _EmptyInventoryRepository();

  @override
  Stream<List<InventoryCatalogueItem>> watchCatalogue(
    InventoryCatalogueQuery query,
  ) =>
      Stream.value(const []);

  @override
  Stream<InventoryDashboardStats> watchDashboard(InventoryRole role) =>
      Stream.value(InventoryDashboardStats.empty);

  @override
  Stream<List<InventoryStockMovement>> watchMovements({
    String itemId = '',
    String requestId = '',
    int limit = 100,
  }) =>
      Stream.value(const []);

  @override
  Stream<List<MaterialRequest>> watchRequests(
    InventorySession session,
    InventoryRequestQuery query,
  ) =>
      Stream.value(const []);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
