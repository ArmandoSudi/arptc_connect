import 'dart:async';

import 'package:arptc_connect/modules/itsm/changes/application/changes_application.dart';
import 'package:arptc_connect/modules/itsm/shared/application/itsm_session.dart';
import 'package:arptc_connect/modules/itsm/shared/data/trusted_command_gateways.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_common.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChangeCommandController', () {
    test('USER can submit self-service commands but cannot assess', () async {
      final gateway = _RecordingGateway();
      final controller = ChangeCommandController(
        session: _session(ItsmRole.user),
        accessPolicy: const ChangeAccessPolicy(),
        gateway: gateway,
      );

      await controller
          .execute(_command(ItsmRole.user, ChangeCommandType.submit));
      expect(gateway.commands.single.type, ChangeCommandType.submit);
      expect(
        () => controller.execute(
          _command(ItsmRole.user, ChangeCommandType.assess),
        ),
        throwsA(isA<ChangeAccessDenied>()),
      );
    });

    test('ADMIN remains self-service only', () {
      final controller = ChangeCommandController(
        session: _session(ItsmRole.admin),
        accessPolicy: const ChangeAccessPolicy(),
        gateway: _RecordingGateway(),
      );
      expect(
        () => controller.execute(
          _command(ItsmRole.admin, ChangeCommandType.decideApproval),
        ),
        throwsA(isA<ChangeAccessDenied>()),
      );
    });

    test('MANAGER command actor must match the active session', () {
      final controller = ChangeCommandController(
        session: _session(ItsmRole.manager),
        accessPolicy: const ChangeAccessPolicy(),
        gateway: _RecordingGateway(),
      );
      final forged = ChangeCommand(
        context: ItsmCommandContext(
          idempotencyKey: 'forged-1',
          correlationId: 'change-1',
          actorUserId: 'another-manager',
          actorRole: ItsmRole.manager,
        ),
        type: ChangeCommandType.schedule,
        payload: const {'changeId': 'change-1'},
      );
      expect(
        () => controller.execute(forged),
        throwsA(isA<ChangeAccessDenied>()),
      );
    });

    test('duplicate in-flight commands execute once', () async {
      final gateway = _RecordingGateway(block: true);
      final controller = ChangeCommandController(
        session: _session(ItsmRole.manager),
        accessPolicy: const ChangeAccessPolicy(),
        gateway: gateway,
      );
      final command = _command(ItsmRole.manager, ChangeCommandType.schedule);
      final first = controller.execute(command);
      final second = controller.execute(command);
      gateway.release();
      expect(await first, await second);
      expect(gateway.commands, hasLength(1));
    });
  });
}

ChangeCommand _command(ItsmRole role, ChangeCommandType type) => ChangeCommand(
      context: ItsmCommandContext(
        idempotencyKey: 'command-1',
        correlationId: 'change-1',
        actorUserId: '${role.value.toLowerCase()}-1',
        actorRole: role,
      ),
      type: type,
      payload: const {'changeId': 'change-1'},
    );

ItsmSession _session(ItsmRole role) => ItsmSession(
      sessionKey: '${role.value}|agent@example.com',
      userId: '${role.value.toLowerCase()}-1',
      email: 'agent@example.com',
      displayName: 'Test agent',
      role: role,
    );

class _RecordingGateway implements ChangeCommandGateway {
  _RecordingGateway({this.block = false});

  final bool block;
  final commands = <ChangeCommand>[];
  final _waiter = _Deferred();

  void release() => _waiter.complete();

  @override
  Future<ItsmCommandReceipt> execute(ChangeCommand command) async {
    commands.add(command);
    if (block) await _waiter.future;
    return ItsmCommandReceipt(
      commandId: command.context.idempotencyKey,
      acceptedAt: DateTime.utc(2026, 7, 31),
      wasDuplicate: false,
    );
  }
}

class _Deferred {
  final _completer = Completer<void>();

  Future<void> get future => _completer.future;

  void complete() => _completer.complete();
}
