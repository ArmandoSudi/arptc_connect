import 'dart:async';

import 'package:arptc_connect/modules/itsm/shared/application/itsm_command_executor.dart';
import 'package:arptc_connect/modules/itsm/shared/data/trusted_command_gateways.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_common.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('command context requires stable idempotency metadata', () {
    expect(
      () => ItsmCommandContext(
        idempotencyKey: '',
        correlationId: 'correlation-1',
        actorUserId: 'user-1',
        actorRole: ItsmRole.manager,
      ),
      throwsArgumentError,
    );
  });

  test('executor coalesces duplicate in-flight commands', () async {
    final executor = ItsmCommandExecutor();
    final completer = Completer<ItsmCommandReceipt>();
    var callCount = 0;
    final context = ItsmCommandContext(
      idempotencyKey: 'request-1:transition:assign',
      correlationId: 'correlation-1',
      actorUserId: 'manager-1',
      actorRole: ItsmRole.manager,
    );

    Future<ItsmCommandReceipt> execute() {
      callCount++;
      return completer.future;
    }

    final first = executor.executeOnce(context, execute);
    final duplicate = executor.executeOnce(context, execute);

    expect(identical(first, duplicate), isTrue);
    expect(callCount, 1);
    expect(executor.isExecuting(context.idempotencyKey), isTrue);

    final receipt = ItsmCommandReceipt(
      commandId: 'command-1',
      acceptedAt: DateTime.utc(2026, 7, 31),
      wasDuplicate: false,
    );
    completer.complete(receipt);
    await expectLater(first, completion(same(receipt)));
    await Future<void>.delayed(Duration.zero);
    expect(executor.isExecuting(context.idempotencyKey), isFalse);
  });
}
