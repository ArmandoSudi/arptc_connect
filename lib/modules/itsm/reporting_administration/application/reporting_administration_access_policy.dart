import '../../shared/application/itsm_session.dart';
import '../../shared/domain/itsm_common.dart';
import '../domain/dashboard_snapshot.dart';

enum ReportingAdministrationCapability {
  section,
  operationalDashboard,
  executiveDashboard,
  readConfiguration,
  mutateConfiguration,
  readAudit,
  exportAudit,
}

class ReportingAdministrationAccessPolicy {
  const ReportingAdministrationAccessPolicy();

  bool allows(
      ItsmSession session, ReportingAdministrationCapability capability) {
    return switch (capability) {
      ReportingAdministrationCapability.section ||
      ReportingAdministrationCapability.readConfiguration ||
      ReportingAdministrationCapability.readAudit ||
      ReportingAdministrationCapability.exportAudit =>
        session.role == ItsmRole.manager || session.role == ItsmRole.admin,
      ReportingAdministrationCapability.operationalDashboard ||
      ReportingAdministrationCapability.mutateConfiguration =>
        session.role == ItsmRole.manager,
      ReportingAdministrationCapability.executiveDashboard =>
        session.role == ItsmRole.admin,
    };
  }

  bool getReadOnly(ItsmSession session) => session.role == ItsmRole.admin;

  ReportSnapshotType dashboardType(ItsmSession session) =>
      switch (session.role) {
        ItsmRole.manager => ReportSnapshotType.operational,
        ItsmRole.admin => ReportSnapshotType.executive,
        ItsmRole.user => throw const ReportingAdministrationAccessDenied(
            'USER cannot access Reporting & Administration.',
          ),
      };

  void authorize(
    ItsmSession session,
    ReportingAdministrationCapability capability,
  ) {
    if (!allows(session, capability)) {
      throw ReportingAdministrationAccessDenied(
        '${session.role.value} cannot use ${capability.name}.',
      );
    }
  }
}

class ReportingAdministrationAccessDenied implements Exception {
  const ReportingAdministrationAccessDenied(this.message);
  final String message;

  @override
  String toString() => 'ReportingAdministrationAccessDenied($message)';
}

class ReportingAdministrationAccessState {
  const ReportingAdministrationAccessState({
    required this.role,
    required this.canAccess,
    required this.canOperate,
    required this.isReadOnly,
  });

  const ReportingAdministrationAccessState.denied()
      : role = null,
        canAccess = false,
        canOperate = false,
        isReadOnly = true;

  final ItsmRole? role;
  final bool canAccess;
  final bool canOperate;
  final bool isReadOnly;
}
