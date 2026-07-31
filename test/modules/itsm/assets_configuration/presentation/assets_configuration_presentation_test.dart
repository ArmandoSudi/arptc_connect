import 'dart:typed_data';

import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/itsm/assets_configuration/application/assets_configuration_application.dart';
import 'package:arptc_connect/modules/itsm/assets_configuration/presentation/assets_configuration_presentation.dart';
import 'package:arptc_connect/modules/itsm/shared/application/itsm_providers.dart';
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
    var transitionCount = 0;
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
            onTransition: () => transitionCount += 1,
            onUploadAttachment: () => attachmentCount += 1,
            onUploadPhotograph: () => photographCount += 1,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final label in [
      'Edit asset',
      'Assign asset',
      'Return asset',
      'Change lifecycle state',
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
        transitionCount,
        attachmentCount,
        photographCount,
      ],
      [1, 1, 1, 1, 1, 1],
    );
    expect(tester.takeException(), isNull);
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
