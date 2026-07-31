import 'dart:async';

import 'package:arptc_connect/modules/itsm/security_compliance/application/security_compliance_application.dart';
import 'package:arptc_connect/modules/itsm/shared/application/itsm_session.dart';
import 'package:arptc_connect/modules/itsm/shared/data/trusted_command_gateways.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_common.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SecurityComplianceCommandController', () {
    test('deduplicates an in-flight trusted command', () async {
      final gateway = _Gateway();
      final controller = SecurityComplianceCommandController(
        session: _session(ItsmRole.manager),
        policy: const SecurityComplianceApplicationPolicy(),
        gateway: gateway,
      );
      final command = _command(
        SecurityComplianceCommandType.createFinding,
        ItsmRole.manager,
      );

      final first = controller.execute(command);
      final second = controller.execute(command);

      expect(gateway.calls, 1);
      gateway.complete();
      expect((await first).commandId, 'command-1');
      expect((await second).commandId, 'command-1');
      expect(controller.isExecuting(command.context.idempotencyKey), isFalse);
    });

    test('USER can use exception and correction self-service only', () async {
      final gateway = _ImmediateGateway();
      final controller = SecurityComplianceCommandController(
        session: _session(ItsmRole.user),
        policy: const SecurityComplianceApplicationPolicy(),
        gateway: gateway,
      );

      await controller.execute(
        _command(SecurityComplianceCommandType.createException, ItsmRole.user),
      );
      await controller.execute(
        _command(
          SecurityComplianceCommandType.requestAccessCorrection,
          ItsmRole.user,
          suffix: 'correction',
        ),
      );
      expect(
        () => controller.execute(
          _command(
            SecurityComplianceCommandType.createFinding,
            ItsmRole.user,
            suffix: 'finding',
          ),
        ),
        throwsA(isA<SecurityComplianceAccessDenied>()),
      );
    });

    test('ADMIN has no raw operational command access', () {
      final controller = SecurityComplianceCommandController(
        session: _session(ItsmRole.admin),
        policy: const SecurityComplianceApplicationPolicy(),
        gateway: _ImmediateGateway(),
      );
      expect(
        () => controller.execute(
          _command(
              SecurityComplianceCommandType.assessCompliance, ItsmRole.admin),
        ),
        throwsA(isA<SecurityComplianceAccessDenied>()),
      );
    });

    test('rejects a command actor from a previous session', () {
      final controller = SecurityComplianceCommandController(
        session: _session(ItsmRole.manager),
        policy: const SecurityComplianceApplicationPolicy(),
        gateway: _ImmediateGateway(),
      );
      expect(
        () => controller.execute(
          SecurityComplianceCommand(
            context: ItsmCommandContext(
              idempotencyKey: 'security:old-user:0001',
              correlationId: 'test-old-user',
              actorUserId: 'old-user',
              actorRole: ItsmRole.manager,
            ),
            type: SecurityComplianceCommandType.createFinding,
          ),
        ),
        throwsA(isA<SecurityComplianceAccessDenied>()),
      );
    });
  });
}

ItsmSession _session(ItsmRole role) => ItsmSession(
      sessionKey: 'user-1|user@example.com',
      userId: 'user-1',
      email: 'user@example.com',
      displayName: 'Test User',
      role: role,
    );

SecurityComplianceCommand _command(
  SecurityComplianceCommandType type,
  ItsmRole role, {
  String suffix = 'default',
}) =>
    SecurityComplianceCommand(
      context: ItsmCommandContext(
        idempotencyKey: 'security:user-1:$suffix',
        correlationId: 'test-$suffix',
        actorUserId: 'user-1',
        actorRole: role,
      ),
      type: type,
    );

class _Gateway implements SecurityComplianceCommandGateway {
  final _completer = Completer<ItsmCommandReceipt>();
  int calls = 0;

  @override
  Future<ItsmCommandReceipt> execute(SecurityComplianceCommand command) {
    calls += 1;
    return _completer.future;
  }

  void complete() => _completer.complete(
        ItsmCommandReceipt(
          commandId: 'command-1',
          acceptedAt: DateTime.utc(2026, 7, 31),
          wasDuplicate: false,
        ),
      );
}

class _ImmediateGateway implements SecurityComplianceCommandGateway {
  @override
  Future<ItsmCommandReceipt> execute(
    SecurityComplianceCommand command,
  ) async =>
      ItsmCommandReceipt(
        commandId: command.type.command,
        acceptedAt: DateTime.utc(2026, 7, 31),
        wasDuplicate: false,
      );
}
