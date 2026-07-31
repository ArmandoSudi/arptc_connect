import '../../shared/data/itsm_work_item_repository.dart';
import '../../shared/domain/itsm_common.dart';
import '../../shared/domain/pagination.dart';
import '../domain/workflow_configuration.dart';

class WorkflowConfigurationQuery {
  const WorkflowConfigurationQuery(
      {this.status, this.module, this.workItemType});

  final ItsmPublicationState? status;
  final String? module;
  final ItsmWorkItemType? workItemType;
}

abstract interface class WorkflowDefinitionRepository {
  Future<PageResult<WorkflowConfiguration>> fetchDefinitions({
    required ItsmQueryPrincipal principal,
    required WorkflowConfigurationQuery query,
    required PageRequest page,
  });

  Stream<WorkflowConfiguration?> watchDefinition({
    required ItsmQueryPrincipal principal,
    required String workflowId,
  });

  Future<PageResult<WorkflowVersionConfiguration>> fetchVersions({
    required ItsmQueryPrincipal principal,
    required String workflowId,
    required PageRequest page,
  });
}
