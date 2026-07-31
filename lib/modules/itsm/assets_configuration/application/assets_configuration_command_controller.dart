import '../../shared/application/itsm_command_executor.dart';
import '../../shared/application/itsm_session.dart';
import '../../shared/data/trusted_command_gateways.dart';
import 'assets_configuration_access_policy.dart';
import 'assets_configuration_contracts.dart';

class AssetsConfigurationCommandController {
  AssetsConfigurationCommandController({
    required ItsmSession session,
    required AssetsConfigurationAccessPolicy accessPolicy,
    required AssetsConfigurationCommandPort commandPort,
    ItsmCommandExecutor? executor,
  })  : _session = session,
        _accessPolicy = accessPolicy,
        _commandPort = commandPort,
        _executor = executor ?? ItsmCommandExecutor();

  final ItsmSession _session;
  final AssetsConfigurationAccessPolicy _accessPolicy;
  final AssetsConfigurationCommandPort _commandPort;
  final ItsmCommandExecutor _executor;

  Future<ItsmCommandReceipt> operateAsset(AssetOperationalCommand command) {
    _authorizeManagerCommand(command);
    return _execute(command);
  }

  Future<ItsmCommandReceipt> recordStockMovement(
    StockMovementCommand command,
  ) {
    _authorizeManagerCommand(command);
    if (command.actorUserId != _session.userId ||
        !_hasValidStockQuantity(command)) {
      throw const AssetsConfigurationAccessDenied(
        'A valid stock quantity and the active actor are required.',
      );
    }
    return _execute(command);
  }

  bool _hasValidStockQuantity(StockMovementCommand command) {
    bool isInteger(num value) => value == value.roundToDouble();

    return switch (command.type) {
      StockMovementType.adjustment =>
        isInteger(command.adjustmentDelta ?? command.quantity) &&
            (command.adjustmentDelta ?? command.quantity) != 0,
      StockMovementType.reconciliation =>
        isInteger(command.targetOnHand ?? command.quantity) &&
            (command.targetOnHand ?? command.quantity) >= 0 &&
            isInteger(command.targetReserved) &&
            command.targetReserved >= 0 &&
            command.targetReserved <=
                (command.targetOnHand ?? command.quantity),
      _ => isInteger(command.quantity) &&
          command.quantity > 0 &&
          isInteger(command.reservedQuantity) &&
          command.reservedQuantity >= 0 &&
          command.reservedQuantity <= command.quantity,
    };
  }

  Future<ItsmCommandReceipt> manageConfiguration(
    ManagerConfigurationCommand command,
  ) {
    _authorizeManagerCommand(command);
    return _execute(command);
  }

  bool isExecuting(String idempotencyKey) {
    return _executor.isExecuting(idempotencyKey);
  }

  void _authorizeManagerCommand(AssetsConfigurationCommand command) {
    _accessPolicy.authorizeOperational(_session);
    if (command.context.actorUserId != _session.userId ||
        command.context.actorRole != _session.role) {
      throw const AssetsConfigurationAccessDenied(
        'The operational command actor must match the active MANAGER session.',
      );
    }
  }

  Future<ItsmCommandReceipt> _execute(AssetsConfigurationCommand command) {
    return _executor.executeOnce(
      command.context,
      () => _commandPort.execute(command),
    );
  }
}
