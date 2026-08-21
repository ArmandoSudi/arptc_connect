import '../domain/inventory_domain.dart';
import 'inventory_session.dart';

abstract final class InventoryCommands {
  static const saveItem = 'inventorySaveItem';
  static const setItemActive = 'inventorySetItemActive';
  static const saveWarehouse = 'inventorySaveWarehouse';
  static const saveLocation = 'inventorySaveLocation';
  static const saveParameter = 'inventorySaveParameter';
  static const receiveStock = 'inventoryReceiveStock';
  static const returnStock = 'inventoryReturnStock';
  static const transferStock = 'inventoryTransferStock';
  static const adjustStock = 'inventoryAdjustStock';
  static const reconcileStock = 'inventoryReconcileStock';
  static const setBalanceThreshold = 'inventorySetBalanceThreshold';
  static const submitRequest = 'inventorySubmitRequest';
  static const startReview = 'inventoryStartReview';
  static const takeOverRequest = 'inventoryTakeOverRequest';
  static const adjustRequestLine = 'inventoryAdjustRequestLine';
  static const reserveRequestLine = 'inventoryReserveRequestLine';
  static const markRequestReady = 'inventoryMarkRequestReady';
  static const issueRequest = 'inventoryIssueRequest';
  static const closeShortfall = 'inventoryCloseShortfall';
  static const cancelRequest = 'inventoryCancelRequest';
  static const rejectRequest = 'inventoryRejectRequest';
  static const confirmReceipt = 'inventoryConfirmReceipt';
}

class InventoryCatalogueQuery {
  const InventoryCatalogueQuery({this.search = '', this.categoryId = ''});

  final String search;
  final String categoryId;

  @override
  bool operator ==(Object other) =>
      other is InventoryCatalogueQuery &&
      other.search == search &&
      other.categoryId == categoryId;

  @override
  int get hashCode => Object.hash(search, categoryId);
}

class InventoryRequestQuery {
  const InventoryRequestQuery({
    this.statuses = const [],
    this.search = '',
    this.assignedToMe = false,
    this.limit = 100,
  });

  final List<MaterialRequestStatus> statuses;
  final String search;
  final bool assignedToMe;
  final int limit;

  @override
  bool operator ==(Object other) =>
      other is InventoryRequestQuery &&
      _sameStatuses(other.statuses, statuses) &&
      other.search == search &&
      other.assignedToMe == assignedToMe &&
      other.limit == limit;

  @override
  int get hashCode => Object.hash(
        Object.hashAll(statuses),
        search,
        assignedToMe,
        limit,
      );
}

class InventoryItemQuery {
  const InventoryItemQuery({
    this.search = '',
    this.categoryId = '',
    this.activeOnly = false,
    this.limit = 100,
  });

  final String search;
  final String categoryId;
  final bool activeOnly;
  final int limit;

  @override
  bool operator ==(Object other) =>
      other is InventoryItemQuery &&
      other.search == search &&
      other.categoryId == categoryId &&
      other.activeOnly == activeOnly &&
      other.limit == limit;

  @override
  int get hashCode => Object.hash(search, categoryId, activeOnly, limit);
}

class InventoryMovementQuery {
  const InventoryMovementQuery({
    this.itemId = '',
    this.requestId = '',
    this.limit = 100,
  });

  final String itemId;
  final String requestId;
  final int limit;

  @override
  bool operator ==(Object other) =>
      other is InventoryMovementQuery &&
      other.itemId == itemId &&
      other.requestId == requestId &&
      other.limit == limit;

  @override
  int get hashCode => Object.hash(itemId, requestId, limit);
}

abstract interface class InventoryReadRepository {
  Stream<List<InventoryCatalogueItem>> watchCatalogue(
    InventoryCatalogueQuery query,
  );

  Stream<List<InventoryItem>> watchItems(InventoryItemQuery query);
  Future<InventoryPageResult<InventoryItem>> fetchItemsPage(
    InventoryItemQuery query,
    InventoryPageRequest page,
  );
  Stream<InventoryItem?> watchItem(String itemId);
  Stream<List<InventoryWarehouse>> watchWarehouses({bool activeOnly = false});
  Stream<List<InventoryLocation>> watchLocations({String warehouseId = ''});
  Stream<List<InventoryParameter>> watchParameters(
    InventoryParameterType type,
  );
  Stream<List<InventoryBalance>> watchBalances({String itemId = ''});
  Stream<List<InventoryStockMovement>> watchMovements({
    String itemId = '',
    String requestId = '',
    int limit = 100,
  });
  Future<InventoryPageResult<InventoryStockMovement>> fetchMovementsPage({
    required InventoryMovementQuery query,
    required InventoryPageRequest page,
  });
  Stream<List<MaterialRequest>> watchRequests(
    InventorySession session,
    InventoryRequestQuery query,
  );
  Future<InventoryPageResult<MaterialRequest>> fetchRequestsPage(
    InventorySession session,
    InventoryRequestQuery query,
    InventoryPageRequest page,
  );
  Stream<MaterialRequest?> watchRequest(String requestId);
  Stream<List<MaterialRequestLine>> watchRequestLines(String requestId);
  Stream<List<MaterialRequestAllocation>> watchRequestAllocations(
    String requestId,
  );
  Stream<List<InventoryAlert>> watchActiveAlerts({int limit = 100});
  Stream<List<InventoryAuditEvent>> watchAudit({int limit = 100});
  Stream<InventoryDashboardStats> watchDashboard(InventoryRole role);
}

class InventoryCommand {
  InventoryCommand({
    required this.functionName,
    required this.commandId,
    required Map<String, Object?> payload,
  }) : payload = Map.unmodifiable(payload);

  final String functionName;
  final String commandId;
  final Map<String, Object?> payload;

  Map<String, Object?> toPayload() => {
        'commandId': commandId,
        ...payload,
      };
}

class InventoryCommandResult {
  const InventoryCommandResult({
    required this.commandId,
    required this.entityId,
    required this.wasReplay,
  });

  final String commandId;
  final String entityId;
  final bool wasReplay;
}

abstract interface class InventoryCommandGateway {
  Future<InventoryCommandResult> execute(InventoryCommand command);
}

class InventoryCommandException implements Exception {
  const InventoryCommandException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}

bool _sameStatuses(
  List<MaterialRequestStatus> left,
  List<MaterialRequestStatus> right,
) =>
    left.length == right.length &&
    left.asMap().entries.every((entry) => entry.value == right[entry.key]);
