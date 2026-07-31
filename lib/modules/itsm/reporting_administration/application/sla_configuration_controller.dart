import '../data/reporting_administration_command_gateway.dart';
import '../domain/configuration_common.dart';
import '../domain/sla_configuration.dart';
import 'reporting_administration_command_controller.dart';

class SlaConfigurationController {
  const SlaConfigurationController(this._commands);
  final ReportingAdministrationCommandController _commands;

  Future<ReportingAdministrationCommandResult> saveDraft(
    SlaPolicyVersionConfiguration version, {
    required String idempotencyKey,
    bool create = false,
    String? sourceVersionDocumentId,
  }) =>
      _commands.execute(ReportingAdministrationCommand(
        type: create
            ? ReportingAdministrationCommandType.createSlaDraft
            : ReportingAdministrationCommandType.updateSlaDraft,
        idempotencyKey: idempotencyKey,
        payload: create
            ? {
                'definitionId': version.policyId,
                'sourceVersionDocumentId': sourceVersionDocumentId,
                'draft': version.toCommandDefinition(),
              }
            : {
                'definitionId': version.policyId,
                'versionDocumentId': version.versionId,
                'expectedRevision': version.revision,
                'draft': version.toCommandDefinition(),
              },
      ));

  Future<ReportingAdministrationCommandResult> validate(
    SlaPolicyVersionConfiguration version, {
    required String idempotencyKey,
  }) {
    final validation = version.validateForPublication();
    if (!validation.isValid) {
      throw SlaConfigurationValidationException(validation);
    }
    return _commands.execute(ReportingAdministrationCommand(
      type: ReportingAdministrationCommandType.validateSlaDraft,
      idempotencyKey: idempotencyKey,
      payload: {
        'definitionId': version.policyId,
        'versionDocumentId': version.versionId,
        'expectedRevision': version.revision,
      },
    ));
  }

  Future<ReportingAdministrationCommandResult> publish({
    required String policyId,
    required String versionId,
    required int expectedRevision,
    required String idempotencyKey,
  }) =>
      _commands.execute(ReportingAdministrationCommand(
        type: ReportingAdministrationCommandType.publishSlaVersion,
        idempotencyKey: idempotencyKey,
        payload: {
          'definitionId': policyId,
          'versionDocumentId': versionId,
          'expectedRevision': expectedRevision,
        },
      ));

  Future<ReportingAdministrationCommandResult> retire({
    required String policyId,
    required int expectedRevision,
    required String reason,
    required String idempotencyKey,
  }) =>
      _commands.execute(ReportingAdministrationCommand(
        type: ReportingAdministrationCommandType.retireSlaVersion,
        idempotencyKey: idempotencyKey,
        payload: {
          'definitionId': policyId,
          'expectedRevision': expectedRevision,
          'reason': reason,
        },
      ));
}

class SlaConfigurationValidationException implements Exception {
  const SlaConfigurationValidationException(this.validation);
  final ConfigurationValidationResult validation;
}
