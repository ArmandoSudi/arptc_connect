import 'dart:async';

import 'package:arptc_connect/modules/itsm/reporting_administration/application/reporting_administration_application.dart';
import 'package:arptc_connect/modules/itsm/reporting_administration/data/reporting_administration_command_gateway.dart';
import 'package:arptc_connect/modules/itsm/shared/application/itsm_session.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_common.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const policy = ReportingAdministrationAccessPolicy();

  test('role policy separates operational, executive and mutation access', () {
    final manager = _session(ItsmRole.manager);
    final admin = _session(ItsmRole.admin);
    final user = _session(ItsmRole.user);
    expect(
        policy.allows(
            manager, ReportingAdministrationCapability.operationalDashboard),
        isTrue);
    expect(
        policy.allows(
            manager, ReportingAdministrationCapability.executiveDashboard),
        isFalse);
    expect(
        policy.allows(
            admin, ReportingAdministrationCapability.executiveDashboard),
        isTrue);
    expect(
        policy.allows(
            admin, ReportingAdministrationCapability.mutateConfiguration),
        isFalse);
    expect(policy.allows(user, ReportingAdministrationCapability.section),
        isFalse);
  });

  test('ADMIN cannot execute configuration commands', () async {
    final gateway = _Gateway();
    final controller = ReportingAdministrationCommandController(
      session: _session(ItsmRole.admin),
      accessPolicy: policy,
      gateway: gateway,
    );
    await expectLater(
      controller.execute(_command('admin-command')),
      throwsA(isA<ReportingAdministrationAccessDenied>()),
    );
    expect(gateway.calls, 0);
  });

  test('MANAGER command controller suppresses duplicate in-flight commands',
      () async {
    final gateway = _Gateway(block: true);
    final controller = ReportingAdministrationCommandController(
      session: _session(ItsmRole.manager),
      accessPolicy: policy,
      gateway: gateway,
    );
    final first = controller.execute(_command('same-key'));
    expect(controller.isExecuting('same-key'), isTrue);
    await expectLater(
        controller.execute(_command('same-key')), throwsStateError);
    gateway.complete();
    await first;
    expect(controller.isExecuting('same-key'), isFalse);
    expect(gateway.calls, 1);
  });
}

ItsmSession _session(ItsmRole role) => ItsmSession(
      sessionKey: '${role.value}|test',
      userId: '${role.value.toLowerCase()}-1',
      email: '${role.value.toLowerCase()}@example.com',
      displayName: role.value,
      role: role,
    );

ReportingAdministrationCommand _command(String key) =>
    ReportingAdministrationCommand(
      type: ReportingAdministrationCommandType.validateSlaDraft,
      idempotencyKey: key,
      payload: const {'policyId': 'sla-1'},
    );

class _Gateway implements ReportingAdministrationCommandGateway {
  _Gateway({this.block = false});
  final bool block;
  int calls = 0;
  final Completer<void> _release = Completer<void>();

  void complete() => _release.complete();

  @override
  Future<ReportingAdministrationCommandResult> execute(
      ReportingAdministrationCommand command) async {
    calls++;
    if (block) await _release.future;
    return ReportingAdministrationCommandResult(
      commandId: 'command-$calls',
      acceptedAt: DateTime.utc(2026, 7, 31),
      wasDuplicate: false,
    );
  }
}
