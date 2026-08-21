import 'package:arptc_connect/modules/inventory/domain/inventory_domain.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InventoryQuantity', () {
    test('stores decimal quantities as exact thousandths', () {
      expect(InventoryQuantity.parse('1.250').milliUnits, 1250);
      expect(InventoryQuantity.parse('0,075').milliUnits, 75);
      expect(InventoryQuantity.parse('12').format(), '12');
      expect(InventoryQuantity.parse('12.500').format(), '12.5');
    });

    test('rejects more than three decimal places', () {
      expect(() => InventoryQuantity.parse('1.2345'), throwsFormatException);
    });

    test('supports exact signed arithmetic and clamping', () {
      final received = InventoryQuantity.parse('5.125');
      final issued = InventoryQuantity.parse('2.375');

      expect(received - issued, InventoryQuantity.parse('2.75'));
      expect(issued + InventoryQuantity.parse('0.625'),
          InventoryQuantity.parse('3'));
      expect(InventoryQuantity.parse('-0.001').isNegative, isTrue);
      expect(InventoryQuantity.parse('-0.001').clampToZero(),
          InventoryQuantity.zero);
    });

    test('normalizes Firestore values without floating-point arithmetic', () {
      expect(
        InventoryQuantity.fromFirestore(1250),
        InventoryQuantity.parse('1.25'),
      );
      expect(
        InventoryQuantity.fromFirestore('75'),
        InventoryQuantity.parse('0.075'),
      );
      expect(InventoryQuantity.fromFirestore(null), InventoryQuantity.zero);
    });

    test('rejects ambiguous and malformed quantities', () {
      for (final value in ['', '.5', '1.', '1 000', 'one']) {
        expect(
          () => InventoryQuantity.parse(value),
          throwsFormatException,
          reason: value,
        );
      }
    });
  });

  group('InventoryAccessPolicy', () {
    test('keeps ADMIN read-only', () {
      const policy = InventoryAccessPolicy(InventoryRole.admin);
      expect(policy.canReadAllRequests, isTrue);
      expect(policy.canReadExactStock, isTrue);
      expect(policy.canManageInventory, isFalse);
      expect(policy.canSubmitOwnRequest, isFalse);
    });

    test('allows MANAGER operations and on-behalf submission', () {
      const policy = InventoryAccessPolicy(InventoryRole.manager);
      expect(policy.canManageInventory, isTrue);
      expect(policy.canSubmitOnBehalf, isTrue);
      expect(policy.canProcessRequests, isTrue);
    });

    test('enforces the complete role capability matrix', () {
      const none = InventoryAccessPolicy(InventoryRole.none);
      const user = InventoryAccessPolicy(InventoryRole.user);
      const manager = InventoryAccessPolicy(InventoryRole.manager);
      const admin = InventoryAccessPolicy(InventoryRole.admin);

      expect(none.canAccess, isFalse);
      expect(none.canBrowseCatalogue, isFalse);

      expect(user.canBrowseCatalogue, isTrue);
      expect(user.canSubmitOwnRequest, isTrue);
      expect(user.canReadOwnRequests, isTrue);
      expect(user.canReadAllRequests, isFalse);
      expect(user.canReadExactStock, isFalse);
      expect(user.canReadAudit, isFalse);

      expect(manager.canReadAllRequests, isTrue);
      expect(manager.canExecuteStockOperations, isTrue);
      expect(manager.canManageParameters, isTrue);
      expect(manager.isReadOnlyAdmin, isFalse);

      expect(admin.canBrowseCatalogue, isTrue);
      expect(admin.canReadAllRequests, isTrue);
      expect(admin.canReadAudit, isTrue);
      expect(admin.canSubmitOnBehalf, isFalse);
      expect(admin.canProcessRequests, isFalse);
      expect(admin.canExecuteStockOperations, isFalse);
      expect(admin.isReadOnlyAdmin, isTrue);
    });

    test('parses roles defensively', () {
      expect(InventoryRole.fromValue(' manager '), InventoryRole.manager);
      expect(InventoryRole.fromValue('ADMIN'), InventoryRole.admin);
      expect(InventoryRole.fromValue('unknown'), InventoryRole.none);
      expect(InventoryRole.fromValue(null), InventoryRole.none);
    });
  });

  group('MaterialRequestWorkflow', () {
    test('requires requester confirmation before terminal fulfillment', () {
      expect(
        MaterialRequestWorkflow.canTransition(
          MaterialRequestStatus.readyForIssue,
          MaterialRequestStatus.awaitingConfirmation,
        ),
        isTrue,
      );
      expect(
        MaterialRequestWorkflow.canTransition(
          MaterialRequestStatus.awaitingConfirmation,
          MaterialRequestStatus.fulfilled,
        ),
        isTrue,
      );
      expect(
        MaterialRequestWorkflow.canTransition(
          MaterialRequestStatus.readyForIssue,
          MaterialRequestStatus.fulfilled,
        ),
        isFalse,
      );
    });

    test('prevents cancellation after partial fulfillment', () {
      expect(
        MaterialRequestWorkflow.canTransition(
          MaterialRequestStatus.partiallyFulfilled,
          MaterialRequestStatus.cancelled,
        ),
        isFalse,
      );
    });

    test('maps every persisted status and terminal state', () {
      for (final status in MaterialRequestStatus.values) {
        expect(
          MaterialRequestStatus.fromValue(status.firestoreValue),
          status,
          reason: status.firestoreValue,
        );
      }

      expect(MaterialRequestStatus.fromValue('not-a-status'),
          MaterialRequestStatus.submitted);
      expect(MaterialRequestStatus.fulfilled.isTerminal, isTrue);
      expect(MaterialRequestStatus.closedShort.isTerminal, isTrue);
      expect(MaterialRequestStatus.cancelled.isTerminal, isTrue);
      expect(MaterialRequestStatus.rejected.isTerminal, isTrue);
      expect(MaterialRequestStatus.awaitingConfirmation.isTerminal, isFalse);
    });

    test('rejects invalid transitions with an actionable state error', () {
      expect(
        () => MaterialRequestWorkflow.requireTransition(
          MaterialRequestStatus.submitted,
          MaterialRequestStatus.fulfilled,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('submitted'),
          ),
        ),
      );
    });

    test('allows the manager review and fulfillment path', () {
      const path = [
        MaterialRequestStatus.submitted,
        MaterialRequestStatus.underReview,
        MaterialRequestStatus.adjusted,
        MaterialRequestStatus.readyForIssue,
        MaterialRequestStatus.partiallyFulfilled,
        MaterialRequestStatus.awaitingConfirmation,
        MaterialRequestStatus.fulfilled,
      ];

      for (var index = 0; index < path.length - 1; index++) {
        expect(
          MaterialRequestWorkflow.canTransition(path[index], path[index + 1]),
          isTrue,
          reason:
              '${path[index].firestoreValue} -> ${path[index + 1].firestoreValue}',
        );
      }
    });
  });

  group('MaterialRequest serialization', () {
    test('hydrates request snapshots, status, dates, and reasons', () {
      final createdAt = DateTime.utc(2026, 8, 1, 8, 30);
      final request = MaterialRequest.fromFirestore(
        _FakeDocumentSnapshot('request-1', {
          'requestNumber': 'MAT-0001',
          'status': 'awaiting_confirmation',
          'submittedBy': _agentMap('manager-1', 'Inventory Manager'),
          'requestedFor': _agentMap('agent-1', 'Sarah Agent'),
          'assignedManager': _agentMap('manager-1', 'Inventory Manager'),
          'recipient': _agentMap('agent-1', 'Sarah Agent'),
          'justification': 'Operational need',
          'deliveryDestination': 'Head office',
          'hasAdjustments': true,
          'hasIssuedStock': true,
          'lineCount': 2,
          'shortfallReason': 'One line partially issued',
          'createdAt': Timestamp.fromDate(createdAt),
          'updatedAt': createdAt.toIso8601String(),
          'submittedAt': createdAt,
        }),
      );

      expect(request.id, 'request-1');
      expect(request.requestNumber, 'MAT-0001');
      expect(request.status, MaterialRequestStatus.awaitingConfirmation);
      expect(request.submittedBy.userId, 'manager-1');
      expect(request.requestedFor.departmentName, 'Finance');
      expect(request.assignedManager?.name, 'Inventory Manager');
      expect(request.recipient?.userId, 'agent-1');
      expect(request.hasAdjustments, isTrue);
      expect(request.hasIssuedStock, isTrue);
      expect(request.lineCount, 2);
      expect(request.createdAt?.toUtc(), createdAt);
      expect(request.updatedAt, createdAt);
      expect(request.canBeConfirmedBy('agent-1'), isTrue);
      expect(request.canBeConfirmedBy('someone-else'), isFalse);
      expect(request.canBeCancelledBy('agent-1'), isFalse);
    });

    test('hydrates line quantities and clamps negative outstanding stock', () {
      final line = MaterialRequestLine.fromFirestore(
        _FakeDocumentSnapshot('line-1', {
          'itemId': 'paper-a4',
          'itemName': 'A4 Paper',
          'unitOfMeasureName': 'Ream',
          'status': 'partially_fulfilled',
          'requestedMilli': 5000,
          'approvedMilli': 4000,
          'reservedMilli': 1000,
          'issuedMilli': 4500,
          'adjustmentReason': 'Limited availability',
        }),
      );

      expect(line.status, MaterialRequestLineStatus.partiallyFulfilled);
      expect(line.requested, InventoryQuantity.parse('5'));
      expect(line.approved, InventoryQuantity.parse('4'));
      expect(line.issued, InventoryQuantity.parse('4.5'));
      expect(line.outstanding, InventoryQuantity.zero);
      expect(line.adjustmentReason, 'Limited availability');
    });

    test('agent snapshots round-trip through their persisted map', () {
      const original = InventoryAgentSnapshot(
        userId: 'agent-1',
        name: 'Sarah Agent',
        email: 'sarah@example.com',
        organizationId: 'org-1',
        departmentId: 'department-1',
        departmentName: 'Finance',
        serviceId: 'service-1',
        serviceName: 'Accounting',
        bureauId: 'bureau-1',
        bureauName: 'Payments',
      );

      final restored = InventoryAgentSnapshot.fromMap(original.toMap());

      expect(restored.userId, original.userId);
      expect(restored.email, original.email);
      expect(restored.departmentId, original.departmentId);
      expect(restored.serviceName, original.serviceName);
      expect(restored.bureauName, original.bureauName);
    });
  });

  test('balance availability excludes reserved stock', () {
    final balance = InventoryBalance(
      id: 'balance-1',
      itemId: 'item-1',
      itemName: 'Paper',
      warehouseId: 'warehouse-1',
      warehouseName: 'Central',
      locationId: 'location-1',
      locationName: 'Shelf A',
      onHand: InventoryQuantity.parse('10'),
      reserved: InventoryQuantity.parse('4.5'),
      threshold: InventoryQuantity.parse('6'),
      updatedAt: DateTime.utc(2026),
    );

    expect(balance.available, InventoryQuantity.parse('5.5'));
    expect(balance.isLowStock, isTrue);
  });
}

Map<String, Object?> _agentMap(String userId, String name) => {
      'userId': userId,
      'name': name,
      'email': '$userId@example.com',
      'organizationId': 'org-1',
      'departmentId': 'department-1',
      'departmentName': 'Finance',
      'serviceId': 'service-1',
      'serviceName': 'Accounting',
      'bureauId': 'bureau-1',
      'bureauName': 'Payments',
    };

// Firestore exposes a sealed snapshot API, so this lightweight boundary fake is
// intentionally limited to serialization tests.
// ignore: subtype_of_sealed_class
class _FakeDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  _FakeDocumentSnapshot(this.id, Map<String, Object?> data)
      : _data = Map<String, dynamic>.from(data);

  @override
  final String id;

  final Map<String, dynamic> _data;

  @override
  Map<String, dynamic>? data() => Map<String, dynamic>.from(_data);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
