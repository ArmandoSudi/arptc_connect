import 'package:arptc_connect/modules/itsm/changes/application/changes_application.dart';
import 'package:arptc_connect/modules/itsm/changes/data/firebase_change_command_gateway.dart';
import 'package:arptc_connect/modules/itsm/shared/data/trusted_command_gateways.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_common.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('gateway invokes the command-specific trusted callable', () async {
    final invoker = _RecordingInvoker();
    final gateway = FirebaseChangeCommandGateway(invoker);
    final command = ChangeCommand(
      context: ItsmCommandContext(
        idempotencyKey: 'approval-1',
        correlationId: 'change-1',
        actorUserId: 'manager-1',
        actorRole: ItsmRole.manager,
      ),
      type: ChangeCommandType.decideApproval,
      payload: const {
        'changeId': 'change-1',
        'approvalId': 'approval-1',
        'decision': 'approved',
      },
    );

    final receipt = await gateway.execute(command);

    expect(invoker.functionName, 'itsmDecideChangeApproval');
    expect(invoker.data['command'], 'change.approval.decide');
    expect(invoker.data['idempotencyKey'], 'approval-1');
    expect(receipt.commandId, 'approval-1');
  });
}

class _RecordingInvoker implements ChangeCallableInvoker {
  String? functionName;
  Map<String, Object?> data = const {};

  @override
  Future<Object?> invoke(
    String functionName,
    Map<String, Object?> data,
  ) async {
    this.functionName = functionName;
    this.data = data;
    return {
      'commandId': 'approval-1',
      'acceptedAt': DateTime.utc(2026, 7, 31).toIso8601String(),
      'wasDuplicate': false,
    };
  }
}
