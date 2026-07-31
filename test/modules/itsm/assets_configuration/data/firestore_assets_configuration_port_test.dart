import 'package:arptc_connect/modules/itsm/assets_configuration/application/assets_configuration_contracts.dart'
    as application;
import 'package:arptc_connect/modules/itsm/assets_configuration/data/firestore_assets_configuration_port.dart';
import 'package:arptc_connect/modules/itsm/assets_configuration/domain/assets_configuration_domain.dart'
    as domain;
import 'package:arptc_connect/modules/itsm/shared/data/trusted_command_gateways.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_common.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/pagination.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FirestoreAssetsConfigurationPort reads', () {
    test('self-service reads use the dedicated safe projection collection', () {
      expect(
        AssetsConfigurationFirestoreCollections.assetSelfServiceProjections,
        'assetSelfServiceProjections',
      );
      expect(
        AssetsConfigurationFirestoreCollections.assetSelfServiceProjections,
        isNot('assets'),
      );
    });

    test('isolates My Assets with principal.userId and enforces the bound',
        () async {
      final reads = _FakeReadAdapter()
        ..projections = [
          _projection(userId: 'agent-1', assetId: 'asset-1'),
          _projection(userId: 'agent-2', assetId: 'asset-2'),
        ];
      final port = _port(reads: reads);

      final assets =
          await port.watchMyAssets(principal: _principal(), limit: 25).first;

      expect(reads.requestedUserId, 'agent-1');
      expect(reads.requestedLimit, 25);
      expect(assets.map((asset) => asset.id), ['asset-1']);
      expect(
        () => port.watchMyAssets(principal: _principal(), limit: 101),
        throwsRangeError,
      );
    });

    test('maps authoritative asset and bounded lifecycle data to detail DTO',
        () async {
      final reads = _FakeReadAdapter()
        ..asset = _asset()
        ..lifecycle = [_lifecycle()];
      final port = _port(reads: reads);

      final detail = await port
          .watchAssetDetail(
            principal: _principal(role: ItsmRole.manager),
            assetId: 'asset-1',
          )
          .first;

      expect(detail, isNotNull);
      expect(detail!.summary.assetTag, 'ARPTC-001');
      expect(detail.summary.name, 'Dell Latitude 7440');
      expect(detail.lifecycle, hasLength(1));
      expect(
        detail.lifecycle.single.status,
        application.AssetLifecycleStatus.inMaintenance,
      );
      expect(reads.lifecycleLimit, 100);
    });

    test('self-service detail reads only the safe owner projection', () async {
      final reads = _FakeReadAdapter()
        ..asset = _asset()
        ..projection = _projection(userId: 'agent-1', assetId: 'asset-1')
        ..lifecycle = [_lifecycle()];
      final port = _port(reads: reads);

      final detail = await port
          .watchMyAssetDetail(
            principal: _principal(),
            assetId: 'asset-1',
          )
          .first;

      expect(detail, isNotNull);
      expect(detail!.lifecycle, isEmpty);
      expect(detail.attachmentNames, isEmpty);
      expect(detail.acquisitionCost, isNull);
      expect(detail.acquisitionDate, isNull);
      expect(detail.supplierName, isEmpty);
      expect(detail.securityBaseline, isEmpty);
      expect(reads.assetWatchCount, 0);
      expect(reads.lifecycleLimit, 0);
      expect(reads.projectionUserId, 'agent-1');
      expect(reads.projectionAssetId, 'asset-1');
    });

    test('USER cannot invoke authoritative asset detail directly', () {
      final reads = _FakeReadAdapter()..asset = _asset();
      final port = _port(reads: reads);

      expect(
        () => port.watchAssetDetail(
          principal: _principal(),
          assetId: 'asset-1',
        ),
        throwsA(isA<application.AssetsConfigurationAccessDenied>()),
      );
      expect(reads.assetWatchCount, 0);
    });

    test('preserves cursor pagination while mapping authoritative assets',
        () async {
      final cursor = PageCursor({
        'updatedAt': fixtureDate.toIso8601String(),
        'documentId': 'asset-1',
      });
      final reads = _FakeReadAdapter()
        ..assetPage = PageResult(
          items: [_asset()],
          hasMore: true,
          nextCursor: cursor,
        );
      final port = _port(reads: reads);

      final result = await port.fetchAssetPage(
        principal: _principal(role: ItsmRole.manager),
        request: application.AssetPageRequest(
          query: const application.AssetListQuery(search: 'dell'),
          page: PageRequest(limit: 12),
        ),
      );

      expect(reads.pageLimit, 12);
      expect(result.items.single.id, 'asset-1');
      expect(result.hasMore, isTrue);
      expect(result.nextCursor, cursor);
    });

    test('dependency graph uses bounded denormalized relationship data',
        () async {
      final reads = _FakeReadAdapter()
        ..configurationItems = [_configurationItem()]
        ..relationships = [_relationship()];
      final port = _port(reads: reads);

      final graph = await port
          .watchDependencyView(
            principal: _principal(role: ItsmRole.manager),
            configurationItemId: 'ci-1',
          )
          .first;

      expect(graph, isNotNull);
      expect(graph!.root.id, 'ci-1');
      expect(graph.relationships.single.targetId, 'ci-2');
      expect(graph.items.map((item) => item.id), containsAll(['ci-1', 'ci-2']));
      expect(reads.relationshipLimit, 100);
      expect(reads.relationshipWatchCount, 1);
    });
  });

  group('FirestoreAssetsConfigurationPort commands', () {
    test('lifecycle transition resolves revision and sends exact envelope',
        () async {
      final reads = _FakeReadAdapter()..revision = 7;
      final calls = _RecordingCallableInvoker(result: {
        'commandId': 'receipt-1',
        'acceptedAt': fixtureDate.toIso8601String(),
        'wasDuplicate': true,
      });
      final port = _port(reads: reads, calls: calls);

      final receipt = await port.execute(
        application.AssetOperationalCommand(
          context: _context('asset-command-0001'),
          assetId: 'asset-1',
          operation: 'update_lifecycle',
          fields: const {
            'fromStatus': 'assigned',
            'toStatus': 'inMaintenance',
          },
        ),
      );

      expect(reads.revisionAssetId, 'asset-1');
      expect(calls.functionName, 'itsmTransitionAsset');
      expect(calls.envelope.keys, {'command', 'idempotencyKey', 'payload'});
      expect(calls.envelope['command'], 'asset.lifecycle.transition');
      final payload = calls.payload;
      expect(payload['assetId'], 'asset-1');
      expect(payload['expectedRevision'], 7);
      expect(payload['toStatus'], 'in_maintenance');
      expect(payload['reason'], isNotEmpty);
      expect(payload, isNot(contains('fromStatus')));
      expect(payload, isNot(contains('actorUserId')));
      expect(payload, isNot(contains('actorRole')));
      expect(receipt.commandId, 'receipt-1');
      expect(receipt.acceptedAt, fixtureDate);
      expect(receipt.wasDuplicate, isTrue);
    });

    test('stock transfer preserves movement fields and registered metadata',
        () async {
      final reads = _FakeReadAdapter()
        ..supportingDocument = const StockSupportingDocumentMetadata(
          attachmentId: 'evidence-1',
          stockItemId: 'stock-1',
          storagePath:
              'itsm/stock/stock-1/supportingDocuments/evidence-1/document.pdf',
          fileName: 'document.pdf',
          contentType: 'application/pdf',
          sizeBytes: 2048,
          checksum: 'sha256-value',
        );
      final calls = _RecordingCallableInvoker(result: const {});
      final port = _port(reads: reads, calls: calls);

      await port.execute(
        application.StockMovementCommand(
          context: _context('stock-command-0001'),
          itemId: 'stock-1',
          type: application.StockMovementType.transfer,
          quantity: 4,
          actorUserId: 'agent-1',
          sourceLocationId: 'store-a',
          destinationLocationId: 'store-b',
          recipientUserId: 'agent-2',
          relatedRequestId: 'request-1',
          supportingDocumentId: 'evidence-1',
        ),
      );

      expect(calls.functionName, 'itsmTransferStock');
      expect(calls.envelope['command'], 'stock.transfer');
      expect(calls.payload, containsPair('stockItemId', 'stock-1'));
      expect(calls.payload, containsPair('quantity', 4));
      expect(calls.payload, containsPair('sourceLocationId', 'store-a'));
      expect(calls.payload, containsPair('destinationLocationId', 'store-b'));
      expect(calls.payload, containsPair('recipientUserId', 'agent-2'));
      expect(calls.payload, containsPair('relatedRequestId', 'request-1'));
      expect(calls.payload, containsPair('correlationId', 'correlation-1'));
      expect(calls.payload, isNot(contains('actorUserId')));
      expect(
        calls.payload['supportingDocument'],
        containsPair(
          'storagePath',
          'itsm/stock/stock-1/supportingDocuments/evidence-1/document.pdf',
        ),
      );
    });

    test('issue can consume a specified reserved quantity', () async {
      final calls = _RecordingCallableInvoker(result: const {});
      final port = _port(calls: calls);

      await port.execute(
        application.StockMovementCommand(
          context: _context('stock-command-reserved-issue'),
          itemId: 'stock-1',
          type: application.StockMovementType.issue,
          quantity: 5,
          reservedQuantity: 3,
          actorUserId: 'agent-1',
          sourceLocationId: 'store-a',
          recipientUserId: 'agent-2',
        ),
      );

      expect(calls.functionName, 'itsmIssueStock');
      expect(calls.payload, containsPair('quantity', 5));
      expect(calls.payload, containsPair('reservedQuantity', 3));
    });

    test('adjustment sends a signed decrease delta', () async {
      final reads = _FakeReadAdapter()
        ..supportingDocument = const StockSupportingDocumentMetadata(
          attachmentId: 'evidence-1',
          stockItemId: 'stock-1',
          storagePath:
              'itsm/stock/stock-1/supportingDocuments/evidence-1/count.pdf',
          fileName: 'count.pdf',
          contentType: 'application/pdf',
          sizeBytes: 50,
        );
      final calls = _RecordingCallableInvoker(result: const {});
      final port = _port(reads: reads, calls: calls);

      await port.execute(
        application.StockMovementCommand(
          context: _context('stock-command-decrease'),
          itemId: 'stock-1',
          type: application.StockMovementType.adjustment,
          quantity: 0,
          adjustmentDelta: -4,
          actorUserId: 'agent-1',
          sourceLocationId: 'store-a',
          supportingDocumentId: 'evidence-1',
          reason: 'Physical count correction.',
        ),
      );

      expect(calls.payload, containsPair('adjustmentDelta', -4));
      expect(
          calls.payload, containsPair('reason', 'Physical count correction.'));
      expect(calls.payload, isNot(contains('quantity')));
    });

    test('reconciliation preserves zero targets', () async {
      final reads = _FakeReadAdapter()
        ..supportingDocument = const StockSupportingDocumentMetadata(
          attachmentId: 'evidence-1',
          stockItemId: 'stock-1',
          storagePath:
              'itsm/stock/stock-1/supportingDocuments/evidence-1/count.pdf',
          fileName: 'count.pdf',
          contentType: 'application/pdf',
          sizeBytes: 50,
        );
      final calls = _RecordingCallableInvoker(result: const {});
      final port = _port(reads: reads, calls: calls);

      await port.execute(
        application.StockMovementCommand(
          context: _context('stock-command-zero-reconcile'),
          itemId: 'stock-1',
          type: application.StockMovementType.reconciliation,
          quantity: 99,
          targetOnHand: 0,
          targetReserved: 0,
          actorUserId: 'agent-1',
          sourceLocationId: 'store-a',
          supportingDocumentId: 'evidence-1',
        ),
      );

      expect(calls.payload, containsPair('targetOnHand', 0));
      expect(calls.payload, containsPair('targetReserved', 0));
      expect(calls.payload, isNot(contains('quantity')));
    });

    test('cross-item evidence is rejected before callable invocation',
        () async {
      final reads = _FakeReadAdapter()
        ..supportingDocument = const StockSupportingDocumentMetadata(
          attachmentId: 'evidence-2',
          stockItemId: 'stock-2',
          storagePath:
              'itsm/stock/stock-2/supportingDocuments/evidence-2/count.pdf',
          fileName: 'count.pdf',
          contentType: 'application/pdf',
          sizeBytes: 50,
        );
      final calls = _RecordingCallableInvoker(result: const {});
      final port = _port(reads: reads, calls: calls);

      final future = port.execute(
        application.StockMovementCommand(
          context: _context('stock-command-cross-item'),
          itemId: 'stock-1',
          type: application.StockMovementType.adjustment,
          quantity: 1,
          adjustmentDelta: 1,
          actorUserId: 'agent-1',
          sourceLocationId: 'store-a',
          supportingDocumentId: 'evidence-2',
        ),
      );

      await expectLater(
        future,
        throwsA(
          isA<AssetsConfigurationCommandException>().having(
            (error) => error.code,
            'code',
            'supporting-document-stock-item-mismatch',
          ),
        ),
      );
      expect(calls.callCount, 0);
    });

    test('adjustment fails rather than forging missing evidence', () async {
      final reads = _FakeReadAdapter();
      final calls = _RecordingCallableInvoker(result: const {});
      final port = _port(reads: reads, calls: calls);

      final future = port.execute(
        application.StockMovementCommand(
          context: _context('stock-command-0002'),
          itemId: 'stock-1',
          type: application.StockMovementType.adjustment,
          quantity: 2,
          actorUserId: 'agent-1',
          sourceLocationId: 'store-a',
          supportingDocumentId: 'missing-document',
        ),
      );

      await expectLater(
        future,
        throwsA(
          isA<AssetsConfigurationCommandException>().having(
            (error) => error.code,
            'code',
            'supporting-document-required',
          ),
        ),
      );
      expect(calls.callCount, 0);
    });

    test('manager configuration maps exact callable without trusted actor data',
        () async {
      final calls = _RecordingCallableInvoker(result: const {});
      final port = _port(calls: calls);

      final receipt = await port.execute(
        application.ManagerConfigurationCommand(
          context: _context('licence-command-001'),
          recordType: 'licence',
          operation: 'register',
          recordId: 'licence-1',
          fields: const {
            'softwareProduct': 'Microsoft 365',
            'vendor': 'Microsoft',
            'licenceType': 'subscription',
            'purchasedQuantity': 20,
          },
        ),
      );

      expect(calls.functionName, 'itsmRegisterLicence');
      expect(calls.envelope['command'], 'licence.register');
      expect(calls.payload['licenceId'], 'licence-1');
      expect(calls.payload, isNot(contains('actorUserId')));
      expect(calls.payload, isNot(contains('actorRole')));
      expect(receipt.commandId, 'licence-command-001');
      expect(receipt.acceptedAt, fixtureDate);
    });

    test('stock location master data uses strict save mapping', () async {
      final calls = _RecordingCallableInvoker(result: const {});
      final port = _port(calls: calls);

      await port.execute(
        application.ManagerConfigurationCommand(
          context: _context('stock-location-save'),
          recordType: 'stock.location',
          operation: 'save',
          recordId: 'store-a',
          fields: const {
            'name': 'Central store',
            'siteId': 'hq',
            'isActive': true,
            'quantityOnHand': 999,
          },
        ),
      );

      expect(calls.functionName, 'itsmSaveStockLocation');
      expect(calls.envelope['command'], 'stock.location.save');
      expect(calls.payload['id'], 'store-a');
      expect(calls.payload, isNot(contains('stockLocationId')));
      expect(calls.payload, isNot(contains('quantityOnHand')));
    });

    test('stock item master data cannot directly alter quantities', () async {
      final calls = _RecordingCallableInvoker(result: const {});
      final port = _port(calls: calls);

      await port.execute(
        application.ManagerConfigurationCommand(
          context: _context('stock-item-save'),
          recordType: 'stock.item',
          operation: 'save',
          recordId: 'stock-1',
          fields: const {
            'sku': 'LAPTOP-01',
            'name': 'Laptop',
            'kind': 'serializedAsset',
            'minimumQuantity': 3,
            'quantityOnHand': 500,
            'quantityReserved': 100,
          },
        ),
      );

      expect(calls.functionName, 'itsmSaveStockItem');
      expect(calls.envelope['command'], 'stock.item.save');
      expect(calls.payload['id'], 'stock-1');
      expect(calls.payload, isNot(contains('stockItemId')));
      expect(calls.payload, isNot(contains('locationId')));
      expect(calls.payload, isNot(contains('locationName')));
      expect(calls.payload, isNot(contains('quantityOnHand')));
      expect(calls.payload, isNot(contains('quantityReserved')));
    });

    test('licence secret fields are rejected before callable invocation',
        () async {
      final calls = _RecordingCallableInvoker(result: const {});
      final port = _port(calls: calls);

      final future = port.execute(
        application.ManagerConfigurationCommand(
          context: _context('licence-command-002'),
          recordType: 'licence',
          operation: 'register',
          recordId: 'licence-1',
          fields: const {
            'softwareProduct': 'Product',
            'vendor': 'Vendor',
            'licenceKey': 'must-not-leave-device',
          },
        ),
      );

      await expectLater(
        future,
        throwsA(
          isA<AssetsConfigurationCommandException>().having(
            (error) => error.code,
            'code',
            'secret-field-rejected',
          ),
        ),
      );
      expect(calls.callCount, 0);
    });
  });
}

final fixtureDate = DateTime.utc(2026, 7, 31, 9);

FirestoreAssetsConfigurationPort _port({
  _FakeReadAdapter? reads,
  _RecordingCallableInvoker? calls,
}) =>
    FirestoreAssetsConfigurationPort.withAdapters(
      readAdapter: reads ?? _FakeReadAdapter(),
      callableInvoker: calls ?? _RecordingCallableInvoker(result: const {}),
      clock: () => fixtureDate,
    );

application.AssetConfigurationPrincipal _principal({
  ItsmRole role = ItsmRole.user,
}) =>
    application.AssetConfigurationPrincipal(
      sessionKey: 'session-1',
      userId: 'agent-1',
      role: role,
    );

ItsmCommandContext _context(String idempotencyKey) => ItsmCommandContext(
      idempotencyKey: idempotencyKey,
      correlationId: 'correlation-1',
      actorUserId: 'agent-1',
      actorRole: ItsmRole.manager,
      actorDisplayName: 'Manager One',
    );

domain.Asset _asset() => domain.Asset(
      id: 'asset-1',
      assetTag: 'ARPTC-001',
      categoryId: 'laptop',
      categoryName: 'Laptop',
      type: 'Computer',
      brand: 'Dell',
      model: 'Latitude 7440',
      status: domain.AssetStatus.assigned,
      condition: domain.AssetCondition.good,
      assignedUserId: 'agent-1',
      assignedUserName: 'Agent One',
      createdAt: fixtureDate.subtract(const Duration(days: 30)),
      updatedAt: fixtureDate,
    );

domain.AssetSelfServiceProjection _projection({
  required String userId,
  required String assetId,
}) =>
    domain.AssetSelfServiceProjection(
      id: 'projection-$userId-$assetId',
      assetId: assetId,
      assignedUserId: userId,
      assetTag: 'TAG-$assetId',
      assetName: 'Dell Latitude',
      assetType: 'Laptop',
      categoryName: 'Computer',
      brand: 'Dell',
      model: 'Latitude',
      serialNumber: 'SAFE-SERIAL',
      barcode: 'SAFE-BARCODE',
      description: 'Assigned workstation',
      locationName: 'Kinshasa',
      departmentName: 'IT',
      assignedUserName: 'Agent',
      status: domain.AssetStatus.assigned,
      condition: domain.AssetCondition.good,
      complianceState: 'compliant',
      updatedAt: fixtureDate,
    );

domain.AssetLifecycleEvent _lifecycle() => domain.AssetLifecycleEvent(
      id: 'event-1',
      assetId: 'asset-1',
      type: domain.AssetLifecycleEventType.maintenanceStarted,
      fromStatus: domain.AssetStatus.assigned,
      toStatus: domain.AssetStatus.inMaintenance,
      actorUserId: 'manager-1',
      actorName: 'Manager One',
      occurredAt: fixtureDate,
      reason: 'Preventive maintenance',
    );

domain.ConfigurationItem _configurationItem() => domain.ConfigurationItem(
      id: 'ci-1',
      name: 'Email Service',
      type: domain.ConfigurationItemType.service,
      criticality: domain.CiCriticality.high,
      operationalStatus: domain.CiOperationalStatus.operational,
      dataQualityStatus: domain.CiDataQualityStatus.verified,
      createdAt: fixtureDate,
      updatedAt: fixtureDate,
    );

domain.CiRelationship _relationship() => domain.CiRelationship(
      id: 'relationship-1',
      sourceCiId: 'ci-1',
      sourceCiName: 'Email Service',
      targetCiId: 'ci-2',
      targetCiName: 'Mail Server',
      type: domain.CiRelationshipType.dependsOn,
      createdAt: fixtureDate,
      createdByUserId: 'manager-1',
    );

class _RecordingCallableInvoker implements AssetsConfigurationCallableInvoker {
  _RecordingCallableInvoker({required this.result});

  final Object? result;
  int callCount = 0;
  String functionName = '';
  Map<String, Object?> envelope = const {};

  Map<String, Object?> get payload =>
      Map<String, Object?>.from(envelope['payload']! as Map);

  @override
  Future<Object?> invoke(
    String functionName,
    Map<String, Object?> envelope,
  ) async {
    callCount += 1;
    this.functionName = functionName;
    this.envelope = envelope;
    return result;
  }
}

class _FakeReadAdapter implements AssetsConfigurationReadAdapter {
  List<domain.AssetSelfServiceProjection> projections = const [];
  domain.AssetSelfServiceProjection? projection;
  List<domain.Asset> assets = const [];
  domain.Asset? asset;
  List<domain.AssetLifecycleEvent> lifecycle = const [];
  PageResult<domain.Asset>? assetPage;
  List<domain.StockItem> stockItems = const [];
  List<domain.StockMovement> stockMovements = const [];
  List<domain.SoftwareLicence> licences = const [];
  List<domain.Supplier> suppliers = const [];
  List<domain.SupplierContract> contracts = const [];
  List<domain.Warranty> warranties = const [];
  List<domain.ConfigurationItem> configurationItems = const [];
  List<domain.CiRelationship> relationships = const [];
  StockSupportingDocumentMetadata? supportingDocument;
  int revision = 0;

  String requestedUserId = '';
  int requestedLimit = 0;
  int lifecycleLimit = 0;
  int pageLimit = 0;
  int relationshipLimit = 0;
  int relationshipWatchCount = 0;
  String revisionAssetId = '';
  String projectionUserId = '';
  String projectionAssetId = '';
  int assetWatchCount = 0;

  @override
  Future<PageResult<domain.Asset>> fetchAssetPage({
    required application.AssetListQuery query,
    required PageRequest page,
  }) async {
    pageLimit = page.limit;
    return assetPage ?? PageResult(items: assets, hasMore: false);
  }

  @override
  Future<List<domain.AssetLifecycleEvent>> fetchAssetLifecycle({
    required String assetId,
    required int limit,
  }) async {
    lifecycleLimit = limit;
    return lifecycle;
  }

  @override
  Future<int> fetchAssetRevision(String assetId) async {
    revisionAssetId = assetId;
    return revision;
  }

  @override
  Future<StockSupportingDocumentMetadata?> resolveSupportingDocument(
    String attachmentId,
  ) async =>
      supportingDocument;

  @override
  Stream<domain.Asset?> watchAsset(String assetId) {
    assetWatchCount += 1;
    return Stream.value(asset);
  }

  @override
  Stream<domain.AssetSelfServiceProjection?> watchMyAssetProjection({
    required String currentUserId,
    required String assetId,
  }) {
    projectionUserId = currentUserId;
    projectionAssetId = assetId;
    return Stream.value(projection);
  }

  @override
  Stream<List<domain.Asset>> watchAssets({
    required application.AssetListQuery query,
    required int limit,
  }) =>
      Stream.value(assets);

  @override
  Stream<List<domain.AssetSelfServiceProjection>> watchMyAssetProjections({
    required String currentUserId,
    required int limit,
  }) {
    requestedUserId = currentUserId;
    requestedLimit = limit;
    return Stream.value(projections);
  }

  @override
  Stream<List<domain.ConfigurationItem>> watchConfigurationItems({
    required int limit,
  }) =>
      Stream.value(configurationItems);

  @override
  Stream<List<domain.CiRelationship>> watchConfigurationRelationships({
    required String configurationItemId,
    required int limit,
  }) {
    relationshipLimit = limit;
    relationshipWatchCount += 1;
    return Stream.value(relationships);
  }

  @override
  Stream<List<domain.SupplierContract>> watchContracts({required int limit}) =>
      Stream.value(contracts);

  @override
  Stream<List<domain.SoftwareLicence>> watchLicences({required int limit}) =>
      Stream.value(licences);

  @override
  Stream<List<domain.StockItem>> watchStockItems({required int limit}) =>
      Stream.value(stockItems);

  @override
  Stream<List<domain.StockMovement>> watchStockMovements({
    required int limit,
  }) =>
      Stream.value(stockMovements);

  @override
  Stream<List<domain.Supplier>> watchSuppliers({required int limit}) =>
      Stream.value(suppliers);

  @override
  Stream<List<domain.Warranty>> watchWarranties({required int limit}) =>
      Stream.value(warranties);
}
