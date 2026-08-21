import 'package:cloud_firestore/cloud_firestore.dart';

import '../application/inventory_contracts.dart';
import '../application/inventory_session.dart';
import '../domain/inventory_domain.dart';

class FirestoreInventoryRepository implements InventoryReadRepository {
  const FirestoreInventoryRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<List<InventoryCatalogueItem>> watchCatalogue(
    InventoryCatalogueQuery query,
  ) {
    Query<Map<String, dynamic>> reference = _firestore
        .collection('inventoryCatalogProjections')
        .where('isActive', isEqualTo: true)
        .where('isRequestable', isEqualTo: true);
    if (query.categoryId.trim().isNotEmpty) {
      reference = reference.where(
        'categoryId',
        isEqualTo: query.categoryId.trim(),
      );
    }
    return reference.orderBy('nameLower').limit(100).snapshots().map(
          (snapshot) => _search(
            snapshot.docs.map(InventoryCatalogueItem.fromFirestore),
            query.search,
            (item) => '${item.name} ${item.sku}',
          ),
        );
  }

  @override
  Stream<List<InventoryItem>> watchItems(InventoryItemQuery query) {
    _requireLimit(query.limit);
    Query<Map<String, dynamic>> reference =
        _firestore.collection('inventoryItems');
    if (query.activeOnly) {
      reference = reference.where('isActive', isEqualTo: true);
    }
    if (query.categoryId.trim().isNotEmpty) {
      reference = reference.where(
        'categoryId',
        isEqualTo: query.categoryId.trim(),
      );
    }
    return reference.orderBy('nameLower').limit(query.limit).snapshots().map(
          (snapshot) => _search(
            snapshot.docs.map(InventoryItem.fromFirestore),
            query.search,
            (item) => '${item.name} ${item.sku}',
          ),
        );
  }

  @override
  Future<InventoryPageResult<InventoryItem>> fetchItemsPage(
    InventoryItemQuery request,
    InventoryPageRequest page,
  ) async {
    page.validate();
    Query<Map<String, dynamic>> query = _firestore.collection('inventoryItems');
    if (request.activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }
    if (request.categoryId.trim().isNotEmpty) {
      query = query.where('categoryId', isEqualTo: request.categoryId.trim());
    }
    query = query.orderBy('nameLower').orderBy(FieldPath.documentId);
    query = _startAfter(query, page.cursor);
    final snapshot = await query.limit(page.limit).get();
    final items = _search(
      snapshot.docs.map(InventoryItem.fromFirestore),
      request.search,
      (item) => '${item.name} ${item.sku}',
    );
    return _pageResult(
      items: items,
      documents: snapshot.docs,
      pageSize: page.limit,
      sortField: 'nameLower',
    );
  }

  @override
  Stream<InventoryItem?> watchItem(String itemId) => _firestore
      .collection('inventoryItems')
      .doc(itemId.trim())
      .snapshots()
      .map((snapshot) =>
          snapshot.exists ? InventoryItem.fromFirestore(snapshot) : null);

  @override
  Stream<List<InventoryWarehouse>> watchWarehouses({bool activeOnly = false}) {
    Query<Map<String, dynamic>> query =
        _firestore.collection('inventoryWarehouses');
    if (activeOnly) query = query.where('isActive', isEqualTo: true);
    return query.orderBy('nameLower').limit(100).snapshots().map(
          (snapshot) => snapshot.docs
              .map(InventoryWarehouse.fromFirestore)
              .toList(growable: false),
        );
  }

  @override
  Stream<List<InventoryLocation>> watchLocations({String warehouseId = ''}) {
    Query<Map<String, dynamic>> query =
        _firestore.collection('inventoryLocations');
    if (warehouseId.trim().isNotEmpty) {
      query = query.where('warehouseId', isEqualTo: warehouseId.trim());
    }
    return query.orderBy('nameLower').limit(100).snapshots().map(
          (snapshot) => snapshot.docs
              .map(InventoryLocation.fromFirestore)
              .toList(growable: false),
        );
  }

  @override
  Stream<List<InventoryParameter>> watchParameters(
    InventoryParameterType type,
  ) =>
      _firestore
          .collection('inventoryParameters')
          .where('type', isEqualTo: type.value)
          .orderBy('nameLower')
          .limit(100)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map(InventoryParameter.fromFirestore)
                .toList(growable: false),
          );

  @override
  Stream<List<InventoryBalance>> watchBalances({String itemId = ''}) {
    Query<Map<String, dynamic>> query =
        _firestore.collection('inventoryBalances');
    if (itemId.trim().isNotEmpty) {
      query = query.where('itemId', isEqualTo: itemId.trim());
    }
    return query.orderBy('itemNameLower').limit(100).snapshots().map(
          (snapshot) => snapshot.docs
              .map(InventoryBalance.fromFirestore)
              .toList(growable: false),
        );
  }

  @override
  Stream<List<InventoryStockMovement>> watchMovements({
    String itemId = '',
    String requestId = '',
    int limit = 100,
  }) {
    _requireLimit(limit);
    Query<Map<String, dynamic>> query =
        _firestore.collection('inventoryStockMovements');
    if (itemId.trim().isNotEmpty) {
      query = query.where('itemId', isEqualTo: itemId.trim());
    }
    if (requestId.trim().isNotEmpty) {
      query = query.where('relatedRequestId', isEqualTo: requestId.trim());
    }
    return query
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(InventoryStockMovement.fromFirestore)
              .toList(growable: false),
        );
  }

  @override
  Future<InventoryPageResult<InventoryStockMovement>> fetchMovementsPage({
    required InventoryMovementQuery query,
    required InventoryPageRequest page,
  }) async {
    page.validate();
    Query<Map<String, dynamic>> reference =
        _firestore.collection('inventoryStockMovements');
    if (query.itemId.trim().isNotEmpty) {
      reference = reference.where('itemId', isEqualTo: query.itemId.trim());
    }
    if (query.requestId.trim().isNotEmpty) {
      reference = reference.where(
        'relatedRequestId',
        isEqualTo: query.requestId.trim(),
      );
    }
    reference = reference
        .orderBy('createdAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true);
    reference = _startAfter(reference, page.cursor);
    final snapshot = await reference.limit(page.limit).get();
    return _pageResult(
      items: snapshot.docs
          .map(InventoryStockMovement.fromFirestore)
          .toList(growable: false),
      documents: snapshot.docs,
      pageSize: page.limit,
      sortField: 'createdAt',
    );
  }

  @override
  Stream<List<MaterialRequest>> watchRequests(
    InventorySession session,
    InventoryRequestQuery request,
  ) {
    _requireLimit(request.limit);
    Query<Map<String, dynamic>> query =
        _firestore.collection('materialRequests');
    if (session.role == InventoryRole.user) {
      query = query.where(
        'requestedFor.userId',
        isEqualTo: session.userId,
      );
    } else if (request.assignedToMe) {
      query = query.where(
        'assignedManager.userId',
        isEqualTo: session.userId,
      );
    }
    if (request.statuses.isNotEmpty) {
      query = query.where(
        'status',
        whereIn: request.statuses
            .map((status) => status.firestoreValue)
            .toList(growable: false),
      );
    }
    return query
        .orderBy('updatedAt', descending: true)
        .limit(request.limit)
        .snapshots()
        .map(
          (snapshot) => _search(
            snapshot.docs.map(MaterialRequest.fromFirestore),
            request.search,
            (entry) => '${entry.requestNumber} ${entry.requestedFor.name}',
          ),
        );
  }

  @override
  Future<InventoryPageResult<MaterialRequest>> fetchRequestsPage(
    InventorySession session,
    InventoryRequestQuery request,
    InventoryPageRequest page,
  ) async {
    page.validate();
    Query<Map<String, dynamic>> query =
        _firestore.collection('materialRequests');
    if (session.role == InventoryRole.user) {
      query = query.where('requestedFor.userId', isEqualTo: session.userId);
    } else if (request.assignedToMe) {
      query = query.where(
        'assignedManager.userId',
        isEqualTo: session.userId,
      );
    }
    if (request.statuses.isNotEmpty) {
      query = query.where(
        'status',
        whereIn: request.statuses
            .map((status) => status.firestoreValue)
            .toList(growable: false),
      );
    }
    query = query
        .orderBy('updatedAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true);
    query = _startAfter(query, page.cursor);
    final snapshot = await query.limit(page.limit).get();
    final items = _search(
      snapshot.docs.map(MaterialRequest.fromFirestore),
      request.search,
      (entry) => '${entry.requestNumber} ${entry.requestedFor.name}',
    );
    return _pageResult(
      items: items,
      documents: snapshot.docs,
      pageSize: page.limit,
      sortField: 'updatedAt',
    );
  }

  @override
  Stream<MaterialRequest?> watchRequest(String requestId) => _firestore
      .collection('materialRequests')
      .doc(requestId.trim())
      .snapshots()
      .map((snapshot) =>
          snapshot.exists ? MaterialRequest.fromFirestore(snapshot) : null);

  @override
  Stream<List<MaterialRequestLine>> watchRequestLines(String requestId) =>
      _firestore
          .collection('materialRequests')
          .doc(requestId.trim())
          .collection('lines')
          .orderBy('itemNameLower')
          .limit(100)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map(MaterialRequestLine.fromFirestore)
                .toList(growable: false),
          );

  @override
  Stream<List<MaterialRequestAllocation>> watchRequestAllocations(
    String requestId,
  ) =>
      _firestore
          .collection('materialRequests')
          .doc(requestId.trim())
          .collection('allocations')
          .orderBy('createdAt')
          .limit(100)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map(MaterialRequestAllocation.fromFirestore)
                .toList(growable: false),
          );

  @override
  Stream<List<InventoryAlert>> watchActiveAlerts({int limit = 100}) {
    _requireLimit(limit);
    return _firestore
        .collection('inventoryAlerts')
        .where('isActive', isEqualTo: true)
        .orderBy('triggeredAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(InventoryAlert.fromFirestore)
              .toList(growable: false),
        );
  }

  @override
  Stream<List<InventoryAuditEvent>> watchAudit({int limit = 100}) {
    _requireLimit(limit);
    return _firestore
        .collection('inventoryAuditEvents')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(InventoryAuditEvent.fromFirestore)
              .toList(growable: false),
        );
  }

  @override
  Stream<InventoryDashboardStats> watchDashboard(InventoryRole role) =>
      _firestore
          .collection('inventoryDashboardSnapshots')
          .doc(role == InventoryRole.admin ? 'admin' : 'manager')
          .snapshots()
          .map((snapshot) => _dashboard(snapshot.data()));
}

List<T> _search<T>(
  Iterable<T> values,
  String input,
  String Function(T value) text,
) {
  final search = input.trim().toLowerCase();
  return values
      .where((value) =>
          search.isEmpty || text(value).toLowerCase().contains(search))
      .toList(growable: false);
}

void _requireLimit(int limit) {
  if (limit < 1 || limit > 100) throw RangeError.range(limit, 1, 100, 'limit');
}

InventoryDashboardStats _dashboard(Map<String, dynamic>? data) {
  final map = data ?? const <String, dynamic>{};
  Map<String, num> numbers(String key) {
    final raw = map[key];
    if (raw is! Map) return const {};
    return raw.map(
      (key, value) => MapEntry(key.toString(), value is num ? value : 0),
    );
  }

  return InventoryDashboardStats(
    submittedCount: (map['submittedCount'] as num?)?.toInt() ?? 0,
    underReviewCount: (map['underReviewCount'] as num?)?.toInt() ?? 0,
    readyForIssueCount: (map['readyForIssueCount'] as num?)?.toInt() ?? 0,
    partiallyFulfilledCount:
        (map['partiallyFulfilledCount'] as num?)?.toInt() ?? 0,
    lowStockCount: (map['lowStockCount'] as num?)?.toInt() ?? 0,
    outOfStockCount: (map['outOfStockCount'] as num?)?.toInt() ?? 0,
    fulfilledTodayCount: (map['fulfilledTodayCount'] as num?)?.toInt() ?? 0,
    averageFulfillmentMinutes: map['averageFulfillmentMinutes'] as num? ?? 0,
    requestsByStatus: numbers('requestsByStatus'),
    topRequestedItems: numbers('topRequestedItems'),
    consumptionByDepartment: numbers('consumptionByDepartment'),
    issuesVsReceipts: numbers('issuesVsReceipts'),
    lowStockByWarehouse: numbers('lowStockByWarehouse'),
    monthlyFulfillmentTrend: numbers('monthlyFulfillmentTrend'),
    oldestPendingRequests: const [],
    recentMovements: const [],
  );
}

Query<Map<String, dynamic>> _startAfter(
  Query<Map<String, dynamic>> query,
  InventoryPageCursor? cursor,
) {
  if (cursor == null) return query;
  final value = cursor.sortValue is DateTime
      ? Timestamp.fromDate(cursor.sortValue! as DateTime)
      : cursor.sortValue;
  return query.startAfter([value, cursor.documentId]);
}

InventoryPageResult<T> _pageResult<T>({
  required List<T> items,
  required List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  required int pageSize,
  required String sortField,
}) {
  final last = documents.isEmpty ? null : documents.last;
  return InventoryPageResult<T>(
    items: items,
    hasMore: documents.length == pageSize,
    nextCursor: last == null
        ? null
        : InventoryPageCursor(
            documentId: last.id,
            sortValue:
                inventoryDate(last.data()[sortField]) ?? last.data()[sortField],
          ),
  );
}
