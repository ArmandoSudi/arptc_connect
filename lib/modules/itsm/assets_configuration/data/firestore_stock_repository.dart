import 'package:cloud_firestore/cloud_firestore.dart';

import '../../shared/domain/pagination.dart';
import '../domain/assets_configuration_domain.dart';
import 'firestore_page_support.dart';
import 'stock_repository.dart';

class FirestoreStockRepository implements StockRepository {
  FirestoreStockRepository(FirebaseFirestore firestore)
      : _locations = firestore.collection('stockLocations'),
        _items = firestore.collection('stockItems'),
        _movements = firestore.collection('stockMovements');

  final CollectionReference<Map<String, dynamic>> _locations;
  final CollectionReference<Map<String, dynamic>> _items;
  final CollectionReference<Map<String, dynamic>> _movements;

  @override
  Stream<List<StockLocation>> watchLocations({
    bool activeOnly = true,
    int limit = PageRequest.maximumLimit,
  }) {
    requireRepositoryLimit(limit);
    Query<Map<String, dynamic>> query = _locations;
    if (activeOnly) query = query.where('isActive', isEqualTo: true);
    return query.orderBy('name').limit(limit).snapshots().map(
          (snapshot) => snapshot.docs
              .map(StockLocation.fromFirestore)
              .toList(growable: false),
        );
  }

  @override
  Future<PageResult<StockItem>> fetchItemsPage({
    required StockItemQuery query,
    required PageRequest page,
  }) {
    Query<Map<String, dynamic>> firestoreQuery = _items;
    if (query.locationId.trim().isNotEmpty) {
      firestoreQuery = firestoreQuery.where(
        'locationId',
        isEqualTo: query.locationId.trim(),
      );
    }
    if (query.lowStockOnly) {
      firestoreQuery = firestoreQuery.where('isLowStock', isEqualTo: true);
    }
    if (query.kind != null) {
      firestoreQuery =
          firestoreQuery.where('kind', isEqualTo: query.kind!.name);
    }
    return fetchFirestorePage(
      query: firestoreQuery,
      page: page,
      sortField: 'updatedAt',
      parse: StockItem.fromFirestore,
    );
  }

  @override
  Stream<StockItem?> watchItem(String stockItemId) {
    final id = requireRepositoryId(stockItemId, 'stockItemId');
    return _items.doc(id).snapshots().map(
          (snapshot) =>
              snapshot.exists ? StockItem.fromFirestore(snapshot) : null,
        );
  }

  @override
  Future<PageResult<StockMovement>> fetchMovementsPage({
    required String stockItemId,
    required PageRequest page,
  }) {
    final id = requireRepositoryId(stockItemId, 'stockItemId');
    return fetchFirestorePage(
      query: _movements.where('stockItemId', isEqualTo: id),
      page: page,
      sortField: 'occurredAt',
      parse: StockMovement.fromFirestore,
    );
  }
}
