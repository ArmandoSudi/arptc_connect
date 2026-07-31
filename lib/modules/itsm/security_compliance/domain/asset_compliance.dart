import 'security_compliance_serialization.dart';
import 'security_evidence.dart';

enum ComplianceControlType {
  operatingSystemSupport,
  patchStatus,
  antivirusEdr,
  encryption,
  backup,
  approvedSoftware,
  securityBaseline;

  String get value => enumStorageValue(this);

  static ComplianceControlType fromValue(Object? value) =>
      enumFromStorageValue(values, value, ComplianceControlType.patchStatus);
}

enum ComplianceCheckResult {
  compliant,
  nonCompliant,
  notApplicable,
  unknown;

  String get value => enumStorageValue(this);

  static ComplianceCheckResult fromValue(Object? value) =>
      enumFromStorageValue(values, value, ComplianceCheckResult.unknown);
}

enum AssetComplianceResult {
  compliant,
  nonCompliant,
  assessmentPending;

  String get value => enumStorageValue(this);

  static AssetComplianceResult fromValue(Object? value) => enumFromStorageValue(
      values, value, AssetComplianceResult.assessmentPending);
}

enum OwnDeviceComplianceStatus {
  compliant,
  actionRequired,
  assessmentPending;

  String get value => enumStorageValue(this);

  static OwnDeviceComplianceStatus fromValue(Object? value) =>
      enumFromStorageValue(
        values,
        value,
        OwnDeviceComplianceStatus.assessmentPending,
      );
}

class ComplianceControlAssessment {
  ComplianceControlAssessment({
    required this.control,
    required this.result,
    required DateTime assessedAt,
    required String assessedBy,
    this.summary = '',
    Iterable<String> evidenceIds = const [],
  })  : assessedAt = assessedAt.toUtc(),
        assessedBy = requireSecurityComplianceText(
          assessedBy,
          'assessedBy',
        ),
        evidenceIds = immutableSecurityComplianceStrings(evidenceIds);

  final ComplianceControlType control;
  final ComplianceCheckResult result;
  final String summary;
  final DateTime assessedAt;
  final String assessedBy;
  final List<String> evidenceIds;

  factory ComplianceControlAssessment.fromMap(Map<String, Object?> map) =>
      ComplianceControlAssessment(
        control: ComplianceControlType.fromValue(map['control']),
        result: ComplianceCheckResult.fromValue(map['result']),
        summary: securityComplianceString(map['summary']),
        assessedAt: requireSecurityComplianceDate(
          map['assessedAt'],
          'assessedAt',
        ),
        assessedBy: securityComplianceString(map['assessedBy']),
        evidenceIds: securityComplianceStrings(map['evidenceIds']),
      );

  Map<String, Object?> toMap() => {
        'control': control.value,
        'result': result.value,
        'summary': summary,
        'assessedAt': assessedAt.toIso8601String(),
        'assessedBy': assessedBy,
        'evidenceIds': evidenceIds,
      };
}

abstract final class AssetComplianceCalculator {
  static AssetComplianceResult calculate(
    Iterable<ComplianceControlAssessment> checks,
  ) {
    final list = List<ComplianceControlAssessment>.from(checks);
    if (list.isEmpty ||
        list.any((check) => check.result == ComplianceCheckResult.unknown)) {
      return AssetComplianceResult.assessmentPending;
    }
    if (list.any(
      (check) => check.result == ComplianceCheckResult.nonCompliant,
    )) {
      return AssetComplianceResult.nonCompliant;
    }
    final applicable = list.where(
      (check) => check.result != ComplianceCheckResult.notApplicable,
    );
    return applicable.isEmpty
        ? AssetComplianceResult.assessmentPending
        : AssetComplianceResult.compliant;
  }

  static OwnDeviceComplianceStatus safeStatus(
    AssetComplianceResult result,
  ) =>
      switch (result) {
        AssetComplianceResult.compliant => OwnDeviceComplianceStatus.compliant,
        AssetComplianceResult.nonCompliant =>
          OwnDeviceComplianceStatus.actionRequired,
        AssetComplianceResult.assessmentPending =>
          OwnDeviceComplianceStatus.assessmentPending,
      };
}

class AssetComplianceAssessment {
  AssetComplianceAssessment({
    required String id,
    required String assetId,
    required String assetTag,
    required String assetName,
    required String assessedBy,
    required DateTime assessedAt,
    required this.result,
    required DateTime updatedAt,
    this.assignedUserId,
    this.assignedUserName = '',
    this.remediationRequestId,
    this.remediationChangeId,
    this.remediationSummary = '',
    DateTime? nextAssessmentAt,
    Iterable<ComplianceControlAssessment> checks = const [],
    Iterable<SecurityEvidenceMetadata> evidence = const [],
  })  : id = requireSecurityComplianceText(id, 'id'),
        assetId = requireSecurityComplianceText(assetId, 'assetId'),
        assetTag = requireSecurityComplianceText(assetTag, 'assetTag'),
        assetName = requireSecurityComplianceText(assetName, 'assetName'),
        assessedBy = requireSecurityComplianceText(
          assessedBy,
          'assessedBy',
        ),
        assessedAt = assessedAt.toUtc(),
        updatedAt = updatedAt.toUtc(),
        nextAssessmentAt = nextAssessmentAt?.toUtc(),
        checks = List<ComplianceControlAssessment>.unmodifiable(checks),
        evidence = List<SecurityEvidenceMetadata>.unmodifiable(evidence) {
    if (updatedAt.isBefore(this.assessedAt)) {
      throw ArgumentError('updatedAt cannot precede assessedAt.');
    }
    final calculated = AssetComplianceCalculator.calculate(this.checks);
    if (calculated != result) {
      throw ArgumentError(
        'Assessment result must match the individual compliance checks.',
      );
    }
    if (result == AssetComplianceResult.nonCompliant &&
        remediationRequestId == null &&
        remediationChangeId == null &&
        remediationSummary.trim().isEmpty) {
      throw ArgumentError(
        'A non-compliant assessment requires remediation tracking.',
      );
    }
  }

  final String id;
  final String assetId;
  final String assetTag;
  final String assetName;
  final String? assignedUserId;
  final String assignedUserName;
  final String assessedBy;
  final DateTime assessedAt;
  final DateTime? nextAssessmentAt;
  final AssetComplianceResult result;
  final List<ComplianceControlAssessment> checks;
  final List<SecurityEvidenceMetadata> evidence;
  final String? remediationRequestId;
  final String? remediationChangeId;
  final String remediationSummary;
  final DateTime updatedAt;

  OwnDeviceComplianceProjection toOwnDeviceProjection({
    required String assignedUserId,
    required DateTime projectedAt,
  }) {
    if (this.assignedUserId != assignedUserId.trim()) {
      throw StateError(
        'Compliance can only be projected to the currently assigned user.',
      );
    }
    return OwnDeviceComplianceProjection(
      id: '$assetId-$assignedUserId',
      assetId: assetId,
      assetTag: assetTag,
      assetName: assetName,
      assignedUserId: assignedUserId,
      status: AssetComplianceCalculator.safeStatus(result),
      assessedAt: assessedAt,
      updatedAt: projectedAt,
    );
  }

  factory AssetComplianceAssessment.fromMap(
    String id,
    Map<String, Object?> map,
  ) =>
      AssetComplianceAssessment(
        id: id,
        assetId: securityComplianceString(map['assetId']),
        assetTag: securityComplianceString(map['assetTag']),
        assetName: securityComplianceString(map['assetName']),
        assignedUserId: securityComplianceNullableString(
          map['assignedUserId'],
        ),
        assignedUserName: securityComplianceString(map['assignedUserName']),
        assessedBy: securityComplianceString(map['assessedBy']),
        assessedAt: requireSecurityComplianceDate(
          map['assessedAt'],
          'assessedAt',
        ),
        nextAssessmentAt: securityComplianceDate(map['nextAssessmentAt']),
        result: AssetComplianceResult.fromValue(map['result']),
        checks: securityComplianceModels(
          map['checks'],
          ComplianceControlAssessment.fromMap,
        ),
        evidence: securityComplianceModels(
          map['evidence'],
          SecurityEvidenceMetadata.fromMap,
        ),
        remediationRequestId: securityComplianceNullableString(
          map['remediationRequestId'],
        ),
        remediationChangeId: securityComplianceNullableString(
          map['remediationChangeId'],
        ),
        remediationSummary: securityComplianceString(
          map['remediationSummary'],
        ),
        updatedAt: requireSecurityComplianceDate(
          map['updatedAt'],
          'updatedAt',
        ),
      );

  Map<String, Object?> toMap() => {
        'assetId': assetId,
        'assetTag': assetTag,
        'assetName': assetName,
        'assignedUserId': assignedUserId,
        'assignedUserName': assignedUserName,
        'assessedBy': assessedBy,
        'assessedAt': assessedAt.toIso8601String(),
        'nextAssessmentAt': nextAssessmentAt?.toIso8601String(),
        'result': result.value,
        'checks': checks.map((check) => check.toMap()).toList(growable: false),
        'evidence':
            evidence.map((item) => item.toMap()).toList(growable: false),
        'remediationRequestId': remediationRequestId,
        'remediationChangeId': remediationChangeId,
        'remediationSummary': remediationSummary,
        'updatedAt': updatedAt.toIso8601String(),
      };
}

/// Deliberately contains no control, evidence, vulnerability or remediation
/// details. USER and ADMIN self-service reads must use this projection only.
class OwnDeviceComplianceProjection {
  OwnDeviceComplianceProjection({
    required String id,
    required String assetId,
    required String assetTag,
    required String assetName,
    required String assignedUserId,
    required this.status,
    required DateTime assessedAt,
    required DateTime updatedAt,
  })  : id = requireSecurityComplianceText(id, 'id'),
        assetId = requireSecurityComplianceText(assetId, 'assetId'),
        assetTag = requireSecurityComplianceText(assetTag, 'assetTag'),
        assetName = requireSecurityComplianceText(assetName, 'assetName'),
        assignedUserId = requireSecurityComplianceText(
          assignedUserId,
          'assignedUserId',
        ),
        assessedAt = assessedAt.toUtc(),
        updatedAt = updatedAt.toUtc();

  final String id;
  final String assetId;
  final String assetTag;
  final String assetName;
  final String assignedUserId;
  final OwnDeviceComplianceStatus status;
  final DateTime assessedAt;
  final DateTime updatedAt;

  bool isOwnedBy(String userId) => assignedUserId == userId.trim();

  factory OwnDeviceComplianceProjection.fromMap(
    String id,
    Map<String, Object?> map,
  ) =>
      OwnDeviceComplianceProjection(
        id: id,
        assetId: securityComplianceString(map['assetId']),
        assetTag: securityComplianceString(map['assetTag']),
        assetName: securityComplianceString(map['assetName']),
        assignedUserId: securityComplianceString(map['assignedUserId']),
        status: OwnDeviceComplianceStatus.fromValue(map['status']),
        assessedAt: requireSecurityComplianceDate(
          map['assessedAt'],
          'assessedAt',
        ),
        updatedAt: requireSecurityComplianceDate(
          map['updatedAt'],
          'updatedAt',
        ),
      );

  Map<String, Object?> toMap() => {
        'assetId': assetId,
        'assetTag': assetTag,
        'assetName': assetName,
        'assignedUserId': assignedUserId,
        'status': status.value,
        'assessedAt': assessedAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
