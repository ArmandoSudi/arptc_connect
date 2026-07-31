import '../../shared/domain/itsm_common.dart';
import '../../shared/domain/itsm_work_item.dart';
import 'security_compliance_serialization.dart';
import 'security_evidence.dart';

enum SecurityFindingSeverity {
  low,
  medium,
  high,
  critical;

  static SecurityFindingSeverity fromValue(Object? value) =>
      enumFromStorageValue(values, value, SecurityFindingSeverity.medium);
}

enum SecurityFindingRisk {
  low,
  medium,
  high,
  critical;

  static SecurityFindingRisk fromValue(Object? value) =>
      enumFromStorageValue(values, value, SecurityFindingRisk.medium);
}

enum SecurityFindingStatus {
  detected,
  triaged,
  assigned,
  remediation,
  validation,
  closed,
  riskAccepted,
  cancelled;

  String get value => enumStorageValue(this);

  static SecurityFindingStatus fromValue(Object? value) =>
      enumFromStorageValue(values, value, SecurityFindingStatus.detected);
}

enum FindingValidationResult {
  notAssessed,
  passed,
  failed,
  partiallyValidated;

  String get value => enumStorageValue(this);

  static FindingValidationResult fromValue(Object? value) =>
      enumFromStorageValue(values, value, FindingValidationResult.notAssessed);
}

class SecurityFinding {
  SecurityFinding({
    required String id,
    required String reference,
    required String title,
    required String description,
    required String source,
    required this.severity,
    required this.risk,
    required this.status,
    required this.confidentiality,
    required DateTime createdAt,
    required String createdBy,
    required DateTime updatedAt,
    required String updatedBy,
    this.owner,
    this.remediationPlan = '',
    this.riskAcceptanceReason = '',
    this.validationResult = FindingValidationResult.notAssessed,
    this.validationComment = '',
    DateTime? dueAt,
    DateTime? closedAt,
    this.relatedIncidentId,
    this.relatedChangeId,
    Iterable<String> affectedAssetIds = const [],
    Iterable<String> affectedCiIds = const [],
    Iterable<String> affectedServiceIds = const [],
    Iterable<SecurityEvidenceMetadata> evidence = const [],
    Iterable<RemediationLink> remediationLinks = const [],
  })  : id = requireSecurityComplianceText(id, 'id'),
        reference = requireSecurityComplianceText(reference, 'reference'),
        title = requireSecurityComplianceText(title, 'title'),
        description = requireSecurityComplianceText(
          description,
          'description',
        ),
        source = requireSecurityComplianceText(source, 'source'),
        createdAt = createdAt.toUtc(),
        createdBy = requireSecurityComplianceText(createdBy, 'createdBy'),
        updatedAt = updatedAt.toUtc(),
        updatedBy = requireSecurityComplianceText(updatedBy, 'updatedBy'),
        dueAt = dueAt?.toUtc(),
        closedAt = closedAt?.toUtc(),
        affectedAssetIds = immutableSecurityComplianceStrings(
          affectedAssetIds,
        ),
        affectedCiIds = immutableSecurityComplianceStrings(affectedCiIds),
        affectedServiceIds = immutableSecurityComplianceStrings(
          affectedServiceIds,
        ),
        evidence = List<SecurityEvidenceMetadata>.unmodifiable(evidence),
        remediationLinks = List<RemediationLink>.unmodifiable(
          remediationLinks,
        ) {
    if (updatedAt.isBefore(createdAt)) {
      throw ArgumentError('updatedAt cannot precede createdAt.');
    }
    if (closedAt != null && closedAt.isBefore(createdAt)) {
      throw ArgumentError('closedAt cannot precede createdAt.');
    }
    if (status == SecurityFindingStatus.closed && closedAt == null) {
      throw ArgumentError('A closed finding requires closedAt.');
    }
  }

  final String id;
  final String reference;
  final String title;
  final String description;
  final String source;
  final SecurityFindingSeverity severity;
  final SecurityFindingRisk risk;
  final SecurityFindingStatus status;
  final ItsmConfidentiality confidentiality;
  final List<String> affectedAssetIds;
  final List<String> affectedCiIds;
  final List<String> affectedServiceIds;
  final List<SecurityEvidenceMetadata> evidence;
  final SecurityActor? owner;
  final String remediationPlan;
  final List<RemediationLink> remediationLinks;
  final String riskAcceptanceReason;
  final DateTime? dueAt;
  final FindingValidationResult validationResult;
  final String validationComment;
  final String? relatedIncidentId;
  final String? relatedChangeId;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;
  final DateTime? closedAt;

  bool get isTerminal => const {
        SecurityFindingStatus.closed,
        SecurityFindingStatus.cancelled,
      }.contains(status);

  bool isOverdueAt(DateTime at) =>
      !isTerminal && dueAt != null && dueAt!.isBefore(at.toUtc());

  ItsmWorkItemSummary toWorkItemSummary() => ItsmWorkItemSummary(
        id: id,
        reference: reference,
        type: ItsmWorkItemType.securityFinding,
        title: title,
        description: description,
        requesterId: createdBy,
        status: status.value,
        lifecycleState: switch (status) {
          SecurityFindingStatus.closed => ItsmLifecycleState.closed,
          SecurityFindingStatus.cancelled => ItsmLifecycleState.cancelled,
          _ => ItsmLifecycleState.active,
        },
        createdAt: createdAt,
        createdBy: createdBy,
        updatedAt: updatedAt,
        updatedBy: updatedBy,
        assignedUserId: owner?.userId,
        impact: switch (severity) {
          SecurityFindingSeverity.low => ItsmImpact.low,
          SecurityFindingSeverity.medium => ItsmImpact.medium,
          SecurityFindingSeverity.high => ItsmImpact.high,
          SecurityFindingSeverity.critical => ItsmImpact.critical,
        },
        dueAt: dueAt,
        closedAt: closedAt,
        confidentiality: confidentiality,
        linkedAssetIds: affectedAssetIds,
        linkedCiIds: affectedCiIds,
      );

  factory SecurityFinding.fromMap(String id, Map<String, Object?> map) =>
      SecurityFinding(
        id: id,
        reference: securityComplianceString(map['reference']),
        title: securityComplianceString(map['title']),
        description: securityComplianceString(map['description']),
        source: securityComplianceString(map['source']),
        severity: SecurityFindingSeverity.fromValue(map['severity']),
        risk: SecurityFindingRisk.fromValue(map['risk']),
        status: SecurityFindingStatus.fromValue(map['status']),
        confidentiality: ItsmConfidentiality.fromValue(
          map['confidentiality'],
        ),
        affectedAssetIds: securityComplianceStrings(
          map['affectedAssetIds'],
        ),
        affectedCiIds: securityComplianceStrings(map['affectedCiIds']),
        affectedServiceIds: securityComplianceStrings(
          map['affectedServiceIds'],
        ),
        evidence: securityComplianceModels(
          map['evidence'],
          SecurityEvidenceMetadata.fromMap,
        ),
        owner: securityComplianceMap(map['owner']).isEmpty
            ? null
            : SecurityActor.fromMap(securityComplianceMap(map['owner'])),
        remediationPlan: securityComplianceString(map['remediationPlan']),
        remediationLinks: securityComplianceModels(
          map['remediationLinks'],
          RemediationLink.fromMap,
        ),
        riskAcceptanceReason: securityComplianceString(
          map['riskAcceptanceReason'],
        ),
        dueAt: securityComplianceDate(map['dueAt']),
        validationResult: FindingValidationResult.fromValue(
          map['validationResult'],
        ),
        validationComment: securityComplianceString(
          map['validationComment'],
        ),
        relatedIncidentId: securityComplianceNullableString(
          map['relatedIncidentId'],
        ),
        relatedChangeId: securityComplianceNullableString(
          map['relatedChangeId'],
        ),
        createdAt: requireSecurityComplianceDate(
          map['createdAt'],
          'createdAt',
        ),
        createdBy: securityComplianceString(map['createdBy']),
        updatedAt: requireSecurityComplianceDate(
          map['updatedAt'],
          'updatedAt',
        ),
        updatedBy: securityComplianceString(map['updatedBy']),
        closedAt: securityComplianceDate(map['closedAt']),
      );

  Map<String, Object?> toMap() => {
        'reference': reference,
        'title': title,
        'description': description,
        'source': source,
        'severity': severity.name,
        'risk': risk.name,
        'status': status.value,
        'confidentiality': confidentiality.value,
        'affectedAssetIds': affectedAssetIds,
        'affectedCiIds': affectedCiIds,
        'affectedServiceIds': affectedServiceIds,
        'evidence':
            evidence.map((item) => item.toMap()).toList(growable: false),
        'owner': owner?.toMap(),
        'remediationPlan': remediationPlan,
        'remediationLinks': remediationLinks
            .map((item) => item.toMap())
            .toList(growable: false),
        'riskAcceptanceReason': riskAcceptanceReason,
        'dueAt': dueAt?.toIso8601String(),
        'validationResult': validationResult.value,
        'validationComment': validationComment,
        'relatedIncidentId': relatedIncidentId,
        'relatedChangeId': relatedChangeId,
        'createdAt': createdAt.toIso8601String(),
        'createdBy': createdBy,
        'updatedAt': updatedAt.toIso8601String(),
        'updatedBy': updatedBy,
        'closedAt': closedAt?.toIso8601String(),
      };
}

enum SecurityFindingTransitionIssue {
  invalidTransition,
  ownerRequired,
  remediationPlanRequired,
  dueDateRequired,
  validationPassedRequired,
  validationCommentRequired,
  riskAcceptanceReasonRequired,
  cancellationReasonRequired,
}

class SecurityFindingTransitionValidation {
  SecurityFindingTransitionValidation(
    Iterable<SecurityFindingTransitionIssue> issues,
  ) : issues = List<SecurityFindingTransitionIssue>.unmodifiable(issues);

  final List<SecurityFindingTransitionIssue> issues;
  bool get isValid => issues.isEmpty;
}

abstract final class SecurityFindingTransitionPolicy {
  static const _transitions =
      <SecurityFindingStatus, Set<SecurityFindingStatus>>{
    SecurityFindingStatus.detected: {
      SecurityFindingStatus.triaged,
      SecurityFindingStatus.cancelled,
    },
    SecurityFindingStatus.triaged: {
      SecurityFindingStatus.assigned,
      SecurityFindingStatus.riskAccepted,
      SecurityFindingStatus.cancelled,
    },
    SecurityFindingStatus.assigned: {
      SecurityFindingStatus.remediation,
      SecurityFindingStatus.riskAccepted,
      SecurityFindingStatus.cancelled,
    },
    SecurityFindingStatus.remediation: {
      SecurityFindingStatus.validation,
      SecurityFindingStatus.riskAccepted,
      SecurityFindingStatus.cancelled,
    },
    SecurityFindingStatus.validation: {
      SecurityFindingStatus.remediation,
      SecurityFindingStatus.closed,
    },
    SecurityFindingStatus.riskAccepted: {SecurityFindingStatus.closed},
    SecurityFindingStatus.closed: {},
    SecurityFindingStatus.cancelled: {},
  };

  static Set<SecurityFindingStatus> validNextStatuses(
    SecurityFindingStatus current,
  ) =>
      Set<SecurityFindingStatus>.unmodifiable(
          _transitions[current] ?? const {});

  static SecurityFindingTransitionValidation validate({
    required SecurityFinding finding,
    required SecurityFindingStatus next,
    String reason = '',
  }) {
    final issues = <SecurityFindingTransitionIssue>[];
    if (!(_transitions[finding.status] ?? const {}).contains(next)) {
      issues.add(SecurityFindingTransitionIssue.invalidTransition);
    }
    if ({
          SecurityFindingStatus.assigned,
          SecurityFindingStatus.remediation,
          SecurityFindingStatus.validation,
        }.contains(next) &&
        finding.owner == null) {
      issues.add(SecurityFindingTransitionIssue.ownerRequired);
    }
    if (next == SecurityFindingStatus.remediation) {
      if (finding.remediationPlan.trim().isEmpty) {
        issues.add(SecurityFindingTransitionIssue.remediationPlanRequired);
      }
      if (finding.dueAt == null) {
        issues.add(SecurityFindingTransitionIssue.dueDateRequired);
      }
    }
    if (next == SecurityFindingStatus.closed &&
        finding.status == SecurityFindingStatus.validation) {
      if (finding.validationResult != FindingValidationResult.passed) {
        issues.add(SecurityFindingTransitionIssue.validationPassedRequired);
      }
      if (finding.validationComment.trim().isEmpty) {
        issues.add(SecurityFindingTransitionIssue.validationCommentRequired);
      }
    }
    if (next == SecurityFindingStatus.riskAccepted &&
        finding.riskAcceptanceReason.trim().isEmpty) {
      issues.add(SecurityFindingTransitionIssue.riskAcceptanceReasonRequired);
    }
    if (next == SecurityFindingStatus.cancelled && reason.trim().isEmpty) {
      issues.add(SecurityFindingTransitionIssue.cancellationReasonRequired);
    }
    return SecurityFindingTransitionValidation(issues);
  }
}
