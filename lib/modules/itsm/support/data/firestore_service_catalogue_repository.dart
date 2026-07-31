import 'package:cloud_firestore/cloud_firestore.dart';

import '../../shared/data/itsm_work_item_repository.dart';
import '../../shared/domain/itsm_common.dart';
import '../../shared/domain/pagination.dart';
import '../domain/support_domain.dart';
import 'service_catalogue_repository.dart';

class FirestoreServiceCatalogueRepository
    implements ServiceCatalogueRepository {
  FirestoreServiceCatalogueRepository(this._firestore);

  static const int maximumLiveItems = 100;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _items =>
      _firestore.collection('serviceCatalogItems');

  @override
  Future<PageResult<ServiceCatalogueItem>> fetchPublishedPage({
    required ItsmQueryPrincipal principal,
    required CataloguePrincipal cataloguePrincipal,
    required ServiceCatalogueQuery query,
    required PageRequest page,
    required String languageCode,
  }) async {
    _validatePrincipal(principal, cataloguePrincipal);
    if (page.direction != PageDirection.forward) {
      throw const ServiceCatalogueRepositoryException(
        'The service catalogue supports forward cursor pagination only.',
      );
    }
    final firestoreQuery = _publishedQuery(
      role: principal.role,
      cursor: page.cursor,
    ).limit(page.limit + 1);
    final snapshot = await firestoreQuery.get();
    final hasMore = snapshot.docs.length > page.limit;
    final pageDocuments = hasMore
        ? snapshot.docs.take(page.limit).toList(growable: false)
        : snapshot.docs;
    final effectiveAt = query.effectiveAt ?? DateTime.now();
    final items = pageDocuments
        .map(_fromDocument)
        .where(
          (item) =>
              item.isAvailableTo(cataloguePrincipal, at: effectiveAt) &&
              query.matches(item, languageCode),
        )
        .toList(growable: false);
    final lastDocument = pageDocuments.isEmpty ? null : pageDocuments.last;
    return PageResult(
      items: items,
      hasMore: hasMore,
      nextCursor:
          hasMore && lastDocument != null ? _cursor(lastDocument) : null,
    );
  }

  @override
  Stream<List<ServiceCatalogueItem>> watchPublishedFirstPage({
    required ItsmQueryPrincipal principal,
    required CataloguePrincipal cataloguePrincipal,
    required ServiceCatalogueQuery query,
    required int limit,
    required String languageCode,
  }) {
    _validatePrincipal(principal, cataloguePrincipal);
    if (limit < 1 || limit > PageRequest.maximumLimit) {
      throw RangeError.range(
        limit,
        1,
        PageRequest.maximumLimit,
        'limit',
      );
    }
    final effectiveAt = query.effectiveAt ?? DateTime.now();
    return _publishedQuery(role: principal.role).limit(limit).snapshots().map(
          (snapshot) => snapshot.docs
              .map(_fromDocument)
              .where(
                (item) =>
                    item.isAvailableTo(
                      cataloguePrincipal,
                      at: effectiveAt,
                    ) &&
                    query.matches(item, languageCode),
              )
              .toList(growable: false),
        );
  }

  @override
  Future<ServiceCatalogueItem?> getPublishedById({
    required ItsmQueryPrincipal principal,
    required CataloguePrincipal cataloguePrincipal,
    required String id,
    required DateTime at,
  }) async {
    _validatePrincipal(principal, cataloguePrincipal);
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) {
      throw ArgumentError.value(id, 'id', 'A catalogue item ID is required.');
    }
    final snapshot = await _items.doc(normalizedId).get();
    if (!snapshot.exists) return null;
    final item = _fromDocument(snapshot);
    return item.isAvailableTo(cataloguePrincipal, at: at) ? item : null;
  }

  Query<Map<String, dynamic>> _publishedQuery({
    required ItsmRole role,
    PageCursor? cursor,
  }) {
    Query<Map<String, dynamic>> query = _items
        .where('status', isEqualTo: ItsmPublicationState.published.value)
        .where('visibleRoles', arrayContains: role.value)
        .orderBy('sortOrder')
        .orderBy(FieldPath.documentId);
    if (cursor != null) {
      final sortOrder = cursor['sortOrder'];
      final documentId = cursor['documentId']?.toString().trim() ?? '';
      if (sortOrder is! num || documentId.isEmpty) {
        throw const ServiceCatalogueRepositoryException(
          'Catalogue cursors require sortOrder and documentId.',
        );
      }
      query = query.startAfter([sortOrder, documentId]);
    }
    return query;
  }

  ServiceCatalogueItem _fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    if (data == null) {
      throw const ServiceCatalogueRepositoryException(
        'A catalogue document has no data.',
      );
    }
    return ServiceCatalogueItem.fromMap(
      document.id,
      Map<String, Object?>.from(data),
    );
  }

  PageCursor _cursor(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return PageCursor({
      'sortOrder': document.data()['sortOrder'] ?? 0,
      'documentId': document.id,
    });
  }

  void _validatePrincipal(
    ItsmQueryPrincipal principal,
    CataloguePrincipal cataloguePrincipal,
  ) {
    if (principal.userId.trim().isEmpty ||
        principal.userId.trim() != cataloguePrincipal.userId.trim() ||
        principal.role != cataloguePrincipal.role) {
      throw const ServiceCatalogueRepositoryException(
        'The catalogue principal does not match the active ITSM session.',
      );
    }
  }
}
