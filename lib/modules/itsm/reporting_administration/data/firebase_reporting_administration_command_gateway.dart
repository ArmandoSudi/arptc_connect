import 'package:cloud_functions/cloud_functions.dart';

import '../domain/configuration_common.dart';
import 'reporting_administration_command_gateway.dart';

abstract interface class ReportingAdministrationCallableInvoker {
  Future<Object?> invoke(String functionName, Map<String, Object?> data);
}

class FirebaseReportingAdministrationCallableInvoker
    implements ReportingAdministrationCallableInvoker {
  const FirebaseReportingAdministrationCallableInvoker(this._functions);
  final FirebaseFunctions _functions;

  @override
  Future<Object?> invoke(
          String functionName, Map<String, Object?> data) async =>
      (await _functions.httpsCallable(functionName).call(data)).data;
}

class FirebaseReportingAdministrationCommandGateway
    implements ReportingAdministrationCommandGateway {
  FirebaseReportingAdministrationCommandGateway(this._invoker,
      {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final ReportingAdministrationCallableInvoker _invoker;
  final DateTime Function() _now;

  @override
  Future<ReportingAdministrationCommandResult> execute(
    ReportingAdministrationCommand command,
  ) async {
    final response = await _invoker.invoke(command.type.functionName, {
      'idempotencyKey': command.idempotencyKey,
      'payload': command.payload,
    });
    final map = configurationMap(response);
    final commandId = configurationString(map['commandId'] ?? map['receiptId']);
    if (commandId.isEmpty) {
      throw const ReportingAdministrationGatewayException(
        'The trusted command returned no receipt identifier.',
      );
    }
    return ReportingAdministrationCommandResult(
      commandId: commandId,
      entityId: _nullable(map['entityId'] ??
          map['policyId'] ??
          map['itemId'] ??
          map['workflowId'] ??
          map['exportId']),
      versionId: _nullable(map['versionId']),
      acceptedAt: configurationDate(map['acceptedAt']) ?? _now().toUtc(),
      wasDuplicate: configurationBool(map['wasDuplicate']),
    );
  }
}

class ReportingAdministrationGatewayException implements Exception {
  const ReportingAdministrationGatewayException(this.message);
  final String message;

  @override
  String toString() => 'ReportingAdministrationGatewayException($message)';
}

String? _nullable(Object? value) {
  final result = configurationString(value);
  return result.isEmpty ? null : result;
}
