import 'package:arptc_connect/modules/itsm/assets_configuration/data/firestore_licence_repository.dart';
import 'package:arptc_connect/modules/itsm/assets_configuration/data/firestore_supplier_warranty_repository.dart';
import 'package:arptc_connect/modules/itsm/assets_configuration/domain/assets_configuration_domain.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final occurredAt = DateTime.utc(2026, 7, 31, 10);

  group('trusted Function schema compatibility', () {
    test('parses nested asset lifecycle actor and evidence metadata', () {
      final event = AssetLifecycleEvent.fromMap('event-1', {
        'assetId': 'asset-1',
        'fromStatus': 'assigned',
        'toStatus': 'in_maintenance',
        'reason': 'Preventive maintenance',
        'actor': {
          'userId': 'manager-1',
          'name': 'IT Manager',
          'email': 'manager@example.test',
          'role': 'MANAGER',
        },
        'evidence': [
          {
            'attachmentId': 'attachment-1',
            'storagePath': 'itsm/assets/evidence/attachment-1.pdf',
          },
        ],
        'occurredAt': Timestamp.fromDate(occurredAt),
      });

      expect(event.type, AssetLifecycleEventType.maintenanceStarted);
      expect(event.actorUserId, 'manager-1');
      expect(event.actorName, 'IT Manager');
      expect(event.attachmentIds, ['attachment-1']);
      expect(event.occurredAt, occurredAt);
    });

    test('maps trusted licence allocation and release records additively', () {
      final allocation = SoftwareLicenceAssignment.fromMap('allocation-1', {
        'licenceId': 'licence-1',
        'assignmentType': 'user',
        'assigneeId': 'agent-1',
        'assigneeName': 'Agent One',
        'quantity': 2,
        'status': 'active',
        'allocatedBy': {'userId': 'manager-1', 'name': 'IT Manager'},
        'allocatedAt': Timestamp.fromDate(occurredAt),
      });
      final released = SoftwareLicenceAssignment.fromMap('allocation-2', {
        'licenceId': 'licence-1',
        'assignmentType': 'device',
        'assigneeId': 'asset-1',
        'assigneeName': 'Laptop ARPTC-001',
        'quantity': 1,
        'status': 'released',
        'allocatedBy': {'userId': 'manager-1'},
        'allocatedAt': Timestamp.fromDate(occurredAt),
        'releasedBy': {'userId': 'manager-2'},
        'releasedAt':
            Timestamp.fromDate(occurredAt.add(const Duration(days: 1))),
      });

      expect(allocation.assignedUserId, 'agent-1');
      expect(allocation.assignedUserName, 'Agent One');
      expect(allocation.assignedByUserId, 'manager-1');
      expect(released.assignedAssetId, 'asset-1');
      expect(released.status, LicenceAssignmentStatus.released);
      expect(released.revokedByUserId, 'manager-2');
    });

    test('maps nested trusted licence history records', () {
      final event = LicenceHistoryEvent.fromMap('history-1', {
        'licenceId': 'licence-1',
        'action': 'allocated',
        'before': {'allocatedQuantity': 2},
        'after': {
          'allocatedQuantity': 4,
          'allocationId': 'allocation-1',
        },
        'actor': {'userId': 'manager-1'},
        'occurredAt': Timestamp.fromDate(occurredAt),
      });

      expect(event.type, LicenceHistoryEventType.assigned);
      expect(event.actorUserId, 'manager-1');
      expect(event.quantityDelta, 2);
      expect(event.assignmentId, 'allocation-1');
    });

    test('maps trusted contract, warranty, and nested claim records', () {
      final contract = SupplierContract.fromMap('contract-1', {
        'contractNumber': 'CON-2026-01',
        'name': 'Device support',
        'supplierId': 'supplier-1',
        'status': 'active',
        'startDate': '2026-01-01T00:00:00.000Z',
        'endDate': '2027-01-01T00:00:00.000Z',
        'updatedAt': Timestamp.fromDate(occurredAt),
      });
      final warranty = Warranty.fromMap('warranty-1', {
        'warrantyNumber': 'WAR-2026-01',
        'supplierId': 'supplier-1',
        'status': 'active',
        'startDate': '2026-01-01T00:00:00.000Z',
        'expirationDate': '2027-01-01T00:00:00.000Z',
        'assetIds': ['asset-1'],
      });
      final claim = WarrantyClaim.fromMap('claim-1', {
        'warrantyId': 'warranty-1',
        'assetId': 'asset-1',
        'title': 'Battery failure',
        'description': 'The battery no longer charges.',
        'status': 'closed',
        'actor': {'userId': 'manager-1', 'name': 'IT Manager'},
        'createdAt': Timestamp.fromDate(occurredAt),
        'updatedAt':
            Timestamp.fromDate(occurredAt.add(const Duration(days: 2))),
        'supportingDocument': {'attachmentId': 'document-1'},
        'evidence': [
          {'attachmentId': 'evidence-1'},
        ],
        'transitionReason': 'Replacement supplied.',
      });

      expect(contract.reference, 'CON-2026-01');
      expect(warranty.reference, 'WAR-2026-01');
      expect(warranty.linkedAssetIds, ['asset-1']);
      expect(claim.issueSummary, 'Battery failure');
      expect(claim.description, 'The battery no longer charges.');
      expect(claim.submittedByUserId, 'manager-1');
      expect(claim.status, WarrantyClaimStatus.closed);
      expect(claim.resolvedAt, occurredAt.add(const Duration(days: 2)));
      expect(claim.attachmentIds, containsAll(['document-1', 'evidence-1']));
    });
  });

  group('trusted repository paths', () {
    test('uses the licence allocations subcollection and trusted sort field',
        () {
      expect(
        softwareLicenceAllocationsPath('licence-1'),
        'softwareLicences/licence-1/allocations',
      );
      expect(softwareLicenceAllocationSortField, 'allocatedAt');
    });

    test('uses the nested warranty claims subcollection', () {
      expect(warrantyClaimsPath('warranty-1'), 'warranties/warranty-1/claims');
      expect(warrantyClaimSortField, 'updatedAt');
    });

    test('rejects empty parent identifiers', () {
      expect(() => softwareLicenceAllocationsPath(' '), throwsArgumentError);
      expect(() => warrantyClaimsPath(' '), throwsArgumentError);
    });
  });
}
