import '../../shared/domain/itsm_common.dart';
import 'security_compliance_serialization.dart';
import 'security_evidence.dart';

enum AccessReviewCampaignStatus {
  draft,
  active,
  completed,
  cancelled;

  String get value => enumStorageValue(this);

  static AccessReviewCampaignStatus fromValue(Object? value) =>
      enumFromStorageValue(values, value, AccessReviewCampaignStatus.draft);
}

class AccessReviewCampaign {
  AccessReviewCampaign({
    required String id,
    required String reference,
    required String title,
    required String scope,
    required String systemId,
    required String systemName,
    required this.owner,
    required this.status,
    required DateTime startsAt,
    required DateTime dueAt,
    required DateTime createdAt,
    required String createdBy,
    required DateTime updatedAt,
    this.allowSelfServiceCorrection = true,
    Iterable<String> reviewerUserIds = const [],
    Iterable<String> departmentIds = const [],
  })  : id = requireSecurityComplianceText(id, 'id'),
        reference = requireSecurityComplianceText(reference, 'reference'),
        title = requireSecurityComplianceText(title, 'title'),
        scope = requireSecurityComplianceText(scope, 'scope'),
        systemId = requireSecurityComplianceText(systemId, 'systemId'),
        systemName = requireSecurityComplianceText(systemName, 'systemName'),
        startsAt = startsAt.toUtc(),
        dueAt = dueAt.toUtc(),
        createdAt = createdAt.toUtc(),
        createdBy = requireSecurityComplianceText(createdBy, 'createdBy'),
        updatedAt = updatedAt.toUtc(),
        reviewerUserIds = immutableSecurityComplianceStrings(reviewerUserIds),
        departmentIds = immutableSecurityComplianceStrings(departmentIds) {
    if (!this.dueAt.isAfter(this.startsAt)) {
      throw ArgumentError('dueAt must be after startsAt.');
    }
    if (updatedAt.isBefore(createdAt)) {
      throw ArgumentError('updatedAt cannot precede createdAt.');
    }
    if (status == AccessReviewCampaignStatus.active &&
        this.reviewerUserIds.isEmpty) {
      throw ArgumentError('An active campaign requires a reviewer.');
    }
  }

  final String id;
  final String reference;
  final String title;
  final String scope;
  final String systemId;
  final String systemName;
  final SecurityActor owner;
  final AccessReviewCampaignStatus status;
  final DateTime startsAt;
  final DateTime dueAt;
  final bool allowSelfServiceCorrection;
  final List<String> reviewerUserIds;
  final List<String> departmentIds;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;

  bool isOverdueAt(DateTime at) =>
      status == AccessReviewCampaignStatus.active && dueAt.isBefore(at.toUtc());

  factory AccessReviewCampaign.fromMap(
    String id,
    Map<String, Object?> map,
  ) =>
      AccessReviewCampaign(
        id: id,
        reference: securityComplianceString(map['reference']),
        title: securityComplianceString(map['title']),
        scope: securityComplianceString(map['scope']),
        systemId: securityComplianceString(map['systemId']),
        systemName: securityComplianceString(map['systemName']),
        owner: SecurityActor.fromMap(securityComplianceMap(map['owner'])),
        status: AccessReviewCampaignStatus.fromValue(map['status']),
        startsAt: requireSecurityComplianceDate(map['startsAt'], 'startsAt'),
        dueAt: requireSecurityComplianceDate(map['dueAt'], 'dueAt'),
        allowSelfServiceCorrection: securityComplianceBool(
          map['allowSelfServiceCorrection'],
          true,
        ),
        reviewerUserIds: securityComplianceStrings(map['reviewerUserIds']),
        departmentIds: securityComplianceStrings(map['departmentIds']),
        createdAt: requireSecurityComplianceDate(
          map['createdAt'],
          'createdAt',
        ),
        createdBy: securityComplianceString(map['createdBy']),
        updatedAt: requireSecurityComplianceDate(
          map['updatedAt'],
          'updatedAt',
        ),
      );

  Map<String, Object?> toMap() => {
        'reference': reference,
        'title': title,
        'scope': scope,
        'systemId': systemId,
        'systemName': systemName,
        'owner': owner.toMap(),
        'status': status.value,
        'startsAt': startsAt.toIso8601String(),
        'dueAt': dueAt.toIso8601String(),
        'allowSelfServiceCorrection': allowSelfServiceCorrection,
        'reviewerUserIds': reviewerUserIds,
        'departmentIds': departmentIds,
        'createdAt': createdAt.toIso8601String(),
        'createdBy': createdBy,
        'updatedAt': updatedAt.toIso8601String(),
      };
}

enum AccessReviewDecision {
  pending,
  retain,
  revoke,
  modify;

  static AccessReviewDecision fromValue(Object? value) =>
      enumFromStorageValue(values, value, AccessReviewDecision.pending);
}

enum AccessReviewCompletionStatus {
  pending,
  decided,
  revocationPending,
  completed;

  String get value => enumStorageValue(this);

  static AccessReviewCompletionStatus fromValue(Object? value) =>
      enumFromStorageValue(
        values,
        value,
        AccessReviewCompletionStatus.pending,
      );
}

enum AccessRevocationAction {
  revoke,
  modify;

  static AccessRevocationAction fromValue(Object? value) =>
      enumFromStorageValue(values, value, AccessRevocationAction.revoke);
}

enum AccessRevocationTaskStatus {
  pending,
  inProgress,
  completed,
  failed,
  cancelled;

  String get value => enumStorageValue(this);

  static AccessRevocationTaskStatus fromValue(Object? value) =>
      enumFromStorageValue(
        values,
        value,
        AccessRevocationTaskStatus.pending,
      );
}

class AccessRevocationTask {
  AccessRevocationTask({
    required String id,
    required String accessReviewItemId,
    required this.action,
    required this.status,
    required String assignedToUserId,
    required DateTime dueAt,
    required DateTime createdAt,
    required String createdBy,
    this.targetAccess = '',
    this.completionEvidenceId,
    DateTime? completedAt,
    this.completedBy,
  })  : id = requireSecurityComplianceText(id, 'id'),
        accessReviewItemId = requireSecurityComplianceText(
          accessReviewItemId,
          'accessReviewItemId',
        ),
        assignedToUserId = requireSecurityComplianceText(
          assignedToUserId,
          'assignedToUserId',
        ),
        dueAt = dueAt.toUtc(),
        createdAt = createdAt.toUtc(),
        createdBy = requireSecurityComplianceText(createdBy, 'createdBy'),
        completedAt = completedAt?.toUtc() {
    if (this.dueAt.isBefore(this.createdAt)) {
      throw ArgumentError('Task dueAt cannot precede createdAt.');
    }
    if (action == AccessRevocationAction.modify &&
        targetAccess.trim().isEmpty) {
      throw ArgumentError('An access modification requires targetAccess.');
    }
    if (status == AccessRevocationTaskStatus.completed &&
        (completedAt == null || completedBy?.trim().isEmpty != false)) {
      throw ArgumentError(
        'A completed revocation task requires completion metadata.',
      );
    }
  }

  final String id;
  final String accessReviewItemId;
  final AccessRevocationAction action;
  final String targetAccess;
  final AccessRevocationTaskStatus status;
  final String assignedToUserId;
  final DateTime dueAt;
  final DateTime createdAt;
  final String createdBy;
  final String? completionEvidenceId;
  final DateTime? completedAt;
  final String? completedBy;

  factory AccessRevocationTask.fromMap(Map<String, Object?> map) =>
      AccessRevocationTask(
        id: securityComplianceString(map['id']),
        accessReviewItemId: securityComplianceString(
          map['accessReviewItemId'],
        ),
        action: AccessRevocationAction.fromValue(map['action']),
        targetAccess: securityComplianceString(map['targetAccess']),
        status: AccessRevocationTaskStatus.fromValue(map['status']),
        assignedToUserId: securityComplianceString(
          map['assignedToUserId'],
        ),
        dueAt: requireSecurityComplianceDate(map['dueAt'], 'dueAt'),
        createdAt: requireSecurityComplianceDate(
          map['createdAt'],
          'createdAt',
        ),
        createdBy: securityComplianceString(map['createdBy']),
        completionEvidenceId: securityComplianceNullableString(
          map['completionEvidenceId'],
        ),
        completedAt: securityComplianceDate(map['completedAt']),
        completedBy: securityComplianceNullableString(map['completedBy']),
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'accessReviewItemId': accessReviewItemId,
        'action': action.name,
        'targetAccess': targetAccess,
        'status': status.value,
        'assignedToUserId': assignedToUserId,
        'dueAt': dueAt.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'createdBy': createdBy,
        'completionEvidenceId': completionEvidenceId,
        'completedAt': completedAt?.toIso8601String(),
        'completedBy': completedBy,
      };
}

class AccessReviewItem {
  AccessReviewItem({
    required String id,
    required String campaignId,
    required String systemId,
    required String systemName,
    required this.subjectUser,
    required String currentAccess,
    required String currentRole,
    required String departmentId,
    required String departmentName,
    required this.reviewer,
    required this.decision,
    required this.completionStatus,
    required DateTime dueAt,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.justification = '',
    DateTime? decidedAt,
    this.revocationTask,
    Iterable<SecurityEvidenceMetadata> evidence = const [],
  })  : id = requireSecurityComplianceText(id, 'id'),
        campaignId = requireSecurityComplianceText(campaignId, 'campaignId'),
        systemId = requireSecurityComplianceText(systemId, 'systemId'),
        systemName = requireSecurityComplianceText(systemName, 'systemName'),
        currentAccess = requireSecurityComplianceText(
          currentAccess,
          'currentAccess',
        ),
        currentRole = requireSecurityComplianceText(
          currentRole,
          'currentRole',
        ),
        departmentId = requireSecurityComplianceText(
          departmentId,
          'departmentId',
        ),
        departmentName = requireSecurityComplianceText(
          departmentName,
          'departmentName',
        ),
        dueAt = dueAt.toUtc(),
        createdAt = createdAt.toUtc(),
        updatedAt = updatedAt.toUtc(),
        decidedAt = decidedAt?.toUtc(),
        evidence = List<SecurityEvidenceMetadata>.unmodifiable(evidence) {
    if (updatedAt.isBefore(createdAt)) {
      throw ArgumentError('updatedAt cannot precede createdAt.');
    }
    if (decision == AccessReviewDecision.pending && decidedAt != null) {
      throw ArgumentError('A pending review cannot have decidedAt.');
    }
    if (decision != AccessReviewDecision.pending && decidedAt == null) {
      throw ArgumentError('A decided review requires decidedAt.');
    }
    if ({AccessReviewDecision.revoke, AccessReviewDecision.modify}
            .contains(decision) &&
        revocationTask == null) {
      throw ArgumentError(
        'Revoked or modified access requires a revocation/change task.',
      );
    }
  }

  final String id;
  final String campaignId;
  final String systemId;
  final String systemName;
  final SecurityActor subjectUser;
  final String currentAccess;
  final String currentRole;
  final String departmentId;
  final String departmentName;
  final SecurityActor reviewer;
  final AccessReviewDecision decision;
  final String justification;
  final DateTime dueAt;
  final List<SecurityEvidenceMetadata> evidence;
  final AccessRevocationTask? revocationTask;
  final AccessReviewCompletionStatus completionStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? decidedAt;

  bool isOwnedBy(String userId) => subjectUser.userId == userId.trim();

  bool isOverdueAt(DateTime at) =>
      completionStatus != AccessReviewCompletionStatus.completed &&
      dueAt.isBefore(at.toUtc());

  factory AccessReviewItem.fromMap(String id, Map<String, Object?> map) =>
      AccessReviewItem(
        id: id,
        campaignId: securityComplianceString(map['campaignId']),
        systemId: securityComplianceString(map['systemId']),
        systemName: securityComplianceString(map['systemName']),
        subjectUser: SecurityActor.fromMap(
          securityComplianceMap(map['subjectUser']),
        ),
        currentAccess: securityComplianceString(map['currentAccess']),
        currentRole: securityComplianceString(map['currentRole']),
        departmentId: securityComplianceString(map['departmentId']),
        departmentName: securityComplianceString(map['departmentName']),
        reviewer: SecurityActor.fromMap(
          securityComplianceMap(map['reviewer']),
        ),
        decision: AccessReviewDecision.fromValue(map['decision']),
        justification: securityComplianceString(map['justification']),
        dueAt: requireSecurityComplianceDate(map['dueAt'], 'dueAt'),
        evidence: securityComplianceModels(
          map['evidence'],
          SecurityEvidenceMetadata.fromMap,
        ),
        revocationTask: securityComplianceMap(map['revocationTask']).isEmpty
            ? null
            : AccessRevocationTask.fromMap(
                securityComplianceMap(map['revocationTask']),
              ),
        completionStatus: AccessReviewCompletionStatus.fromValue(
          map['completionStatus'],
        ),
        createdAt: requireSecurityComplianceDate(
          map['createdAt'],
          'createdAt',
        ),
        updatedAt: requireSecurityComplianceDate(
          map['updatedAt'],
          'updatedAt',
        ),
        decidedAt: securityComplianceDate(map['decidedAt']),
      );

  Map<String, Object?> toMap() => {
        'campaignId': campaignId,
        'systemId': systemId,
        'systemName': systemName,
        'subjectUser': subjectUser.toMap(),
        'currentAccess': currentAccess,
        'currentRole': currentRole,
        'departmentId': departmentId,
        'departmentName': departmentName,
        'reviewer': reviewer.toMap(),
        'decision': decision.name,
        'justification': justification,
        'dueAt': dueAt.toIso8601String(),
        'evidence':
            evidence.map((item) => item.toMap()).toList(growable: false),
        'revocationTask': revocationTask?.toMap(),
        'completionStatus': completionStatus.value,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'decidedAt': decidedAt?.toIso8601String(),
      };
}

enum AccessCorrectionRequestType { correction, revocation }

enum AccessCorrectionRequestStatus {
  submitted,
  inReview,
  completed,
  rejected,
  cancelled;

  String get value => enumStorageValue(this);
}

class AccessCorrectionRequest {
  AccessCorrectionRequest({
    required String id,
    required String accessReviewItemId,
    required String requestedBy,
    required this.type,
    required String reason,
    required this.status,
    required DateTime createdAt,
  })  : id = requireSecurityComplianceText(id, 'id'),
        accessReviewItemId = requireSecurityComplianceText(
          accessReviewItemId,
          'accessReviewItemId',
        ),
        requestedBy = requireSecurityComplianceText(
          requestedBy,
          'requestedBy',
        ),
        reason = requireSecurityComplianceText(reason, 'reason'),
        createdAt = createdAt.toUtc();

  final String id;
  final String accessReviewItemId;
  final String requestedBy;
  final AccessCorrectionRequestType type;
  final String reason;
  final AccessCorrectionRequestStatus status;
  final DateTime createdAt;

  factory AccessCorrectionRequest.fromMap(Map<String, Object?> map) =>
      AccessCorrectionRequest(
        id: securityComplianceString(map['id']),
        accessReviewItemId: securityComplianceString(
          map['accessReviewItemId'],
        ),
        requestedBy: securityComplianceString(map['requestedBy']),
        type: enumFromStorageValue(
          AccessCorrectionRequestType.values,
          map['type'],
          AccessCorrectionRequestType.correction,
        ),
        reason: securityComplianceString(map['reason']),
        status: enumFromStorageValue(
          AccessCorrectionRequestStatus.values,
          map['status'],
          AccessCorrectionRequestStatus.submitted,
        ),
        createdAt: requireSecurityComplianceDate(
          map['createdAt'],
          'createdAt',
        ),
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'accessReviewItemId': accessReviewItemId,
        'requestedBy': requestedBy,
        'type': type.name,
        'reason': reason,
        'status': status.value,
        'createdAt': createdAt.toIso8601String(),
      };
}

enum AccessReviewDecisionIssue {
  actorMustBeManager,
  actorNotReviewer,
  itemAlreadyDecided,
  justificationRequired,
  revocationTaskRequired,
  taskActionMismatch,
}

class AccessReviewDecisionValidation {
  AccessReviewDecisionValidation(Iterable<AccessReviewDecisionIssue> issues)
      : issues = List<AccessReviewDecisionIssue>.unmodifiable(issues);

  final List<AccessReviewDecisionIssue> issues;
  bool get isValid => issues.isEmpty;
}

abstract final class AccessReviewDecisionPolicy {
  static AccessReviewDecisionValidation validate({
    required AccessReviewItem item,
    required ItsmRole actorRole,
    required String actorUserId,
    required AccessReviewDecision decision,
    required String justification,
    AccessRevocationTask? revocationTask,
  }) {
    final issues = <AccessReviewDecisionIssue>[];
    if (actorRole != ItsmRole.manager) {
      issues.add(AccessReviewDecisionIssue.actorMustBeManager);
    }
    if (item.reviewer.userId != actorUserId.trim()) {
      issues.add(AccessReviewDecisionIssue.actorNotReviewer);
    }
    if (item.decision != AccessReviewDecision.pending) {
      issues.add(AccessReviewDecisionIssue.itemAlreadyDecided);
    }
    if (justification.trim().isEmpty) {
      issues.add(AccessReviewDecisionIssue.justificationRequired);
    }
    final taskRequired = const {
      AccessReviewDecision.revoke,
      AccessReviewDecision.modify,
    }.contains(decision);
    if (taskRequired && revocationTask == null) {
      issues.add(AccessReviewDecisionIssue.revocationTaskRequired);
    }
    if (revocationTask != null) {
      final expected = decision == AccessReviewDecision.modify
          ? AccessRevocationAction.modify
          : AccessRevocationAction.revoke;
      if (revocationTask.action != expected) {
        issues.add(AccessReviewDecisionIssue.taskActionMismatch);
      }
    }
    return AccessReviewDecisionValidation(issues);
  }
}

abstract final class AccessReviewCampaignTransitionPolicy {
  static bool canTransition(
    AccessReviewCampaignStatus current,
    AccessReviewCampaignStatus next,
  ) =>
      switch (current) {
        AccessReviewCampaignStatus.draft => const {
            AccessReviewCampaignStatus.active,
            AccessReviewCampaignStatus.cancelled,
          }.contains(next),
        AccessReviewCampaignStatus.active => const {
            AccessReviewCampaignStatus.completed,
            AccessReviewCampaignStatus.cancelled,
          }.contains(next),
        AccessReviewCampaignStatus.completed ||
        AccessReviewCampaignStatus.cancelled =>
          false,
      };
}
