import '../../shared/application/itsm_session.dart';
import '../data/reporting_administration_command_gateway.dart';
import 'reporting_administration_access_policy.dart';

class ReportingAdministrationCommandController {
  ReportingAdministrationCommandController({
    required ItsmSession session,
    required ReportingAdministrationAccessPolicy accessPolicy,
    required ReportingAdministrationCommandGateway gateway,
  })  : _session = session,
        _accessPolicy = accessPolicy,
        _gateway = gateway;

  final ItsmSession _session;
  final ReportingAdministrationAccessPolicy _accessPolicy;
  final ReportingAdministrationCommandGateway _gateway;
  final Set<String> _inFlight = {};

  bool isExecuting(String idempotencyKey) => _inFlight.contains(idempotencyKey);

  Future<ReportingAdministrationCommandResult> execute(
    ReportingAdministrationCommand command,
  ) async {
    _accessPolicy.authorize(
      _session,
      ReportingAdministrationCapability.mutateConfiguration,
    );
    if (!_inFlight.add(command.idempotencyKey)) {
      throw StateError('This configuration command is already running.');
    }
    try {
      return await _gateway.execute(command);
    } finally {
      _inFlight.remove(command.idempotencyKey);
    }
  }
}
