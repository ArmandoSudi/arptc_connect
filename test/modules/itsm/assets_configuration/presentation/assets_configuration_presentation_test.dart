import 'dart:typed_data';

import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/itsm/assets_configuration/application/assets_configuration_application.dart';
import 'package:arptc_connect/modules/itsm/assets_configuration/data/firestore_assets_configuration_port.dart';
import 'package:arptc_connect/modules/itsm/assets_configuration/domain/asset_assignee.dart';
import 'package:arptc_connect/modules/itsm/assets_configuration/domain/asset_parameter.dart';
import 'package:arptc_connect/modules/itsm/assets_configuration/presentation/assets_configuration_presentation.dart';
import 'package:arptc_connect/modules/itsm/shared/application/itsm_providers.dart';
import 'package:arptc_connect/modules/itsm/shared/data/trusted_command_gateways.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_common.dart';
import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../application/assets_configuration_test_support.dart';

void main() {
  test('stock barcode resolver supports scanners and SKU fallback', () {
    const item = StockItemSummary(
      id: 'item-1',
      name: 'USB-C adapter',
      sku: 'USB-C-01',
      barcode: '620000000001',
      quantity: 2,
      minimumQuantity: 1,
      locationName: 'Main stock',
    );

    expect(findStockItemByBarcode([item], ' 620000000001 '), same(item));
    expect(findStockItemByBarcode([item], 'usb-c-01'), same(item));
    expect(findStockItemByBarcode([item], 'missing'), isNull);
  });

  testWidgets('self-service overview hides every operational destination',
      (tester) async {
    await tester.pumpWidget(
      _app(const AssetsConfigurationOverviewView(canOperate: false)),
    );
    await tester.pumpAndSettle();

    expect(find.text('My Assets'), findsOneWidget);
    expect(find.text('Asset register'), findsNothing);
    expect(find.text('Stock management'), findsNothing);
    expect(find.text('Software licences'), findsNothing);
  });

  testWidgets('manager overview exposes the full operational workspace',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1180, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _app(const AssetsConfigurationOverviewView(canOperate: true)),
    );
    await tester.pumpAndSettle();

    expect(find.text('My Assets'), findsOneWidget);
    expect(find.text('Asset register'), findsOneWidget);
    expect(find.text('Stock management'), findsOneWidget);
    expect(find.text('Software licences'), findsOneWidget);
    expect(find.text('Configuration management database'), findsOneWidget);
  });

  testWidgets('my assets uses a compact card layout on mobile', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _app(
        MyAssetsView(
          assets: [assetSummary()],
          onSelected: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Latitude 7440'), findsOneWidget);
    expect(find.textContaining('ARPTC-001'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('asset register exposes company asset filters and identifiers',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1100, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final selectedAssets = <AssetSummary>[];
    await tester.pumpWidget(
      _app(
        AssetRegisterView(
          assets: const [
            AssetSummary(
              id: 'asset-1',
              assetTag: 'SN-001',
              name: 'Dell Latitude',
              categoryId: 'laptop',
              categoryName: 'Laptop',
              status: AssetLifecycleStatus.inStock,
              brand: 'Dell',
              model: 'Latitude 7450',
              serialNumber: 'SN-001',
              productNumber: 'PN-7450',
              stateName: 'Good',
              isInStock: true,
            ),
          ],
          categoryOptions: const {'laptop': 'Laptop'},
          brandOptions: const ['Dell'],
          onSelected: selectedAssets.add,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Search by serial or product number'), findsOneWidget);
    expect(find.text('Filter by category'), findsOneWidget);
    expect(find.text('Filter by brand'), findsOneWidget);
    expect(find.text('Filter by availability'), findsOneWidget);
    expect(find.text('In stock'), findsOneWidget);
    expect(find.text('SN-001'), findsOneWidget);
    expect(find.text('PN-7450'), findsOneWidget);
    expect(find.text('Good'), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);

    await tester.tap(
      find.descendant(
        of: find.byType(DataTable),
        matching: find.text('In stock'),
      ),
    );
    await tester.pump();
    expect(selectedAssets.map((asset) => asset.id), ['asset-1']);
  });

  testWidgets('asset registration does not require a location', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1100, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final readPort = RecordingAssetsReadPort()
      ..assetParameters = const [
        AssetParameter(
          id: 'category-laptop',
          type: AssetParameterType.category,
          name: 'Laptop',
          isActive: true,
        ),
        AssetParameter(
          id: 'state-good',
          type: AssetParameterType.state,
          name: 'Good',
          isActive: true,
        ),
      ];
    final commandPort = RecordingAssetsCommandPort();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itsmSessionProvider.overrideWith(
            (ref) => Stream.value(assetSession(ItsmRole.manager)),
          ),
          assetsConfigurationReadPortProvider.overrideWithValue(readPort),
          assetsConfigurationCommandPortProvider.overrideWithValue(commandPort),
        ],
        child: _app(
          AssetRegisterScreen(
            onAssetSelected: (_) {},
            onManageParameters: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await _enterField(tester, 'Brand', 'Dell');
    await _enterField(tester, 'Model', 'Latitude 7450');
    await _enterField(tester, 'Serial number', 'SN-LOCATION-OPTIONAL');
    await tester.ensureVisible(find.text('Select a category'));
    await tester.tap(find.text('Select a category'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Laptop').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Select a condition'));
    await tester.tap(find.text('Select a condition'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Good').last);
    await tester.pumpAndSettle();
    final acquisitionDate = tester.widget<CommonTextInput>(
      find.widgetWithText(CommonTextInput, 'Acquisition date'),
    );
    acquisitionDate.controller!.text = '2026-08-14';
    await tester.pump();
    await tester.tap(find.text('Add Asset ID').last);
    await tester.pumpAndSettle();

    final command = commandPort.commands.single as ManagerConfigurationCommand;
    expect(command.fields['serialNumber'], 'SN-LOCATION-OPTIONAL');
    expect(command.fields, isNot(contains('locationId')));
    expect(command.fields, isNot(contains('locationName')));
    expect(command.fields, isNot(contains('assignedUserId')));
    expect(command.fields, isNot(contains('assignedAt')));
  });

  testWidgets('asset registration can optionally assign a searched agent',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 850));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final readPort = RecordingAssetsReadPort()
      ..assetParameters = const [
        AssetParameter(
          id: 'category-laptop',
          type: AssetParameterType.category,
          name: 'Laptop',
          isActive: true,
        ),
        AssetParameter(
          id: 'state-good',
          type: AssetParameterType.state,
          name: 'Good',
          isActive: true,
        ),
      ]
      ..assetAssignees = const [
        AssetAssignee(
          id: 'agent-armando',
          displayName: 'Armando Sudi',
          email: 'armando@arptc.cd',
          departmentId: 'it',
        ),
      ];
    final commandPort = RecordingAssetsCommandPort();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itsmSessionProvider.overrideWith(
            (ref) => Stream.value(assetSession(ItsmRole.manager)),
          ),
          assetsConfigurationReadPortProvider.overrideWithValue(readPort),
          assetsConfigurationCommandPortProvider.overrideWithValue(commandPort),
        ],
        child: _app(
          AssetRegisterScreen(
            onAssetSelected: (_) {},
            onManageParameters: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await _enterField(tester, 'Brand', 'Dell');
    await _enterField(tester, 'Model', 'Latitude 7450');
    await _enterField(tester, 'Serial number', 'SN-DIRECT-ASSIGN');
    await tester.ensureVisible(find.text('Select a category'));
    await tester.tap(find.text('Select a category'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Laptop').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Select a condition'));
    await tester.tap(find.text('Select a condition'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Good').last);
    await tester.pumpAndSettle();
    final acquisitionDate = tester.widget<CommonTextInput>(
      find.widgetWithText(CommonTextInput, 'Acquisition date'),
    );
    acquisitionDate.controller!.text = '2026-08-14';
    await tester.ensureVisible(
      find.widgetWithText(CommonTextInput, 'Search agents'),
    );
    await _enterField(tester, 'Search agents', 'arma');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Armando Sudi').last);
    await tester.pumpAndSettle();

    expect(find.text('Assignment date'), findsOneWidget);
    await tester.ensureVisible(find.text('Add Asset ID').last);
    await tester.tap(find.text('Add Asset ID').last);
    await tester.pumpAndSettle();

    final command = commandPort.commands.single as ManagerConfigurationCommand;
    expect(command.fields['assignedUserId'], 'agent-armando');
    expect(command.fields['assignedAt'], isNotEmpty);
    expect(command.fields, isNot(contains('assignedUserName')));
    expect(command.fields, isNot(contains('assignedUserEmail')));
    expect(command.fields, isNot(contains('status')));
    expect(readPort.assigneeSearches, contains('arma'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('asset register and registration dialog use bounded queries',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1100, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final readPort = RecordingAssetsReadPort();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itsmSessionProvider.overrideWith(
            (ref) => Stream.value(assetSession(ItsmRole.manager)),
          ),
          assetsConfigurationReadPortProvider.overrideWithValue(readPort),
          assetsConfigurationCommandPortProvider.overrideWithValue(
            RecordingAssetsCommandPort(),
          ),
        ],
        child: _app(
          AssetRegisterScreen(
            onAssetSelected: (_) {},
            onManageParameters: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Latitude 7440'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Register a new asset'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('asset parameters screen provides location category state tabs',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final readPort = RecordingAssetsReadPort()
      ..assetParameters = const [
        AssetParameter(
          id: 'location-hq',
          type: AssetParameterType.location,
          name: 'Head office',
          isActive: true,
          revision: 2,
        ),
        AssetParameter(
          id: 'category-laptop',
          type: AssetParameterType.category,
          name: 'Laptop',
          isActive: true,
        ),
        AssetParameter(
          id: 'state-good',
          type: AssetParameterType.state,
          name: 'Good',
          isActive: true,
        ),
      ];
    final commandPort = RecordingAssetsCommandPort();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itsmSessionProvider.overrideWith(
            (ref) => Stream.value(assetSession(ItsmRole.manager)),
          ),
          assetsConfigurationReadPortProvider.overrideWithValue(readPort),
          assetsConfigurationCommandPortProvider.overrideWithValue(commandPort),
        ],
        child: _app(const AssetParametersScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Locations'), findsOneWidget);
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Conditions'), findsOneWidget);
    expect(find.text('Head office'), findsOneWidget);

    await tester.tap(find.text('Categories'));
    await tester.pumpAndSettle();
    expect(find.text('Laptop'), findsOneWidget);
    expect(find.text('Head office'), findsNothing);

    await tester.tap(find.text('Add category'));
    await tester.pumpAndSettle();
    final input = find.descendant(
      of: find.widgetWithText(CommonTextInput, 'Name'),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(input, 'Monitor');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final create = commandPort.commands.single as ManagerConfigurationCommand;
    expect(create.recordId, isEmpty);
    expect(create.fields['type'], 'category');
    expect(create.fields['name'], 'Monitor');

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('Delete parameter?'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    final deletion = commandPort.commands.last as ManagerConfigurationCommand;
    expect(deletion.recordId, 'category-laptop');
    expect(deletion.fields['isActive'], false);
    expect(deletion.fields['expectedRevision'], 0);
  });

  testWidgets('asset parameters explain when the callable is not deployed',
      (tester) async {
    final readPort = RecordingAssetsReadPort();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itsmSessionProvider.overrideWith(
            (ref) => Stream.value(assetSession(ItsmRole.manager)),
          ),
          assetsConfigurationReadPortProvider.overrideWithValue(readPort),
          assetsConfigurationCommandPortProvider.overrideWithValue(
            const _UnavailableAssetsCommandPort(),
          ),
        ],
        child: _app(const AssetParametersScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add location'));
    await tester.pumpAndSettle();
    final input = find.descendant(
      of: find.widgetWithText(CommonTextInput, 'Name'),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(input, 'Head office');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'The asset service is not available on the server. '
        'Deploy the latest Firebase Functions, then try again.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('assignment history distinguishes current and previous owners',
      (tester) async {
    await tester.pumpWidget(
      _app(
        AssetAssignmentHistoryPanel(
          entries: [
            AssetAssignmentHistoryEntry(
              id: 'assignment-2',
              assignedUserName: 'Current Agent',
              assignedAt: DateTime.utc(2026, 8, 1),
              status: 'current',
            ),
            AssetAssignmentHistoryEntry(
              id: 'assignment-1',
              assignedUserName: 'Previous Agent',
              assignedAt: DateTime.utc(2026, 1, 1),
              returnedAt: DateTime.utc(2026, 7, 31),
              status: 'returned',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Assignment history'), findsOneWidget);
    expect(find.text('Current Agent'), findsOneWidget);
    expect(find.text('Previous Agent'), findsOneWidget);
    expect(find.textContaining('Current assignment'), findsOneWidget);
    expect(find.textContaining('Previous assignment'), findsOneWidget);
  });

  testWidgets('state history shows each observation and transition',
      (tester) async {
    await tester.pumpWidget(
      _app(
        AssetStateHistoryPanel(
          entries: [
            AssetStateHistoryEntry(
              id: 'state-event-1',
              fromStateName: 'Good',
              toStateName: 'Repairable',
              observation: 'Battery health is below threshold.',
              actorName: 'Manager One',
              changedAt: DateTime.utc(2026, 8, 14),
              revision: 3,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Condition change history'), findsOneWidget);
    expect(find.text('Good → Repairable'), findsOneWidget);
    expect(find.textContaining('Battery health is below threshold.'),
        findsOneWidget);
  });

  testWidgets('asset detail emits each catalogue navigation intent',
      (tester) async {
    final actions = <AssetCatalogueAction>[];
    await tester.pumpWidget(
      _app(
        SingleChildScrollView(
          child: AssetDetailView(
            detail: assetDetail(),
            isManager: false,
            onCatalogueAction: actions.add,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final label in [
      'Report a fault',
      'Request repair',
      'Request replacement',
      'Request configuration',
      'Request return',
    ]) {
      await tester.scrollUntilVisible(
        find.text(label),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text(label));
    }

    expect(actions, AssetCatalogueAction.values);
  });

  testWidgets('manager asset actions remain usable on a phone viewport',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var editCount = 0;
    var assignCount = 0;
    var returnCount = 0;
    var statusCount = 0;
    var attachmentCount = 0;
    var photographCount = 0;
    await tester.pumpWidget(
      _app(
        SingleChildScrollView(
          child: AssetDetailView(
            detail: assetDetail(),
            isManager: true,
            onEdit: () => editCount += 1,
            onAssign: () => assignCount += 1,
            onReturn: () => returnCount += 1,
            onUpdateStatus: () => statusCount += 1,
            onUploadAttachment: () => attachmentCount += 1,
            onUploadPhotograph: () => photographCount += 1,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final label in [
      'Edit asset',
      'Return asset',
      'Update asset status',
      'Upload attachment',
      'Upload photograph',
    ]) {
      await tester.scrollUntilVisible(
        find.text(label),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text(label));
    }

    expect(
      [
        editCount,
        assignCount,
        returnCount,
        statusCount,
        attachmentCount,
        photographCount,
      ],
      [1, 0, 1, 1, 1, 1],
    );
    expect(find.text('Update condition'), findsNothing);
    expect(find.text('Change lifecycle state'), findsNothing);
    expect(find.text('Decommission asset'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('status hub consolidates condition lifecycle and decommission',
      (tester) async {
    final readPort = _statusReadPort();
    await _pumpManagerAssetDetail(
      tester,
      readPort: readPort,
      commandPort: RecordingAssetsCommandPort(),
    );

    await _openStatusHub(tester);

    expect(find.text('Asset condition'), findsWidgets);
    expect(find.text('Asset lifecycle'), findsOneWidget);
    expect(find.text('Decommission asset'), findsOneWidget);
    expect(find.text('Configured'), findsOneWidget);
    expect(find.text('Maintenance'), findsOneWidget);
    expect(find.text('Assigned'), findsNothing);
    expect(find.text('Returned'), findsNothing);
    expect(find.text('Update condition'), findsNothing);
    expect(find.text('Change lifecycle state'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('status hub uses a centered responsive dialog on desktop',
      (tester) async {
    final readPort = _statusReadPort();
    await _pumpManagerAssetDetail(
      tester,
      readPort: readPort,
      commandPort: RecordingAssetsCommandPort(),
      size: const Size(1200, 900),
    );

    await _openStatusHub(tester);

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Asset condition'), findsWidgets);
    expect(find.text('Asset lifecycle'), findsOneWidget);
    expect(find.text('Decommission asset'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('status hub records a condition change with an observation',
      (tester) async {
    final readPort = _statusReadPort();
    final commandPort = RecordingAssetsCommandPort();
    await _pumpManagerAssetDetail(
      tester,
      readPort: readPort,
      commandPort: commandPort,
    );

    await _openStatusHub(tester);
    await tester.tap(find.text('Asset condition').last);
    await tester.pumpAndSettle();

    expect(find.text('Update condition'), findsOneWidget);
    await tester.tap(find.text('Good').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Damaged').last);
    await tester.pumpAndSettle();
    await _enterField(
      tester,
      'Reason for the condition change',
      'Battery casing is cracked.',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    final command = commandPort.commands.single as AssetOperationalCommand;
    expect(command.operation, 'change_state');
    expect(command.fields['stateId'], 'condition-damaged');
    expect(command.fields['stateName'], 'Damaged');
    expect(command.fields['observation'], 'Battery casing is cracked.');
  });

  testWidgets('status hub exposes only safe lifecycle transitions',
      (tester) async {
    final readPort = _statusReadPort();
    final commandPort = RecordingAssetsCommandPort();
    await _pumpManagerAssetDetail(
      tester,
      readPort: readPort,
      commandPort: commandPort,
    );

    await _openStatusHub(tester);
    await tester.tap(find.text('Asset lifecycle'));
    await tester.pumpAndSettle();

    expect(find.text('Assigned'), findsNothing);
    expect(find.text('Returned'), findsNothing);
    await tester.tap(find.text('Configured'));
    await tester.pumpAndSettle();
    await _enterField(
      tester,
      'Transition reason',
      'Security baseline has been installed.',
    );
    await tester.tap(
      find.widgetWithText(FilledButton, 'Change lifecycle state'),
    );
    await tester.pumpAndSettle();

    final command = commandPort.commands.single as AssetOperationalCommand;
    expect(command.operation, 'transition');
    expect(command.fields['toStatus'], 'configured');
    expect(
      command.fields['reason'],
      'Security baseline has been installed.',
    );
  });

  testWidgets('assigned assets can be reported lost with confirmation',
      (tester) async {
    final readPort = _statusReadPort(
      status: AssetLifecycleStatus.assigned,
      assignedUserName: 'Armando Sudi',
      isInStock: false,
    );
    final commandPort = RecordingAssetsCommandPort();
    await _pumpManagerAssetDetail(
      tester,
      readPort: readPort,
      commandPort: commandPort,
    );

    await _openStatusHub(tester);
    expect(find.text('Lost'), findsOneWidget);
    expect(find.text('Stolen'), findsOneWidget);
    await tester.tap(find.text('Asset lifecycle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lost').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('Confirm exceptional status'), findsOneWidget);
    expect(find.textContaining('current custodian'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
    await tester.pumpAndSettle();
    await _enterField(
      tester,
      'Transition reason',
      'Custodian reported the laptop missing.',
    );
    await tester.tap(
      find.widgetWithText(FilledButton, 'Change lifecycle state'),
    );
    await tester.pumpAndSettle();

    final command = commandPort.commands.single as AssetOperationalCommand;
    expect(command.operation, 'transition');
    expect(command.fields['toStatus'], 'lost');
    expect(
      command.fields['reason'],
      'Custodian reported the laptop missing.',
    );
  });

  testWidgets('status hub keeps decommissioning destructive and confirmed',
      (tester) async {
    final readPort = _statusReadPort();
    final commandPort = RecordingAssetsCommandPort();
    await _pumpManagerAssetDetail(
      tester,
      readPort: readPort,
      commandPort: commandPort,
    );

    await _openStatusHub(tester);
    await tester.ensureVisible(find.text('Decommission asset'));
    await tester.tap(find.text('Decommission asset'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining("This ends the asset's active lifecycle"),
      findsOneWidget,
    );
    await _enterField(
      tester,
      'Decommissioning reason and observation',
      'Repair is no longer economically viable.',
    );
    await tester.tap(find.byIcon(Icons.inventory_2_outlined).last);
    await tester.pumpAndSettle();

    final command = commandPort.commands.single as AssetOperationalCommand;
    expect(command.operation, 'decommission');
    expect(
      command.fields['observation'],
      'Repair is no longer economically viable.',
    );
  });

  testWidgets('self-service detail callback never executes asset command',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final readPort = RecordingAssetsReadPort();
    final commandPort = RecordingAssetsCommandPort();
    AssetCatalogueAction? selectedAction;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itsmSessionProvider.overrideWith(
            (ref) => Stream.value(assetSession(ItsmRole.admin)),
          ),
          assetsConfigurationReadPortProvider.overrideWithValue(readPort),
          assetsConfigurationCommandPortProvider.overrideWithValue(commandPort),
        ],
        child: _app(
          AssetDetailScreen(
            assetId: 'asset-1',
            selfService: true,
            onCatalogueAction: (_, action) => selectedAction = action,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Report a fault'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Report a fault'));

    expect(selectedAction, AssetCatalogueAction.reportFault);
    expect(commandPort.commands, isEmpty);
  });

  testWidgets('stock view and CMDB dependency view fit a mobile viewport',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const root = ConfigurationItemSummary(
      id: 'ci-1',
      name: 'ERP service',
      typeName: 'service',
      criticality: 'high',
      operationalStatus: 'active',
    );
    await tester.pumpWidget(
      _app(
        SingleChildScrollView(
          child: Column(
            children: [
              StockWorkspaceView(
                items: const [
                  StockItemSummary(
                    id: 'item-1',
                    name: 'USB-C adapter',
                    sku: 'USB-C-01',
                    quantity: 2,
                    minimumQuantity: 5,
                    locationName: 'Main stock',
                  ),
                ],
                movements: const [],
                onRecordMovement: (_) {},
              ),
              ConfigurationDependencyViewWidget(
                view: ConfigurationDependencyView(root: root),
                onClose: () {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Low stock'), findsWidgets);
    expect(find.text('ERP service'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('stock scanner opens the matched item movement workflow',
      (tester) async {
    await tester.pumpWidget(
      _app(
        SingleChildScrollView(
          child: StockWorkspaceView(
            items: const [
              StockItemSummary(
                id: 'item-1',
                name: 'USB-C adapter',
                sku: 'USB-C-01',
                barcode: '620000000001',
                quantity: 2,
                minimumQuantity: 1,
                locationName: 'Main stock',
              ),
            ],
            movements: const [],
            onRecordMovement: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scan barcode'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '620000000001');
    await tester.tap(find.text('Select'));
    await tester.pumpAndSettle();

    expect(find.text('Add Stock movements: USB-C adapter'), findsOneWidget);
  });

  testWidgets('stock screen sends adjustments through the evidence-aware port',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final readPort = RecordingAssetsReadPort()
      ..stockItems = const [
        StockItemSummary(
          id: 'item-1',
          name: 'USB-C adapter',
          sku: 'USB-C-01',
          barcode: '620000000001',
          quantity: 4,
          minimumQuantity: 1,
          locationName: 'Main stock',
        ),
      ];
    final commandPort = RecordingAssetsCommandPort();
    final gateway = _RecordingAttachmentGateway();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itsmSessionProvider.overrideWith(
            (ref) => Stream.value(assetSession(ItsmRole.manager)),
          ),
          assetsConfigurationReadPortProvider.overrideWithValue(readPort),
          assetsConfigurationCommandPortProvider.overrideWithValue(commandPort),
          assetsAttachmentGatewayProvider.overrideWithValue(gateway),
        ],
        child: _app(
          StockScreen(
            attachmentPicker: const _PickedEvidenceFile(),
            attachmentIdFactory: () => 'evidence-1',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.swap_horiz_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Receipt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adjustment').last);
    await tester.pumpAndSettle();
    await _enterField(tester, 'Quantity', '2');
    await _enterField(tester, 'Source location', 'main-store');
    await tester.tap(find.byIcon(Icons.upload_file_outlined));
    await tester.pumpAndSettle();
    await _enterField(tester, 'Movement reason', 'Physical count correction.');
    await tester.tap(find.text('Add Stock movements'));
    await tester.pumpAndSettle();

    expect(gateway.requests.single.parentId, 'item-1');
    final command = commandPort.commands.single as StockMovementCommand;
    expect(command.type, StockMovementType.adjustment);
    expect(command.adjustmentDelta, 2);
    expect(command.supportingDocumentId, 'evidence-1');
    expect(command.reason, 'Physical count correction.');
  });
}

RecordingAssetsReadPort _statusReadPort({
  AssetLifecycleStatus status = AssetLifecycleStatus.inStock,
  String assignedUserName = '',
  bool isInStock = true,
}) {
  return RecordingAssetsReadPort()
    ..detail = AssetDetail(
      summary: AssetSummary(
        id: 'asset-1',
        assetTag: 'ARPTC-001',
        name: 'Latitude 7440',
        categoryName: 'Laptop',
        status: status,
        brand: 'Dell',
        model: 'Latitude 7440',
        serialNumber: 'SN-001',
        stateName: 'Good',
        assignedUserName: assignedUserName,
        isInStock: isInStock,
      ),
      stateName: 'Good',
    )
    ..assetParameters = const [
      AssetParameter(
        id: 'condition-good',
        type: AssetParameterType.state,
        name: 'Good',
        isActive: true,
      ),
      AssetParameter(
        id: 'condition-damaged',
        type: AssetParameterType.state,
        name: 'Damaged',
        isActive: true,
      ),
    ];
}

Future<void> _pumpManagerAssetDetail(
  WidgetTester tester, {
  required RecordingAssetsReadPort readPort,
  required RecordingAssetsCommandPort commandPort,
  Size size = const Size(390, 900),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        itsmSessionProvider.overrideWith(
          (ref) => Stream.value(assetSession(ItsmRole.manager)),
        ),
        assetsConfigurationReadPortProvider.overrideWithValue(readPort),
        assetsConfigurationCommandPortProvider.overrideWithValue(commandPort),
      ],
      child: _app(
        const AssetDetailScreen(
          assetId: 'asset-1',
          selfService: false,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openStatusHub(WidgetTester tester) async {
  await tester.drag(
    find.byType(CustomScrollView),
    const Offset(0, -900),
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Update asset status'));
  await tester.tap(find.text('Update asset status'));
  await tester.pumpAndSettle();
}

Future<void> _enterField(
  WidgetTester tester,
  String label,
  String value,
) async {
  final input = find.descendant(
    of: find.ancestor(
      of: find.text(label),
      matching: find.byType(CommonTextInput),
    ),
    matching: find.byType(TextFormField),
  );
  await tester.enterText(input, value);
}

class _PickedEvidenceFile implements AssetsAttachmentFilePicker {
  const _PickedEvidenceFile();

  @override
  Future<AssetsPickedFile?> pick({required bool imagesOnly}) async {
    return AssetsPickedFile(
      fileName: 'count.pdf',
      contentType: 'application/pdf',
      bytes: Uint8List.fromList([1, 2, 3]),
    );
  }
}

class _RecordingAttachmentGateway implements AssetsAttachmentGateway {
  final requests = <AssetsAttachmentUploadRequest>[];

  @override
  Future<AssetsAttachmentUploadResult> uploadAndAwaitRegistration(
    AssetsAttachmentUploadRequest request,
  ) async {
    requests.add(request);
    return AssetsAttachmentUploadResult(
      attachmentId: request.attachmentId,
      storagePath: request.storagePath,
      fileName: request.safeFileName,
      kind: request.kind,
    );
  }
}

class _UnavailableAssetsCommandPort implements AssetsConfigurationCommandPort {
  const _UnavailableAssetsCommandPort();

  @override
  Future<ItsmCommandReceipt> execute(AssetsConfigurationCommand command) =>
      Future.error(
        const AssetsConfigurationCommandException(
          code: 'internal',
          message: 'internal',
        ),
      );
}

Widget _app(Widget child) {
  return ResponsiveBreakpoints.builder(
    breakpoints: const [
      Breakpoint(start: 0, end: 450, name: 'MOBILE'),
      Breakpoint(start: 451, end: 960, name: 'TABLET'),
      Breakpoint(start: 961, end: double.infinity, name: 'DESKTOP'),
    ],
    child: MaterialApp(
      localizationsDelegates: const [S.delegate],
      supportedLocales: S.delegate.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}
