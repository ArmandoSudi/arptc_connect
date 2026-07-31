import '../../shared/data/itsm_work_item_repository.dart';
import '../../shared/domain/itsm_common.dart';
import '../../shared/domain/pagination.dart';
import '../domain/reporting_administration_domain.dart';

class ReportSnapshotQuery {
  const ReportSnapshotQuery({
    required this.audience,
    required this.type,
    this.scopeType,
    this.scopeId,
  });

  final ItsmRole audience;
  final ReportSnapshotType type;
  final String? scopeType;
  final String? scopeId;
}

abstract interface class ReportSnapshotRepository {
  Stream<ItsmReportSnapshot?> watchCurrent({
    required ItsmQueryPrincipal principal,
    required ReportSnapshotQuery query,
  });

  Future<PageResult<ItsmReportSnapshot>> fetchHistory({
    required ItsmQueryPrincipal principal,
    required ReportSnapshotQuery query,
    required PageRequest page,
  });
}
