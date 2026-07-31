import 'package:arptc_connect/modules/itsm/security_compliance/domain/security_compliance_domain.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_common.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SecurityComplianceAccessPolicy', () {
    test('preserves exactly the shared USER, MANAGER and ADMIN roles', () {
      expect(ItsmRole.values.map((role) => role.value), [
        'USER',
        'MANAGER',
        'ADMIN',
      ]);
    });

    test('reserves raw security findings for MANAGER', () {
      expect(
        SecurityComplianceAccessPolicy.canReadFinding(
          role: ItsmRole.manager,
        ),
        isTrue,
      );
      expect(
        SecurityComplianceAccessPolicy.canReadFinding(role: ItsmRole.user),
        isFalse,
      );
      expect(
        SecurityComplianceAccessPolicy.canReadFinding(role: ItsmRole.admin),
        isFalse,
      );
    });

    test('allows USER and ADMIN to read only their own exceptions', () {
      final exception = _exception();

      for (final role in [ItsmRole.user, ItsmRole.admin]) {
        expect(
          SecurityComplianceAccessPolicy.canReadException(
            role: role,
            actorUserId: 'user-1',
            exception: exception,
          ),
          isTrue,
        );
        expect(
          SecurityComplianceAccessPolicy.canReadException(
            role: role,
            actorUserId: 'user-2',
            exception: exception,
          ),
          isFalse,
        );
      }
      expect(
        SecurityComplianceAccessPolicy.canReadException(
          role: ItsmRole.manager,
          actorUserId: 'manager-1',
          exception: exception,
        ),
        isTrue,
      );
    });

    test('requires explicit MANAGER authorization for restricted evidence', () {
      final evidence = _restrictedEvidence();

      expect(
        SecurityComplianceAccessPolicy.canReadOperationalEvidence(
          role: ItsmRole.manager,
          actorUserId: 'manager-1',
          evidence: evidence,
        ),
        isTrue,
      );
      expect(
        SecurityComplianceAccessPolicy.canReadOperationalEvidence(
          role: ItsmRole.manager,
          actorUserId: 'manager-2',
          evidence: evidence,
        ),
        isFalse,
      );
      expect(
        SecurityComplianceAccessPolicy.canReadOperationalEvidence(
          role: ItsmRole.admin,
          actorUserId: 'manager-1',
          evidence: evidence,
        ),
        isFalse,
      );
    });

    test('limits detailed compliance and own-device projection by role', () {
      final projection = OwnDeviceComplianceProjection(
        id: 'projection-1',
        assetId: 'asset-1',
        assetTag: 'ARPTC-1',
        assetName: 'Laptop',
        assignedUserId: 'user-1',
        status: OwnDeviceComplianceStatus.compliant,
        assessedAt: DateTime.utc(2026, 8, 1),
        updatedAt: DateTime.utc(2026, 8, 2),
      );

      expect(
        SecurityComplianceAccessPolicy.canReadComplianceAssessment(
          role: ItsmRole.manager,
        ),
        isTrue,
      );
      expect(
        SecurityComplianceAccessPolicy.canReadComplianceAssessment(
          role: ItsmRole.admin,
        ),
        isFalse,
      );
      expect(
        SecurityComplianceAccessPolicy.canReadOwnComplianceProjection(
          role: ItsmRole.user,
          actorUserId: 'user-1',
          projection: projection,
        ),
        isTrue,
      );
      expect(
        SecurityComplianceAccessPolicy.canReadOwnComplianceProjection(
          role: ItsmRole.user,
          actorUserId: 'user-2',
          projection: projection,
        ),
        isFalse,
      );
      expect(
        SecurityComplianceAccessPolicy.canReadOwnComplianceProjection(
          role: ItsmRole.admin,
          actorUserId: 'user-1',
          projection: projection,
        ),
        isFalse,
      );
    });

    test('allows own access review and governed correction requests', () {
      final campaign = _campaign(allowSelfServiceCorrection: true);
      final disabled = _campaign(allowSelfServiceCorrection: false);
      final item = _reviewItem();

      expect(
        SecurityComplianceAccessPolicy.canReadAccessReviewItem(
          role: ItsmRole.admin,
          actorUserId: 'user-1',
          item: item,
        ),
        isTrue,
      );
      expect(
        SecurityComplianceAccessPolicy.canReadAccessReviewItem(
          role: ItsmRole.admin,
          actorUserId: 'user-2',
          item: item,
        ),
        isFalse,
      );
      expect(
        SecurityComplianceAccessPolicy.canRequestAccessCorrection(
          role: ItsmRole.user,
          actorUserId: 'user-1',
          item: item,
          campaign: campaign,
        ),
        isTrue,
      );
      expect(
        SecurityComplianceAccessPolicy.canRequestAccessCorrection(
          role: ItsmRole.user,
          actorUserId: 'user-1',
          item: item,
          campaign: disabled,
        ),
        isFalse,
      );
    });
  });

  group('pure serialization helpers', () {
    test('accepts DateTime, ISO, epoch and timestamp-like values as UTC', () {
      final expected = DateTime.utc(2026, 8, 1, 12);

      expect(securityComplianceDate(expected), expected);
      expect(securityComplianceDate(expected.toIso8601String()), expected);
      expect(
        securityComplianceDate(expected.millisecondsSinceEpoch),
        expected,
      );
      expect(securityComplianceDate(_TimestampLike(expected)), expected);
    });

    test('normalizes enum names and de-duplicates immutable strings', () {
      expect(enumStorageValue(OwnDeviceComplianceStatus.actionRequired),
          'action_required');
      final values = securityComplianceStrings(['one', ' one ', '', 'two']);
      expect(values, ['one', 'two']);
      expect(() => values.add('three'), throwsUnsupportedError);
    });
  });
}

SecurityException _exception() => SecurityException(
      id: 'exception-1',
      reference: 'EXC-1',
      title: 'Temporary exception',
      requirementOrControl: 'Encryption baseline',
      businessJustification: 'Legacy replacement is pending.',
      scope: 'One appliance',
      riskDescription: 'Potential data exposure.',
      compensatingControls: [
        CompensatingControl(
          id: 'control-1',
          description: 'Network isolation',
        ),
      ],
      requester: SecurityActor(userId: 'user-1', displayName: 'User One'),
      status: SecurityExceptionStatus.submitted,
      requestedStartAt: DateTime.utc(2026, 8, 1),
      requestedEndAt: DateTime.utc(2026, 12, 31),
      reviewAt: DateTime.utc(2026, 10, 31),
      createdAt: DateTime.utc(2026, 7, 31),
      updatedAt: DateTime.utc(2026, 8, 1),
      updatedBy: 'user-1',
    );

SecurityEvidenceMetadata _restrictedEvidence() => SecurityEvidenceMetadata(
      id: 'evidence-1',
      fileName: 'restricted.pdf',
      contentType: 'application/pdf',
      storagePath: 'restricted/evidence-1',
      confidentiality: ItsmConfidentiality.restricted,
      createdBy: 'manager-1',
      createdAt: DateTime.utc(2026, 8, 1),
      authorizedManagerIds: const ['manager-1'],
    );

AccessReviewCampaign _campaign({required bool allowSelfServiceCorrection}) =>
    AccessReviewCampaign(
      id: 'campaign-1',
      reference: 'AR-1',
      title: 'Directory review',
      scope: 'Finance',
      systemId: 'directory-1',
      systemName: 'Directory',
      owner: SecurityActor(userId: 'manager-1', displayName: 'Manager One'),
      status: AccessReviewCampaignStatus.active,
      startsAt: DateTime.utc(2026, 8, 1),
      dueAt: DateTime.utc(2026, 8, 31),
      allowSelfServiceCorrection: allowSelfServiceCorrection,
      reviewerUserIds: const ['manager-1'],
      createdAt: DateTime.utc(2026, 7, 31),
      createdBy: 'manager-1',
      updatedAt: DateTime.utc(2026, 8, 1),
    );

AccessReviewItem _reviewItem() => AccessReviewItem(
      id: 'item-1',
      campaignId: 'campaign-1',
      systemId: 'directory-1',
      systemName: 'Directory',
      subjectUser: SecurityActor(userId: 'user-1', displayName: 'User One'),
      currentAccess: 'Read',
      currentRole: 'reader',
      departmentId: 'department-1',
      departmentName: 'Finance',
      reviewer: SecurityActor(
        userId: 'manager-1',
        displayName: 'Manager One',
      ),
      decision: AccessReviewDecision.pending,
      completionStatus: AccessReviewCompletionStatus.pending,
      dueAt: DateTime.utc(2026, 8, 31),
      createdAt: DateTime.utc(2026, 8, 1),
      updatedAt: DateTime.utc(2026, 8, 1),
    );

class _TimestampLike {
  const _TimestampLike(this.value);

  final DateTime value;

  DateTime toDate() => value;
}
