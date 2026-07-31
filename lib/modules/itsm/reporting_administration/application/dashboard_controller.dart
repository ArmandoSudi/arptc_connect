import '../../shared/application/itsm_session.dart';
import '../../shared/domain/itsm_common.dart';
import '../data/report_snapshot_repository.dart';
import '../domain/dashboard_snapshot.dart';
import 'reporting_administration_access_policy.dart';

class DashboardController {
  const DashboardController({required this.accessPolicy});

  final ReportingAdministrationAccessPolicy accessPolicy;

  ReportSnapshotQuery queryFor(
    ItsmSession session, {
    ReportSnapshotType? type,
  }) {
    accessPolicy.authorize(session, ReportingAdministrationCapability.section);
    final selected = type ?? accessPolicy.dashboardType(session);
    if (selected == ReportSnapshotType.operational) {
      accessPolicy.authorize(
        session,
        ReportingAdministrationCapability.operationalDashboard,
      );
    } else if (selected == ReportSnapshotType.executive) {
      accessPolicy.authorize(
        session,
        ReportingAdministrationCapability.executiveDashboard,
      );
    }
    return ReportSnapshotQuery(
      audience:
          session.role == ItsmRole.manager ? ItsmRole.manager : ItsmRole.admin,
      type: selected,
    );
  }
}
