import 'package:cloud_functions/cloud_functions.dart';

import '../../shared/data/trusted_command_gateways.dart';
import '../application/change_commands.dart';
import '../domain/change_serialization.dart';

abstract interface class ChangeCallableInvoker {
  Future<Object?> invoke(String functionName, Map<String, Object?> data);
}

class FirebaseChangeCallableInvoker implements ChangeCallableInvoker {
  const FirebaseChangeCallableInvoker(this._functions);

  final FirebaseFunctions _functions;

  @override
  Future<Object?> invoke(
          String functionName, Map<String, Object?> data) async =>
      (await _functions.httpsCallable(functionName).call(data)).data;
}

class FirebaseChangeCommandGateway implements ChangeCommandGateway {
  const FirebaseChangeCommandGateway(this._invoker);

  final ChangeCallableInvoker _invoker;

  @override
  Future<ItsmCommandReceipt> execute(ChangeCommand command) async {
    final response = await _invoker.invoke(command.type.functionName, {
      'command': command.type.command,
      'idempotencyKey': command.context.idempotencyKey,
      'payload': command.payload,
    });
    final map = response is Map
        ? response.map((key, value) => MapEntry(key.toString(), value))
        : const <String, Object?>{};
    final commandId = changeString(map['commandId']);
    final acceptedAt = changeDateFromValue(map['acceptedAt']);
    if (commandId.isEmpty || acceptedAt == null) {
      throw const ChangeCommandGatewayException(
        'The trusted change command returned an incomplete receipt.',
      );
    }
    return ItsmCommandReceipt(
      commandId: commandId,
      acceptedAt: acceptedAt,
      wasDuplicate: changeBool(map['wasDuplicate']),
    );
  }
}

class ChangeCommandGatewayException implements Exception {
  const ChangeCommandGatewayException(this.message);

  final String message;

  @override
  String toString() => 'ChangeCommandGatewayException($message)';
}
