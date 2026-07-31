import 'package:arptc_connect/modules/itsm/assets_configuration/data/assets_configuration_data.dart';
import 'package:arptc_connect/modules/itsm/assets_configuration/domain/assets_configuration_domain.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/pagination.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

class RecordingStockInvoker implements StockCallableInvoker {
  String? functionName;
  Map<String, Object?>? payload;
  Object? result;

  @override
  Future<Object?> invoke(
    String functionName,
    Map<String, Object?> payload,
  ) async {
    this.functionName = functionName;
    this.payload = payload;
    return result;
  }
}

void main() {
  test('cursor codec round-trips stable date and document ID values', () {
    const codec = FirestorePageCursorCodec(sortField: 'updatedAt');
    final date = DateTime.utc(2026, 7, 31, 10, 30);
    final cursor = codec.encode(sortAt: date, documentId: 'asset-25');
    final decoded = codec.decode(cursor);

    expect((decoded.first as Timestamp).toDate().toUtc(), date);
    expect(decoded.last, 'asset-25');
    expect(
      () => codec.decode(PageCursor({'updatedAt': date.toIso8601String()})),
      throwsA(isA<AssetsConfigurationPaginationException>()),
    );
  });

  test('stock mutation is sent only through the trusted callable envelope',
      () async {
    final invoker = RecordingStockInvoker()
      ..result = {
        'commandId': 'command-1',
        'movementId': 'movement-1',
        'acceptedAt': '2026-07-31T10:30:00.000Z',
        'wasDuplicate': false,
      };
    final gateway = FirebaseStockCommandGateway(invoker);
    final receipt = await gateway.submitMovement(
      StockMovementRequest(
        idempotencyKey: 'idempotency-1',
        stockItemId: 'stock-1',
        type: StockMovementType.issue,
        quantity: 1,
        sourceLocationId: 'store-1',
        actorUserId: 'manager-1',
        recipientUserId: 'agent-1',
        requestedAt: DateTime.utc(2026, 7, 31),
      ),
    );

    expect(
      invoker.functionName,
      FirebaseStockCommandGateway.submitMovementFunctionName,
    );
    expect(invoker.payload?['command'], 'stock.movement.submit');
    expect(invoker.payload?['idempotencyKey'], 'idempotency-1');
    expect(receipt.movementId, 'movement-1');
  });
}
