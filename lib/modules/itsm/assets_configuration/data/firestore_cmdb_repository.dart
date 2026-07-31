import 'package:cloud_firestore/cloud_firestore.dart';

import '../../shared/domain/pagination.dart';
import '../domain/assets_configuration_domain.dart';
import 'cmdb_repository.dart';
import 'firestore_page_support.dart';

abstract final class CmdbFirestoreFields {
  static const itemType = 'ciType';
  static const relationshipSource = 'sourceEntityId';
  static const relationshipTarget = 'targetEntityId';
}

class FirestoreCmdbRepository implements CmdbRepository {
  FirestoreCmdbRepository(FirebaseFirestore firestore)
      : _items = firestore.collection('configurationItems'),
        _relationships = firestore.collection('ciRelationships');

  final CollectionReference<Map<String, dynamic>> _items;
  final CollectionReference<Map<String, dynamic>> _relationships;

  @override
  Future<PageResult<ConfigurationItem>> fetchItemsPage({
    required ConfigurationItemQuery query,
    required PageRequest page,
  }) {
    Query<Map<String, dynamic>> firestoreQuery = _items;
    if (query.type != null) {
      firestoreQuery = firestoreQuery.where(
        CmdbFirestoreFields.itemType,
        isEqualTo: query.type!.value,
      );
    }
    if (query.operationalStatus != null) {
      firestoreQuery = firestoreQuery.where(
        'operationalStatus',
        isEqualTo: query.operationalStatus!.name,
      );
    }
    if (query.criticality != null) {
      firestoreQuery = firestoreQuery.where(
        'criticality',
        isEqualTo: query.criticality!.name,
      );
    }
    if (query.supportGroupId.trim().isNotEmpty) {
      firestoreQuery = firestoreQuery.where(
        'supportGroupId',
        isEqualTo: query.supportGroupId.trim(),
      );
    }
    return fetchFirestorePage(
      query: firestoreQuery,
      page: page,
      sortField: 'updatedAt',
      parse: ConfigurationItem.fromFirestore,
    );
  }

  @override
  Stream<ConfigurationItem?> watchItem(String configurationItemId) {
    final id = requireRepositoryId(
      configurationItemId,
      'configurationItemId',
    );
    return _items.doc(id).snapshots().map(
          (snapshot) => snapshot.exists
              ? ConfigurationItem.fromFirestore(snapshot)
              : null,
        );
  }

  @override
  Future<PageResult<CiRelationship>> fetchOutgoingRelationships({
    required String configurationItemId,
    required PageRequest page,
  }) {
    final id = requireRepositoryId(
      configurationItemId,
      'configurationItemId',
    );
    return fetchFirestorePage(
      query: _relationships.where(
        CmdbFirestoreFields.relationshipSource,
        isEqualTo: id,
      ),
      page: page,
      sortField: 'createdAt',
      parse: CiRelationship.fromFirestore,
    );
  }

  @override
  Future<PageResult<CiRelationship>> fetchIncomingRelationships({
    required String configurationItemId,
    required PageRequest page,
  }) {
    final id = requireRepositoryId(
      configurationItemId,
      'configurationItemId',
    );
    return fetchFirestorePage(
      query: _relationships.where(
        CmdbFirestoreFields.relationshipTarget,
        isEqualTo: id,
      ),
      page: page,
      sortField: 'createdAt',
      parse: CiRelationship.fromFirestore,
    );
  }
}
