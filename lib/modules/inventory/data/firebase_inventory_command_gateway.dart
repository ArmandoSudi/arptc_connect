import 'package:cloud_functions/cloud_functions.dart';

import '../application/inventory_contracts.dart';

class FirebaseInventoryCommandGateway implements InventoryCommandGateway {
  const FirebaseInventoryCommandGateway(this._functions);

  final FirebaseFunctions _functions;

  @override
  Future<InventoryCommandResult> execute(InventoryCommand command) async {
    try {
      return await _invoke(command);
    } on FirebaseFunctionsException catch (error) {
      throw _commandException(error);
    }
  }

  Future<InventoryCommandResult> _invoke(InventoryCommand command) async {
    final response = await _functions
        .httpsCallable(command.functionName)
        .call<Map<String, dynamic>>(command.toPayload());
    final data = response.data;
    return InventoryCommandResult(
      commandId: (data['commandId'] ?? command.commandId).toString(),
      entityId: (data['entityId'] ?? data['requestId'] ?? data['itemId'] ?? '')
          .toString(),
      wasReplay: data['replayed'] == true,
    );
  }
}

InventoryCommandException _commandException(
  FirebaseFunctionsException error,
) =>
    InventoryCommandException(
      error.code,
      error.message ?? 'The Inventory operation failed.',
    );
