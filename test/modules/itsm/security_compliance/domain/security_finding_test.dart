import 'package:arptc_connect/modules/itsm/security_compliance/domain/security_compliance_domain.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_common.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SecurityFinding', () {
    test('round-trips operational and shared work-item fields', () {
      final source = _finding(
        evidence: [_evidence()],
        remediationLinks: [
          RemediationLink(
            id: 'change-1',
            type: RemediationLinkType.changeRequest,
            reference: 'CHG-1',
            status: 'scheduled',
          ),
        ],
      );

      final parsed = SecurityFinding.fromMap(source.id, source.toMap());
      final summary = parsed.toWorkItemSummary();

      expect(parsed.reference, 'FND-1');
      expect(parsed.evidence.single.storagePath, 'security/finding-1/evidence');
      expect(parsed.remediationLinks.single.type,
          RemediationLinkType.changeRequest);
      expect(summary.type.value, 'security_finding');
      expect(summary.confidentiality, ItsmConfidentiality.restricted);
      expect(summary.linkedAssetIds, ['asset-1']);
    });

    test('keeps persisted collections immutable', () {
      final finding = _finding(evidence: [_evidence()]);

      expect(
        () => finding.affectedAssetIds.add('asset-2'),
        throwsUnsupportedError,
      );
      expect(() => finding.evidence.clear(), throwsUnsupportedError);
    });

    test('calculates overdue state only for non-terminal findings', () {
      final finding = _finding();

      expect(finding.isOverdueAt(DateTime.utc(2026, 8, 11)), isTrue);
      expect(finding.isOverdueAt(DateTime.utc(2026, 8, 9)), isFalse);
    });
  });

  group('SecurityFindingTransitionPolicy', () {
    test('exposes the governed lifecycle and terminal states', () {
      expect(
        SecurityFindingTransitionPolicy.validNextStatuses(
          SecurityFindingStatus.detected,
        ),
        containsAll([
          SecurityFindingStatus.triaged,
          SecurityFindingStatus.cancelled,
        ]),
      );
      expect(
        SecurityFindingTransitionPolicy.validNextStatuses(
          SecurityFindingStatus.closed,
        ),
        isEmpty,
      );
    });

    test('requires owner, remediation plan and due date', () {
      final validation = SecurityFindingTransitionPolicy.validate(
        finding: _finding(
          status: SecurityFindingStatus.assigned,
          owner: false,
          remediationPlan: '',
          hasDueDate: false,
        ),
        next: SecurityFindingStatus.remediation,
      );

      expect(
        validation.issues,
        containsAll([
          SecurityFindingTransitionIssue.ownerRequired,
          SecurityFindingTransitionIssue.remediationPlanRequired,
          SecurityFindingTransitionIssue.dueDateRequired,
        ]),
      );
    });

    test('requires successful validation and a validation comment to close',
        () {
      final validation = SecurityFindingTransitionPolicy.validate(
        finding: _finding(
          status: SecurityFindingStatus.validation,
          validationResult: FindingValidationResult.failed,
          validationComment: '',
        ),
        next: SecurityFindingStatus.closed,
      );

      expect(
        validation.issues,
        containsAll([
          SecurityFindingTransitionIssue.validationPassedRequired,
          SecurityFindingTransitionIssue.validationCommentRequired,
        ]),
      );
    });

    test('requires reasons for risk acceptance and cancellation', () {
      final acceptance = SecurityFindingTransitionPolicy.validate(
        finding: _finding(
          status: SecurityFindingStatus.triaged,
          riskAcceptanceReason: '',
        ),
        next: SecurityFindingStatus.riskAccepted,
      );
      final cancellation = SecurityFindingTransitionPolicy.validate(
        finding: _finding(),
        next: SecurityFindingStatus.cancelled,
      );

      expect(
        acceptance.issues,
        contains(SecurityFindingTransitionIssue.riskAcceptanceReasonRequired),
      );
      expect(
        cancellation.issues,
        contains(SecurityFindingTransitionIssue.cancellationReasonRequired),
      );
    });
  });

  group('SecurityEvidenceMetadata', () {
    test('requires explicit authorization for restricted evidence', () {
      expect(
        () => SecurityEvidenceMetadata(
          id: 'evidence-1',
          fileName: 'finding.pdf',
          contentType: 'application/pdf',
          storagePath: 'restricted/finding.pdf',
          confidentiality: ItsmConfidentiality.restricted,
          createdBy: 'manager-1',
          createdAt: DateTime.utc(2026, 8, 1),
        ),
        throwsArgumentError,
      );
    });

    test('round-trips restricted authorization as an immutable set-like list',
        () {
      final evidence = SecurityEvidenceMetadata.fromMap(_evidence().toMap());

      expect(evidence.authorizedManagerIds, ['manager-1']);
      expect(
        () => evidence.authorizedManagerIds.add('manager-2'),
        throwsUnsupportedError,
      );
    });
  });
}

SecurityFinding _finding({
  SecurityFindingStatus status = SecurityFindingStatus.detected,
  bool owner = true,
  String remediationPlan = 'Patch and validate the affected host.',
  bool hasDueDate = true,
  FindingValidationResult validationResult =
      FindingValidationResult.notAssessed,
  String validationComment = '',
  String riskAcceptanceReason = 'Approved temporary acceptance.',
  Iterable<SecurityEvidenceMetadata> evidence = const [],
  Iterable<RemediationLink> remediationLinks = const [],
}) {
  return SecurityFinding(
    id: 'finding-1',
    reference: 'FND-1',
    title: 'Unsupported operating system',
    description: 'A production workstation is outside vendor support.',
    source: 'asset_compliance',
    severity: SecurityFindingSeverity.high,
    risk: SecurityFindingRisk.high,
    status: status,
    confidentiality: ItsmConfidentiality.restricted,
    affectedAssetIds: const ['asset-1'],
    affectedCiIds: const ['ci-1'],
    affectedServiceIds: const ['service-1'],
    evidence: evidence,
    owner: owner
        ? SecurityActor(userId: 'manager-1', displayName: 'Manager One')
        : null,
    remediationPlan: remediationPlan,
    remediationLinks: remediationLinks,
    riskAcceptanceReason: riskAcceptanceReason,
    dueAt: hasDueDate ? DateTime.utc(2026, 8, 10) : null,
    validationResult: validationResult,
    validationComment: validationComment,
    createdAt: DateTime.utc(2026, 8, 1),
    createdBy: 'manager-1',
    updatedAt: DateTime.utc(2026, 8, 2),
    updatedBy: 'manager-1',
  );
}

SecurityEvidenceMetadata _evidence() => SecurityEvidenceMetadata(
      id: 'evidence-1',
      fileName: 'finding.pdf',
      contentType: 'application/pdf',
      storagePath: 'security/finding-1/evidence',
      confidentiality: ItsmConfidentiality.restricted,
      createdBy: 'manager-1',
      createdAt: DateTime.utc(2026, 8, 1),
      authorizedManagerIds: const ['manager-1'],
    );
