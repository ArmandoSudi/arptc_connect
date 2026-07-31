import 'package:cloud_functions/cloud_functions.dart';

import '../../shared/data/trusted_command_gateways.dart';
import '../application/security_compliance_commands.dart';
import '../domain/security_compliance_serialization.dart';

abstract interface class SecurityComplianceCallableInvoker {
  Future<Object?> invoke(String functionName, Map<String, Object?> data);
}

class FirebaseSecurityComplianceCallableInvoker
    implements SecurityComplianceCallableInvoker {
  const FirebaseSecurityComplianceCallableInvoker(this._functions);

  final FirebaseFunctions _functions;

  @override
  Future<Object?> invoke(
    String functionName,
    Map<String, Object?> data,
  ) async =>
      (await _functions.httpsCallable(functionName).call(data)).data;
}

class FirebaseSecurityComplianceCommandGateway
    implements SecurityComplianceCommandGateway {
  FirebaseSecurityComplianceCommandGateway(
    this._invoker, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final SecurityComplianceCallableInvoker _invoker;
  final DateTime Function() _now;

  @override
  Future<ItsmCommandReceipt> execute(
    SecurityComplianceCommand command,
  ) async {
    final response = await _invoker.invoke(command.type.functionName, {
      'command': command.type.command,
      'idempotencyKey': command.context.idempotencyKey,
      'payload': command.payload,
    });
    final map = response is Map
        ? response.map((key, value) => MapEntry(key.toString(), value))
        : const <String, Object?>{};
    final commandId = _resultId(map);
    final acceptedAt =
        securityComplianceDate(map['acceptedAt']) ?? _now().toUtc();
    if (commandId.isEmpty) {
      throw const SecurityComplianceCommandGatewayException(
        'The trusted security command returned no entity identifier.',
      );
    }
    return ItsmCommandReceipt(
      commandId: commandId,
      acceptedAt: acceptedAt,
      wasDuplicate: securityComplianceBool(map['wasDuplicate']),
    );
  }

  String _resultId(Map<String, Object?> map) {
    for (final key in const [
      'commandId',
      'findingId',
      'exceptionId',
      'assessmentId',
      'campaignId',
      'itemId',
      'taskId',
      'requestId',
    ]) {
      final value = securityComplianceString(map[key]);
      if (value.isNotEmpty) return value;
    }
    return '';
  }
}

class SecurityComplianceCommandGatewayException implements Exception {
  const SecurityComplianceCommandGatewayException(this.message);

  final String message;

  @override
  String toString() => 'SecurityComplianceCommandGatewayException($message)';
}
