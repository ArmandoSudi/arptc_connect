import 'package:cloud_functions/cloud_functions.dart';

import '../domain/assets_configuration_domain.dart';
import 'stock_repository.dart';

abstract interface class StockCallableInvoker {
  Future<Object?> invoke(String functionName, Map<String, Object?> payload);
}

class FirebaseStockCallableInvoker implements StockCallableInvoker {
  const FirebaseStockCallableInvoker(this._functions);

  final FirebaseFunctions _functions;

  @override
  Future<Object?> invoke(
    String functionName,
    Map<String, Object?> payload,
  ) async =>
      (await _functions.httpsCallable(functionName).call(payload)).data;
}

class FirebaseStockCommandGateway implements StockCommandGateway {
  const FirebaseStockCommandGateway(this._invoker);

  static const submitMovementFunctionName = 'itsmSubmitStockMovement';

  final StockCallableInvoker _invoker;

  @override
  Future<StockCommandReceipt> submitMovement(
    StockMovementRequest request,
  ) async {
    final result = await _invoker.invoke(submitMovementFunctionName, {
      'command': 'stock.movement.submit',
      'idempotencyKey': request.idempotencyKey,
      'payload': request.toCommandPayload(),
    });
    final data = itsmAssetMap(result);
    final commandId = itsmAssetString(data, 'commandId');
    final movementId = itsmAssetString(data, 'movementId');
    final acceptedAt = itsmAssetDate(data['acceptedAt']);
    if (commandId.isEmpty || movementId.isEmpty || acceptedAt == null) {
      throw const StockCommandGatewayException(
        'The stock command response is incomplete.',
      );
    }
    return StockCommandReceipt(
      commandId: commandId,
      movementId: movementId,
      acceptedAt: acceptedAt,
      wasDuplicate: itsmAssetBool(data, 'wasDuplicate'),
    );
  }
}

class StockCommandGatewayException implements Exception {
  const StockCommandGatewayException(this.message);

  final String message;

  @override
  String toString() => 'StockCommandGatewayException($message)';
}
