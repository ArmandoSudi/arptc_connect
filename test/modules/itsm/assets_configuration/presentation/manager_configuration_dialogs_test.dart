import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/itsm/assets_configuration/application/assets_configuration_application.dart';
import 'package:arptc_connect/modules/itsm/assets_configuration/domain/asset_assignee.dart';
import 'package:arptc_connect/modules/itsm/assets_configuration/presentation/assets_configuration_presentation.dart';
import 'package:arptc_connect/modules/itsm/shared/application/itsm_providers.dart';
import 'package:arptc_connect/modules/itsm/shared/data/trusted_command_gateways.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_common.dart';
import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../application/assets_configuration_test_support.dart';

void main() {
  testWidgets('asset assignment searches agents and submits the selected UID',
      (tester) async {
    final commandPort = RecordingAssetsCommandPort();
    final readPort = RecordingAssetsReadPort()
      ..assetAssignees = const [
        AssetAssignee(
          id: 'agent-alice',
          displayName: 'Alice Kabwe',
          email: 'alice@arptc.cd',
        ),
        AssetAssignee(
          id: 'agent-armando',
          displayName: 'Armando Sudi',
          email: 'armando@arptc.cd',
          departmentId: 'it',
        ),
      ];
    await tester.pumpWidget(
      _specificDialogApp(
        commandPort,
        readPort: readPort,
        onPressed: (context, ref) => showAssignAssetToAgentDialog(
          context,
          ref,
          assetDetail(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open dialog'));
    await tester.pumpAndSettle();
    final searchField = find.widgetWithText(TextFormField, 'Search agents');
    expect(searchField, findsOneWidget);
    await tester.enterText(searchField, 'arma');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Armando Sudi').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Assign asset').last);
    await tester.pumpAndSettle();

    final command = commandPort.commands.single as AssetOperationalCommand;
    expect(command.operation, 'assign');
    expect(command.fields['assignedUserId'], 'agent-armando');
    expect(command.fields['departmentId'], 'it');
    expect(command.fields, isNot(contains('assignedUserName')));
    expect(readPort.assigneeSearches, contains('arma'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('asset assignment sends only the selected agent UID',
      (tester) async {
    final commandPort = RecordingAssetsCommandPort();
    await tester.pumpWidget(
      _specificDialogApp(
        commandPort,
        onPressed: (context, ref) => showAssignAssetDialog(
          context,
          ref,
          assetDetail(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open dialog'));
    await tester.pumpAndSettle();
    await _enter(tester, 'Assigned agent UID', 'agent-42');
    await tester.tap(find.text('Assign asset').last);
    await tester.pumpAndSettle();

    final command = commandPort.commands.single as AssetOperationalCommand;
    expect(command.operation, 'assign');
    expect(command.assetId, 'asset-1');
    expect(command.fields['assignedUserId'], 'agent-42');
    expect(command.fields, isNot(contains('assignedUserName')));
    expect(command.fields, isNot(contains('assignedUserEmail')));
  });

  testWidgets('lifecycle dialog exposes only valid next states',
      (tester) async {
    final commandPort = RecordingAssetsCommandPort();
    await tester.pumpWidget(
      _specificDialogApp(
        commandPort,
        onPressed: (context, ref) => showAssetLifecycleTransitionDialog(
          context,
          ref,
          AssetDetail(
            summary: const AssetSummary(
              id: 'asset-1',
              assetTag: 'ARPTC-001',
              name: 'Laptop',
              categoryName: 'Computer',
              status: AssetLifecycleStatus.planned,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open dialog'));
    await tester.pumpAndSettle();
    expect(find.text('Ordered'), findsOneWidget);
    expect(find.text('Retired'), findsNothing);
    expect(find.text('Assigned'), findsNothing);
    expect(find.text('Disposed'), findsNothing);

    await tester.tap(find.text('Ordered'));
    await tester.pumpAndSettle();
    await _enter(tester, 'Transition reason', 'Purchase order approved.');
    await tester.tap(find.text('Change lifecycle state').last);
    await tester.pumpAndSettle();

    final command = commandPort.commands.single as AssetOperationalCommand;
    expect(command.operation, 'transition');
    expect(command.fields['toStatus'], 'ordered');
    expect(command.fields['reason'], 'Purchase order approved.');
  });

  testWidgets('stock master dialogs emit location and item save commands',
      (tester) async {
    final commandPort = RecordingAssetsCommandPort();
    await tester.pumpWidget(
      _specificDialogApp(
        commandPort,
        onPressed: (context, ref) => showSaveStockLocationDialog(context, ref),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open dialog'));
    await tester.pumpAndSettle();
    await _enter(tester, 'Stock location ID', 'main-store');
    await _enter(tester, 'Name', 'Main store');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    var command = commandPort.commands.single as ManagerConfigurationCommand;
    expect(command.recordType, 'stock_location');
    expect(command.operation, 'save');
    expect(command.recordId, 'main-store');

    await tester.pumpWidget(
      _specificDialogApp(
        commandPort,
        onPressed: (context, ref) => showSaveStockItemDialog(
          context,
          ref,
          item: const StockItemSummary(
            id: 'adapter',
            name: 'USB-C adapter',
            sku: 'USB-C-01',
            quantity: 4,
            minimumQuantity: 2,
            locationName: 'main-store',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open dialog'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    command = commandPort.commands.last as ManagerConfigurationCommand;
    expect(command.recordType, 'stock_item');
    expect(command.recordId, 'adapter');
    expect(command.fields['minimumQuantity'], 2);
  });

  testWidgets('stock adjustment captures direction and mandatory evidence',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    StockMovementDraft? captured;
    final commandPort = RecordingAssetsCommandPort();
    await tester.pumpWidget(
      _specificDialogApp(
        commandPort,
        onPressed: (context, ref) => showStockMovementDialog(
          context,
          const StockItemSummary(
            id: 'adapter',
            name: 'USB-C adapter',
            sku: 'USB-C-01',
            quantity: 4,
            minimumQuantity: 2,
            locationName: 'main-store',
          ),
          (draft) => captured = draft,
          onUploadSupportingDocument: (_) async => 'evidence-7',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open dialog'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Receipt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adjustment').last);
    await tester.pumpAndSettle();
    await _enter(tester, 'Quantity', '3');
    await tester.tap(find.text('Increase stock'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Decrease stock').last);
    await _enter(tester, 'Source location', 'main-store');
    await tester.ensureVisible(find.byIcon(Icons.upload_file_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.upload_file_outlined));
    await tester.pumpAndSettle();
    await _enter(tester, 'Movement reason', 'Physical count correction.');
    await tester.tap(find.text('Add Stock movements'));
    await tester.pumpAndSettle();

    expect(captured, isNotNull);
    expect(captured!.type, StockMovementType.adjustment);
    expect(captured!.adjustmentDelta, -3);
    expect(captured!.supportingDocumentId, 'evidence-7');
    expect(captured!.reason, 'Physical count correction.');
  });

  testWidgets('asset registration validates IDs and dispatches trusted command',
      (tester) async {
    final commandPort = RecordingAssetsCommandPort();
    await tester.pumpWidget(
      _dialogApp(
        commandPort,
        action: showRegisterAssetDialog,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open dialog'));
    await tester.pumpAndSettle();
    await _enter(tester, 'Asset ID', 'invalid id');
    await _enter(tester, 'Asset tag', 'ARPTC-900');
    await _enter(tester, 'Category ID', 'laptop');
    await _enter(tester, 'Type', 'Laptop');
    await tester.tap(find.text('Add Asset ID'));
    await tester.pump();

    expect(
      find.text(
        'Use letters, numbers, dots, dashes, underscores, or colons only.',
      ),
      findsOneWidget,
    );
    expect(commandPort.commands, isEmpty);

    await _enter(tester, 'Asset ID', 'asset-900');
    await tester.tap(find.text('Add Asset ID'));
    await tester.pumpAndSettle();

    final command = commandPort.commands.single as ManagerConfigurationCommand;
    expect(command.recordType, 'asset');
    expect(command.operation, 'register');
    expect(command.recordId, 'asset-900');
    expect(command.fields['assetTag'], 'ARPTC-900');
    expect(command.fields['status'], 'planned');
    expect(find.text('The configuration operation was completed.'),
        findsOneWidget);
  });

  testWidgets(
      'licence allocation exposes loading and prevents duplicate submit',
      (tester) async {
    final commandPort = RecordingAssetsCommandPort()
      ..completeImmediately = false;
    const licence = LicenceSummary(
      id: 'licence-1',
      productName: 'Productivity Suite',
      vendorName: 'Vendor',
      licenceType: 'subscription',
      purchasedQuantity: 10,
      allocatedQuantity: 4,
      complianceState: ComplianceState.compliant,
    );
    await tester.pumpWidget(
      _specificDialogApp(
        commandPort,
        onPressed: (context, ref) =>
            showLicenceActionDialog(context, ref, licence),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open dialog'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Allocate licence').last);
    await tester.pumpAndSettle();
    await _enter(tester, 'Assignee ID', 'agent-8');
    await _enter(tester, 'Assignee name', 'Grace Mbala');
    await _enter(tester, 'Quantity', '2');
    await tester.tap(find.text('Allocate licence').last);
    await tester.pump();

    expect(commandPort.commands, hasLength(1));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final submitButton =
        tester.widget<FilledButton>(find.byType(FilledButton).last);
    expect(submitButton.onPressed, isNull);
    expect(commandPort.commands, hasLength(1));

    final command = commandPort.commands.single as ManagerConfigurationCommand;
    expect(command.recordType, 'licence');
    expect(command.operation, 'allocate');
    expect(command.recordId, 'licence-1');
    expect(command.fields['assignmentType'], 'user');
    expect(command.fields['quantity'], 2);

    commandPort.completer.complete(
      ItsmCommandReceipt(
        commandId: command.context.idempotencyKey,
        acceptedAt: fixtureDate,
        wasDuplicate: false,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('The configuration operation was completed.'),
        findsOneWidget);
  });

  testWidgets('warranty selection records a claim against selected warranty',
      (tester) async {
    final commandPort = RecordingAssetsCommandPort();
    const warranty = WarrantySummary(
      id: 'warranty-1',
      name: 'Three year cover',
      supplierName: 'Supplier',
      coverage: 'Parts and labour',
      linkedAssetCount: 3,
    );
    await tester.pumpWidget(
      _specificDialogApp(
        commandPort,
        onPressed: (context, ref) =>
            showWarrantyClaimDialog(context, ref, warranty),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open dialog'));
    await tester.pumpAndSettle();
    await _enter(tester, 'Claim ID', 'claim-44');
    await _enter(tester, 'Asset ID', 'asset-12');
    await _enter(tester, 'Title', 'Failed display');
    await _enter(tester, 'Description', 'Display stopped working.');
    await tester.tap(find.text('Record warranty claim'));
    await tester.pumpAndSettle();

    final command = commandPort.commands.single as ManagerConfigurationCommand;
    expect(command.recordType, 'warranty.claim');
    expect(command.operation, 'record');
    expect(command.recordId, 'claim-44');
    expect(command.fields['warrantyId'], 'warranty-1');
    expect(command.fields['assetId'], 'asset-12');
  });

  testWidgets('supplier edit preserves the primary contact', (tester) async {
    final commandPort = RecordingAssetsCommandPort();
    await tester.pumpWidget(
      _specificDialogApp(
        commandPort,
        onPressed: (context, ref) => showAddSupplierDialog(
          context,
          ref,
          supplier: const SupplierSummary(
            id: 'supplier-1',
            name: 'Office Systems',
            contactName: 'Grace Mbala',
            email: 'grace@example.org',
            phone: '+243000000000',
            supportTerms: '8x5 support',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open dialog'));
    await tester.pumpAndSettle();
    expect(find.text('Office Systems'), findsOneWidget);
    expect(find.text('Grace Mbala'), findsOneWidget);
    await tester.tap(find.text('Save supplier'));
    await tester.pumpAndSettle();

    final command = commandPort.commands.single as ManagerConfigurationCommand;
    expect(command.recordId, 'supplier-1');
    expect(command.fields['contactName'], 'Grace Mbala');
    expect(command.fields['contactEmail'], 'grace@example.org');
  });

  testWidgets('warranty claim transition requires a reason and target state',
      (tester) async {
    final commandPort = RecordingAssetsCommandPort();
    const warranty = WarrantySummary(
      id: 'warranty-1',
      name: 'Three year cover',
      supplierName: 'supplier-1',
      coverage: 'Parts and labour',
      linkedAssetCount: 3,
    );
    await tester.pumpWidget(
      _specificDialogApp(
        commandPort,
        onPressed: (context, ref) =>
            showWarrantyClaimTransitionDialog(context, ref, warranty),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open dialog'));
    await tester.pumpAndSettle();
    await _enter(tester, 'Claim ID', 'claim-44');
    await tester.tap(find.text('Update claim status').last);
    await tester.pump();
    expect(commandPort.commands, isEmpty);

    await _enter(tester, 'Claim reason or resolution', 'Repair approved.');
    await tester.tap(find.text('Update claim status').last);
    await tester.pumpAndSettle();

    final command = commandPort.commands.single as ManagerConfigurationCommand;
    expect(command.operation, 'transition');
    expect(command.fields['toStatus'], 'acknowledged');
    expect(command.fields['reason'], 'Repair approved.');
  });

  testWidgets('CMDB edit parses related record IDs', (tester) async {
    final commandPort = RecordingAssetsCommandPort();
    const item = ConfigurationItemSummary(
      id: 'ci-1',
      name: 'ERP service',
      typeName: 'service',
      criticality: 'high',
      operationalStatus: 'active',
    );
    await tester.pumpWidget(
      _specificDialogApp(
        commandPort,
        onPressed: (context, ref) =>
            showAddConfigurationItemDialog(context, ref, item: item),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open dialog'));
    await tester.pumpAndSettle();
    await _enter(tester, 'Related incident IDs', 'INC-1, INC-2');
    await tester.tap(find.text('Save configuration item'));
    await tester.pumpAndSettle();

    final command = commandPort.commands.single as ManagerConfigurationCommand;
    expect(command.recordId, 'ci-1');
    expect(command.fields['relatedIncidentIds'], ['INC-1', 'INC-2']);
  });

  testWidgets('CMDB relationship create and retire use directional commands',
      (tester) async {
    final commandPort = RecordingAssetsCommandPort();
    const item = ConfigurationItemSummary(
      id: 'ci-source',
      name: 'Payroll service',
      typeName: 'service',
      criticality: 'high',
      operationalStatus: 'active',
    );
    await tester.pumpWidget(
      _specificDialogApp(
        commandPort,
        onPressed: (context, ref) =>
            showCreateRelationshipDialog(context, ref, item),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open dialog'));
    await tester.pumpAndSettle();
    await _enter(tester, 'Record ID', 'rel-1');
    await _enter(tester, 'Target ID', 'ci-target');
    await tester.tap(find.text('Create relationship'));
    await tester.pumpAndSettle();

    var command = commandPort.commands.single as ManagerConfigurationCommand;
    expect(command.recordType, 'cmdb.relationship');
    expect(command.operation, 'create');
    expect(command.fields['sourceEntityId'], 'ci-source');
    expect(command.fields['targetEntityId'], 'ci-target');
    expect(command.fields['relationshipType'], 'depends_on');

    await tester.pumpWidget(
      _specificDialogApp(
        commandPort,
        onPressed: (context, ref) => showRetireRelationshipDialog(
          context,
          ref,
          const ConfigurationRelationship(
            id: 'rel-1',
            sourceId: 'ci-source',
            sourceName: 'Payroll service',
            type: 'depends_on',
            targetId: 'ci-target',
            targetName: 'Database',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open dialog'));
    await tester.pumpAndSettle();
    await _enter(tester, 'Reason', 'Dependency replaced.');
    await tester.tap(find.text('Retire relationship').last);
    await tester.pumpAndSettle();

    command = commandPort.commands.last as ManagerConfigurationCommand;
    expect(command.operation, 'retire');
    expect(command.recordId, 'rel-1');
    expect(command.fields['reason'], 'Dependency replaced.');
  });
}

Future<void> _enter(WidgetTester tester, String label, String value) async {
  final input = find.widgetWithText(CommonTextInput, label);
  expect(input, findsOneWidget);
  final textField = find.descendant(
    of: input,
    matching: find.byType(TextFormField),
  );
  await tester.enterText(textField, value);
}

Widget _dialogApp(
  RecordingAssetsCommandPort commandPort, {
  required ManagerDialogAction action,
}) {
  return _specificDialogApp(commandPort, onPressed: action);
}

Widget _specificDialogApp(
  RecordingAssetsCommandPort commandPort, {
  required Future<void> Function(BuildContext context, WidgetRef ref) onPressed,
  RecordingAssetsReadPort? readPort,
}) {
  return ProviderScope(
    overrides: [
      itsmSessionProvider.overrideWith(
        (ref) => Stream.value(assetSession(ItsmRole.manager)),
      ),
      assetsConfigurationCommandPortProvider.overrideWithValue(commandPort),
      if (readPort != null)
        assetsConfigurationReadPortProvider.overrideWithValue(readPort),
    ],
    child: MaterialApp(
      localizationsDelegates: const [S.delegate],
      supportedLocales: S.delegate.supportedLocales,
      home: Scaffold(
        body: Consumer(
          builder: (context, ref, _) => Center(
            child: FilledButton(
              onPressed: () => onPressed(context, ref),
              child: const Text('Open dialog'),
            ),
          ),
        ),
      ),
    ),
  );
}
