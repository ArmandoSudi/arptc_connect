import 'dart:async';

import 'package:arptc_connect/modules/itsm/assets_configuration/application/assets_configuration_application.dart';
import 'package:arptc_connect/modules/itsm/shared/application/itsm_session.dart';
import 'package:arptc_connect/modules/itsm/shared/data/trusted_command_gateways.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_common.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/pagination.dart';

final fixtureDate = DateTime.utc(2026, 7, 31, 9);

ItsmSession assetSession(
  ItsmRole role, {
  String userId = 'agent-1',
}) {
  return ItsmSession(
    sessionKey: '$userId|$role',
    userId: userId,
    email: '$userId@example.com',
    displayName: 'Test Agent',
    role: role,
  );
}

AssetSummary assetSummary({
  String id = 'asset-1',
  String assignedUserName = 'Test Agent',
}) {
  return AssetSummary(
    id: id,
    assetTag: 'ARPTC-001',
    name: 'Latitude 7440',
    categoryName: 'Laptop',
    status: AssetLifecycleStatus.assigned,
    brand: 'Dell',
    model: 'Latitude 7440',
    serialNumber: 'SN-001',
    locationName: 'Kinshasa',
    assignedUserName: assignedUserName,
    condition: 'good',
    updatedAt: fixtureDate,
  );
}

AssetDetail assetDetail() {
  return AssetDetail(
    summary: assetSummary(),
    typeName: 'Computer',
    description: 'Primary workstation',
    complianceState: ComplianceState.compliant,
    attachmentNames: const ['front.jpg'],
    lifecycle: [
      AssetLifecycleEntry(
        id: 'event-1',
        status: AssetLifecycleStatus.assigned,
        occurredAt: fixtureDate,
        actorName: 'IT Operator',
      ),
    ],
  );
}

class RecordingAssetsReadPort implements AssetsConfigurationReadPort {
  final principals = <AssetConfigurationPrincipal>[];
  final selfServiceDetailAssetIds = <String>[];
  final operationalDetailAssetIds = <String>[];
  List<AssetSummary> myAssets = [assetSummary()];
  List<AssetSummary> assets = [assetSummary()];
  AssetDetail? detail = assetDetail();
  List<StockItemSummary> stockItems = const [];
  List<StockMovementSummary> stockMovements = const [];

  @override
  Future<PageResult<AssetSummary>> fetchAssetPage({
    required AssetConfigurationPrincipal principal,
    required AssetPageRequest request,
  }) async {
    principals.add(principal);
    return PageResult(items: assets, hasMore: false);
  }

  @override
  Stream<AssetDetail?> watchAssetDetail({
    required AssetConfigurationPrincipal principal,
    required String assetId,
  }) {
    principals.add(principal);
    operationalDetailAssetIds.add(assetId);
    return Stream.value(detail);
  }

  @override
  Stream<AssetDetail?> watchMyAssetDetail({
    required AssetConfigurationPrincipal principal,
    required String assetId,
  }) {
    principals.add(principal);
    selfServiceDetailAssetIds.add(assetId);
    return Stream.value(detail);
  }

  @override
  Stream<List<AssetSummary>> watchAssetRegister({
    required AssetConfigurationPrincipal principal,
    required AssetListQuery query,
    required int limit,
  }) {
    principals.add(principal);
    return Stream.value(assets);
  }

  @override
  Stream<List<AssetSummary>> watchMyAssets({
    required AssetConfigurationPrincipal principal,
    required int limit,
  }) {
    principals.add(principal);
    return Stream.value(myAssets);
  }

  @override
  Stream<List<ConfigurationItemSummary>> watchConfigurationItems({
    required AssetConfigurationPrincipal principal,
    required int limit,
  }) {
    principals.add(principal);
    return const Stream.empty();
  }

  @override
  Stream<ConfigurationDependencyView?> watchDependencyView({
    required AssetConfigurationPrincipal principal,
    required String configurationItemId,
  }) {
    principals.add(principal);
    return const Stream.empty();
  }

  @override
  Stream<List<LicenceSummary>> watchLicences({
    required AssetConfigurationPrincipal principal,
    required int limit,
  }) {
    principals.add(principal);
    return const Stream.empty();
  }

  @override
  Stream<List<StockItemSummary>> watchStockItems({
    required AssetConfigurationPrincipal principal,
    required int limit,
  }) {
    principals.add(principal);
    return Stream.value(stockItems);
  }

  @override
  Stream<List<StockMovementSummary>> watchStockMovements({
    required AssetConfigurationPrincipal principal,
    required int limit,
  }) {
    principals.add(principal);
    return Stream.value(stockMovements);
  }

  @override
  Stream<List<SupplierSummary>> watchSuppliers({
    required AssetConfigurationPrincipal principal,
    required int limit,
  }) {
    principals.add(principal);
    return const Stream.empty();
  }

  @override
  Stream<List<ContractSummary>> watchContracts({
    required AssetConfigurationPrincipal principal,
    required int limit,
  }) {
    principals.add(principal);
    return const Stream.empty();
  }

  @override
  Stream<List<WarrantySummary>> watchWarranties({
    required AssetConfigurationPrincipal principal,
    required int limit,
  }) {
    principals.add(principal);
    return const Stream.empty();
  }
}

class RecordingAssetsCommandPort implements AssetsConfigurationCommandPort {
  final commands = <AssetsConfigurationCommand>[];
  final completer = Completer<ItsmCommandReceipt>();
  bool completeImmediately = true;

  @override
  Future<ItsmCommandReceipt> execute(AssetsConfigurationCommand command) {
    commands.add(command);
    if (!completeImmediately) return completer.future;
    return Future.value(
      ItsmCommandReceipt(
        commandId: command.context.idempotencyKey,
        acceptedAt: fixtureDate,
        wasDuplicate: false,
      ),
    );
  }
}
