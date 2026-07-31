import '../data/reporting_administration_command_gateway.dart';
import '../domain/catalogue_configuration.dart';
import '../domain/configuration_common.dart';
import 'reporting_administration_command_controller.dart';

class CatalogueConfigurationController {
  const CatalogueConfigurationController(this._commands);
  final ReportingAdministrationCommandController _commands;

  Future<ReportingAdministrationCommandResult> saveDraft(
    CatalogueItemVersionConfiguration version, {
    required Map<String, Object?> payload,
    required String idempotencyKey,
    bool create = false,
    String? sourceVersionDocumentId,
  }) =>
      _commands.execute(ReportingAdministrationCommand(
        type: create
            ? ReportingAdministrationCommandType.createCatalogueDraft
            : ReportingAdministrationCommandType.updateCatalogueDraft,
        idempotencyKey: idempotencyKey,
        payload: create
            ? {
                'definitionId': version.itemId,
                'sourceVersionDocumentId': sourceVersionDocumentId,
                'draft': payload,
              }
            : {
                'definitionId': version.itemId,
                'versionDocumentId': version.versionId,
                'expectedRevision': version.revision,
                'draft': payload,
              },
      ));

  Future<ReportingAdministrationCommandResult> validate(
    CatalogueItemVersionConfiguration version, {
    required String idempotencyKey,
    bool workflowVersionPublished = true,
    bool slaVersionPublished = true,
    bool fulfilmentGroupExists = true,
  }) {
    final validation = version.validateForPublication(
      workflowVersionPublished: workflowVersionPublished,
      slaVersionPublished: slaVersionPublished,
      fulfilmentGroupExists: fulfilmentGroupExists,
    );
    if (!validation.isValid) {
      throw CatalogueConfigurationValidationException(validation);
    }
    return _commands.execute(ReportingAdministrationCommand(
      type: ReportingAdministrationCommandType.validateCatalogueDraft,
      idempotencyKey: idempotencyKey,
      payload: {
        'definitionId': version.itemId,
        'versionDocumentId': version.versionId,
        'expectedRevision': version.revision,
      },
    ));
  }

  Future<ReportingAdministrationCommandResult> publish({
    required String itemId,
    required String versionId,
    required int expectedRevision,
    required String idempotencyKey,
  }) =>
      _publish(itemId, versionId, expectedRevision, idempotencyKey);

  Future<ReportingAdministrationCommandResult> retire({
    required String itemId,
    required int expectedRevision,
    required String reason,
    required String idempotencyKey,
  }) =>
      _retire(itemId, expectedRevision, reason, idempotencyKey);

  Future<ReportingAdministrationCommandResult> _publish(
    String itemId,
    String versionId,
    int expectedRevision,
    String idempotencyKey,
  ) =>
      _commands.execute(ReportingAdministrationCommand(
        type: ReportingAdministrationCommandType.publishCatalogueVersion,
        idempotencyKey: idempotencyKey,
        payload: {
          'definitionId': itemId,
          'versionDocumentId': versionId,
          'expectedRevision': expectedRevision,
        },
      ));

  Future<ReportingAdministrationCommandResult> _retire(
    String itemId,
    int expectedRevision,
    String reason,
    String idempotencyKey,
  ) =>
      _commands.execute(ReportingAdministrationCommand(
        type: ReportingAdministrationCommandType.retireCatalogueVersion,
        idempotencyKey: idempotencyKey,
        payload: {
          'definitionId': itemId,
          'expectedRevision': expectedRevision,
          'reason': reason,
        },
      ));
}

class CatalogueConfigurationValidationException implements Exception {
  const CatalogueConfigurationValidationException(this.validation);
  final ConfigurationValidationResult validation;
}
