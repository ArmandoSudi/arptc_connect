import 'package:arptc_connect/modules/itsm/security_compliance/application/security_compliance_commands.dart';
import 'package:arptc_connect/modules/itsm/security_compliance/data/firebase_security_compliance_command_gateway.dart';
import 'package:arptc_connect/modules/itsm/shared/data/trusted_command_gateways.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_common.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sends only command, idempotencyKey and payload', () async {
    final invoker = _Invoker({
      'findingId': 'finding-1',
      'status': 'detected',
      'revision': 0,
      'reference': 'SECF-0001',
    });
    final gateway = FirebaseSecurityComplianceCommandGateway(
      invoker,
      now: () => DateTime.utc(2026, 7, 31, 10),
    );
    final receipt = await gateway.execute(_command());

    expect(invoker.functionName, 'itsmCreateSecurityFinding');
    expect(invoker.data.keys, {'command', 'idempotencyKey', 'payload'});
    expect(invoker.data, isNot(contains('correlationId')));
    expect(receipt.commandId, 'finding-1');
    expect(receipt.acceptedAt, DateTime.utc(2026, 7, 31, 10));
  });

  test('rejects an incomplete trusted receipt', () async {
    final gateway = FirebaseSecurityComplianceCommandGateway(_Invoker({}));
    expect(
      gateway.execute(_command()),
      throwsA(isA<SecurityComplianceCommandGatewayException>()),
    );
  });
}

SecurityComplianceCommand _command() => SecurityComplianceCommand(
      context: ItsmCommandContext(
        idempotencyKey: 'security:test:0001',
        correlationId: 'correlation-1',
        actorUserId: 'manager-1',
        actorRole: ItsmRole.manager,
      ),
      type: SecurityComplianceCommandType.createFinding,
      payload: const {'title': 'Finding'},
    );

class _Invoker implements SecurityComplianceCallableInvoker {
  _Invoker(this.response);

  final Object? response;
  String? functionName;
  Map<String, Object?> data = const {};

  @override
  Future<Object?> invoke(
    String functionName,
    Map<String, Object?> data,
  ) async {
    this.functionName = functionName;
    this.data = data;
    return response;
  }
}
