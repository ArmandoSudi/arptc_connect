import 'package:cloud_firestore/cloud_firestore.dart';

import '../../shared/data/itsm_work_item_repository.dart';
import '../../shared/domain/itsm_common.dart';
import '../../shared/domain/pagination.dart';
import '../domain/catalogue_configuration.dart';
import 'catalogue_administration_repository.dart';
import 'firestore_repository_support.dart';

class FirestoreCatalogueAdministrationRepository
    implements CatalogueAdministrationRepository {
  FirestoreCatalogueAdministrationRepository(this._firestore);
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _items =>
      _firestore.collection('serviceCatalogItems');

  @override
  Future<PageResult<CatalogueItemConfiguration>> fetchItems({
    required ItsmQueryPrincipal principal,
    required CatalogueAdministrationQuery query,
    required PageRequest page,
  }) async {
    _authorize(principal);
    requireForwardPage(page);
    Query<Map<String, dynamic>> request = _items;
    if (principal.role == ItsmRole.admin) {
      request =
          request.where('status', whereIn: const ['published', 'retired']);
    } else if (query.status != null) {
      request = request.where('status', isEqualTo: query.status!.value);
    }
    if (query.categoryId?.trim().isNotEmpty == true) {
      request =
          request.where('categoryId', isEqualTo: query.categoryId!.trim());
    }
    request = request
        .orderBy('updatedAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true);
    request = applyDescendingCursor(request, page.cursor, 'updatedAt');
    final snapshot = await request.limit(page.limit + 1).get();
    final hasMore = snapshot.docs.length > page.limit;
    final docs = snapshot.docs.take(page.limit).toList(growable: false);
    return PageResult(
      items: docs.map((doc) => CatalogueItemConfiguration.fromMap(
          doc.id, Map<String, Object?>.from(doc.data()))),
      hasMore: hasMore,
      nextCursor: hasMore && docs.isNotEmpty
          ? documentCursor(docs.last, 'updatedAt')
          : null,
    );
  }

  @override
  Stream<CatalogueItemConfiguration?> watchItem({
    required ItsmQueryPrincipal principal,
    required String itemId,
  }) {
    _authorize(principal);
    return _items.doc(itemId.trim()).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return null;
      final item = CatalogueItemConfiguration.fromMap(
          doc.id, Map<String, Object?>.from(data));
      if (principal.role == ItsmRole.admin &&
          item.status == ItsmPublicationState.draft) return null;
      return item;
    });
  }

  @override
  Future<PageResult<CatalogueItemVersionConfiguration>> fetchVersions({
    required ItsmQueryPrincipal principal,
    required String itemId,
    required PageRequest page,
  }) async {
    _authorize(principal);
    requireForwardPage(page);
    Query<Map<String, dynamic>> request =
        _items.doc(itemId.trim()).collection('versions');
    if (principal.role == ItsmRole.admin) {
      request =
          request.where('status', whereIn: const ['published', 'retired']);
    }
    request = request
        .orderBy('version', descending: true)
        .orderBy(FieldPath.documentId, descending: true);
    if (page.cursor != null) {
      request =
          request.startAfter([page.cursor!['version'], page.cursor!['id']]);
    }
    final snapshot = await request.limit(page.limit + 1).get();
    final hasMore = snapshot.docs.length > page.limit;
    final docs = snapshot.docs.take(page.limit).toList(growable: false);
    return PageResult(
      items: docs.map((doc) => CatalogueItemVersionConfiguration.fromMap(
          itemId, doc.id, Map<String, Object?>.from(doc.data()))),
      hasMore: hasMore,
      nextCursor: hasMore && docs.isNotEmpty
          ? PageCursor(
              {'version': docs.last.data()['version'], 'id': docs.last.id})
          : null,
    );
  }

  void _authorize(ItsmQueryPrincipal principal) =>
      validateReadRole(principal.role, principal.role != ItsmRole.user);
}
