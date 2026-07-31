import '../../shared/data/itsm_work_item_repository.dart';
import '../../shared/domain/pagination.dart';
import '../domain/audit_query.dart';

abstract interface class AuditEventRepository {
  Future<PageResult<GlobalAuditEvent>> fetchEvents({
    required ItsmQueryPrincipal principal,
    required AuditQuery query,
    required PageRequest page,
  });

  Future<AuditExportReceipt> requestExport({
    required ItsmQueryPrincipal principal,
    required AuditQuery query,
    required String idempotencyKey,
  });
}
