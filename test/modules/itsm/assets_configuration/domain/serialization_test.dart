import 'package:arptc_connect/modules/itsm/assets_configuration/domain/assets_configuration_domain.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('asset round-trips additive Firestore fields', () {
    final source = Asset(
      id: 'asset-1',
      assetTag: 'ARPTC-001',
      categoryId: 'laptop',
      categoryName: 'Laptop',
      type: 'Computer',
      brand: 'Dell',
      model: 'Latitude',
      status: AssetStatus.assigned,
      isInStock: false,
      condition: AssetCondition.good,
      assignedUserId: 'agent-1',
      assignedUserName: 'Agent One',
      attachmentIds: const ['attachment-1'],
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 7, 31),
    );

    final parsed = Asset.fromMap(source.id, source.toFirestore());

    expect(parsed.assetTag, source.assetTag);
    expect(parsed.status, AssetStatus.assigned);
    expect(parsed.isInStock, isFalse);
    expect(parsed.assignedUserId, 'agent-1');
    expect(parsed.attachmentIds, ['attachment-1']);
  });

  test('asset state event preserves the observation and actor', () {
    final source = AssetStateEvent(
      id: 'state-event-1',
      assetId: 'asset-1',
      fromStateId: 'good',
      fromStateName: 'Good',
      toStateId: 'repairable',
      toStateName: 'Repairable',
      observation: 'Battery health is below threshold.',
      actorUserId: 'manager-1',
      actorName: 'Manager One',
      changedAt: DateTime.utc(2026, 8, 14),
      revision: 3,
    );

    final parsed = AssetStateEvent.fromMap(
      source.id,
      source.toFirestore(),
    );

    expect(parsed.fromStateName, 'Good');
    expect(parsed.toStateName, 'Repairable');
    expect(parsed.observation, 'Battery health is below threshold.');
    expect(parsed.actorName, 'Manager One');
    expect(parsed.revision, 3);
  });

  test('self-service projection exposes only custodian-safe fields', () {
    final projection = AssetSelfServiceProjection.fromMap('projection-1', {
      'assetId': 'asset-1',
      'assignedUserId': 'agent-1',
      'assetTag': 'ARPTC-001',
      'assetName': 'Dell Latitude',
      'assetType': 'Laptop',
      'status': 'assigned',
      'condition': 'good',
      'complianceState': 'compliant',
      'isCurrent': true,
      'updatedAt': DateTime.utc(2026, 7, 31),
      'acquisitionCost': 1200,
      'supplierName': 'Sensitive supplier',
      'securityBaselineId': 'restricted-baseline',
      'attachmentIds': ['restricted-file'],
    });

    expect(projection.assetId, 'asset-1');
    expect(projection.assignedUserId, 'agent-1');
    expect(projection.complianceState, 'compliant');
    expect(
      projection.toString(),
      isNot(contains('Sensitive supplier')),
    );
  });

  test('stock, supplier and CI serializers retain canonical enum values', () {
    final stock = StockItem.fromMap('stock-1', {
      'sku': 'SKU-1',
      'name': 'Keyboard',
      'kind': 'consumable',
      'locationId': 'store-1',
      'locationName': 'Main Store',
      'quantityOnHand': 5,
      'quantityReserved': 2,
      'minimumQuantity': 1,
      'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 7, 31)),
    });
    final ci = ConfigurationItem.fromMap('ci-1', {
      'name': 'Email Service',
      'type': 'service',
      'criticality': 'critical',
      'operationalStatus': 'operational',
      'dataQualityStatus': 'verified',
      'createdAt': DateTime.utc(2026),
      'updatedAt': DateTime.utc(2026),
    });

    expect(stock.quantityAvailable, 3);
    expect(stock.toFirestore()['quantityAvailable'], 3);
    expect(ci.type, ConfigurationItemType.service);
    expect(ci.toFirestore()['criticality'], 'critical');
    expect(ci.toFirestore()['ciType'], 'service');
    expect(ci.toFirestore(), isNot(contains('type')));
  });

  test('persisted collections are immutable to callers', () {
    final asset = Asset.fromMap('asset-1', {
      'assetTag': 'TAG-1',
      'type': 'Laptop',
      'status': 'in_stock',
      'condition': 'good',
      'attachmentIds': ['one'],
      'createdAt': DateTime.utc(2026),
      'updatedAt': DateTime.utc(2026),
    });
    final ci = ConfigurationItem.fromMap('ci-1', {
      'name': 'Server',
      'type': 'server',
      'configurationAttributes': {'os': 'Linux'},
      'createdAt': DateTime.utc(2026),
      'updatedAt': DateTime.utc(2026),
    });

    expect(() => asset.attachmentIds.add('two'), throwsUnsupportedError);
    expect(
      () => ci.configurationAttributes['os'] = 'Other',
      throwsUnsupportedError,
    );
  });

  test('trusted Function asset and stock documents map without data loss', () {
    final asset = Asset.fromMap('asset-1', {
      'assetTag': 'ARPTC-001',
      'barcode': 'QR-001',
      'type': 'laptop',
      'currency': 'USD',
      'photoAttachmentIds': ['photo-1'],
      'status': 'in_stock',
      'condition': 'good',
    });
    final stock = StockItem.fromMap('stock-1', {
      'sku': 'CAB-1',
      'name': 'Network cable',
      'totalOnHand': 12,
      'totalReserved': 2,
      'minimumQuantity': 3,
    });
    final movement = StockMovement.fromMap('movement-1', {
      'stockItemId': 'stock-1',
      'movementType': 'adjustment',
      'quantity': 2,
      'actorUserId': 'manager-1',
      'actor': {'userId': 'manager-1', 'name': 'Asset Manager'},
      'recipient': {'userId': 'agent-1', 'name': 'Agent One'},
      'supportingDocument': {'attachmentId': 'evidence-1'},
      'quantityChanges': {
        'main': {'onHand': -2, 'reserved': 0},
      },
      'after': {
        'main': {'onHand': 10, 'reserved': 2},
      },
    });

    expect(asset.qrBarcode, 'QR-001');
    expect(asset.currencyCode, 'USD');
    expect(asset.photographIds, ['photo-1']);
    expect(stock.locationId, isEmpty);
    expect(stock.quantityAvailable, 10);
    expect(movement.type, StockMovementType.adjustmentDecrease);
    expect(movement.actorName, 'Asset Manager');
    expect(movement.recipientName, 'Agent One');
    expect(movement.supportingDocumentId, 'evidence-1');
    expect(movement.resultingQuantityOnHand, 10);
    expect(movement.resultingQuantityReserved, 2);
  });

  test('trusted Function supplier, warranty, licence and CMDB fields map', () {
    final supplier = Supplier.fromMap('supplier-1', {
      'name': 'Vendor',
      'supplierCode': 'SUP-1',
      'contactName': 'Support Desk',
      'contactEmail': 'support@example.test',
      'contactPhone': '+243000000',
      'assetCategoryIds': ['laptop'],
      'slaSummary': '8x5 support',
      'isActive': true,
    });
    final contract = SupplierContract.fromMap('contract-1', {
      'contractNumber': 'CTR-1',
      'name': 'Hardware support',
      'supplierId': 'supplier-1',
      'status': 'active',
      'startDate': DateTime.utc(2026),
      'endDate': DateTime.utc(2027),
    });
    final warranty = Warranty.fromMap('warranty-1', {
      'warrantyNumber': 'WAR-1',
      'supplierId': 'supplier-1',
      'status': 'active',
      'coverage': 'Parts and labour',
      'startDate': DateTime.utc(2026),
      'expirationDate': DateTime.utc(2027),
      'assetIds': ['asset-1'],
    });
    final licence = SoftwareLicence.fromMap('licence-1', {
      'softwareProduct': 'Office Suite',
      'vendor': 'Vendor',
      'licenceType': 'subscription',
      'purchasedQuantity': 10,
      'allocatedQuantity': 2,
      'purchaseDate': DateTime.utc(2026),
      'effectiveDate': DateTime.utc(2026),
      'currency': 'USD',
      'updatedAt': DateTime.utc(2026),
    });
    final ci = ConfigurationItem.fromMap('ci-1', {
      'name': 'Payroll',
      'ciType': 'application',
      'operationalStatus': 'active',
      'configurationBaseline': {'version': '1'},
    });
    final relationship = CiRelationship.fromMap('relationship-1', {
      'sourceEntityId': 'ci-1',
      'sourceName': 'Payroll',
      'targetEntityId': 'ci-2',
      'targetName': 'Database',
      'relationshipType': 'depends_on',
      'createdBy': 'manager-1',
    });

    expect(supplier.registrationNumber, 'SUP-1');
    expect(supplier.contacts.single.email, 'support@example.test');
    expect(supplier.suppliedAssetCategoryIds, ['laptop']);
    expect(contract.reference, 'CTR-1');
    expect(contract.startsAt, DateTime.utc(2026));
    expect(warranty.reference, 'WAR-1');
    expect(warranty.linkedAssetIds, ['asset-1']);
    expect(licence.currencyCode, 'USD');
    expect(ci.type, ConfigurationItemType.application);
    expect(ci.operationalStatus, CiOperationalStatus.operational);
    expect(ci.configurationAttributes['version'], '1');
    expect(relationship.sourceCiId, 'ci-1');
    expect(relationship.targetCiId, 'ci-2');
    expect(relationship.createdByUserId, 'manager-1');
    expect(ci.toFirestore()['ciType'], 'application');
    expect(
      relationship.toFirestore(),
      containsPair('sourceEntityId', 'ci-1'),
    );
    expect(
      relationship.toFirestore(),
      containsPair('targetEntityId', 'ci-2'),
    );
    expect(relationship.toFirestore(), isNot(contains('sourceCiId')));
  });
}
