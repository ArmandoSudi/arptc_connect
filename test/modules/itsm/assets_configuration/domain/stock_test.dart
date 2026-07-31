import 'package:arptc_connect/modules/itsm/assets_configuration/domain/assets_configuration_domain.dart';
import 'package:flutter_test/flutter_test.dart';

StockMovementRequest movement(
  StockMovementType type,
  int quantity, {
  bool consumeReservation = false,
  int reservedQuantity = 0,
  int? adjustmentDelta,
  int? targetOnHand,
  int targetReserved = 0,
  String source = 'store-a',
  String destination = 'store-b',
  String recipient = 'agent-1',
  String reason = 'Approved reconciliation',
}) =>
    StockMovementRequest(
      idempotencyKey: 'command-${type.name}-$quantity',
      stockItemId: 'stock-1',
      type: type,
      quantity: quantity,
      actorUserId: 'manager-1',
      requestedAt: DateTime.utc(2026, 7, 31),
      sourceLocationId: source,
      destinationLocationId: destination,
      recipientUserId: recipient,
      reason: reason,
      consumeReservation: consumeReservation,
      reservedQuantity: reservedQuantity,
      adjustmentDelta: adjustmentDelta,
      targetOnHand: targetOnHand,
      targetReserved: targetReserved,
    );

void main() {
  group('StockQuantityCalculator', () {
    test('applies receipt, reservation and reserved issue consistently', () {
      var quantity = StockQuantityCalculator.apply(
        onHand: 5,
        reserved: 0,
        request: movement(StockMovementType.receipt, 5),
      );
      expect(quantity.onHand, 10);

      quantity = StockQuantityCalculator.apply(
        onHand: quantity.onHand,
        reserved: quantity.reserved,
        request: movement(StockMovementType.reservation, 3),
      );
      expect(quantity.available, 7);

      quantity = StockQuantityCalculator.apply(
        onHand: quantity.onHand,
        reserved: quantity.reserved,
        request: movement(
          StockMovementType.issue,
          2,
          consumeReservation: true,
        ),
      );
      expect(quantity.onHand, 8);
      expect(quantity.reserved, 1);
    });

    test('rejects negative, over-reserved and invalid reconciliation states',
        () {
      expect(
        () => StockQuantityCalculator.apply(
          onHand: 2,
          reserved: 0,
          request: movement(StockMovementType.issue, 3),
        ),
        throwsA(isA<StockValidationException>()),
      );
      expect(
        () => StockQuantityCalculator.apply(
          onHand: 5,
          reserved: 4,
          request: movement(
            StockMovementType.reconciliation,
            3,
            targetOnHand: 3,
            targetReserved: 4,
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('supports a zero-count reconciliation', () {
      final result = StockQuantityCalculator.apply(
        onHand: 5,
        reserved: 0,
        request: movement(StockMovementType.reconciliation, 0),
      );
      expect(result.onHand, 0);
    });

    test('partially fulfils a reservation during issue', () {
      final result = StockQuantityCalculator.apply(
        onHand: 10,
        reserved: 5,
        request: movement(
          StockMovementType.issue,
          4,
          reservedQuantity: 2,
        ),
      );

      expect(result.onHand, 6);
      expect(result.reserved, 3);
    });
  });

  group('StockMovementRequest validation', () {
    test('requires distinct transfer locations', () {
      expect(
        () => movement(
          StockMovementType.transfer,
          1,
          source: 'store-a',
          destination: 'store-a',
        ),
        throwsArgumentError,
      );
    });

    test('requires a recipient for issues and reasons for adjustments', () {
      expect(
        () => movement(StockMovementType.issue, 1, recipient: ''),
        throwsArgumentError,
      );
      expect(
        () => movement(
          StockMovementType.adjustmentDecrease,
          1,
          reason: '',
        ),
        throwsArgumentError,
      );
    });

    test('serializes signed adjustment and zero reconciliation targets', () {
      final adjustment = movement(
        StockMovementType.adjustmentDecrease,
        3,
        adjustmentDelta: -3,
      ).toCommandPayload();
      final reconciliation = movement(
        StockMovementType.reconciliation,
        8,
        targetOnHand: 0,
        targetReserved: 0,
      ).toCommandPayload();

      expect(adjustment['adjustmentDelta'], -3);
      expect(adjustment, isNot(contains('quantity')));
      expect(reconciliation['targetOnHand'], 0);
      expect(reconciliation['targetReserved'], 0);
    });

    test('rejects an adjustment delta with the wrong direction', () {
      expect(
        () => movement(
          StockMovementType.adjustmentDecrease,
          3,
          adjustmentDelta: 3,
        ),
        throwsArgumentError,
      );
    });
  });
}
