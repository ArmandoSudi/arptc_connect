import '../../shared/application/itsm_command_executor.dart';
import '../../shared/application/itsm_session.dart';
import '../../shared/data/trusted_command_gateways.dart';
import 'security_compliance_access.dart';
import 'security_compliance_commands.dart';

class SecurityComplianceCommandController {
  SecurityComplianceCommandController({
    required ItsmSession session,
    required SecurityComplianceApplicationPolicy policy,
    required SecurityComplianceCommandGateway gateway,
    ItsmCommandExecutor? executor,
  })  : _session = session,
        _policy = policy,
        _gateway = gateway,
        _executor = executor ?? ItsmCommandExecutor();

  final ItsmSession _session;
  final SecurityComplianceApplicationPolicy _policy;
  final SecurityComplianceCommandGateway _gateway;
  final ItsmCommandExecutor _executor;

  bool isExecuting(String idempotencyKey) =>
      _executor.isExecuting(idempotencyKey);

  Future<ItsmCommandReceipt> execute(SecurityComplianceCommand command) {
    if (command.context.actorUserId != _session.userId ||
        command.context.actorRole != _session.role) {
      throw const SecurityComplianceAccessDenied(
        'The command actor must match the active ITSM session.',
      );
    }
    if (command.type.isOperational) {
      _policy.authorize(_session, SecurityComplianceScope.operational);
    } else if (command.type.isSelfServiceException) {
      _policy.authorizeExceptionSubmission(_session);
    } else {
      _policy.authorize(_session, SecurityComplianceScope.selfService);
    }
    return _executor.executeOnce(
      command.context,
      () => _gateway.execute(command),
    );
  }
}
