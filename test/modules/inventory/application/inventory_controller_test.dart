import 'dart:async';

import 'package:arptc_connect/modules/authentication/providers/authorized_session_provider.dart';
import 'package:arptc_connect/modules/inventory/application/inventory_contracts.dart';
import 'package:arptc_connect/modules/inventory/application/inventory_providers.dart';
import 'package:arptc_connect/modules/inventory/application/inventory_request_draft_controller.dart';
import 'package:arptc_connect/modules/inventory/application/inventory_session.dart';
import 'package:arptc_connect/modules/inventory/domain/inventory_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InventoryRequestDraftController', () {
    test('adds, replaces, removes, trims, and clears draft data', () {
      final controller = InventoryRequestDraftController();
      final item = _catalogueItem('paper');

      controller.setQuantity(item, InventoryQuantity.parse('2.5'));
      expect(controller.state.lines, hasLength(1));
      expect(controller.state.lines.single.quantity,
          InventoryQuantity.parse('2.5'));

      controller.setQuantity(item, InventoryQuantity.parse('4'));
      expect(controller.state.lines, hasLength(1));
      expect(
          controller.state.lines.single.quantity, InventoryQuantity.parse('4'));

      controller.setDetails(
        justification: '  Monthly supplies  ',
        destination: '  Main office  ',
      );
      expect(controller.state.justification, 'Monthly supplies');
      expect(controller.state.deliveryDestination, 'Main office');

      controller.setQuantity(item, InventoryQuantity.zero);
      expect(controller.state.lines, isEmpty);

      controller.setQuantity(item, InventoryQuantity.parse('1'));
      controller.clear();
      expect(controller.state.lines, isEmpty);
      expect(controller.state.justification, isEmpty);
      expect(controller.state.deliveryDestination, isEmpty);
    });

    test('exposes immutable line collections', () {
      final controller = InventoryRequestDraftController()
        ..setQuantity(
          _catalogueItem('paper'),
          InventoryQuantity.parse('1'),
        );

      expect(
        () => controller.state.lines.add(
          InventoryRequestDraftLine(
            item: _catalogueItem('pen'),
            quantity: InventoryQuantity.parse('1'),
          ),
        ),
        throwsUnsupportedError,
      );
    });
  });

  test('session-keyed draft providers isolate successive user carts', () {
    final container = ProviderContainer(
      overrides: [
        currentAuthorizedSessionKeyProvider.overrideWithValue('session-a'),
      ],
    );
    addTearDown(container.dispose);
    final item = _catalogueItem('paper');

    container
        .read(inventoryRequestDraftProvider('session-a').notifier)
        .setQuantity(item, InventoryQuantity.parse('3'));

    expect(
      container
          .read(inventoryRequestDraftProvider('session-a'))
          .lines
          .single
          .quantity,
      InventoryQuantity.parse('3'),
    );
    expect(
      container.read(inventoryRequestDraftProvider('session-b')).lines,
      isEmpty,
    );
  });

  group('InventoryCommandController', () {
    test('rejects a duplicate action while the first command is pending',
        () async {
      final gateway = _PendingGateway();
      final controller = InventoryCommandController(
        gateway: gateway,
        isAuthorized: true,
      );
      addTearDown(controller.dispose);

      final first = controller.execute(
        functionName: InventoryCommands.submitRequest,
        commandId: 'command-1',
        payload: const {'requestId': 'request-1'},
      );

      expect(controller.state.isLoading, isTrue);
      await expectLater(
        controller.execute(
          functionName: InventoryCommands.submitRequest,
          commandId: 'command-2',
          payload: const {'requestId': 'request-1'},
        ),
        throwsA(isA<InventoryCommandInProgress>()),
      );
      expect(gateway.calls, 1);

      gateway.complete(
        const InventoryCommandResult(
          commandId: 'command-1',
          entityId: 'request-1',
          wasReplay: false,
        ),
      );
      final result = await first;

      expect(result.entityId, 'request-1');
      expect(controller.state.valueOrNull?.commandId, 'command-1');
    });

    test('fails closed before calling the gateway without a session', () async {
      final gateway = _PendingGateway();
      final controller = InventoryCommandController(
        gateway: gateway,
        isAuthorized: false,
      );
      addTearDown(controller.dispose);

      await expectLater(
        controller.execute(
          functionName: InventoryCommands.saveItem,
          commandId: 'command-1',
          payload: const {},
        ),
        throwsA(isA<InventorySessionRequired>()),
      );
      expect(gateway.calls, 0);
      expect(controller.state.hasValue, isTrue);
    });

    test('captures command failures and can clear a completed state', () async {
      final gateway = _FailingGateway();
      final controller = InventoryCommandController(
        gateway: gateway,
        isAuthorized: true,
      );
      addTearDown(controller.dispose);

      await expectLater(
        controller.execute(
          functionName: InventoryCommands.adjustStock,
          commandId: 'command-1',
          payload: const {},
        ),
        throwsA(isA<InventoryCommandException>()),
      );
      expect(controller.state.hasError, isTrue);

      controller.clear();
      expect(controller.state.valueOrNull, isNull);
      expect(controller.state.hasError, isFalse);
    });
  });
}

InventoryCatalogueItem _catalogueItem(String id) => InventoryCatalogueItem(
      id: id,
      sku: id.toUpperCase(),
      name: id == 'paper' ? 'A4 Paper' : 'Blue Pen',
      nameLower: id == 'paper' ? 'a4 paper' : 'blue pen',
      description: 'Office supply',
      categoryId: 'office',
      categoryName: 'Office supplies',
      unitOfMeasureName: 'Unit',
      availability: InventoryAvailability.available,
      isRequestable: true,
      isActive: true,
    );

class _PendingGateway implements InventoryCommandGateway {
  final Completer<InventoryCommandResult> _completer =
      Completer<InventoryCommandResult>();
  int calls = 0;

  @override
  Future<InventoryCommandResult> execute(InventoryCommand command) {
    calls++;
    return _completer.future;
  }

  void complete(InventoryCommandResult result) => _completer.complete(result);
}

class _FailingGateway implements InventoryCommandGateway {
  @override
  Future<InventoryCommandResult> execute(InventoryCommand command) {
    throw const InventoryCommandException('failed-precondition', 'Failed');
  }
}
