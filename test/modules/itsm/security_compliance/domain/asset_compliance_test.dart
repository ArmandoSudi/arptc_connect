import 'package:arptc_connect/modules/itsm/security_compliance/domain/security_compliance_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AssetComplianceCalculator', () {
    test('returns assessment pending for absent or unknown checks', () {
      expect(
        AssetComplianceCalculator.calculate(const []),
        AssetComplianceResult.assessmentPending,
      );
      expect(
        AssetComplianceCalculator.calculate([
          _check(
            ComplianceControlType.patchStatus,
            ComplianceCheckResult.unknown,
          ),
        ]),
        AssetComplianceResult.assessmentPending,
      );
    });

    test('returns non-compliant when any control fails', () {
      final result = AssetComplianceCalculator.calculate([
        _check(
          ComplianceControlType.operatingSystemSupport,
          ComplianceCheckResult.compliant,
        ),
        _check(
          ComplianceControlType.encryption,
          ComplianceCheckResult.nonCompliant,
        ),
      ]);

      expect(result, AssetComplianceResult.nonCompliant);
      expect(
        AssetComplianceCalculator.safeStatus(result),
        OwnDeviceComplianceStatus.actionRequired,
      );
    });

    test('ignores not-applicable controls when applicable checks pass', () {
      final result = AssetComplianceCalculator.calculate([
        _check(
          ComplianceControlType.backup,
          ComplianceCheckResult.notApplicable,
        ),
        _check(
          ComplianceControlType.securityBaseline,
          ComplianceCheckResult.compliant,
        ),
      ]);

      expect(result, AssetComplianceResult.compliant);
      expect(
        AssetComplianceCalculator.safeStatus(result),
        OwnDeviceComplianceStatus.compliant,
      );
    });
  });

  group('AssetComplianceAssessment', () {
    test('round-trips all operational checks and remediation links', () {
      final source = _assessment();

      final parsed =
          AssetComplianceAssessment.fromMap(source.id, source.toMap());

      expect(parsed.result, AssetComplianceResult.nonCompliant);
      expect(parsed.checks, hasLength(2));
      expect(parsed.remediationChangeId, 'change-1');
      expect(parsed.checks.first.control, ComplianceControlType.patchStatus);
    });

    test('rejects a result inconsistent with individual checks', () {
      expect(
        () => AssetComplianceAssessment(
          id: 'assessment-1',
          assetId: 'asset-1',
          assetTag: 'ARPTC-1',
          assetName: 'Laptop',
          assessedBy: 'manager-1',
          assessedAt: DateTime.utc(2026, 8, 1),
          result: AssetComplianceResult.compliant,
          checks: [
            _check(
              ComplianceControlType.encryption,
              ComplianceCheckResult.nonCompliant,
            ),
          ],
          updatedAt: DateTime.utc(2026, 8, 1),
        ),
        throwsArgumentError,
      );
    });

    test('requires remediation tracking when the asset is non-compliant', () {
      expect(
        () => AssetComplianceAssessment(
          id: 'assessment-1',
          assetId: 'asset-1',
          assetTag: 'ARPTC-1',
          assetName: 'Laptop',
          assessedBy: 'manager-1',
          assessedAt: DateTime.utc(2026, 8, 1),
          result: AssetComplianceResult.nonCompliant,
          checks: [
            _check(
              ComplianceControlType.encryption,
              ComplianceCheckResult.nonCompliant,
            ),
          ],
          updatedAt: DateTime.utc(2026, 8, 1),
        ),
        throwsArgumentError,
      );
    });

    test('creates a projection only for the currently assigned user', () {
      final assessment = _assessment();

      final projection = assessment.toOwnDeviceProjection(
        assignedUserId: 'user-1',
        projectedAt: DateTime.utc(2026, 8, 2),
      );

      expect(projection.status, OwnDeviceComplianceStatus.actionRequired);
      expect(projection.isOwnedBy('user-1'), isTrue);
      expect(
        () => assessment.toOwnDeviceProjection(
          assignedUserId: 'user-2',
          projectedAt: DateTime.utc(2026, 8, 2),
        ),
        throwsStateError,
      );
    });
  });

  group('OwnDeviceComplianceProjection', () {
    test('serializes only safe self-service fields', () {
      final projection = _assessment().toOwnDeviceProjection(
        assignedUserId: 'user-1',
        projectedAt: DateTime.utc(2026, 8, 2),
      );
      final map = projection.toMap();

      expect(
        map.keys,
        unorderedEquals([
          'assetId',
          'assetTag',
          'assetName',
          'assignedUserId',
          'status',
          'assessedAt',
          'updatedAt',
        ]),
      );
      expect(map, isNot(contains('checks')));
      expect(map, isNot(contains('evidence')));
      expect(map, isNot(contains('remediationSummary')));
      expect(map['status'], 'action_required');
    });

    test('cannot deserialize an unsupported detailed compliance value', () {
      final projection = OwnDeviceComplianceProjection.fromMap('projection-1', {
        'assetId': 'asset-1',
        'assetTag': 'ARPTC-1',
        'assetName': 'Laptop',
        'assignedUserId': 'user-1',
        'status': 'critical_vulnerability',
        'assessedAt': DateTime.utc(2026, 8, 1),
        'updatedAt': DateTime.utc(2026, 8, 2),
      });

      expect(
        projection.status,
        OwnDeviceComplianceStatus.assessmentPending,
      );
    });
  });
}

ComplianceControlAssessment _check(
  ComplianceControlType control,
  ComplianceCheckResult result,
) =>
    ComplianceControlAssessment(
      control: control,
      result: result,
      summary: 'Manager-only detail',
      assessedAt: DateTime.utc(2026, 8, 1),
      assessedBy: 'manager-1',
      evidenceIds: const ['evidence-1'],
    );

AssetComplianceAssessment _assessment() => AssetComplianceAssessment(
      id: 'assessment-1',
      assetId: 'asset-1',
      assetTag: 'ARPTC-1',
      assetName: 'Manager Laptop',
      assignedUserId: 'user-1',
      assignedUserName: 'User One',
      assessedBy: 'manager-1',
      assessedAt: DateTime.utc(2026, 8, 1),
      result: AssetComplianceResult.nonCompliant,
      checks: [
        _check(
          ComplianceControlType.patchStatus,
          ComplianceCheckResult.nonCompliant,
        ),
        _check(
          ComplianceControlType.antivirusEdr,
          ComplianceCheckResult.compliant,
        ),
      ],
      remediationChangeId: 'change-1',
      remediationSummary: 'Apply the approved patch through CHG-1.',
      updatedAt: DateTime.utc(2026, 8, 1),
    );
