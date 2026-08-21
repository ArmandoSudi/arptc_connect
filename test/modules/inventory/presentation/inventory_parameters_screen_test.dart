import 'package:arptc_connect/core/theme.dart';
import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/inventory/application/inventory_contracts.dart';
import 'package:arptc_connect/modules/inventory/application/inventory_providers.dart';
import 'package:arptc_connect/modules/inventory/application/inventory_session.dart';
import 'package:arptc_connect/modules/inventory/domain/inventory_domain.dart';
import 'package:arptc_connect/modules/inventory/presentation/screens/inventory_parameters_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';

void main() {
  testWidgets('warehouse list remains scrollable and create dialog validates',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final gateway = _RecordingCommandGateway();
    await tester.pumpWidget(_parametersApp(gateway));
    await tester.pumpAndSettle();

    expect(find.text('Warehouse 0'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(_filledButtonWithText('Add parameter'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Code'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Address'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pump();
    expect(find.text('This field is required.'), findsNWidgets(2));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'CENTRAL');
    await tester.enterText(fields.at(1), 'Central warehouse');
    await tester.enterText(fields.at(2), 'Head office');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(gateway.commands, hasLength(1));
    expect(
        gateway.commands.single.functionName, InventoryCommands.saveWarehouse);
    expect(gateway.commands.single.payload['name'], 'Central warehouse');
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all parameter tabs keep their add actions interactive',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_parametersApp(_RecordingCommandGateway()));
    await tester.pumpAndSettle();

    for (final tab in const [
      'Warehouses',
      'Locations',
      'Categories',
      'Units of measure',
      'Item types',
      'Operational reasons',
    ]) {
      await tester.tap(find.text(tab).first);
      await tester.pumpAndSettle();
      await tester.tap(_filledButtonWithText('Add parameter'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget, reason: tab);
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: tab);
    }
  });

  testWidgets('category, unit, and item type submit their canonical types',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final gateway = _RecordingCommandGateway();
    await tester.pumpWidget(_parametersApp(gateway));
    await tester.pumpAndSettle();

    for (final entry in const [
      ('Categories', 'Office supplies', 'category'),
      ('Units of measure', 'Box', 'unit_of_measure'),
      ('Item types', 'Consumable', 'item_type'),
    ]) {
      await tester.tap(find.text(entry.$1).first);
      await tester.pumpAndSettle();
      await tester.tap(_filledButtonWithText('Add parameter'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), entry.$2);
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      final command = gateway.commands.last;
      expect(command.functionName, InventoryCommands.saveParameter);
      expect(command.payload['type'], entry.$3);
      expect(command.payload['name'], entry.$2);
    }

    expect(gateway.commands, hasLength(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile parameter header keeps the add action visible',
      (tester) async {
    tester.view.physicalSize = const Size(390, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_parametersApp(_RecordingCommandGateway()));
    await tester.pumpAndSettle();

    final addButton = _filledButtonWithText('Add parameter');
    expect(addButton, findsOneWidget);
    expect(tester.getRect(addButton).right, lessThanOrEqualTo(390));

    await tester.tap(addButton);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Finder _filledButtonWithText(String label) => find.ancestor(
      of: find.text(label),
      matching: find.byWidgetPredicate((widget) => widget is FilledButton),
    );

Widget _parametersApp(_RecordingCommandGateway gateway) => ProviderScope(
      overrides: [
        inventorySessionProvider.overrideWithValue(
          const AsyncData(
            InventorySession(
              sessionKey: 'manager-1|manager@example.com',
              userId: 'manager-1',
              email: 'manager@example.com',
              displayName: 'Inventory Manager',
              role: InventoryRole.manager,
              profile: {},
            ),
          ),
        ),
        inventoryRepositoryProvider.overrideWithValue(
          const _ParametersRepository(),
        ),
        inventoryCommandControllerProvider.overrideWith(
          (ref) => InventoryCommandController(
            gateway: gateway,
            isAuthorized: true,
          ),
        ),
        inventoryCommandIdFactoryProvider.overrideWithValue(() => 'command-1'),
      ],
      child: ResponsiveBreakpoints.builder(
        breakpoints: const [
          Breakpoint(start: 0, end: 450, name: MOBILE),
          Breakpoint(start: 451, end: 960, name: TABLET),
          Breakpoint(start: 961, end: double.infinity, name: DESKTOP),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: S.delegate.supportedLocales,
          localizationsDelegates: const [S.delegate],
          theme: CorporateBlueTheme.light,
          home: const InventoryParametersScreen(),
        ),
      ),
    );

class _RecordingCommandGateway implements InventoryCommandGateway {
  final commands = <InventoryCommand>[];

  @override
  Future<InventoryCommandResult> execute(InventoryCommand command) async {
    commands.add(command);
    return InventoryCommandResult(
      commandId: command.commandId,
      entityId: 'warehouse-1',
      wasReplay: false,
    );
  }
}

class _ParametersRepository implements InventoryReadRepository {
  const _ParametersRepository();

  @override
  Stream<List<InventoryWarehouse>> watchWarehouses({bool activeOnly = false}) {
    final values = List.generate(
      30,
      (index) => InventoryWarehouse(
        id: 'warehouse-$index',
        code: 'WH-$index',
        name: 'Warehouse $index',
        address: 'Address $index',
        isActive: true,
      ),
    );
    return Stream.value(values);
  }

  @override
  Stream<List<InventoryLocation>> watchLocations({String warehouseId = ''}) =>
      Stream.value(const []);

  @override
  Stream<List<InventoryParameter>> watchParameters(
    InventoryParameterType type,
  ) =>
      Stream.value(const []);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
