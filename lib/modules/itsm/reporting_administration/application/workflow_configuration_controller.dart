import '../data/reporting_administration_command_gateway.dart';
import '../domain/workflow_configuration.dart';
import '../../shared/domain/workflow.dart';
import 'reporting_administration_command_controller.dart';

class WorkflowConfigurationController {
  const WorkflowConfigurationController(this._commands);
  final ReportingAdministrationCommandController _commands;

  Future<ReportingAdministrationCommandResult> saveDraft(
    WorkflowVersionConfiguration version, {
    required Map<String, Object?> payload,
    required String idempotencyKey,
    bool create = false,
    String? sourceVersionDocumentId,
  }) =>
      _commands.execute(ReportingAdministrationCommand(
        type: create
            ? ReportingAdministrationCommandType.createWorkflowDraft
            : ReportingAdministrationCommandType.updateWorkflowDraft,
        idempotencyKey: idempotencyKey,
        payload: create
            ? {
                'definitionId': version.workflowId,
                'sourceVersionDocumentId': sourceVersionDocumentId,
                'draft': payload,
              }
            : {
                'definitionId': version.workflowId,
                'versionDocumentId': version.versionId,
                'expectedRevision': version.revision,
                'draft': payload,
              },
      ));

  Future<ReportingAdministrationCommandResult> validate(
    WorkflowVersionConfiguration version, {
    required String idempotencyKey,
  }) {
    final validation = version.validateForPublication();
    if (!validation.isValid) {
      throw WorkflowConfigurationValidationException(validation);
    }
    return _commands.execute(ReportingAdministrationCommand(
      type: ReportingAdministrationCommandType.validateWorkflowDraft,
      idempotencyKey: idempotencyKey,
      payload: {
        'definitionId': version.workflowId,
        'versionDocumentId': version.versionId,
        'expectedRevision': version.revision,
      },
    ));
  }

  Future<ReportingAdministrationCommandResult> publish({
    required String workflowId,
    required String versionId,
    required int expectedRevision,
    required String idempotencyKey,
  }) =>
      _publish(workflowId, versionId, expectedRevision, idempotencyKey);

  Future<ReportingAdministrationCommandResult> retire({
    required String workflowId,
    required int expectedRevision,
    required String reason,
    required String idempotencyKey,
  }) =>
      _retire(workflowId, expectedRevision, reason, idempotencyKey);

  Future<ReportingAdministrationCommandResult> _publish(
    String workflowId,
    String versionId,
    int expectedRevision,
    String idempotencyKey,
  ) =>
      _commands.execute(ReportingAdministrationCommand(
        type: ReportingAdministrationCommandType.publishWorkflowVersion,
        idempotencyKey: idempotencyKey,
        payload: {
          'definitionId': workflowId,
          'versionDocumentId': versionId,
          'expectedRevision': expectedRevision,
        },
      ));

  Future<ReportingAdministrationCommandResult> _retire(
    String workflowId,
    int expectedRevision,
    String reason,
    String idempotencyKey,
  ) =>
      _commands.execute(ReportingAdministrationCommand(
        type: ReportingAdministrationCommandType.retireWorkflowVersion,
        idempotencyKey: idempotencyKey,
        payload: {
          'definitionId': workflowId,
          'expectedRevision': expectedRevision,
          'reason': reason,
        },
      ));
}

class WorkflowConfigurationValidationException implements Exception {
  const WorkflowConfigurationValidationException(this.validation);
  final WorkflowValidationResult validation;
}
