import '../data/reporting_administration_command_gateway.dart';
import 'reporting_administration_command_controller.dart';

class CatalogueParameterController {
  const CatalogueParameterController(this._commands);

  final ReportingAdministrationCommandController _commands;

  Future<ReportingAdministrationCommandResult> save({
    required String id,
    required String type,
    required String label,
    required String idempotencyKey,
  }) =>
      _commands.execute(
        ReportingAdministrationCommand(
          type: ReportingAdministrationCommandType.saveReferenceData,
          idempotencyKey: idempotencyKey,
          payload: {
            'referenceId': id.trim(),
            'type': type,
            'label': {'en': label.trim(), 'fr': label.trim()},
          },
        ),
      );

  Future<ReportingAdministrationCommandResult> deactivate({
    required String id,
    required String idempotencyKey,
  }) =>
      _commands.execute(
        ReportingAdministrationCommand(
          type: ReportingAdministrationCommandType.deactivateReferenceData,
          idempotencyKey: idempotencyKey,
          payload: {'referenceId': id.trim()},
        ),
      );
}
