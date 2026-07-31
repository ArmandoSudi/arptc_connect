import '../../shared/application/itsm_session.dart';
import '../../shared/domain/pagination.dart';
import '../data/audit_event_repository.dart';
import '../domain/audit_query.dart';
import 'reporting_administration_access_policy.dart';

class AuditLogController {
  const AuditLogController({
    required this.session,
    required this.policy,
    required this.repository,
  });

  final ItsmSession session;
  final ReportingAdministrationAccessPolicy policy;
  final AuditEventRepository repository;

  Future<PageResult<GlobalAuditEvent>> fetch(
    AuditQuery query, {
    PageRequest? page,
  }) {
    policy.authorize(session, ReportingAdministrationCapability.readAudit);
    return repository.fetchEvents(
      principal: session.queryPrincipal,
      query: query,
      page: page ?? PageRequest(),
    );
  }

  Future<AuditExportReceipt> export(
    AuditQuery query, {
    required String idempotencyKey,
  }) {
    policy.authorize(session, ReportingAdministrationCapability.exportAudit);
    return repository.requestExport(
      principal: session.queryPrincipal,
      query: query,
      idempotencyKey: idempotencyKey,
    );
  }
}
