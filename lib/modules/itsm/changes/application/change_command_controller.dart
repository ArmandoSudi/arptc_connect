import '../../shared/application/itsm_command_executor.dart';
import '../../shared/application/itsm_session.dart';
import '../../shared/data/trusted_command_gateways.dart';
import 'change_access_policy.dart';
import 'change_commands.dart';

class ChangeCommandController {
  ChangeCommandController({
    required ItsmSession session,
    required ChangeAccessPolicy accessPolicy,
    required ChangeCommandGateway gateway,
    ItsmCommandExecutor? executor,
  })  : _session = session,
        _accessPolicy = accessPolicy,
        _gateway = gateway,
        _executor = executor ?? ItsmCommandExecutor();

  final ItsmSession _session;
  final ChangeAccessPolicy _accessPolicy;
  final ChangeCommandGateway _gateway;
  final ItsmCommandExecutor _executor;

  bool isExecuting(String idempotencyKey) =>
      _executor.isExecuting(idempotencyKey);

  Future<ItsmCommandReceipt> execute(ChangeCommand command) {
    if (command.type.isSelfService) {
      if (!_accessPolicy.canUseSelfService(_session)) {
        throw const ChangeAccessDenied('Self-service access is required.');
      }
    } else {
      _accessPolicy.authorizeOperational(_session);
    }
    if (command.context.actorUserId != _session.userId ||
        command.context.actorRole != _session.role) {
      throw const ChangeAccessDenied(
        'The command actor must match the active ITSM session.',
      );
    }
    return _executor.executeOnce(
      command.context,
      () => _gateway.execute(command),
    );
  }
}
