import 'dart:collection';

import '../../shared/application/itsm_session.dart';
import '../../shared/data/trusted_command_gateways.dart';
import '../../shared/domain/itsm_common.dart';
import '../../shared/domain/pagination.dart';

enum AssetLifecycleStatus {
  planned,
  ordered,
  received,
  inStock,
  configured,
  assigned,
  inMaintenance,
  returned,
  retired,
  disposed,
  lost,
  stolen,
}

enum AssetCatalogueAction {
  reportFault,
  requestRepair,
  requestReplacement,
  requestConfiguration,
  requestReturn,
}

enum StockMovementType {
  receipt,
  reservation,
  issue,
  returnToStock,
  transfer,
  adjustment,
  reconciliation,
}

enum ContractState { draft, active, expired, terminated }

enum ComplianceState { compliant, actionRequired, assessmentPending }

class AssetConfigurationPrincipal {
  const AssetConfigurationPrincipal({
    required this.sessionKey,
    required this.userId,
    required this.role,
  });

  factory AssetConfigurationPrincipal.fromSession(ItsmSession session) {
    return AssetConfigurationPrincipal(
      sessionKey: session.sessionKey,
      userId: session.userId,
      role: session.role,
    );
  }

  final String sessionKey;
  final String userId;
  final ItsmRole role;
}

class AssetListQuery {
  const AssetListQuery({
    this.search = '',
    this.statuses = const {},
    this.categoryId,
    this.locationId,
  });

  final String search;
  final Set<AssetLifecycleStatus> statuses;
  final String? categoryId;
  final String? locationId;

  @override
  bool operator ==(Object other) {
    return other is AssetListQuery &&
        other.search == search &&
        _sameSet(other.statuses, statuses) &&
        other.categoryId == categoryId &&
        other.locationId == locationId;
  }

  @override
  int get hashCode => Object.hash(
        search,
        Object.hashAllUnordered(statuses),
        categoryId,
        locationId,
      );
}

class AssetPageRequest {
  const AssetPageRequest({required this.query, required this.page});

  final AssetListQuery query;
  final PageRequest page;

  @override
  bool operator ==(Object other) {
    return other is AssetPageRequest &&
        other.query == query &&
        other.page.limit == page.limit &&
        other.page.cursor == page.cursor &&
        other.page.direction == page.direction;
  }

  @override
  int get hashCode => Object.hash(
        query,
        page.limit,
        page.cursor,
        page.direction,
      );
}

class AssetSummary {
  const AssetSummary({
    required this.id,
    required this.assetTag,
    required this.name,
    required this.categoryName,
    required this.status,
    this.brand = '',
    this.model = '',
    this.serialNumber = '',
    this.locationName = '',
    this.assignedUserName = '',
    this.condition = '',
    this.photoUrl,
    this.updatedAt,
  });

  final String id;
  final String assetTag;
  final String name;
  final String categoryName;
  final AssetLifecycleStatus status;
  final String brand;
  final String model;
  final String serialNumber;
  final String locationName;
  final String assignedUserName;
  final String condition;
  final String? photoUrl;
  final DateTime? updatedAt;
}

class AssetLifecycleEntry {
  const AssetLifecycleEntry({
    required this.id,
    required this.status,
    required this.occurredAt,
    required this.actorName,
    this.note = '',
  });

  final String id;
  final AssetLifecycleStatus status;
  final DateTime occurredAt;
  final String actorName;
  final String note;
}

class AssetDetail {
  AssetDetail({
    required this.summary,
    this.assetId = '',
    this.barcode = '',
    this.typeName = '',
    this.description = '',
    this.acquisitionDate,
    this.acquisitionCost,
    this.supplierName = '',
    this.warrantyName = '',
    this.departmentName = '',
    this.stockLocationName = '',
    this.securityBaseline = '',
    this.complianceState = ComplianceState.assessmentPending,
    Iterable<String> attachmentNames = const [],
    Iterable<String> photographIds = const [],
    Iterable<AssetLifecycleEntry> lifecycle = const [],
  })  : attachmentNames = List.unmodifiable(attachmentNames),
        photographIds = List.unmodifiable(photographIds),
        lifecycle = List.unmodifiable(lifecycle);

  final AssetSummary summary;
  final String assetId;
  final String barcode;
  final String typeName;
  final String description;
  final DateTime? acquisitionDate;
  final num? acquisitionCost;
  final String supplierName;
  final String warrantyName;
  final String departmentName;
  final String stockLocationName;
  final String securityBaseline;
  final ComplianceState complianceState;
  final List<String> attachmentNames;
  final List<String> photographIds;
  final List<AssetLifecycleEntry> lifecycle;
}

class StockItemSummary {
  const StockItemSummary({
    required this.id,
    required this.name,
    required this.sku,
    required this.quantity,
    required this.minimumQuantity,
    required this.locationName,
    this.barcode = '',
    this.isConsumable = false,
  });

  final String id;
  final String name;
  final String sku;
  final num quantity;
  final num minimumQuantity;
  final String locationName;
  final String barcode;
  final bool isConsumable;

  bool get isLowStock => quantity <= minimumQuantity;
}

class StockMovementSummary {
  const StockMovementSummary({
    required this.id,
    required this.itemName,
    required this.type,
    required this.quantity,
    required this.actorName,
    required this.occurredAt,
    this.sourceName = '',
    this.destinationName = '',
    this.recipientName = '',
    this.relatedRequestNumber = '',
    this.supportingDocumentName = '',
  });

  final String id;
  final String itemName;
  final StockMovementType type;
  final num quantity;
  final String actorName;
  final DateTime occurredAt;
  final String sourceName;
  final String destinationName;
  final String recipientName;
  final String relatedRequestNumber;
  final String supportingDocumentName;
}

class LicenceSummary {
  const LicenceSummary({
    required this.id,
    required this.productName,
    required this.vendorName,
    required this.licenceType,
    required this.purchasedQuantity,
    required this.allocatedQuantity,
    required this.complianceState,
    this.effectiveAt,
    this.expiresAt,
    this.renewsAt,
    this.contractNumber = '',
  });

  final String id;
  final String productName;
  final String vendorName;
  final String licenceType;
  final int purchasedQuantity;
  final int allocatedQuantity;
  final ComplianceState complianceState;
  final DateTime? effectiveAt;
  final DateTime? expiresAt;
  final DateTime? renewsAt;
  final String contractNumber;

  int get availableQuantity => purchasedQuantity - allocatedQuantity;
}

class SupplierSummary {
  const SupplierSummary({
    required this.id,
    required this.name,
    this.contactName = '',
    this.email = '',
    this.phone = '',
    this.supportTerms = '',
    this.slaName = '',
  });

  final String id;
  final String name;
  final String contactName;
  final String email;
  final String phone;
  final String supportTerms;
  final String slaName;
}

class ContractSummary {
  const ContractSummary({
    required this.id,
    required this.number,
    required this.title,
    required this.supplierName,
    required this.state,
    this.startsAt,
    this.endsAt,
  });

  final String id;
  final String number;
  final String title;
  final String supplierName;
  final ContractState state;
  final DateTime? startsAt;
  final DateTime? endsAt;
}

class WarrantySummary {
  const WarrantySummary({
    required this.id,
    required this.name,
    required this.supplierName,
    required this.coverage,
    required this.linkedAssetCount,
    this.expiresAt,
  });

  final String id;
  final String name;
  final String supplierName;
  final String coverage;
  final int linkedAssetCount;
  final DateTime? expiresAt;
}

class ConfigurationItemSummary {
  const ConfigurationItemSummary({
    required this.id,
    required this.name,
    required this.typeName,
    required this.criticality,
    required this.operationalStatus,
    this.ownerName = '',
    this.supportGroupName = '',
    this.linkedAssetTag = '',
    this.dataQuality = '',
  });

  final String id;
  final String name;
  final String typeName;
  final String criticality;
  final String operationalStatus;
  final String ownerName;
  final String supportGroupName;
  final String linkedAssetTag;
  final String dataQuality;
}

class ConfigurationRelationship {
  const ConfigurationRelationship({
    required this.id,
    required this.sourceId,
    required this.sourceName,
    required this.type,
    required this.targetId,
    required this.targetName,
  });

  final String id;
  final String sourceId;
  final String sourceName;
  final String type;
  final String targetId;
  final String targetName;
}

class ConfigurationDependencyView {
  ConfigurationDependencyView({
    required this.root,
    Iterable<ConfigurationItemSummary> items = const [],
    Iterable<ConfigurationRelationship> relationships = const [],
  })  : items = List.unmodifiable(items),
        relationships = List.unmodifiable(relationships);

  final ConfigurationItemSummary root;
  final List<ConfigurationItemSummary> items;
  final List<ConfigurationRelationship> relationships;
}

abstract interface class AssetsConfigurationReadPort {
  Stream<List<AssetSummary>> watchMyAssets({
    required AssetConfigurationPrincipal principal,
    required int limit,
  });

  Stream<List<AssetSummary>> watchAssetRegister({
    required AssetConfigurationPrincipal principal,
    required AssetListQuery query,
    required int limit,
  });

  Future<PageResult<AssetSummary>> fetchAssetPage({
    required AssetConfigurationPrincipal principal,
    required AssetPageRequest request,
  });

  Stream<AssetDetail?> watchAssetDetail({
    required AssetConfigurationPrincipal principal,
    required String assetId,
  });

  Stream<AssetDetail?> watchMyAssetDetail({
    required AssetConfigurationPrincipal principal,
    required String assetId,
  });

  Stream<List<StockItemSummary>> watchStockItems({
    required AssetConfigurationPrincipal principal,
    required int limit,
  });

  Stream<List<StockMovementSummary>> watchStockMovements({
    required AssetConfigurationPrincipal principal,
    required int limit,
  });

  Stream<List<LicenceSummary>> watchLicences({
    required AssetConfigurationPrincipal principal,
    required int limit,
  });

  Stream<List<SupplierSummary>> watchSuppliers({
    required AssetConfigurationPrincipal principal,
    required int limit,
  });

  Stream<List<ContractSummary>> watchContracts({
    required AssetConfigurationPrincipal principal,
    required int limit,
  });

  Stream<List<WarrantySummary>> watchWarranties({
    required AssetConfigurationPrincipal principal,
    required int limit,
  });

  Stream<List<ConfigurationItemSummary>> watchConfigurationItems({
    required AssetConfigurationPrincipal principal,
    required int limit,
  });

  Stream<ConfigurationDependencyView?> watchDependencyView({
    required AssetConfigurationPrincipal principal,
    required String configurationItemId,
  });
}

sealed class AssetsConfigurationCommand {
  const AssetsConfigurationCommand({required this.context});

  final ItsmCommandContext context;
}

class AssetOperationalCommand extends AssetsConfigurationCommand {
  AssetOperationalCommand({
    required super.context,
    required this.assetId,
    required this.operation,
    Map<String, Object?> fields = const {},
  }) : fields = UnmodifiableMapView(Map.of(fields));

  final String assetId;
  final String operation;
  final Map<String, Object?> fields;
}

class StockMovementCommand extends AssetsConfigurationCommand {
  const StockMovementCommand({
    required super.context,
    required this.itemId,
    required this.type,
    required this.quantity,
    required this.actorUserId,
    this.sourceLocationId,
    this.destinationLocationId,
    this.recipientUserId,
    this.relatedRequestId,
    this.supportingDocumentId,
    this.reason,
    this.reservedQuantity = 0,
    this.adjustmentDelta,
    this.targetOnHand,
    this.targetReserved = 0,
  });

  final String itemId;
  final StockMovementType type;
  final num quantity;
  final String actorUserId;
  final String? sourceLocationId;
  final String? destinationLocationId;
  final String? recipientUserId;
  final String? relatedRequestId;
  final String? supportingDocumentId;
  final String? reason;
  final num reservedQuantity;
  final num? adjustmentDelta;
  final num? targetOnHand;
  final num targetReserved;
}

class ManagerConfigurationCommand extends AssetsConfigurationCommand {
  ManagerConfigurationCommand({
    required super.context,
    required this.recordType,
    required this.operation,
    required this.recordId,
    Map<String, Object?> fields = const {},
  }) : fields = UnmodifiableMapView(Map.of(fields));

  final String recordType;
  final String operation;
  final String recordId;
  final Map<String, Object?> fields;
}

abstract interface class AssetsConfigurationCommandPort {
  Future<ItsmCommandReceipt> execute(AssetsConfigurationCommand command);
}

class AssetsConfigurationAccessDenied implements Exception {
  const AssetsConfigurationAccessDenied(this.message);

  final String message;

  @override
  String toString() => 'AssetsConfigurationAccessDenied($message)';
}

class AssetsConfigurationPortUnavailable implements Exception {
  const AssetsConfigurationPortUnavailable(this.port);

  final String port;

  @override
  String toString() => 'AssetsConfigurationPortUnavailable($port)';
}

bool _sameSet<T>(Set<T> left, Set<T> right) {
  return left.length == right.length && left.containsAll(right);
}
