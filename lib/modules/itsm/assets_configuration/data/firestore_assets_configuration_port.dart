import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../shared/data/trusted_command_gateways.dart';
import '../../shared/domain/itsm_common.dart';
import '../../shared/domain/pagination.dart';
import '../application/assets_configuration_contracts.dart' as application;
import '../domain/assets_configuration_domain.dart' as domain;
import 'firestore_page_support.dart';

abstract final class AssetsConfigurationFirestoreCollections {
  static const assetSelfServiceProjections = 'assetSelfServiceProjections';
}

/// Complete metadata required by the trusted stock movement validator.
class StockSupportingDocumentMetadata {
  const StockSupportingDocumentMetadata({
    required this.attachmentId,
    required this.stockItemId,
    required this.storagePath,
    required this.fileName,
    required this.contentType,
    required this.sizeBytes,
    this.checksum = '',
  });

  final String attachmentId;
  final String stockItemId;
  final String storagePath;
  final String fileName;
  final String contentType;
  final int sizeBytes;
  final String checksum;

  bool get isValid =>
      attachmentId.trim().isNotEmpty &&
      stockItemId.trim().isNotEmpty &&
      storagePath.startsWith(
        'itsm/stock/${stockItemId.trim()}/supportingDocuments/'
        '${attachmentId.trim()}/',
      ) &&
      !storagePath.contains('..') &&
      fileName.trim().isNotEmpty &&
      contentType.trim().isNotEmpty &&
      sizeBytes >= 0;

  Map<String, Object?> toCommandPayload() => {
        'attachmentId': attachmentId.trim(),
        'storagePath': storagePath.trim(),
        'fileName': fileName.trim(),
        'contentType': contentType.trim(),
        'sizeBytes': sizeBytes,
        if (checksum.trim().isNotEmpty) 'checksum': checksum.trim(),
      };
}

/// Injectable read boundary used by the port and focused unit tests.
abstract interface class AssetsConfigurationReadAdapter {
  Stream<List<domain.AssetSelfServiceProjection>> watchMyAssetProjections({
    required String currentUserId,
    required int limit,
  });

  Stream<domain.AssetSelfServiceProjection?> watchMyAssetProjection({
    required String currentUserId,
    required String assetId,
  });

  Stream<List<domain.Asset>> watchAssets({
    required application.AssetListQuery query,
    required int limit,
  });

  Future<PageResult<domain.Asset>> fetchAssetPage({
    required application.AssetListQuery query,
    required PageRequest page,
  });

  Stream<domain.Asset?> watchAsset(String assetId);

  Future<List<domain.AssetLifecycleEvent>> fetchAssetLifecycle({
    required String assetId,
    required int limit,
  });

  Stream<List<domain.AssetAssignment>> watchAssetAssignments({
    required String assetId,
    required int limit,
  });

  Stream<List<domain.AssetStateEvent>> watchAssetStateEvents({
    required String assetId,
    required int limit,
  });

  Stream<List<domain.AssetParameter>> watchAssetParameters({
    required int limit,
  });

  Stream<List<domain.AssetAssignee>> watchAssetAssignees({
    required int limit,
    String organizationId = '',
    String search = '',
  });

  Stream<List<domain.StockItem>> watchStockItems({required int limit});

  Stream<List<domain.StockMovement>> watchStockMovements({
    required int limit,
  });

  Stream<List<domain.SoftwareLicence>> watchLicences({required int limit});

  Stream<List<domain.Supplier>> watchSuppliers({required int limit});

  Stream<List<domain.SupplierContract>> watchContracts({required int limit});

  Stream<List<domain.Warranty>> watchWarranties({required int limit});

  Stream<List<domain.ConfigurationItem>> watchConfigurationItems({
    required int limit,
  });

  Stream<List<domain.CiRelationship>> watchConfigurationRelationships({
    required String configurationItemId,
    required int limit,
  });

  Future<int> fetchAssetRevision(String assetId);

  Future<StockSupportingDocumentMetadata?> resolveSupportingDocument(
    String attachmentId,
  );
}

abstract interface class AssetsConfigurationCallableInvoker {
  Future<Object?> invoke(String functionName, Map<String, Object?> envelope);
}

class FirebaseAssetsConfigurationCallableInvoker
    implements AssetsConfigurationCallableInvoker {
  const FirebaseAssetsConfigurationCallableInvoker(this._functions);

  final FirebaseFunctions _functions;

  @override
  Future<Object?> invoke(
    String functionName,
    Map<String, Object?> envelope,
  ) async =>
      (await _functions.httpsCallable(functionName).call(envelope)).data;
}

/// Firestore-backed, bounded query implementation for the presentation port.
class FirestoreAssetsConfigurationReadAdapter
    implements AssetsConfigurationReadAdapter {
  FirestoreAssetsConfigurationReadAdapter(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<List<domain.AssetSelfServiceProjection>> watchMyAssetProjections({
    required String currentUserId,
    required int limit,
  }) {
    final userId = requireRepositoryId(currentUserId, 'currentUserId');
    requireRepositoryLimit(limit);
    return _firestore
        .collection(
          AssetsConfigurationFirestoreCollections.assetSelfServiceProjections,
        )
        .where('assignedUserId', isEqualTo: userId)
        .where('isCurrent', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(domain.AssetSelfServiceProjection.fromFirestore)
              .toList(growable: false),
        );
  }

  @override
  Stream<domain.AssetSelfServiceProjection?> watchMyAssetProjection({
    required String currentUserId,
    required String assetId,
  }) {
    final userId = requireRepositoryId(currentUserId, 'currentUserId');
    final id = requireRepositoryId(assetId, 'assetId');
    return _firestore
        .collection(
          AssetsConfigurationFirestoreCollections.assetSelfServiceProjections,
        )
        .where('assignedUserId', isEqualTo: userId)
        .where('assetId', isEqualTo: id)
        .where('isCurrent', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true)
        .limit(1)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.isEmpty
              ? null
              : domain.AssetSelfServiceProjection.fromFirestore(
                  snapshot.docs.single,
                ),
        );
  }

  @override
  Stream<List<domain.Asset>> watchAssets({
    required application.AssetListQuery query,
    required int limit,
  }) {
    requireRepositoryLimit(limit);
    final firestoreQuery = _assetQuery(query)
        .orderBy('updatedAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true)
        .limit(limit);
    return firestoreQuery.snapshots().map(
          (snapshot) => snapshot.docs
              .map(domain.Asset.fromFirestore)
              .toList(growable: false),
        );
  }

  @override
  Future<PageResult<domain.Asset>> fetchAssetPage({
    required application.AssetListQuery query,
    required PageRequest page,
  }) =>
      fetchFirestorePage(
        query: _assetQuery(query),
        page: page,
        sortField: 'updatedAt',
        parse: domain.Asset.fromFirestore,
      );

  Query<Map<String, dynamic>> _assetQuery(application.AssetListQuery request) {
    Query<Map<String, dynamic>> query = _firestore.collection('assets');
    final statuses = request.statuses
        .map(_applicationAssetStatusValue)
        .toList(growable: false);
    if (statuses.length == 1) {
      query = query.where('status', isEqualTo: statuses.single);
    } else if (statuses.length > 1 && statuses.length <= 10) {
      query = query.where('status', whereIn: statuses);
    } else if (statuses.length > 10) {
      throw ArgumentError.value(
        statuses.length,
        'statuses',
        'Firestore supports at most 10 status values per bounded query.',
      );
    }
    if ((request.categoryId ?? '').trim().isNotEmpty) {
      query = query.where(
        'categoryId',
        isEqualTo: request.categoryId!.trim(),
      );
    }
    if ((request.locationId ?? '').trim().isNotEmpty) {
      query = query.where(
        'locationId',
        isEqualTo: request.locationId!.trim(),
      );
    }
    final searchToken = request.search.trim().toLowerCase().split(' ').first;
    if (searchToken.isNotEmpty) {
      query = query.where('searchTokens', arrayContains: searchToken);
    }
    return query;
  }

  @override
  Stream<domain.Asset?> watchAsset(String assetId) {
    final id = requireRepositoryId(assetId, 'assetId');
    return _firestore.collection('assets').doc(id).snapshots().map(
          (snapshot) =>
              snapshot.exists ? domain.Asset.fromFirestore(snapshot) : null,
        );
  }

  @override
  Future<List<domain.AssetLifecycleEvent>> fetchAssetLifecycle({
    required String assetId,
    required int limit,
  }) async {
    final id = requireRepositoryId(assetId, 'assetId');
    requireRepositoryLimit(limit);
    final snapshot = await _firestore
        .collection('assetLifecycleEvents')
        .where('assetId', isEqualTo: id)
        .orderBy('occurredAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map(domain.AssetLifecycleEvent.fromFirestore)
        .toList(growable: false);
  }

  @override
  Stream<List<domain.AssetAssignment>> watchAssetAssignments({
    required String assetId,
    required int limit,
  }) {
    final id = requireRepositoryId(assetId, 'assetId');
    requireRepositoryLimit(limit);
    return _firestore
        .collection('assetAssignments')
        .where('assetId', isEqualTo: id)
        .orderBy('assignedAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(domain.AssetAssignment.fromFirestore)
              .toList(growable: false),
        );
  }

  @override
  Stream<List<domain.AssetStateEvent>> watchAssetStateEvents({
    required String assetId,
    required int limit,
  }) {
    final id = requireRepositoryId(assetId, 'assetId');
    requireRepositoryLimit(limit);
    return _firestore
        .collection('assetStateEvents')
        .where('assetId', isEqualTo: id)
        .orderBy('changedAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(domain.AssetStateEvent.fromFirestore)
              .toList(growable: false),
        );
  }

  @override
  Stream<List<domain.AssetParameter>> watchAssetParameters({
    required int limit,
  }) {
    requireRepositoryLimit(limit);
    return _firestore
        .collection('assetParameters')
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(domain.AssetParameter.fromFirestore)
              .where((parameter) => parameter.isActive)
              .toList(growable: false)
            ..sort((left, right) {
              final type = left.type.index.compareTo(right.type.index);
              if (type != 0) return type;
              final order = left.sortOrder.compareTo(right.sortOrder);
              if (order != 0) return order;
              return left.name
                  .toLowerCase()
                  .compareTo(right.name.toLowerCase());
            }),
        );
  }

  @override
  Stream<List<domain.AssetAssignee>> watchAssetAssignees({
    required int limit,
    String organizationId = '',
    String search = '',
  }) {
    requireRepositoryLimit(limit);
    final normalizedOrganizationId = organizationId.trim();
    if (normalizedOrganizationId.isEmpty) {
      return Stream.error(
        StateError('An organization is required to load asset assignees.'),
      );
    }
    Query<Map<String, dynamic>> query = _firestore
        .collection('agentDirectory')
        .where('organizationId', isEqualTo: normalizedOrganizationId)
        .where('isActive', isEqualTo: true)
        .orderBy('displayNameLower');
    final normalizedSearch = search.trim().toLowerCase();
    if (normalizedSearch.isNotEmpty) {
      query =
          query.startAt([normalizedSearch]).endAt(['$normalizedSearch\uf8ff']);
    }
    return query.limit(limit).snapshots().map(
      (snapshot) {
        final agents = snapshot.docs
            .map(domain.AssetAssignee.fromFirestore)
            .toList(growable: false);
        agents.sort(
          (left, right) => left.displayName
              .toLowerCase()
              .compareTo(right.displayName.toLowerCase()),
        );
        return agents;
      },
    );
  }

  @override
  Stream<List<domain.StockItem>> watchStockItems({required int limit}) =>
      _watchCollection(
        collection: 'stockItems',
        sortField: 'updatedAt',
        limit: limit,
        parse: domain.StockItem.fromFirestore,
      );

  @override
  Stream<List<domain.StockMovement>> watchStockMovements({
    required int limit,
  }) =>
      _watchCollection(
        collection: 'stockMovements',
        sortField: 'occurredAt',
        limit: limit,
        parse: domain.StockMovement.fromFirestore,
      );

  @override
  Stream<List<domain.SoftwareLicence>> watchLicences({required int limit}) =>
      _watchCollection(
        collection: 'softwareLicences',
        sortField: 'updatedAt',
        limit: limit,
        parse: domain.SoftwareLicence.fromFirestore,
      );

  @override
  Stream<List<domain.Supplier>> watchSuppliers({required int limit}) =>
      _watchCollection(
        collection: 'suppliers',
        sortField: 'updatedAt',
        limit: limit,
        parse: domain.Supplier.fromFirestore,
      );

  @override
  Stream<List<domain.SupplierContract>> watchContracts({required int limit}) =>
      _watchCollection(
        collection: 'supplierContracts',
        sortField: 'updatedAt',
        limit: limit,
        parse: domain.SupplierContract.fromFirestore,
      );

  @override
  Stream<List<domain.Warranty>> watchWarranties({required int limit}) =>
      _watchCollection(
        collection: 'warranties',
        sortField: 'expirationDate',
        limit: limit,
        parse: domain.Warranty.fromFirestore,
      );

  @override
  Stream<List<domain.ConfigurationItem>> watchConfigurationItems({
    required int limit,
  }) =>
      _watchCollection(
        collection: 'configurationItems',
        sortField: 'updatedAt',
        limit: limit,
        parse: domain.ConfigurationItem.fromFirestore,
      );

  @override
  Stream<List<domain.CiRelationship>> watchConfigurationRelationships({
    required String configurationItemId,
    required int limit,
  }) {
    final id = requireRepositoryId(
      configurationItemId,
      'configurationItemId',
    );
    requireRepositoryLimit(limit);
    final outgoingLimit = (limit + 1) ~/ 2;
    final incomingLimit = limit - outgoingLimit;
    final outgoing = _relationshipQuery('sourceEntityId', id, outgoingLimit);
    if (incomingLimit == 0) return outgoing;
    final incoming = _relationshipQuery('targetEntityId', id, incomingLimit);
    return _combineLatestLists(outgoing, incoming, limit);
  }

  Stream<List<domain.CiRelationship>> _relationshipQuery(
    String field,
    String id,
    int limit,
  ) =>
      _firestore
          .collection('ciRelationships')
          .where(field, isEqualTo: id)
          .orderBy('createdAt', descending: true)
          .orderBy(FieldPath.documentId, descending: true)
          .limit(limit)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map(domain.CiRelationship.fromFirestore)
                .toList(growable: false),
          );

  @override
  Future<int> fetchAssetRevision(String assetId) async {
    final id = requireRepositoryId(assetId, 'assetId');
    final snapshot = await _firestore.collection('assets').doc(id).get();
    if (!snapshot.exists) {
      throw AssetsConfigurationDataException('Asset $id does not exist.');
    }
    final revision = snapshot.data()?['revision'];
    if (revision is int && revision >= 0) return revision;
    if (revision is num && revision >= 0 && revision == revision.round()) {
      return revision.toInt();
    }
    throw AssetsConfigurationDataException(
      'Asset $id has no valid revision.',
    );
  }

  @override
  Future<StockSupportingDocumentMetadata?> resolveSupportingDocument(
    String attachmentId,
  ) async {
    final id = requireRepositoryId(attachmentId, 'attachmentId');
    final snapshot =
        await _firestore.collection('stockSupportingDocuments').doc(id).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    final metadata = StockSupportingDocumentMetadata(
      attachmentId: id,
      stockItemId: data['stockItemId']?.toString() ?? '',
      storagePath: data['storagePath']?.toString() ?? '',
      fileName: data['fileName']?.toString() ?? '',
      contentType: data['contentType']?.toString() ?? '',
      sizeBytes: _integer(data['sizeBytes']) ?? -1,
      checksum: data['checksum']?.toString() ?? '',
    );
    return metadata.isValid ? metadata : null;
  }

  Stream<List<T>> _watchCollection<T>({
    required String collection,
    required String sortField,
    required int limit,
    required T Function(QueryDocumentSnapshot<Map<String, dynamic>>) parse,
  }) {
    requireRepositoryLimit(limit);
    return _firestore
        .collection(collection)
        .orderBy(sortField, descending: true)
        .orderBy(FieldPath.documentId, descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(parse).toList(growable: false),
        );
  }
}

class FirestoreAssetsConfigurationPort
    implements
        application.AssetsConfigurationReadPort,
        application.AssetsConfigurationCommandPort {
  factory FirestoreAssetsConfigurationPort({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    DateTime Function()? clock,
  }) {
    final database = firestore ?? FirebaseFirestore.instance;
    return FirestoreAssetsConfigurationPort.withAdapters(
      readAdapter: FirestoreAssetsConfigurationReadAdapter(database),
      callableInvoker: FirebaseAssetsConfigurationCallableInvoker(
        functions ?? FirebaseFunctions.instance,
      ),
      clock: clock,
    );
  }

  FirestoreAssetsConfigurationPort.withAdapters({
    required AssetsConfigurationReadAdapter readAdapter,
    required AssetsConfigurationCallableInvoker callableInvoker,
    DateTime Function()? clock,
  })  : _readAdapter = readAdapter,
        _callableInvoker = callableInvoker,
        _clock = clock ?? DateTime.now;

  static const int detailLifecycleLimit = 100;

  final AssetsConfigurationReadAdapter _readAdapter;
  final AssetsConfigurationCallableInvoker _callableInvoker;
  final DateTime Function() _clock;

  @override
  Stream<List<application.AssetSummary>> watchMyAssets({
    required application.AssetConfigurationPrincipal principal,
    required int limit,
  }) {
    final boundedLimit = _requireBoundedLimit(limit);
    final userId = _requirePrincipalUserId(principal);
    return _readAdapter
        .watchMyAssetProjections(
          currentUserId: userId,
          limit: boundedLimit,
        )
        .map(
          (projections) => projections
              .where(
                (projection) =>
                    projection.assignedUserId == userId && projection.isCurrent,
              )
              .map(_selfServiceSummary)
              .toList(growable: false),
        );
  }

  @override
  Stream<List<application.AssetSummary>> watchAssetRegister({
    required application.AssetConfigurationPrincipal principal,
    required application.AssetListQuery query,
    required int limit,
  }) {
    _requirePrincipalUserId(principal);
    final boundedLimit = _requireBoundedLimit(limit);
    return _readAdapter
        .watchAssets(query: query, limit: boundedLimit)
        .map((assets) => assets.map(_assetSummary).toList(growable: false));
  }

  @override
  Future<PageResult<application.AssetSummary>> fetchAssetPage({
    required application.AssetConfigurationPrincipal principal,
    required application.AssetPageRequest request,
  }) async {
    _requirePrincipalUserId(principal);
    _requireBoundedLimit(request.page.limit);
    final page = await _readAdapter.fetchAssetPage(
      query: request.query,
      page: request.page,
    );
    return page.map(_assetSummary);
  }

  @override
  Stream<application.AssetDetail?> watchAssetDetail({
    required application.AssetConfigurationPrincipal principal,
    required String assetId,
  }) {
    _requirePrincipalUserId(principal);
    if (principal.role != ItsmRole.manager) {
      throw const application.AssetsConfigurationAccessDenied(
        'Only a MANAGER can read an authoritative asset document.',
      );
    }
    final normalizedId = requireRepositoryId(assetId, 'assetId');
    return _readAdapter.watchAsset(normalizedId).asyncMap((asset) async {
      if (asset == null) return null;
      final lifecycle = await _readAdapter.fetchAssetLifecycle(
        assetId: normalizedId,
        limit: detailLifecycleLimit,
      );
      return _assetDetail(asset, lifecycle);
    });
  }

  @override
  Stream<application.AssetDetail?> watchMyAssetDetail({
    required application.AssetConfigurationPrincipal principal,
    required String assetId,
  }) {
    final userId = _requirePrincipalUserId(principal);
    final normalizedId = requireRepositoryId(assetId, 'assetId');
    return _readAdapter
        .watchMyAssetProjection(
          currentUserId: userId,
          assetId: normalizedId,
        )
        .map(
          (projection) =>
              projection == null ? null : _selfServiceAssetDetail(projection),
        );
  }

  @override
  Stream<List<application.AssetAssignmentHistoryEntry>>
      watchAssetAssignmentHistory({
    required application.AssetConfigurationPrincipal principal,
    required String assetId,
    required int limit,
  }) {
    _requirePrincipalUserId(principal);
    if (principal.role != ItsmRole.manager) {
      throw const application.AssetsConfigurationAccessDenied(
        'Only a MANAGER can read an asset assignment history.',
      );
    }
    return _readAdapter
        .watchAssetAssignments(
          assetId: requireRepositoryId(assetId, 'assetId'),
          limit: _requireBoundedLimit(limit),
        )
        .map(
          (assignments) =>
              assignments.map(_assignmentHistoryEntry).toList(growable: false),
        );
  }

  @override
  Stream<List<application.AssetStateHistoryEntry>> watchAssetStateHistory({
    required application.AssetConfigurationPrincipal principal,
    required String assetId,
    required int limit,
  }) {
    _requirePrincipalUserId(principal);
    if (principal.role != ItsmRole.manager) {
      throw const application.AssetsConfigurationAccessDenied(
        'Only a MANAGER can read an asset state history.',
      );
    }
    return _readAdapter
        .watchAssetStateEvents(
          assetId: requireRepositoryId(assetId, 'assetId'),
          limit: _requireBoundedLimit(limit),
        )
        .map(
          (events) => events.map(_stateHistoryEntry).toList(growable: false),
        );
  }

  @override
  Stream<List<domain.AssetParameter>> watchAssetParameters({
    required application.AssetConfigurationPrincipal principal,
    required int limit,
  }) {
    _requirePrincipalUserId(principal);
    if (principal.role != ItsmRole.manager) {
      throw const application.AssetsConfigurationAccessDenied(
        'Only a MANAGER can read asset register parameters.',
      );
    }
    return _readAdapter.watchAssetParameters(
        limit: _requireBoundedLimit(limit));
  }

  @override
  Stream<List<domain.AssetAssignee>> watchAssetAssignees({
    required application.AssetConfigurationPrincipal principal,
    required int limit,
    String search = '',
  }) {
    _requirePrincipalUserId(principal);
    if (principal.role != ItsmRole.manager) {
      throw const application.AssetsConfigurationAccessDenied(
        'Only a MANAGER can choose an asset assignee.',
      );
    }
    return _readAdapter.watchAssetAssignees(
      limit: _requireBoundedLimit(limit),
      organizationId: principal.organizationId,
      search: search,
    );
  }

  @override
  Stream<List<application.StockItemSummary>> watchStockItems({
    required application.AssetConfigurationPrincipal principal,
    required int limit,
  }) {
    _requirePrincipalUserId(principal);
    return _readAdapter
        .watchStockItems(limit: _requireBoundedLimit(limit))
        .map((items) => items.map(_stockItemSummary).toList(growable: false));
  }

  @override
  Stream<List<application.StockMovementSummary>> watchStockMovements({
    required application.AssetConfigurationPrincipal principal,
    required int limit,
  }) {
    _requirePrincipalUserId(principal);
    return _readAdapter
        .watchStockMovements(limit: _requireBoundedLimit(limit))
        .map(
          (movements) =>
              movements.map(_stockMovementSummary).toList(growable: false),
        );
  }

  @override
  Stream<List<application.LicenceSummary>> watchLicences({
    required application.AssetConfigurationPrincipal principal,
    required int limit,
  }) {
    _requirePrincipalUserId(principal);
    return _readAdapter.watchLicences(limit: _requireBoundedLimit(limit)).map(
        (licences) => licences.map(_licenceSummary).toList(growable: false));
  }

  @override
  Stream<List<application.SupplierSummary>> watchSuppliers({
    required application.AssetConfigurationPrincipal principal,
    required int limit,
  }) {
    _requirePrincipalUserId(principal);
    return _readAdapter.watchSuppliers(limit: _requireBoundedLimit(limit)).map(
        (suppliers) => suppliers.map(_supplierSummary).toList(growable: false));
  }

  @override
  Stream<List<application.ContractSummary>> watchContracts({
    required application.AssetConfigurationPrincipal principal,
    required int limit,
  }) {
    _requirePrincipalUserId(principal);
    return _readAdapter.watchContracts(limit: _requireBoundedLimit(limit)).map(
        (contracts) => contracts.map(_contractSummary).toList(growable: false));
  }

  @override
  Stream<List<application.WarrantySummary>> watchWarranties({
    required application.AssetConfigurationPrincipal principal,
    required int limit,
  }) {
    _requirePrincipalUserId(principal);
    return _readAdapter.watchWarranties(limit: _requireBoundedLimit(limit)).map(
        (warranties) =>
            warranties.map(_warrantySummary).toList(growable: false));
  }

  @override
  Stream<List<application.ConfigurationItemSummary>> watchConfigurationItems({
    required application.AssetConfigurationPrincipal principal,
    required int limit,
  }) {
    _requirePrincipalUserId(principal);
    return _readAdapter
        .watchConfigurationItems(limit: _requireBoundedLimit(limit))
        .map((items) =>
            items.map(_configurationItemSummary).toList(growable: false));
  }

  @override
  Stream<application.ConfigurationDependencyView?> watchDependencyView({
    required application.AssetConfigurationPrincipal principal,
    required String configurationItemId,
  }) {
    _requirePrincipalUserId(principal);
    final id = requireRepositoryId(
      configurationItemId,
      'configurationItemId',
    );
    final root = _readAdapter.watchConfigurationItems(limit: 100).map(
          (items) => items.where((item) => item.id == id).firstOrNull,
        );
    final relationships = _readAdapter.watchConfigurationRelationships(
      configurationItemId: id,
      limit: 100,
    );
    return _combineDependency(root, relationships);
  }

  @override
  Future<ItsmCommandReceipt> execute(
    application.AssetsConfigurationCommand command,
  ) async {
    try {
      final invocation = switch (command) {
        application.AssetOperationalCommand value =>
          await _assetInvocation(value),
        application.StockMovementCommand value => await _stockInvocation(value),
        application.ManagerConfigurationCommand value =>
          _configurationInvocation(value),
      };
      final result = await _callableInvoker.invoke(
        invocation.functionName,
        {
          'command': invocation.commandName,
          'idempotencyKey': command.context.idempotencyKey,
          'payload': invocation.payload,
        },
      );
      return _receipt(command.context.idempotencyKey, result);
    } on FirebaseFunctionsException catch (error) {
      if (error.code == 'permission-denied' ||
          error.code == 'unauthenticated') {
        throw application.AssetsConfigurationAccessDenied(
          error.message ?? 'The command is not authorized.',
        );
      }
      throw AssetsConfigurationCommandException(
        code: error.code,
        message: error.message ?? 'The assets command failed.',
        details: error.details,
      );
    }
  }

  Future<_CommandInvocation> _assetInvocation(
    application.AssetOperationalCommand command,
  ) async {
    final operation = _normalizeOperation(command.operation);
    final spec = _assetOperationSpecs[operation];
    if (spec == null) {
      throw AssetsConfigurationCommandException(
        code: 'unsupported-operation',
        message: 'Unsupported asset operation: ${command.operation}.',
      );
    }
    final fields = Map<String, Object?>.from(command.fields);
    fields['assetId'] = command.assetId.trim();
    if (spec.requiresRevision && _integer(fields['expectedRevision']) == null) {
      fields['expectedRevision'] =
          await _readAdapter.fetchAssetRevision(command.assetId);
    }
    if (spec.commandName == 'asset.lifecycle.transition') {
      fields['toStatus'] = _assetStatusCommandValue(fields['toStatus']);
      fields['reason'] = _nonEmptyText(fields['reason']) ??
          'Lifecycle updated through the ITSM asset workspace.';
    }
    return spec.invocation(_whitelist(fields, spec.allowedFields));
  }

  Future<_CommandInvocation> _stockInvocation(
    application.StockMovementCommand command,
  ) async {
    final spec = _stockOperationSpecs[command.type]!;
    final quantity = switch (command.type) {
      application.StockMovementType.adjustment => null,
      application.StockMovementType.reconciliation => null,
      _ => _positiveInteger(command.quantity, 'quantity'),
    };
    StockSupportingDocumentMetadata? supportingDocument;
    final supportingDocumentId = command.supportingDocumentId?.trim() ?? '';
    if (supportingDocumentId.isNotEmpty) {
      supportingDocument = await _readAdapter.resolveSupportingDocument(
        supportingDocumentId,
      );
    }
    final requiresDocument =
        command.type == application.StockMovementType.adjustment ||
            command.type == application.StockMovementType.reconciliation;
    if (requiresDocument &&
        (supportingDocument == null || !supportingDocument.isValid)) {
      throw const AssetsConfigurationCommandException(
        code: 'supporting-document-required',
        message: 'A registered supporting document with complete file metadata '
            'is required for stock adjustment or reconciliation.',
      );
    }
    if (supportingDocument != null &&
        supportingDocument.stockItemId.trim() != command.itemId.trim()) {
      throw const AssetsConfigurationCommandException(
        code: 'supporting-document-stock-item-mismatch',
        message: 'The supporting document belongs to a different stock item.',
      );
    }
    final adjustmentDelta = command.adjustmentDelta ?? command.quantity;
    final targetOnHand = command.targetOnHand ?? command.quantity;
    final reservedQuantity = _nonNegativeInteger(
      command.reservedQuantity,
      'reservedQuantity',
    );
    final normalizedTargetOnHand =
        command.type == application.StockMovementType.reconciliation
            ? _nonNegativeInteger(targetOnHand, 'targetOnHand')
            : 0;
    final normalizedTargetReserved =
        command.type == application.StockMovementType.reconciliation
            ? _nonNegativeInteger(command.targetReserved, 'targetReserved')
            : 0;
    if (quantity != null && reservedQuantity > quantity) {
      throw const AssetsConfigurationCommandException(
        code: 'invalid-argument',
        message: 'reservedQuantity cannot exceed quantity.',
      );
    }
    if (command.type == application.StockMovementType.reconciliation &&
        normalizedTargetReserved > normalizedTargetOnHand) {
      throw const AssetsConfigurationCommandException(
        code: 'invalid-argument',
        message: 'targetReserved cannot exceed targetOnHand.',
      );
    }
    final payload = <String, Object?>{
      'stockItemId': command.itemId.trim(),
      if (command.type == application.StockMovementType.adjustment)
        'adjustmentDelta': _nonZeroInteger(
          adjustmentDelta,
          'adjustmentDelta',
        )
      else if (command.type ==
          application.StockMovementType.reconciliation) ...{
        'targetOnHand': normalizedTargetOnHand,
        'targetReserved': normalizedTargetReserved,
      } else
        'quantity': quantity,
      if (command.type == application.StockMovementType.issue &&
          reservedQuantity > 0)
        'reservedQuantity': reservedQuantity,
      if ((command.sourceLocationId ?? '').trim().isNotEmpty)
        'sourceLocationId': command.sourceLocationId!.trim(),
      if ((command.destinationLocationId ?? '').trim().isNotEmpty)
        'destinationLocationId': command.destinationLocationId!.trim(),
      if ((command.recipientUserId ?? '').trim().isNotEmpty)
        'recipientUserId': command.recipientUserId!.trim(),
      if ((command.relatedRequestId ?? '').trim().isNotEmpty)
        'relatedRequestId': command.relatedRequestId!.trim(),
      if (supportingDocument != null)
        'supportingDocument': supportingDocument.toCommandPayload(),
      'reason': _nonEmptyText(command.reason) ??
          'Stock movement recorded through the ITSM stock workspace.',
      'correlationId': command.context.correlationId,
    };
    return spec.invocation(payload);
  }

  _CommandInvocation _configurationInvocation(
    application.ManagerConfigurationCommand command,
  ) {
    final operation = _normalizeOperation(command.operation);
    final recordType = _normalizeOperation(command.recordType);
    final spec = _configurationSpecs[operation] ??
        _configurationSpecs['$recordType.$operation'];
    if (spec == null) {
      throw AssetsConfigurationCommandException(
        code: 'unsupported-operation',
        message: 'Unsupported ${command.recordType} operation: '
            '${command.operation}.',
      );
    }
    _rejectSecretFields(command.fields);
    final fields = Map<String, Object?>.from(command.fields);
    if (spec.identityField != null && command.recordId.trim().isNotEmpty) {
      fields[spec.identityField!] = command.recordId.trim();
    }
    return spec.invocation(_whitelist(fields, spec.allowedFields));
  }

  ItsmCommandReceipt _receipt(String idempotencyKey, Object? rawResult) {
    final result = _stringMap(rawResult);
    return ItsmCommandReceipt(
      commandId: _nonEmptyText(result['commandId']) ??
          _nonEmptyText(result['receiptId']) ??
          idempotencyKey,
      acceptedAt: _dateTime(result['acceptedAt']) ?? _clock().toUtc(),
      wasDuplicate: result['wasDuplicate'] == true,
    );
  }
}

class AssetsConfigurationCommandException implements Exception {
  const AssetsConfigurationCommandException({
    required this.code,
    required this.message,
    this.details,
  });

  final String code;
  final String message;
  final Object? details;

  @override
  String toString() => 'AssetsConfigurationCommandException($code, $message)';
}

class AssetsConfigurationDataException implements Exception {
  const AssetsConfigurationDataException(this.message);

  final String message;

  @override
  String toString() => 'AssetsConfigurationDataException($message)';
}

class _CommandSpec {
  const _CommandSpec({
    required this.functionName,
    required this.commandName,
    required this.allowedFields,
    this.identityField,
    this.requiresRevision = false,
  });

  final String functionName;
  final String commandName;
  final Set<String> allowedFields;
  final String? identityField;
  final bool requiresRevision;

  _CommandInvocation invocation(Map<String, Object?> payload) =>
      _CommandInvocation(
        functionName: functionName,
        commandName: commandName,
        payload: payload,
      );
}

class _CommandInvocation {
  const _CommandInvocation({
    required this.functionName,
    required this.commandName,
    required this.payload,
  });

  final String functionName;
  final String commandName;
  final Map<String, Object?> payload;
}

const _assetOperationSpecs = <String, _CommandSpec>{
  'update_lifecycle': _CommandSpec(
    functionName: 'itsmTransitionAsset',
    commandName: 'asset.lifecycle.transition',
    requiresRevision: true,
    allowedFields: {
      'assetId',
      'expectedRevision',
      'toStatus',
      'reason',
      'relatedRequestId',
      'locationId',
      'stockLocationId',
      'condition',
      'evidence',
    },
  ),
  'transition': _CommandSpec(
    functionName: 'itsmTransitionAsset',
    commandName: 'asset.lifecycle.transition',
    requiresRevision: true,
    allowedFields: {
      'assetId',
      'expectedRevision',
      'toStatus',
      'reason',
      'relatedRequestId',
      'locationId',
      'stockLocationId',
      'condition',
      'evidence',
    },
  ),
  'update': _CommandSpec(
    functionName: 'itsmUpdateAsset',
    commandName: 'asset.update',
    identityField: 'assetId',
    requiresRevision: true,
    allowedFields: {
      'assetId',
      'expectedRevision',
      'assetTag',
      'barcode',
      'categoryId',
      'categoryName',
      'type',
      'brand',
      'model',
      'serialNumber',
      'productNumber',
      'description',
      'observation',
      'acquisitionDate',
      'acquisitionCost',
      'currency',
      'supplierId',
      'warrantyId',
      'condition',
      'siteId',
      'locationId',
      'locationName',
      'stateId',
      'stateName',
      'departmentId',
      'stockLocationId',
      'securityBaselineId',
      'attachmentIds',
      'photoAttachmentIds',
    },
  ),
  'change_state': _CommandSpec(
    functionName: 'itsmChangeAssetState',
    commandName: 'asset.state.change',
    identityField: 'assetId',
    requiresRevision: true,
    allowedFields: {
      'assetId',
      'expectedRevision',
      'stateId',
      'stateName',
      'observation',
    },
  ),
  'assign': _CommandSpec(
    functionName: 'itsmAssignAsset',
    commandName: 'asset.assign',
    identityField: 'assetId',
    requiresRevision: true,
    allowedFields: {
      'assetId',
      'expectedRevision',
      'assignedUserId',
      'assignedUserName',
      'assignedUserEmail',
      'departmentId',
      'locationId',
      'assignedAt',
      'relatedRequestId',
      'evidence',
    },
  ),
  'return': _CommandSpec(
    functionName: 'itsmReturnAsset',
    commandName: 'asset.return',
    identityField: 'assetId',
    requiresRevision: true,
    allowedFields: {
      'assetId',
      'expectedRevision',
      'condition',
      'locationId',
      'stockLocationId',
      'reason',
      'relatedRequestId',
      'evidence',
    },
  ),
  'decommission': _CommandSpec(
    functionName: 'itsmDecommissionAsset',
    commandName: 'asset.decommission',
    identityField: 'assetId',
    requiresRevision: true,
    allowedFields: {
      'assetId',
      'expectedRevision',
      'observation',
    },
  ),
};

const _stockOperationSpecs = <application.StockMovementType, _CommandSpec>{
  application.StockMovementType.receipt: _CommandSpec(
    functionName: 'itsmReceiveStock',
    commandName: 'stock.receive',
    allowedFields: {},
  ),
  application.StockMovementType.reservation: _CommandSpec(
    functionName: 'itsmReserveStock',
    commandName: 'stock.reserve',
    allowedFields: {},
  ),
  application.StockMovementType.issue: _CommandSpec(
    functionName: 'itsmIssueStock',
    commandName: 'stock.issue',
    allowedFields: {},
  ),
  application.StockMovementType.returnToStock: _CommandSpec(
    functionName: 'itsmReturnStock',
    commandName: 'stock.return',
    allowedFields: {},
  ),
  application.StockMovementType.transfer: _CommandSpec(
    functionName: 'itsmTransferStock',
    commandName: 'stock.transfer',
    allowedFields: {},
  ),
  application.StockMovementType.adjustment: _CommandSpec(
    functionName: 'itsmAdjustStock',
    commandName: 'stock.adjust',
    allowedFields: {},
  ),
  application.StockMovementType.reconciliation: _CommandSpec(
    functionName: 'itsmReconcileStock',
    commandName: 'stock.reconcile',
    allowedFields: {},
  ),
};

const _configurationSpecs = <String, _CommandSpec>{
  'asset.register': _CommandSpec(
    functionName: 'itsmRegisterAsset',
    commandName: 'asset.register',
    identityField: 'assetId',
    allowedFields: {
      'assetId',
      'assetTag',
      'barcode',
      'categoryId',
      'categoryName',
      'type',
      'brand',
      'model',
      'serialNumber',
      'productNumber',
      'description',
      'observation',
      'acquisitionDate',
      'acquisitionCost',
      'currency',
      'supplierId',
      'warrantyId',
      'status',
      'condition',
      'siteId',
      'locationId',
      'locationName',
      'stateId',
      'stateName',
      'departmentId',
      'stockLocationId',
      'securityBaselineId',
      'attachmentIds',
      'photoAttachmentIds',
      'assignedUserId',
      'assignedAt',
    },
  ),
  'stock.location.save': _CommandSpec(
    functionName: 'itsmSaveStockLocation',
    commandName: 'stock.location.save',
    identityField: 'id',
    allowedFields: {
      'id',
      'expectedRevision',
      'name',
      'description',
      'siteId',
      'siteName',
      'barcode',
      'isActive',
    },
  ),
  'asset.parameter.save': _CommandSpec(
    functionName: 'itsmSaveAssetParameter',
    commandName: 'asset.parameter.save',
    identityField: 'id',
    allowedFields: {
      'id',
      'expectedRevision',
      'type',
      'name',
      'isActive',
      'sortOrder',
    },
  ),
  'stock.item.save': _CommandSpec(
    functionName: 'itsmSaveStockItem',
    commandName: 'stock.item.save',
    identityField: 'id',
    allowedFields: {
      'id',
      'expectedRevision',
      'sku',
      'name',
      'description',
      'kind',
      'barcode',
      'assetCategoryId',
      'unitOfMeasure',
      'minimumQuantity',
      'isActive',
    },
  ),
  'licence.register': _CommandSpec(
    functionName: 'itsmRegisterLicence',
    commandName: 'licence.register',
    identityField: 'licenceId',
    allowedFields: {
      'licenceId',
      'softwareProduct',
      'vendor',
      'licenceType',
      'purchasedQuantity',
      'purchaseDate',
      'effectiveDate',
      'expiryDate',
      'renewalDate',
      'contractId',
      'cost',
      'currency',
      'complianceStatus',
    },
  ),
  'licence.allocate': _CommandSpec(
    functionName: 'itsmAllocateLicence',
    commandName: 'licence.allocate',
    identityField: 'licenceId',
    allowedFields: {
      'licenceId',
      'assignmentType',
      'assigneeId',
      'assigneeName',
      'quantity',
      'relatedRequestId',
      'notes',
    },
  ),
  'licence.release': _CommandSpec(
    functionName: 'itsmReleaseLicence',
    commandName: 'licence.release',
    identityField: 'licenceId',
    allowedFields: {
      'licenceId',
      'allocationId',
      'reason',
      'relatedRequestId',
    },
  ),
  'supplier.save': _CommandSpec(
    functionName: 'itsmSaveSupplier',
    commandName: 'supplier.save',
    identityField: 'id',
    allowedFields: {
      'id',
      'expectedRevision',
      'name',
      'description',
      'isActive',
      'supplierCode',
      'legalName',
      'contactName',
      'contactEmail',
      'contactPhone',
      'address',
      'assetCategoryIds',
      'supportTerms',
      'slaSummary',
      'attachmentIds',
    },
  ),
  'contract.save': _CommandSpec(
    functionName: 'itsmSaveContract',
    commandName: 'contract.save',
    identityField: 'id',
    allowedFields: {
      'id',
      'expectedRevision',
      'name',
      'description',
      'isActive',
      'contractNumber',
      'supplierId',
      'startDate',
      'endDate',
      'supportTerms',
      'slaSummary',
      'assetIds',
      'attachmentIds',
      'renewalNoticeDate',
      'status',
    },
  ),
  'warranty.save': _CommandSpec(
    functionName: 'itsmSaveWarranty',
    commandName: 'warranty.save',
    identityField: 'id',
    allowedFields: {
      'id',
      'expectedRevision',
      'name',
      'description',
      'isActive',
      'warrantyNumber',
      'supplierId',
      'contractId',
      'coverage',
      'startDate',
      'expirationDate',
      'assetIds',
      'attachmentIds',
      'status',
    },
  ),
  'warranty.claim.record': _CommandSpec(
    functionName: 'itsmRecordWarrantyClaim',
    commandName: 'warranty.claim.record',
    identityField: 'claimId',
    allowedFields: {
      'warrantyId',
      'claimId',
      'assetId',
      'title',
      'description',
      'supportingDocument',
      'evidence',
      'relatedRequestId',
    },
  ),
  'warranty.claim.transition': _CommandSpec(
    functionName: 'itsmTransitionWarrantyClaim',
    commandName: 'warranty.claim.transition',
    identityField: 'claimId',
    allowedFields: {
      'warrantyId',
      'claimId',
      'expectedRevision',
      'toStatus',
      'reason',
      'evidence',
    },
  ),
  'cmdb.ci.save': _CommandSpec(
    functionName: 'itsmSaveConfigurationItem',
    commandName: 'cmdb.ci.save',
    identityField: 'ciId',
    allowedFields: {
      'ciId',
      'expectedRevision',
      'name',
      'description',
      'ciType',
      'ownerUserId',
      'ownerName',
      'supportGroupId',
      'criticality',
      'operationalStatus',
      'linkedAssetId',
      'configurationBaseline',
      'dataQualityStatus',
      'relatedIncidentIds',
      'relatedRequestIds',
      'relatedChangeIds',
      'relatedFindingIds',
    },
  ),
  'cmdb.relationship.create': _CommandSpec(
    functionName: 'itsmCreateCiRelationship',
    commandName: 'cmdb.relationship.create',
    identityField: 'relationshipId',
    allowedFields: {
      'relationshipId',
      'relationshipType',
      'sourceEntityType',
      'sourceEntityId',
      'targetEntityType',
      'targetEntityId',
      'description',
    },
  ),
  'cmdb.relationship.retire': _CommandSpec(
    functionName: 'itsmRetireCiRelationship',
    commandName: 'cmdb.relationship.retire',
    identityField: 'relationshipId',
    allowedFields: {'relationshipId', 'reason'},
  ),
};

application.AssetSummary _assetSummary(domain.Asset asset) =>
    application.AssetSummary(
      id: asset.id,
      assetTag: asset.assetTag,
      name: _assetDisplayName(asset),
      categoryId: asset.categoryId,
      categoryName: asset.categoryName,
      status: _applicationAssetStatus(asset.status),
      brand: asset.brand,
      model: asset.model,
      serialNumber: asset.serialNumber,
      productNumber: asset.productNumber,
      locationName: asset.locationName,
      stateName: asset.stateName,
      assignedUserName: asset.assignedUserName,
      isInStock: asset.isInStock,
      condition: asset.condition.value,
      updatedAt: asset.updatedAt,
    );

application.AssetSummary _selfServiceSummary(
  domain.AssetSelfServiceProjection projection,
) =>
    application.AssetSummary(
      id: projection.assetId,
      assetTag: projection.assetTag,
      name: projection.assetName.isEmpty
          ? [projection.brand, projection.model]
              .where((value) => value.isNotEmpty)
              .join(' ')
          : projection.assetName,
      categoryName: projection.categoryName.isEmpty
          ? projection.assetType
          : projection.categoryName,
      status: _applicationAssetStatus(projection.status),
      brand: projection.brand,
      model: projection.model,
      serialNumber: projection.serialNumber,
      locationName: projection.locationName,
      assignedUserName: projection.assignedUserName,
      isInStock: false,
      condition: projection.condition.value,
      photoUrl: projection.photoUrl,
      updatedAt: projection.updatedAt,
    );

application.AssetDetail _selfServiceAssetDetail(
  domain.AssetSelfServiceProjection projection,
) =>
    application.AssetDetail(
      summary: _selfServiceSummary(projection),
      assetId: projection.assetId,
      barcode: projection.barcode,
      typeName: projection.assetType,
      description: projection.description,
      departmentName: projection.departmentName,
      complianceState: switch (projection.complianceState) {
        'compliant' => application.ComplianceState.compliant,
        'action_required' => application.ComplianceState.actionRequired,
        _ => application.ComplianceState.assessmentPending,
      },
    );

application.AssetDetail _assetDetail(
  domain.Asset asset,
  List<domain.AssetLifecycleEvent> lifecycle,
) =>
    application.AssetDetail(
      summary: _assetSummary(asset),
      assetId: asset.id,
      barcode: asset.qrBarcode,
      typeName: asset.type,
      description: asset.description,
      observation: asset.observation,
      productNumber: asset.productNumber,
      stateName: asset.stateName,
      acquisitionDate: asset.acquisitionDate,
      acquisitionCost: asset.acquisitionCost,
      supplierName: asset.supplierName,
      warrantyName: asset.warrantyId,
      departmentName: asset.departmentName,
      stockLocationName: asset.stockLocationId,
      securityBaseline: asset.securityBaselineId,
      complianceState: asset.securityBaselineId.isEmpty
          ? application.ComplianceState.assessmentPending
          : application.ComplianceState.compliant,
      attachmentNames: asset.attachmentIds,
      photographIds: asset.photographIds,
      lifecycle: lifecycle
          .map(
            (event) => application.AssetLifecycleEntry(
              id: event.id,
              status: _applicationAssetStatus(event.toStatus),
              occurredAt: event.occurredAt,
              actorName: event.actorName,
              note: event.reason,
            ),
          )
          .toList(growable: false),
    );

application.AssetAssignmentHistoryEntry _assignmentHistoryEntry(
  domain.AssetAssignment assignment,
) =>
    application.AssetAssignmentHistoryEntry(
      id: assignment.id,
      assignedUserName: assignment.assignedUserName,
      assignedAt: assignment.assignedAt,
      returnedAt: assignment.returnedAt,
      status: assignment.status.name,
      assignmentReason: assignment.assignmentReason,
    );

application.AssetStateHistoryEntry _stateHistoryEntry(
  domain.AssetStateEvent event,
) =>
    application.AssetStateHistoryEntry(
      id: event.id,
      fromStateName: event.fromStateName,
      toStateName: event.toStateName,
      observation: event.observation,
      actorName: event.actorName,
      changedAt: event.changedAt,
      revision: event.revision,
    );

application.StockItemSummary _stockItemSummary(domain.StockItem item) =>
    application.StockItemSummary(
      id: item.id,
      name: item.name,
      sku: item.sku,
      quantity: item.quantityAvailable,
      minimumQuantity: item.minimumQuantity,
      locationName: item.locationName,
      barcode: item.barcode,
      isConsumable: item.kind == domain.StockItemKind.consumable,
    );

application.StockMovementSummary _stockMovementSummary(
  domain.StockMovement movement,
) =>
    application.StockMovementSummary(
      id: movement.id,
      itemName: movement.stockItemId,
      type: _applicationStockMovementType(movement.type),
      quantity: movement.quantity,
      actorName: movement.actorName,
      occurredAt: movement.occurredAt,
      sourceName: movement.sourceLocationId,
      destinationName: movement.destinationLocationId,
      recipientName: movement.recipientName,
      relatedRequestNumber: movement.relatedRequestId,
      supportingDocumentName: movement.supportingDocumentId,
    );

application.LicenceSummary _licenceSummary(domain.SoftwareLicence licence) =>
    application.LicenceSummary(
      id: licence.id,
      productName: licence.softwareProduct,
      vendorName: licence.vendor,
      licenceType: licence.licenceType.value,
      purchasedQuantity: licence.purchasedQuantity,
      allocatedQuantity: licence.allocatedQuantity,
      complianceState: switch (licence.complianceStatus) {
        domain.LicenceComplianceStatus.compliant =>
          application.ComplianceState.compliant,
        domain.LicenceComplianceStatus.warning ||
        domain.LicenceComplianceStatus.overAllocated ||
        domain.LicenceComplianceStatus.expired =>
          application.ComplianceState.actionRequired,
        _ => application.ComplianceState.assessmentPending,
      },
      effectiveAt: licence.effectiveDate,
      expiresAt: licence.expiryDate,
      renewsAt: licence.renewalDate,
      contractNumber: licence.contractReference,
    );

application.SupplierSummary _supplierSummary(domain.Supplier supplier) {
  domain.SupplierContact? primary;
  for (final contact in supplier.contacts) {
    primary ??= contact;
    if (contact.isPrimary) {
      primary = contact;
      break;
    }
  }
  return application.SupplierSummary(
    id: supplier.id,
    name: supplier.name,
    contactName: primary?.name ?? '',
    email: primary?.email ?? supplier.supportEmail,
    phone: primary?.phone ?? supplier.supportPhone,
    supportTerms: supplier.supportTerms,
    slaName: supplier.slaPolicyId,
  );
}

application.ContractSummary _contractSummary(
        domain.SupplierContract contract) =>
    application.ContractSummary(
      id: contract.id,
      number: contract.reference,
      title: contract.name,
      supplierName: contract.supplierName.isEmpty
          ? contract.supplierId
          : contract.supplierName,
      state: application.ContractState.values.byName(contract.status.name),
      startsAt: contract.startsAt,
      endsAt: contract.endsAt,
    );

application.WarrantySummary _warrantySummary(domain.Warranty warranty) =>
    application.WarrantySummary(
      id: warranty.id,
      name: warranty.reference,
      supplierName: warranty.supplierId,
      coverage: warranty.coverage,
      linkedAssetCount: warranty.linkedAssetIds.length,
      expiresAt: warranty.expiresAt,
    );

application.ConfigurationItemSummary _configurationItemSummary(
  domain.ConfigurationItem item,
) =>
    application.ConfigurationItemSummary(
      id: item.id,
      name: item.name,
      typeName: item.type.value,
      criticality: item.criticality.name,
      operationalStatus: item.operationalStatus.name,
      ownerName: item.ownerName,
      supportGroupName: item.supportGroupName,
      linkedAssetTag: item.linkedAssetTag,
      dataQuality: item.dataQualityStatus.name,
    );

Stream<application.ConfigurationDependencyView?> _combineDependency(
  Stream<domain.ConfigurationItem?> rootStream,
  Stream<List<domain.CiRelationship>> relationshipStream,
) {
  late StreamController<application.ConfigurationDependencyView?> controller;
  StreamSubscription<domain.ConfigurationItem?>? rootSubscription;
  StreamSubscription<List<domain.CiRelationship>>? relationshipSubscription;
  domain.ConfigurationItem? root;
  List<domain.CiRelationship>? relationships;

  void emit() {
    final currentRoot = root;
    final currentRelationships = relationships;
    if (currentRoot == null) {
      if (relationships != null) controller.add(null);
      return;
    }
    if (currentRelationships == null) return;
    final items = <String, application.ConfigurationItemSummary>{
      currentRoot.id: _configurationItemSummary(currentRoot),
    };
    for (final relationship in currentRelationships) {
      if (!items.containsKey(relationship.sourceCiId)) {
        items[relationship.sourceCiId] = _relationshipItem(
          relationship.sourceCiId,
          relationship.sourceCiName,
        );
      }
      if (!items.containsKey(relationship.targetCiId)) {
        items[relationship.targetCiId] = _relationshipItem(
          relationship.targetCiId,
          relationship.targetCiName,
        );
      }
    }
    controller.add(
      application.ConfigurationDependencyView(
        root: _configurationItemSummary(currentRoot),
        items: items.values,
        relationships: currentRelationships
            .map(
              (relationship) => application.ConfigurationRelationship(
                id: relationship.id,
                sourceId: relationship.sourceCiId,
                sourceName: relationship.sourceCiName,
                type: relationship.type.value,
                targetId: relationship.targetCiId,
                targetName: relationship.targetCiName,
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  controller = StreamController<application.ConfigurationDependencyView?>(
    onListen: () {
      rootSubscription = rootStream.listen(
        (value) {
          root = value;
          emit();
        },
        onError: controller.addError,
      );
      relationshipSubscription = relationshipStream.listen(
        (value) {
          relationships = value;
          emit();
        },
        onError: controller.addError,
      );
    },
    onCancel: () async {
      await rootSubscription?.cancel();
      await relationshipSubscription?.cancel();
    },
  );
  return controller.stream;
}

application.ConfigurationItemSummary _relationshipItem(
  String id,
  String name,
) =>
    application.ConfigurationItemSummary(
      id: id,
      name: name.isEmpty ? id : name,
      typeName: '',
      criticality: '',
      operationalStatus: '',
    );

Stream<List<T>> _combineLatestLists<T>(
  Stream<List<T>> first,
  Stream<List<T>> second,
  int limit,
) {
  late StreamController<List<T>> controller;
  StreamSubscription<List<T>>? firstSubscription;
  StreamSubscription<List<T>>? secondSubscription;
  List<T>? firstValue;
  List<T>? secondValue;

  void emit() {
    if (firstValue == null || secondValue == null) return;
    controller.add(
      [...firstValue!, ...secondValue!].take(limit).toList(growable: false),
    );
  }

  controller = StreamController<List<T>>(
    onListen: () {
      firstSubscription = first.listen(
        (value) {
          firstValue = value;
          emit();
        },
        onError: controller.addError,
      );
      secondSubscription = second.listen(
        (value) {
          secondValue = value;
          emit();
        },
        onError: controller.addError,
      );
    },
    onCancel: () async {
      await firstSubscription?.cancel();
      await secondSubscription?.cancel();
    },
  );
  return controller.stream;
}

application.AssetLifecycleStatus _applicationAssetStatus(
  domain.AssetStatus status,
) =>
    application.AssetLifecycleStatus.values.byName(status.name);

String _applicationAssetStatusValue(application.AssetLifecycleStatus status) =>
    switch (status) {
      application.AssetLifecycleStatus.inStock => 'in_stock',
      application.AssetLifecycleStatus.inMaintenance => 'in_maintenance',
      _ => status.name,
    };

String _assetStatusCommandValue(Object? value) {
  final normalized = value?.toString().trim() ?? '';
  return switch (normalized) {
    'inStock' || 'in_stock' => 'in_stock',
    'inMaintenance' || 'in_maintenance' => 'in_maintenance',
    _ => normalized.toLowerCase(),
  };
}

application.StockMovementType _applicationStockMovementType(
  domain.StockMovementType type,
) =>
    switch (type) {
      domain.StockMovementType.receipt => application.StockMovementType.receipt,
      domain.StockMovementType.reservation ||
      domain.StockMovementType.reservationRelease =>
        application.StockMovementType.reservation,
      domain.StockMovementType.issue => application.StockMovementType.issue,
      domain.StockMovementType.returnToStock =>
        application.StockMovementType.returnToStock,
      domain.StockMovementType.transfer =>
        application.StockMovementType.transfer,
      domain.StockMovementType.adjustmentIncrease ||
      domain.StockMovementType.adjustmentDecrease =>
        application.StockMovementType.adjustment,
      domain.StockMovementType.reconciliation =>
        application.StockMovementType.reconciliation,
    };

String _assetDisplayName(domain.Asset asset) {
  final name = [asset.brand, asset.model]
      .where((value) => value.trim().isNotEmpty)
      .join(' ')
      .trim();
  return name.isEmpty ? asset.type : name;
}

String _requirePrincipalUserId(
  application.AssetConfigurationPrincipal principal,
) =>
    requireRepositoryId(principal.userId, 'principal.userId');

int _requireBoundedLimit(int limit) {
  requireRepositoryLimit(limit);
  return limit;
}

int _positiveInteger(num value, String field) {
  if (value <= 0 || value != value.roundToDouble()) {
    throw AssetsConfigurationCommandException(
      code: 'invalid-argument',
      message: '$field must be a positive integer.',
    );
  }
  return value.toInt();
}

int _nonNegativeInteger(num value, String field) {
  if (value < 0 || value != value.roundToDouble()) {
    throw AssetsConfigurationCommandException(
      code: 'invalid-argument',
      message: '$field must be a non-negative integer.',
    );
  }
  return value.toInt();
}

int _nonZeroInteger(num value, String field) {
  if (value == 0 || value != value.roundToDouble()) {
    throw AssetsConfigurationCommandException(
      code: 'invalid-argument',
      message: '$field must be a non-zero integer.',
    );
  }
  return value.toInt();
}

int? _integer(Object? value) {
  if (value is int) return value;
  if (value is num && value == value.round()) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

Map<String, Object?> _whitelist(
  Map<String, Object?> fields,
  Set<String> allowed,
) =>
    Map<String, Object?>.unmodifiable({
      for (final entry in fields.entries)
        if (allowed.contains(entry.key) && entry.value != null)
          entry.key: entry.value,
    });

void _rejectSecretFields(Map<String, Object?> fields) {
  final secretPattern = RegExp(
    r'secret|password|credential|token|private.?key|licen[cs]e.?key',
    caseSensitive: false,
  );
  final secret = fields.keys.where(secretPattern.hasMatch).firstOrNull;
  if (secret != null) {
    throw AssetsConfigurationCommandException(
      code: 'secret-field-rejected',
      message: 'Sensitive licence field "$secret" cannot be sent by this port.',
    );
  }
}

String _normalizeOperation(String value) =>
    value.trim().replaceAll('-', '_').replaceAll(' ', '_').toLowerCase();

String? _nonEmptyText(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

Map<String, Object?> _stringMap(Object? value) {
  if (value is! Map) return const {};
  return value.map((key, entry) => MapEntry(key.toString(), entry));
}

DateTime? _dateTime(Object? value) {
  if (value is Timestamp) return value.toDate().toUtc();
  if (value is DateTime) return value.toUtc();
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
  }
  return DateTime.tryParse(value?.toString() ?? '')?.toUtc();
}
