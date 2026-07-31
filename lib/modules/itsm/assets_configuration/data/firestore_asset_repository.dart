import 'package:cloud_firestore/cloud_firestore.dart';

import '../../shared/domain/pagination.dart';
import '../domain/assets_configuration_domain.dart';
import 'asset_repository.dart';
import 'firestore_page_support.dart';

class FirestoreAssetRepository implements AssetRepository {
  FirestoreAssetRepository(FirebaseFirestore firestore)
      : _assets = firestore.collection('assets'),
        _assignments = firestore.collection('assetAssignments'),
        _lifecycleEvents = firestore.collection('assetLifecycleEvents');

  final CollectionReference<Map<String, dynamic>> _assets;
  final CollectionReference<Map<String, dynamic>> _assignments;
  final CollectionReference<Map<String, dynamic>> _lifecycleEvents;

  @override
  Future<PageResult<Asset>> fetchAssetsPage({
    required AssetQuery query,
    required PageRequest page,
  }) {
    Query<Map<String, dynamic>> firestoreQuery = _assets;
    if (query.status != null) {
      firestoreQuery =
          firestoreQuery.where('status', isEqualTo: query.status!.value);
    }
    if (query.categoryId.trim().isNotEmpty) {
      firestoreQuery = firestoreQuery.where(
        'categoryId',
        isEqualTo: query.categoryId.trim(),
      );
    }
    if (query.locationId.trim().isNotEmpty) {
      firestoreQuery = firestoreQuery.where(
        'locationId',
        isEqualTo: query.locationId.trim(),
      );
    }
    if (query.searchToken.trim().isNotEmpty) {
      firestoreQuery = firestoreQuery.where(
        'searchTokens',
        arrayContains: query.searchToken.trim().toLowerCase(),
      );
    }
    return fetchFirestorePage(
      query: firestoreQuery,
      page: page,
      sortField: 'updatedAt',
      parse: Asset.fromFirestore,
    );
  }

  @override
  Stream<Asset?> watchAsset(String assetId) {
    final id = requireRepositoryId(assetId, 'assetId');
    return _assets.doc(id).snapshots().map(
          (snapshot) => snapshot.exists ? Asset.fromFirestore(snapshot) : null,
        );
  }

  @override
  Future<PageResult<AssetAssignment>> fetchAssignmentsPage({
    required String assetId,
    required PageRequest page,
  }) {
    final id = requireRepositoryId(assetId, 'assetId');
    return fetchFirestorePage(
      query: _assignments.where('assetId', isEqualTo: id),
      page: page,
      sortField: 'assignedAt',
      parse: AssetAssignment.fromFirestore,
    );
  }

  @override
  Future<PageResult<AssetLifecycleEvent>> fetchLifecyclePage({
    required String assetId,
    required PageRequest page,
  }) {
    final id = requireRepositoryId(assetId, 'assetId');
    return fetchFirestorePage(
      query: _lifecycleEvents.where('assetId', isEqualTo: id),
      page: page,
      sortField: 'occurredAt',
      parse: AssetLifecycleEvent.fromFirestore,
    );
  }
}

class FirestoreMyAssetsRepository implements MyAssetsRepository {
  FirestoreMyAssetsRepository(FirebaseFirestore firestore)
      : _assignments = firestore.collection('assetAssignments');

  final CollectionReference<Map<String, dynamic>> _assignments;

  Query<Map<String, dynamic>> _currentAssignments(String currentUserId) {
    final userId = requireRepositoryId(currentUserId, 'currentUserId');
    return _assignments
        .where('assignedUserId', isEqualTo: userId)
        .where('status', isEqualTo: AssetAssignmentStatus.current.name);
  }

  @override
  Future<PageResult<AssetAssignment>> fetchMyAssetsPage({
    required String currentUserId,
    required PageRequest page,
  }) =>
      fetchFirestorePage(
        query: _currentAssignments(currentUserId),
        page: page,
        sortField: 'assignedAt',
        parse: AssetAssignment.fromFirestore,
      );

  @override
  Stream<List<AssetAssignment>> watchMyCurrentAssets({
    required String currentUserId,
    int limit = PageRequest.defaultLimit,
  }) {
    requireRepositoryLimit(limit);
    return _currentAssignments(currentUserId)
        .orderBy('assignedAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(AssetAssignment.fromFirestore)
              .toList(growable: false),
        );
  }
}
