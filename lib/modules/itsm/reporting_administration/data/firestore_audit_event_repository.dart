import 'package:cloud_firestore/cloud_firestore.dart';

import '../../shared/data/itsm_work_item_repository.dart';
import '../../shared/domain/itsm_common.dart';
import '../../shared/domain/pagination.dart';
import '../domain/audit_query.dart';
import 'audit_event_repository.dart';
import 'firestore_repository_support.dart';
import 'reporting_administration_command_gateway.dart';

class FirestoreAuditEventRepository implements AuditEventRepository {
  FirestoreAuditEventRepository(
    this._firestore,
    this._commandGateway,
  );

  final FirebaseFirestore _firestore;
  final ReportingAdministrationCommandGateway _commandGateway;

  @override
  Future<PageResult<GlobalAuditEvent>> fetchEvents({
    required ItsmQueryPrincipal principal,
    required AuditQuery query,
    required PageRequest page,
  }) async {
    _authorize(principal);
    requireForwardPage(page);
    Query<Map<String, dynamic>> request = _firestore
        .collection('itsmAuditEvents')
        .where('createdAt', isGreaterThanOrEqualTo: query.from)
        .where('createdAt', isLessThanOrEqualTo: query.to);
    if (principal.role == ItsmRole.admin) {
      request = request.where('isRestricted', isEqualTo: false);
    } else {
      request = request.where(
        Filter.or(
          Filter('isRestricted', isEqualTo: false),
          Filter('authorizedManagerIds', arrayContains: principal.userId),
        ),
      );
    }
    final field = _fieldFor(query.dimension);
    if (field != null) {
      request = request.where(field, isEqualTo: query.value!.trim());
    }
    request = request
        .orderBy('createdAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true);
    request = applyDescendingCursor(request, page.cursor, 'createdAt');
    final snapshot = await request.limit(page.limit + 1).get();
    final hasMore = snapshot.docs.length > page.limit;
    final docs = snapshot.docs.take(page.limit).toList(growable: false);
    final events = docs
        .map((doc) => GlobalAuditEvent.fromMap(
            doc.id, Map<String, Object?>.from(doc.data())))
        .where((event) =>
            event.canBeReadBy(role: principal.role, userId: principal.userId))
        .toList(growable: false);
    return PageResult(
      items: events,
      hasMore: hasMore,
      nextCursor: hasMore && docs.isNotEmpty
          ? documentCursor(docs.last, 'createdAt')
          : null,
    );
  }

  @override
  Future<AuditExportReceipt> requestExport({
    required ItsmQueryPrincipal principal,
    required AuditQuery query,
    required String idempotencyKey,
  }) async {
    _authorize(principal);
    final result = await _commandGateway.execute(
      ReportingAdministrationCommand(
        type: ReportingAdministrationCommandType.requestAuditExport,
        idempotencyKey: idempotencyKey,
        payload: {'filters': query.toPrimitiveMap()},
      ),
    );
    return AuditExportReceipt(
      exportId: result.entityId ?? result.commandId,
      status: 'queued',
      requestedAt: result.acceptedAt,
    );
  }

  void _authorize(ItsmQueryPrincipal principal) =>
      validateReadRole(principal.role, principal.role != ItsmRole.user);

  String? _fieldFor(AuditEqualityDimension? dimension) => switch (dimension) {
        AuditEqualityDimension.actorUserId => 'actor.userId',
        AuditEqualityDimension.module => 'module',
        AuditEqualityDimension.entityType => 'entityType',
        AuditEqualityDimension.entityId => 'entityId',
        AuditEqualityDimension.reference => 'entityReference',
        AuditEqualityDimension.correlationId => 'correlationId',
        null => null,
      };
}
