import '../../shared/data/itsm_work_item_repository.dart';
import '../../shared/domain/itsm_common.dart';
import '../../shared/domain/pagination.dart';
import '../domain/sla_configuration.dart';

class SlaPolicyQuery {
  const SlaPolicyQuery({this.status, this.workItemType, this.serviceId});

  final ItsmPublicationState? status;
  final ItsmWorkItemType? workItemType;
  final String? serviceId;
}

abstract interface class SlaPolicyRepository {
  Future<PageResult<SlaPolicyConfiguration>> fetchPolicies({
    required ItsmQueryPrincipal principal,
    required SlaPolicyQuery query,
    required PageRequest page,
  });

  Stream<SlaPolicyConfiguration?> watchPolicy({
    required ItsmQueryPrincipal principal,
    required String policyId,
  });

  Future<PageResult<SlaPolicyVersionConfiguration>> fetchVersions({
    required ItsmQueryPrincipal principal,
    required String policyId,
    required PageRequest page,
  });
}
