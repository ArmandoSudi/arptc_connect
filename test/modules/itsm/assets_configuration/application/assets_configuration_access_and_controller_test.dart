import 'package:arptc_connect/modules/itsm/assets_configuration/application/assets_configuration_application.dart';
import 'package:arptc_connect/modules/itsm/shared/data/trusted_command_gateways.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_common.dart';
import 'package:flutter_test/flutter_test.dart';

import 'assets_configuration_test_support.dart';

void main() {
  const policy = AssetsConfigurationAccessPolicy();

  test('USER and ADMIN can read only self-service assets', () {
    expect(policy.canReadMyAssets(assetSession(ItsmRole.user)), isTrue);
    expect(policy.canReadMyAssets(assetSession(ItsmRole.admin)), isTrue);
    expect(policy.canOperate(assetSession(ItsmRole.user)), isFalse);
    expect(policy.canOperate(assetSession(ItsmRole.admin)), isFalse);
  });

  test('MANAGER alone receives operational access', () {
    final session = assetSession(ItsmRole.manager);
    expect(policy.canOperate(session), isTrue);
    expect(() => policy.authorizeOperational(session), returnsNormally);
  });

  test('USER operational command is denied before reaching command port', () {
    final port = RecordingAssetsCommandPort();
    final session = assetSession(ItsmRole.user);
    final controller = AssetsConfigurationCommandController(
      session: session,
      accessPolicy: policy,
      commandPort: port,
    );
    final command = AssetOperationalCommand(
      context: _context(session.role, session.userId, 'denied-command'),
      assetId: 'asset-1',
      operation: 'update_lifecycle',
    );

    expect(
      () => controller.operateAsset(command),
      throwsA(isA<AssetsConfigurationAccessDenied>()),
    );
    expect(port.commands, isEmpty);
  });

  test('duplicate manager command shares one in-flight execution', () async {
    final port = RecordingAssetsCommandPort()..completeImmediately = false;
    final session = assetSession(ItsmRole.manager);
    final controller = AssetsConfigurationCommandController(
      session: session,
      accessPolicy: policy,
      commandPort: port,
    );
    final command = AssetOperationalCommand(
      context: _context(session.role, session.userId, 'same-command'),
      assetId: 'asset-1',
      operation: 'update_lifecycle',
    );

    final first = controller.operateAsset(command);
    final second = controller.operateAsset(command);
    expect(identical(first, second), isTrue);
    expect(port.commands, hasLength(1));

    port.completer.complete(
      ItsmCommandReceipt(
        commandId: 'same-command',
        acceptedAt: fixtureDate,
        wasDuplicate: false,
      ),
    );
    await Future.wait([first, second]);
  });

  test('stock movement requires positive quantity and active actor', () {
    final port = RecordingAssetsCommandPort();
    final session = assetSession(ItsmRole.manager);
    final controller = AssetsConfigurationCommandController(
      session: session,
      accessPolicy: policy,
      commandPort: port,
    );
    final command = StockMovementCommand(
      context: _context(session.role, session.userId, 'stock-command'),
      itemId: 'item-1',
      type: StockMovementType.issue,
      quantity: 0,
      actorUserId: session.userId,
    );

    expect(
      () => controller.recordStockMovement(command),
      throwsA(isA<AssetsConfigurationAccessDenied>()),
    );
    expect(port.commands, isEmpty);
  });

  test('stock adjustment accepts a signed non-zero delta', () async {
    final port = RecordingAssetsCommandPort();
    final session = assetSession(ItsmRole.manager);
    final controller = AssetsConfigurationCommandController(
      session: session,
      accessPolicy: policy,
      commandPort: port,
    );
    final command = StockMovementCommand(
      context: _context(session.role, session.userId, 'stock-decrease'),
      itemId: 'item-1',
      type: StockMovementType.adjustment,
      quantity: 0,
      adjustmentDelta: -2,
      actorUserId: session.userId,
    );

    await controller.recordStockMovement(command);

    expect(port.commands, [command]);
  });

  test('stock reconciliation accepts a zero target', () async {
    final port = RecordingAssetsCommandPort();
    final session = assetSession(ItsmRole.manager);
    final controller = AssetsConfigurationCommandController(
      session: session,
      accessPolicy: policy,
      commandPort: port,
    );
    final command = StockMovementCommand(
      context: _context(session.role, session.userId, 'stock-zero'),
      itemId: 'item-1',
      type: StockMovementType.reconciliation,
      quantity: 10,
      targetOnHand: 0,
      targetReserved: 0,
      actorUserId: session.userId,
    );

    await controller.recordStockMovement(command);

    expect(port.commands, [command]);
  });
}

ItsmCommandContext _context(ItsmRole role, String userId, String key) {
  return ItsmCommandContext(
    idempotencyKey: key,
    correlationId: 'correlation-$key',
    actorUserId: userId,
    actorRole: role,
  );
}
