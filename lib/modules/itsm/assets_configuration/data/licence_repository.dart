import '../../shared/domain/pagination.dart';
import '../domain/assets_configuration_domain.dart';

class LicenceQuery {
  const LicenceQuery({
    this.complianceStatus,
    this.expiringBefore,
    this.vendor = '',
  });

  final LicenceComplianceStatus? complianceStatus;
  final DateTime? expiringBefore;
  final String vendor;
}

abstract interface class LicenceRepository {
  Future<PageResult<SoftwareLicence>> fetchLicencesPage({
    required LicenceQuery query,
    required PageRequest page,
  });

  Stream<SoftwareLicence?> watchLicence(String licenceId);

  Future<PageResult<SoftwareLicenceAssignment>> fetchAssignmentsPage({
    required String licenceId,
    required PageRequest page,
  });

  Future<PageResult<LicenceHistoryEvent>> fetchHistoryPage({
    required String licenceId,
    required PageRequest page,
  });
}
