import '../../shared/domain/approval.dart';
import '../../shared/domain/itsm_common.dart';
import '../../shared/domain/itsm_work_item.dart';
import 'security_compliance_serialization.dart';
import 'security_evidence.dart';

enum SecurityExceptionStatus {
  draft,
  submitted,
  underReview,
  awaitingApproval,
  approved,
  rejected,
  active,
  expired,
  closed,
  cancelled;

  String get value => enumStorageValue(this);

  static SecurityExceptionStatus fromValue(Object? value) =>
      enumFromStorageValue(values, value, SecurityExceptionStatus.draft);
}

class CompensatingControl {
  CompensatingControl({
    required String id,
    required String description,
    this.ownerUserId,
    this.effective = false,
    this.validationNotes = '',
  })  : id = requireSecurityComplianceText(id, 'id'),
        description = requireSecurityComplianceText(
          description,
          'description',
        );

  final String id;
  final String description;
  final String? ownerUserId;
  final bool effective;
  final String validationNotes;

  factory CompensatingControl.fromMap(Map<String, Object?> map) =>
      CompensatingControl(
        id: securityComplianceString(map['id']),
        description: securityComplianceString(map['description']),
        ownerUserId: securityComplianceNullableString(map['ownerUserId']),
        effective: securityComplianceBool(map['effective']),
        validationNotes: securityComplianceString(map['validationNotes']),
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'description': description,
        'ownerUserId': ownerUserId,
        'effective': effective,
        'validationNotes': validationNotes,
      };
}

class SecurityExceptionApproval {
  SecurityExceptionApproval({
    required String id,
    required this.status,
    required DateTime requestedAt,
    Iterable<String> approverUserIds = const [],
    this.approverGroupId,
    this.decidedBy,
    DateTime? decidedAt,
    this.comment = '',
  })  : id = requireSecurityComplianceText(id, 'id'),
        requestedAt = requestedAt.toUtc(),
        approverUserIds = immutableSecurityComplianceStrings(approverUserIds),
        decidedAt = decidedAt?.toUtc() {
    if (this.approverUserIds.isEmpty &&
        (approverGroupId == null || approverGroupId!.trim().isEmpty)) {
      throw ArgumentError('An exception approval requires an approver.');
    }
    if (decidedAt != null && decidedAt.isBefore(this.requestedAt)) {
      throw ArgumentError('decidedAt cannot precede requestedAt.');
    }
  }

  final String id;
  final ApprovalStatus status;
  final List<String> approverUserIds;
  final String? approverGroupId;
  final DateTime requestedAt;
  final String? decidedBy;
  final DateTime? decidedAt;
  final String comment;

  factory SecurityExceptionApproval.fromMap(Map<String, Object?> map) =>
      SecurityExceptionApproval(
        id: securityComplianceString(map['id']),
        status: enumFromStorageValue(
          ApprovalStatus.values,
          map['status'],
          ApprovalStatus.pending,
        ),
        approverUserIds: securityComplianceStrings(map['approverUserIds']),
        approverGroupId: securityComplianceNullableString(
          map['approverGroupId'],
        ),
        requestedAt: requireSecurityComplianceDate(
          map['requestedAt'],
          'requestedAt',
        ),
        decidedBy: securityComplianceNullableString(map['decidedBy']),
        decidedAt: securityComplianceDate(map['decidedAt']),
        comment: securityComplianceString(map['comment']),
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'status': enumStorageValue(status),
        'approverUserIds': approverUserIds,
        'approverGroupId': approverGroupId,
        'requestedAt': requestedAt.toIso8601String(),
        'decidedBy': decidedBy,
        'decidedAt': decidedAt?.toIso8601String(),
        'comment': comment,
      };
}

class SecurityException {
  SecurityException({
    required String id,
    required String reference,
    required String title,
    required String requirementOrControl,
    required String businessJustification,
    required String scope,
    required String riskDescription,
    required this.requester,
    required this.status,
    required DateTime requestedStartAt,
    required DateTime requestedEndAt,
    required DateTime reviewAt,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String updatedBy,
    this.owner,
    this.confidentiality = ItsmConfidentiality.internal,
    this.affectedAssetId,
    this.affectedServiceId,
    this.affectedUserId,
    DateTime? closedAt,
    this.renewedFromExceptionId,
    this.renewalNumber = 0,
    Iterable<CompensatingControl> compensatingControls = const [],
    Iterable<SecurityExceptionApproval> approvals = const [],
    Iterable<SecurityEvidenceMetadata> evidence = const [],
  })  : id = requireSecurityComplianceText(id, 'id'),
        reference = requireSecurityComplianceText(reference, 'reference'),
        title = requireSecurityComplianceText(title, 'title'),
        requirementOrControl = requireSecurityComplianceText(
          requirementOrControl,
          'requirementOrControl',
        ),
        businessJustification = requireSecurityComplianceText(
          businessJustification,
          'businessJustification',
        ),
        scope = requireSecurityComplianceText(scope, 'scope'),
        riskDescription = requireSecurityComplianceText(
          riskDescription,
          'riskDescription',
        ),
        requestedStartAt = requestedStartAt.toUtc(),
        requestedEndAt = requestedEndAt.toUtc(),
        reviewAt = reviewAt.toUtc(),
        createdAt = createdAt.toUtc(),
        updatedAt = updatedAt.toUtc(),
        updatedBy = requireSecurityComplianceText(updatedBy, 'updatedBy'),
        closedAt = closedAt?.toUtc(),
        compensatingControls = List<CompensatingControl>.unmodifiable(
          compensatingControls,
        ),
        approvals = List<SecurityExceptionApproval>.unmodifiable(approvals),
        evidence = List<SecurityEvidenceMetadata>.unmodifiable(evidence) {
    if (!this.requestedEndAt.isAfter(this.requestedStartAt)) {
      throw ArgumentError('requestedEndAt must be after requestedStartAt.');
    }
    if (this.reviewAt.isBefore(this.requestedStartAt) ||
        this.reviewAt.isAfter(this.requestedEndAt)) {
      throw ArgumentError('reviewAt must be within the exception period.');
    }
    if (updatedAt.isBefore(createdAt)) {
      throw ArgumentError('updatedAt cannot precede createdAt.');
    }
    if (renewalNumber < 0) {
      throw RangeError.value(renewalNumber, 'renewalNumber');
    }
    if (status == SecurityExceptionStatus.closed && closedAt == null) {
      throw ArgumentError('A closed exception requires closedAt.');
    }
  }

  final String id;
  final String reference;
  final String title;
  final String requirementOrControl;
  final String businessJustification;
  final String scope;
  final String? affectedAssetId;
  final String? affectedServiceId;
  final String? affectedUserId;
  final String riskDescription;
  final List<CompensatingControl> compensatingControls;
  final SecurityActor requester;
  final SecurityActor? owner;
  final SecurityExceptionStatus status;
  final DateTime requestedStartAt;
  final DateTime requestedEndAt;
  final DateTime reviewAt;
  final List<SecurityExceptionApproval> approvals;
  final List<SecurityEvidenceMetadata> evidence;
  final ItsmConfidentiality confidentiality;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String updatedBy;
  final DateTime? closedAt;
  final String? renewedFromExceptionId;
  final int renewalNumber;

  bool isOwnedBy(String userId) => requester.userId == userId.trim();

  bool isExpiredAt(DateTime at) => !requestedEndAt.isAfter(at.toUtc());

  bool shouldNotifyExpiryAt(DateTime at, {int leadDays = 14}) {
    if (leadDays < 0) throw RangeError.value(leadDays, 'leadDays');
    if (status != SecurityExceptionStatus.approved &&
        status != SecurityExceptionStatus.active) {
      return false;
    }
    final now = at.toUtc();
    final notificationStarts =
        requestedEndAt.subtract(Duration(days: leadDays));
    return !now.isBefore(notificationStarts) && now.isBefore(requestedEndAt);
  }

  ItsmWorkItemSummary toWorkItemSummary() => ItsmWorkItemSummary(
        id: id,
        reference: reference,
        type: ItsmWorkItemType.securityException,
        title: title,
        description: businessJustification,
        requesterId: requester.userId,
        affectedUserId: affectedUserId,
        serviceId: affectedServiceId,
        status: status.value,
        lifecycleState: switch (status) {
          SecurityExceptionStatus.closed => ItsmLifecycleState.closed,
          SecurityExceptionStatus.cancelled => ItsmLifecycleState.cancelled,
          _ => ItsmLifecycleState.active,
        },
        createdAt: createdAt,
        createdBy: requester.userId,
        updatedAt: updatedAt,
        updatedBy: updatedBy,
        dueAt: requestedEndAt,
        closedAt: closedAt,
        confidentiality: confidentiality,
        linkedAssetIds: affectedAssetId == null ? const [] : [affectedAssetId!],
      );

  factory SecurityException.fromMap(String id, Map<String, Object?> map) =>
      SecurityException(
        id: id,
        reference: securityComplianceString(map['reference']),
        title: securityComplianceString(map['title']),
        requirementOrControl: securityComplianceString(
          map['requirementOrControl'],
        ),
        businessJustification: securityComplianceString(
          map['businessJustification'],
        ),
        scope: securityComplianceString(map['scope']),
        affectedAssetId: securityComplianceNullableString(
          map['affectedAssetId'],
        ),
        affectedServiceId: securityComplianceNullableString(
          map['affectedServiceId'],
        ),
        affectedUserId: securityComplianceNullableString(
          map['affectedUserId'],
        ),
        riskDescription: securityComplianceString(map['riskDescription']),
        compensatingControls: securityComplianceModels(
          map['compensatingControls'],
          CompensatingControl.fromMap,
        ),
        requester: SecurityActor.fromMap(
          securityComplianceMap(map['requester']),
        ),
        owner: securityComplianceMap(map['owner']).isEmpty
            ? null
            : SecurityActor.fromMap(securityComplianceMap(map['owner'])),
        status: SecurityExceptionStatus.fromValue(map['status']),
        requestedStartAt: requireSecurityComplianceDate(
          map['requestedStartAt'],
          'requestedStartAt',
        ),
        requestedEndAt: requireSecurityComplianceDate(
          map['requestedEndAt'],
          'requestedEndAt',
        ),
        reviewAt: requireSecurityComplianceDate(map['reviewAt'], 'reviewAt'),
        approvals: securityComplianceModels(
          map['approvals'],
          SecurityExceptionApproval.fromMap,
        ),
        evidence: securityComplianceModels(
          map['evidence'],
          SecurityEvidenceMetadata.fromMap,
        ),
        confidentiality: ItsmConfidentiality.fromValue(
          map['confidentiality'],
        ),
        createdAt: requireSecurityComplianceDate(
          map['createdAt'],
          'createdAt',
        ),
        updatedAt: requireSecurityComplianceDate(
          map['updatedAt'],
          'updatedAt',
        ),
        updatedBy: securityComplianceString(map['updatedBy']),
        closedAt: securityComplianceDate(map['closedAt']),
        renewedFromExceptionId: securityComplianceNullableString(
          map['renewedFromExceptionId'],
        ),
        renewalNumber: securityComplianceInt(map['renewalNumber']),
      );

  Map<String, Object?> toMap() => {
        'reference': reference,
        'title': title,
        'requirementOrControl': requirementOrControl,
        'businessJustification': businessJustification,
        'scope': scope,
        'affectedAssetId': affectedAssetId,
        'affectedServiceId': affectedServiceId,
        'affectedUserId': affectedUserId,
        'riskDescription': riskDescription,
        'compensatingControls': compensatingControls
            .map((item) => item.toMap())
            .toList(growable: false),
        'requester': requester.toMap(),
        'owner': owner?.toMap(),
        'status': status.value,
        'requestedStartAt': requestedStartAt.toIso8601String(),
        'requestedEndAt': requestedEndAt.toIso8601String(),
        'reviewAt': reviewAt.toIso8601String(),
        'approvals': approvals
            .map((approval) => approval.toMap())
            .toList(growable: false),
        'evidence':
            evidence.map((item) => item.toMap()).toList(growable: false),
        'confidentiality': confidentiality.value,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'updatedBy': updatedBy,
        'closedAt': closedAt?.toIso8601String(),
        'renewedFromExceptionId': renewedFromExceptionId,
        'renewalNumber': renewalNumber,
      };
}

enum SecurityExceptionApprovalIssue {
  actorMustBeManager,
  approvalNotPending,
  actorNotAssigned,
  requesterCannotBeSoleApprover,
  rejectionReasonRequired,
}

class SecurityExceptionApprovalValidation {
  SecurityExceptionApprovalValidation(
    Iterable<SecurityExceptionApprovalIssue> issues,
  ) : issues = List<SecurityExceptionApprovalIssue>.unmodifiable(issues);

  final List<SecurityExceptionApprovalIssue> issues;
  bool get isValid => issues.isEmpty;
}

abstract final class SecurityExceptionApprovalPolicy {
  static SecurityExceptionApprovalValidation validate({
    required SecurityException exception,
    required SecurityExceptionApproval approval,
    required ItsmRole actorRole,
    required String actorUserId,
    required ApprovalDecision decision,
    String reason = '',
    Set<String> actorGroupIds = const {},
  }) {
    final issues = <SecurityExceptionApprovalIssue>[];
    final actor = actorUserId.trim();
    if (actorRole != ItsmRole.manager) {
      issues.add(SecurityExceptionApprovalIssue.actorMustBeManager);
    }
    if (approval.status != ApprovalStatus.pending) {
      issues.add(SecurityExceptionApprovalIssue.approvalNotPending);
    }
    final assigned = approval.approverUserIds.contains(actor) ||
        (approval.approverGroupId != null &&
            actorGroupIds.contains(approval.approverGroupId));
    if (!assigned) {
      issues.add(SecurityExceptionApprovalIssue.actorNotAssigned);
    }
    final nonRequesterApprovers = approval.approverUserIds
        .where((id) => id != exception.requester.userId)
        .toSet();
    if (actor == exception.requester.userId && nonRequesterApprovers.isEmpty) {
      issues.add(
        SecurityExceptionApprovalIssue.requesterCannotBeSoleApprover,
      );
    }
    if (decision == ApprovalDecision.reject && reason.trim().isEmpty) {
      issues.add(SecurityExceptionApprovalIssue.rejectionReasonRequired);
    }
    return SecurityExceptionApprovalValidation(issues);
  }
}

enum SecurityExceptionRenewalIssue {
  statusNotRenewable,
  endDateMustExtendException,
  reviewDateOutsideRenewal,
  justificationRequired,
  newApprovalRequired,
}

class SecurityExceptionRenewalRequest {
  SecurityExceptionRenewalRequest({
    required String id,
    required String exceptionId,
    required DateTime requestedEndAt,
    required DateTime reviewAt,
    required String justification,
    required String requestedBy,
    required DateTime requestedAt,
    Iterable<String> approvalIds = const [],
  })  : id = requireSecurityComplianceText(id, 'id'),
        exceptionId = requireSecurityComplianceText(
          exceptionId,
          'exceptionId',
        ),
        requestedEndAt = requestedEndAt.toUtc(),
        reviewAt = reviewAt.toUtc(),
        justification = justification.trim(),
        requestedBy = requireSecurityComplianceText(
          requestedBy,
          'requestedBy',
        ),
        requestedAt = requestedAt.toUtc(),
        approvalIds = immutableSecurityComplianceStrings(approvalIds);

  final String id;
  final String exceptionId;
  final DateTime requestedEndAt;
  final DateTime reviewAt;
  final String justification;
  final String requestedBy;
  final DateTime requestedAt;
  final List<String> approvalIds;

  factory SecurityExceptionRenewalRequest.fromMap(
    Map<String, Object?> map,
  ) =>
      SecurityExceptionRenewalRequest(
        id: securityComplianceString(map['id']),
        exceptionId: securityComplianceString(map['exceptionId']),
        requestedEndAt: requireSecurityComplianceDate(
          map['requestedEndAt'],
          'requestedEndAt',
        ),
        reviewAt: requireSecurityComplianceDate(map['reviewAt'], 'reviewAt'),
        justification: securityComplianceString(map['justification']),
        requestedBy: securityComplianceString(map['requestedBy']),
        requestedAt: requireSecurityComplianceDate(
          map['requestedAt'],
          'requestedAt',
        ),
        approvalIds: securityComplianceStrings(map['approvalIds']),
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'exceptionId': exceptionId,
        'requestedEndAt': requestedEndAt.toIso8601String(),
        'reviewAt': reviewAt.toIso8601String(),
        'justification': justification,
        'requestedBy': requestedBy,
        'requestedAt': requestedAt.toIso8601String(),
        'approvalIds': approvalIds,
      };
}

class SecurityExceptionRenewalValidation {
  SecurityExceptionRenewalValidation(
    Iterable<SecurityExceptionRenewalIssue> issues,
  ) : issues = List<SecurityExceptionRenewalIssue>.unmodifiable(issues);

  final List<SecurityExceptionRenewalIssue> issues;
  bool get isValid => issues.isEmpty;
}

abstract final class SecurityExceptionRenewalPolicy {
  static SecurityExceptionRenewalValidation validate({
    required SecurityException exception,
    required SecurityExceptionRenewalRequest renewal,
  }) {
    final issues = <SecurityExceptionRenewalIssue>[];
    if (!const {
      SecurityExceptionStatus.approved,
      SecurityExceptionStatus.active,
      SecurityExceptionStatus.expired,
    }.contains(exception.status)) {
      issues.add(SecurityExceptionRenewalIssue.statusNotRenewable);
    }
    if (!renewal.requestedEndAt.isAfter(exception.requestedEndAt)) {
      issues.add(SecurityExceptionRenewalIssue.endDateMustExtendException);
    }
    if (renewal.reviewAt.isBefore(exception.requestedEndAt) ||
        renewal.reviewAt.isAfter(renewal.requestedEndAt)) {
      issues.add(SecurityExceptionRenewalIssue.reviewDateOutsideRenewal);
    }
    if (renewal.justification.isEmpty) {
      issues.add(SecurityExceptionRenewalIssue.justificationRequired);
    }
    if (renewal.approvalIds.isEmpty) {
      issues.add(SecurityExceptionRenewalIssue.newApprovalRequired);
    }
    return SecurityExceptionRenewalValidation(issues);
  }
}

abstract final class SecurityExceptionTransitionPolicy {
  static const _transitions =
      <SecurityExceptionStatus, Set<SecurityExceptionStatus>>{
    SecurityExceptionStatus.draft: {
      SecurityExceptionStatus.submitted,
      SecurityExceptionStatus.cancelled,
    },
    SecurityExceptionStatus.submitted: {
      SecurityExceptionStatus.underReview,
      SecurityExceptionStatus.cancelled,
    },
    SecurityExceptionStatus.underReview: {
      SecurityExceptionStatus.awaitingApproval,
      SecurityExceptionStatus.rejected,
    },
    SecurityExceptionStatus.awaitingApproval: {
      SecurityExceptionStatus.approved,
      SecurityExceptionStatus.rejected,
    },
    SecurityExceptionStatus.approved: {
      SecurityExceptionStatus.active,
      SecurityExceptionStatus.closed,
    },
    SecurityExceptionStatus.active: {
      SecurityExceptionStatus.expired,
      SecurityExceptionStatus.closed,
    },
    SecurityExceptionStatus.expired: {
      SecurityExceptionStatus.active,
      SecurityExceptionStatus.closed,
    },
    SecurityExceptionStatus.rejected: {},
    SecurityExceptionStatus.closed: {},
    SecurityExceptionStatus.cancelled: {},
  };

  static bool canTransition(
    SecurityExceptionStatus current,
    SecurityExceptionStatus next,
  ) =>
      (_transitions[current] ?? const {}).contains(next);
}
