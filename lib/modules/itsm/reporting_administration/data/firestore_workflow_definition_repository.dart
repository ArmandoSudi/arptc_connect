import 'package:cloud_firestore/cloud_firestore.dart';

import '../../shared/data/itsm_work_item_repository.dart';
import '../../shared/domain/itsm_common.dart';
import '../../shared/domain/pagination.dart';
import '../domain/workflow_configuration.dart';
import 'firestore_repository_support.dart';
import 'workflow_definition_repository.dart';

class FirestoreWorkflowDefinitionRepository
    implements WorkflowDefinitionRepository {
  FirestoreWorkflowDefinitionRepository(this._firestore);
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _definitions =>
      _firestore.collection('workflowDefinitions');

  @override
  Future<PageResult<WorkflowConfiguration>> fetchDefinitions({
    required ItsmQueryPrincipal principal,
    required WorkflowConfigurationQuery query,
    required PageRequest page,
  }) async {
    _authorize(principal);
    requireForwardPage(page);
    Query<Map<String, dynamic>> request = _definitions;
    if (principal.role == ItsmRole.admin) {
      request =
          request.where('status', whereIn: const ['published', 'retired']);
    } else if (query.status != null) {
      request = request.where('status', isEqualTo: query.status!.value);
    }
    if (query.module?.trim().isNotEmpty == true) {
      request = request.where('module', isEqualTo: query.module!.trim());
    }
    if (query.workItemType != null) {
      request =
          request.where('workItemType', isEqualTo: query.workItemType!.value);
    }
    request = request
        .orderBy('updatedAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true);
    request = applyDescendingCursor(request, page.cursor, 'updatedAt');
    final snapshot = await request.limit(page.limit + 1).get();
    final hasMore = snapshot.docs.length > page.limit;
    final docs = snapshot.docs.take(page.limit).toList(growable: false);
    return PageResult(
      items: docs.map((doc) => WorkflowConfiguration.fromMap(
          doc.id, Map<String, Object?>.from(doc.data()))),
      hasMore: hasMore,
      nextCursor: hasMore && docs.isNotEmpty
          ? documentCursor(docs.last, 'updatedAt')
          : null,
    );
  }

  @override
  Stream<WorkflowConfiguration?> watchDefinition({
    required ItsmQueryPrincipal principal,
    required String workflowId,
  }) {
    _authorize(principal);
    return _definitions.doc(workflowId.trim()).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return null;
      final definition = WorkflowConfiguration.fromMap(
          doc.id, Map<String, Object?>.from(data));
      if (principal.role == ItsmRole.admin &&
          definition.status == ItsmPublicationState.draft) return null;
      return definition;
    });
  }

  @override
  Future<PageResult<WorkflowVersionConfiguration>> fetchVersions({
    required ItsmQueryPrincipal principal,
    required String workflowId,
    required PageRequest page,
  }) async {
    _authorize(principal);
    requireForwardPage(page);
    Query<Map<String, dynamic>> request =
        _definitions.doc(workflowId.trim()).collection('versions');
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
      items: docs.map((doc) => WorkflowVersionConfiguration.fromMap(
          workflowId, doc.id, Map<String, Object?>.from(doc.data()))),
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
