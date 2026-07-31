import 'dart:collection';

import '../../shared/domain/itsm_common.dart';
import 'change_serialization.dart';

enum ChangeType {
  standard('standard'),
  normal('normal'),
  emergency('emergency');

  const ChangeType(this.value);

  final String value;

  static ChangeType fromValue(Object? value) {
    final normalized = changeString(value).toLowerCase().replaceAll('-', '_');
    return values.firstWhere(
      (type) => type.value == normalized,
      orElse: () => ChangeType.normal,
    );
  }
}

enum ChangeStatus {
  draft('draft'),
  submitted('submitted'),
  assessment('assessment'),
  awaitingApproval('awaiting_approval'),
  approved('approved'),
  scheduled('scheduled'),
  implementation('implementation'),
  review('review'),
  closed('closed'),
  rejected('rejected'),
  cancelled('cancelled'),
  failed('failed'),
  rolledBack('rolled_back');

  const ChangeStatus(this.value);

  final String value;

  static ChangeStatus fromValue(Object? value) {
    final normalized = changeString(value).toLowerCase().replaceAll('-', '_');
    return values.firstWhere(
      (status) => status.value == normalized,
      orElse: () => ChangeStatus.draft,
    );
  }

  bool get isTerminal => switch (this) {
        ChangeStatus.closed ||
        ChangeStatus.rejected ||
        ChangeStatus.cancelled =>
          true,
        _ => false,
      };
}

enum ChangeRiskLevel {
  low('low', 1),
  medium('medium', 2),
  high('high', 3),
  critical('critical', 4);

  const ChangeRiskLevel(this.value, this.sortOrder);

  final String value;
  final int sortOrder;

  static ChangeRiskLevel fromValue(Object? value) {
    final normalized = changeString(value).toLowerCase();
    return values.firstWhere(
      (level) => level.value == normalized,
      orElse: () => ChangeRiskLevel.medium,
    );
  }
}

class ChangeActor {
  ChangeActor({
    required String userId,
    required String name,
    required String email,
  })  : userId = requireChangeText(userId, 'userId'),
        name = requireChangeText(name, 'name'),
        email = requireChangeText(email, 'email').toLowerCase();

  factory ChangeActor.fromMap(Map<String, Object?> map) => ChangeActor(
        userId: changeString(map['userId'] ?? map['id']),
        name: changeString(map['name']),
        email: changeString(map['email']),
      );

  final String userId;
  final String name;
  final String email;

  Map<String, Object?> toFirestore() => {
        'userId': userId,
        'name': name,
        'email': email,
      };
}

class ChangeAffectedReference {
  ChangeAffectedReference({
    required String id,
    required String name,
  })  : id = requireChangeText(id, 'id'),
        name = requireChangeText(name, 'name');

  factory ChangeAffectedReference.fromMap(Map<String, Object?> map) =>
      ChangeAffectedReference(
        id: changeString(map['id']),
        name: changeString(map['name']),
      );

  final String id;
  final String name;

  Map<String, Object?> toFirestore() => {'id': id, 'name': name};
}

class ChangeWindow {
  ChangeWindow({
    required DateTime startsAt,
    required DateTime endsAt,
    this.expectedDowntimeMinutes = 0,
  })  : startsAt = startsAt.toUtc(),
        endsAt = endsAt.toUtc() {
    if (!this.endsAt.isAfter(this.startsAt)) {
      throw ArgumentError('The planned end must be after the planned start.');
    }
    if (expectedDowntimeMinutes < 0) {
      throw RangeError.value(
        expectedDowntimeMinutes,
        'expectedDowntimeMinutes',
      );
    }
    if (expectedDowntimeMinutes > duration.inMinutes) {
      throw ArgumentError('Expected downtime cannot exceed the change window.');
    }
  }

  factory ChangeWindow.fromMap(Map<String, Object?> map) => ChangeWindow(
        startsAt: requireChangeDate(map['startsAt'], 'startsAt'),
        endsAt: requireChangeDate(map['endsAt'], 'endsAt'),
        expectedDowntimeMinutes: changeInt(map['expectedDowntimeMinutes']),
      );

  final DateTime startsAt;
  final DateTime endsAt;
  final int expectedDowntimeMinutes;

  Duration get duration => endsAt.difference(startsAt);

  bool overlaps(ChangeWindow other) {
    return startsAt.isBefore(other.endsAt) && endsAt.isAfter(other.startsAt);
  }

  Map<String, Object?> toFirestore() => {
        'startsAt': startsAt,
        'endsAt': endsAt,
        'expectedDowntimeMinutes': expectedDowntimeMinutes,
      };
}

class MaintenancePublication {
  MaintenancePublication({
    required this.isPublished,
    this.title = '',
    this.message = '',
    this.publishedAt,
    this.publishedBy,
  }) {
    if (isPublished) {
      requireChangeText(title, 'title');
      requireChangeText(message, 'message');
      if (publishedAt == null || changeString(publishedBy).isEmpty) {
        throw ArgumentError(
          'Published maintenance requires publication actor and date.',
        );
      }
    }
  }

  factory MaintenancePublication.fromMap(Map<String, Object?> map) =>
      MaintenancePublication(
        isPublished: changeBool(map['isPublished']),
        title: changeString(map['title']),
        message: changeString(map['message']),
        publishedAt: changeDateFromValue(map['publishedAt']),
        publishedBy: changeNullableString(map['publishedBy']),
      );

  final bool isPublished;
  final String title;
  final String message;
  final DateTime? publishedAt;
  final String? publishedBy;

  Map<String, Object?> toFirestore() => {
        'isPublished': isPublished,
        'title': title.trim(),
        'message': message.trim(),
        if (publishedAt != null) 'publishedAt': publishedAt!.toUtc(),
        if (publishedBy != null) 'publishedBy': publishedBy!.trim(),
      };
}

class ChangePlans {
  ChangePlans({
    required this.implementationPlan,
    required this.testPlan,
    required this.communicationPlan,
    required this.rollbackPlan,
    Iterable<String> testEvidenceIds = const [],
  }) : testEvidenceIds = List<String>.unmodifiable(
          testEvidenceIds
              .map((id) => id.trim())
              .where((id) => id.isNotEmpty)
              .toSet(),
        );

  factory ChangePlans.fromMap(Map<String, Object?> map) => ChangePlans(
        implementationPlan: changeString(map['implementationPlan']),
        testPlan: changeString(map['testPlan']),
        communicationPlan: changeString(map['communicationPlan']),
        rollbackPlan: changeString(map['rollbackPlan']),
        testEvidenceIds: changeStringList(map['testEvidenceIds']),
      );

  final String implementationPlan;
  final String testPlan;
  final String communicationPlan;
  final String rollbackPlan;
  final List<String> testEvidenceIds;

  bool get isComplete =>
      implementationPlan.trim().isNotEmpty &&
      testPlan.trim().isNotEmpty &&
      communicationPlan.trim().isNotEmpty &&
      rollbackPlan.trim().isNotEmpty;

  Map<String, Object?> toFirestore() => {
        'implementationPlan': implementationPlan.trim(),
        'testPlan': testPlan.trim(),
        'communicationPlan': communicationPlan.trim(),
        'rollbackPlan': rollbackPlan.trim(),
        'testEvidenceIds': testEvidenceIds,
      };
}

enum ChangeImplementationOutcome {
  successful('successful'),
  successfulWithIssues('successful_with_issues'),
  failed('failed'),
  rolledBack('rolled_back');

  const ChangeImplementationOutcome(this.value);

  final String value;

  static ChangeImplementationOutcome fromValue(Object? value) {
    final raw = changeString(value).toLowerCase().replaceAll('-', '_');
    final normalized = raw == 'succeeded' ? 'successful' : raw;
    return values.firstWhere(
      (outcome) => outcome.value == normalized,
      orElse: () => ChangeImplementationOutcome.failed,
    );
  }
}

class ChangeImplementationResult {
  ChangeImplementationResult({
    required this.outcome,
    required this.summary,
    required this.implementedBy,
    required DateTime startedAt,
    required DateTime endedAt,
    this.rollbackReason,
    Iterable<String> evidenceIds = const [],
  })  : startedAt = startedAt.toUtc(),
        endedAt = endedAt.toUtc(),
        evidenceIds = List<String>.unmodifiable(
          evidenceIds
              .map((id) => id.trim())
              .where((id) => id.isNotEmpty)
              .toSet(),
        ) {
    requireChangeText(summary, 'summary');
    requireChangeText(implementedBy, 'implementedBy');
    if (this.endedAt.isBefore(this.startedAt)) {
      throw ArgumentError('Implementation end cannot precede its start.');
    }
    if (outcome == ChangeImplementationOutcome.rolledBack &&
        changeString(rollbackReason).isEmpty) {
      throw ArgumentError('A rolled-back change requires a reason.');
    }
  }

  factory ChangeImplementationResult.fromMap(Map<String, Object?> map) =>
      ChangeImplementationResult(
        outcome: ChangeImplementationOutcome.fromValue(map['outcome']),
        summary: changeString(map['summary']),
        implementedBy: changeString(map['implementedBy']),
        startedAt: requireChangeDate(map['startedAt'], 'startedAt'),
        endedAt: requireChangeDate(map['endedAt'], 'endedAt'),
        rollbackReason: changeNullableString(map['rollbackReason']),
        evidenceIds: changeStringList(map['evidenceIds']),
      );

  final ChangeImplementationOutcome outcome;
  final String summary;
  final String implementedBy;
  final DateTime startedAt;
  final DateTime endedAt;
  final String? rollbackReason;
  final List<String> evidenceIds;

  Map<String, Object?> toFirestore() => {
        'outcome': outcome.value,
        'summary': summary.trim(),
        'implementedBy': implementedBy.trim(),
        'startedAt': startedAt,
        'endedAt': endedAt,
        if (rollbackReason != null) 'rollbackReason': rollbackReason!.trim(),
        'evidenceIds': evidenceIds,
      };
}

enum PostImplementationReviewOutcome {
  successful('successful'),
  partiallySuccessful('partially_successful'),
  unsuccessful('unsuccessful');

  const PostImplementationReviewOutcome(this.value);

  final String value;

  static PostImplementationReviewOutcome fromValue(Object? value) {
    final raw = changeString(value).toLowerCase().replaceAll('-', '_');
    final normalized = raw == 'partial' ? 'partially_successful' : raw;
    return values.firstWhere(
      (outcome) => outcome.value == normalized,
      orElse: () => PostImplementationReviewOutcome.unsuccessful,
    );
  }
}

class PostImplementationReview {
  PostImplementationReview({
    required this.outcome,
    required this.summary,
    required this.reviewedBy,
    required DateTime reviewedAt,
    this.objectivesMet = false,
    this.unexpectedImpact = '',
    this.lessonsLearned = '',
    Iterable<String> actionItems = const [],
    Iterable<String> resultingIncidentIds = const [],
  })  : reviewedAt = reviewedAt.toUtc(),
        actionItems = List<String>.unmodifiable(
          actionItems
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty),
        ),
        resultingIncidentIds = List<String>.unmodifiable(
          resultingIncidentIds
              .map((id) => id.trim())
              .where((id) => id.isNotEmpty)
              .toSet(),
        ) {
    requireChangeText(summary, 'summary');
    requireChangeText(reviewedBy, 'reviewedBy');
  }

  factory PostImplementationReview.fromMap(Map<String, Object?> map) =>
      PostImplementationReview(
        outcome: PostImplementationReviewOutcome.fromValue(map['outcome']),
        summary: changeString(map['summary']),
        reviewedBy: changeString(
          map['reviewedBy'] ?? map['reviewedByUserId'],
          'unknown',
        ),
        reviewedAt: requireChangeDate(map['reviewedAt'], 'reviewedAt'),
        objectivesMet: changeBool(map['objectivesMet']),
        unexpectedImpact: changeString(map['unexpectedImpact']),
        lessonsLearned: changeString(map['lessonsLearned']),
        actionItems: changeStringList(
          map['actionItems'] ?? map['followUpActions'],
        ),
        resultingIncidentIds: changeStringList(map['resultingIncidentIds']),
      );

  final PostImplementationReviewOutcome outcome;
  final String summary;
  final String reviewedBy;
  final DateTime reviewedAt;
  final bool objectivesMet;
  final String unexpectedImpact;
  final String lessonsLearned;
  final List<String> actionItems;
  final List<String> resultingIncidentIds;

  Map<String, Object?> toFirestore() => {
        'outcome': outcome.value,
        'summary': summary.trim(),
        'reviewedBy': reviewedBy.trim(),
        'reviewedAt': reviewedAt,
        'objectivesMet': objectivesMet,
        'unexpectedImpact': unexpectedImpact.trim(),
        'lessonsLearned': lessonsLearned.trim(),
        'actionItems': actionItems,
        'resultingIncidentIds': resultingIncidentIds,
      };
}

class ChangeRequest {
  ChangeRequest({
    required String id,
    required String changeNumber,
    required this.type,
    required this.status,
    required String title,
    required String description,
    required String justification,
    required this.requester,
    this.owner,
    required this.impact,
    required this.urgency,
    required this.risk,
    required this.plans,
    required DateTime createdAt,
    required String createdBy,
    required DateTime updatedAt,
    required String updatedBy,
    this.revision = 0,
    this.plannedWindow,
    this.maintenancePublication,
    this.implementationResult,
    this.postImplementationReview,
    this.workflowDefinitionId,
    this.workflowVersion,
    this.workflowInstanceId,
    this.activeApprovalId,
    this.approvalGroupId,
    this.rejectionReason,
    this.cancellationReason,
    this.closedAt,
    Iterable<ChangeAffectedReference> affectedServices = const [],
    Iterable<String> affectedCiIds = const [],
    Iterable<String> affectedAssetIds = const [],
    Iterable<String> relatedIncidentIds = const [],
    Iterable<String> relatedRequestIds = const [],
  })  : id = requireChangeText(id, 'id'),
        changeNumber = requireChangeText(changeNumber, 'changeNumber'),
        title = requireChangeText(title, 'title'),
        description = requireChangeText(description, 'description'),
        justification = requireChangeText(justification, 'justification'),
        createdBy = requireChangeText(createdBy, 'createdBy'),
        updatedBy = requireChangeText(updatedBy, 'updatedBy'),
        createdAt = createdAt.toUtc(),
        updatedAt = updatedAt.toUtc(),
        affectedServices = List<ChangeAffectedReference>.unmodifiable(
          affectedServices,
        ),
        affectedCiIds = _immutableIds(affectedCiIds),
        affectedAssetIds = _immutableIds(affectedAssetIds),
        relatedIncidentIds = _immutableIds(relatedIncidentIds),
        relatedRequestIds = _immutableIds(relatedRequestIds) {
    final pinnedVersion = workflowVersion;
    if (pinnedVersion != null && pinnedVersion < 1) {
      throw RangeError.value(pinnedVersion, 'workflowVersion');
    }
    if (revision < 0) throw RangeError.value(revision, 'revision');
    if (status == ChangeStatus.rejected &&
        changeString(rejectionReason).isEmpty) {
      throw ArgumentError('Rejected changes require a rejection reason.');
    }
    if (status == ChangeStatus.cancelled &&
        changeString(cancellationReason).isEmpty) {
      throw ArgumentError('Cancelled changes require a cancellation reason.');
    }
    if (status == ChangeStatus.closed &&
        (implementationResult == null || postImplementationReview == null)) {
      throw ArgumentError(
        'Closed changes require implementation result and review.',
      );
    }
  }

  factory ChangeRequest.standard({
    required String id,
    required String changeNumber,
    required String title,
    required String description,
    required String justification,
    required ChangeActor requester,
    required ChangeActor owner,
    required ItsmImpact impact,
    required ItsmUrgency urgency,
    required ChangeRiskLevel risk,
    required ChangePlans plans,
    required DateTime createdAt,
    required String createdBy,
  }) =>
      ChangeRequest(
        id: id,
        changeNumber: changeNumber,
        type: ChangeType.standard,
        status: ChangeStatus.draft,
        title: title,
        description: description,
        justification: justification,
        requester: requester,
        owner: owner,
        impact: impact,
        urgency: urgency,
        risk: risk,
        plans: plans,
        createdAt: createdAt,
        createdBy: createdBy,
        updatedAt: createdAt,
        updatedBy: createdBy,
      );

  factory ChangeRequest.normal({
    required String id,
    required String changeNumber,
    required String title,
    required String description,
    required String justification,
    required ChangeActor requester,
    required ChangeActor owner,
    required ItsmImpact impact,
    required ItsmUrgency urgency,
    required ChangeRiskLevel risk,
    required ChangePlans plans,
    required DateTime createdAt,
    required String createdBy,
  }) =>
      ChangeRequest(
        id: id,
        changeNumber: changeNumber,
        type: ChangeType.normal,
        status: ChangeStatus.draft,
        title: title,
        description: description,
        justification: justification,
        requester: requester,
        owner: owner,
        impact: impact,
        urgency: urgency,
        risk: risk,
        plans: plans,
        createdAt: createdAt,
        createdBy: createdBy,
        updatedAt: createdAt,
        updatedBy: createdBy,
      );

  factory ChangeRequest.emergency({
    required String id,
    required String changeNumber,
    required String title,
    required String description,
    required String justification,
    required ChangeActor requester,
    required ChangeActor owner,
    required ItsmImpact impact,
    required ItsmUrgency urgency,
    required ChangeRiskLevel risk,
    required ChangePlans plans,
    required DateTime createdAt,
    required String createdBy,
  }) =>
      ChangeRequest(
        id: id,
        changeNumber: changeNumber,
        type: ChangeType.emergency,
        status: ChangeStatus.draft,
        title: title,
        description: description,
        justification: justification,
        requester: requester,
        owner: owner,
        impact: impact,
        urgency: urgency,
        risk: risk,
        plans: plans,
        createdAt: createdAt,
        createdBy: createdBy,
        updatedAt: createdAt,
        updatedBy: createdBy,
      );

  factory ChangeRequest.fromMap(String id, Map<String, Object?> map) {
    final requesterMap = changeMapFromValue(map['requester']);
    final ownerMap = changeMapFromValue(map['owner']);
    final ownerId = changeString(map['ownerUserId'] ?? map['ownerId']);
    return ChangeRequest(
      id: id,
      changeNumber: changeString(map['changeNumber'], id),
      type: ChangeType.fromValue(map['changeType'] ?? map['type']),
      status: ChangeStatus.fromValue(map['status']),
      title: changeString(map['title']),
      description: changeString(map['description']),
      justification: changeString(map['justification']),
      requester: ChangeActor.fromMap(
        requesterMap.isNotEmpty
            ? requesterMap
            : {
                'userId': map['requesterId'],
                'name': map['requesterName'],
                'email': map['requesterEmail'],
              },
      ),
      owner: ownerMap.isNotEmpty || ownerId.isNotEmpty
          ? ChangeActor.fromMap(
              ownerMap.isNotEmpty
                  ? ownerMap
                  : {
                      'userId': ownerId,
                      'name': map['ownerName'] ?? ownerId,
                      'email': map['ownerEmail'] ?? 'unknown@example.invalid',
                    },
            )
          : null,
      affectedServices: _affectedServicesFromMap(map),
      affectedCiIds: changeStringList(map['affectedCiIds']),
      affectedAssetIds: changeStringList(map['affectedAssetIds']),
      relatedIncidentIds: changeStringList(map['relatedIncidentIds']),
      relatedRequestIds: changeStringList(map['relatedRequestIds']),
      impact: _impactFromValue(map['impact']),
      urgency: _urgencyFromValue(map['urgency']),
      risk: ChangeRiskLevel.fromValue(map['risk']),
      plannedWindow: _plannedWindowFromMap(map),
      maintenancePublication: _maintenancePublicationFromMap(map),
      plans: _plansFromMap(map),
      implementationResult: _implementationResultFromMap(map),
      postImplementationReview:
          changeMapFromValue(map['postImplementationReview']).isEmpty
              ? null
              : PostImplementationReview.fromMap(
                  changeMapFromValue(map['postImplementationReview']),
                ),
      workflowDefinitionId: changeNullableString(map['workflowDefinitionId']),
      workflowVersion: map['workflowVersion'] == null
          ? null
          : changeInt(map['workflowVersion']),
      workflowInstanceId: changeNullableString(map['workflowInstanceId']),
      activeApprovalId: changeNullableString(map['activeApprovalId']),
      approvalGroupId: changeNullableString(map['approvalGroupId']),
      rejectionReason: changeNullableString(map['rejectionReason']),
      cancellationReason: changeNullableString(map['cancellationReason']),
      createdAt: changeDateFromValue(map['createdAt']) ?? _epoch,
      createdBy:
          changeString(map['createdBy'] ?? map['createdByUserId'], 'unknown'),
      updatedAt: changeDateFromValue(map['updatedAt']) ?? _epoch,
      updatedBy:
          changeString(map['updatedBy'] ?? map['updatedByUserId'], 'unknown'),
      revision: changeInt(map['revision']),
      closedAt: changeDateFromValue(map['closedAt']),
    );
  }

  final String id;
  final String changeNumber;
  final ChangeType type;
  final ChangeStatus status;
  final String title;
  final String description;
  final String justification;
  final ChangeActor requester;
  final ChangeActor? owner;
  final List<ChangeAffectedReference> affectedServices;
  final List<String> affectedCiIds;
  final List<String> affectedAssetIds;
  final List<String> relatedIncidentIds;
  final List<String> relatedRequestIds;
  final ItsmImpact impact;
  final ItsmUrgency urgency;
  final ChangeRiskLevel risk;
  final ChangeWindow? plannedWindow;
  final MaintenancePublication? maintenancePublication;
  final ChangePlans plans;
  final ChangeImplementationResult? implementationResult;
  final PostImplementationReview? postImplementationReview;
  final String? workflowDefinitionId;
  final int? workflowVersion;
  final String? workflowInstanceId;
  final String? activeApprovalId;
  final String? approvalGroupId;
  final String? rejectionReason;
  final String? cancellationReason;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;
  final int revision;
  final DateTime? closedAt;

  bool get isTerminal => status.isTerminal;

  bool get isMaintenancePublished =>
      maintenancePublication?.isPublished ?? false;

  Map<String, Object?> toFirestore() => UnmodifiableMapView({
        'changeNumber': changeNumber,
        'changeType': type.value,
        'status': status.value,
        'lifecycleState': switch (status) {
          ChangeStatus.closed || ChangeStatus.rejected => 'closed',
          ChangeStatus.cancelled => 'cancelled',
          _ => 'active',
        },
        'title': title,
        'description': description,
        'justification': justification,
        'requester': requester.toFirestore(),
        'requesterId': requester.userId,
        'requesterName': requester.name,
        'requesterEmail': requester.email,
        if (owner != null) 'owner': owner!.toFirestore(),
        if (owner != null) 'ownerUserId': owner!.userId,
        if (owner != null) 'ownerName': owner!.name,
        if (owner != null) 'ownerEmail': owner!.email,
        'affectedServices': affectedServices
            .map((service) => service.toFirestore())
            .toList(growable: false),
        'affectedServiceIds': affectedServices
            .map((service) => service.id)
            .toList(growable: false),
        'affectedCiIds': affectedCiIds,
        'affectedAssetIds': affectedAssetIds,
        'relatedIncidentIds': relatedIncidentIds,
        'relatedRequestIds': relatedRequestIds,
        'impact': impact.value,
        'urgency': urgency.value,
        'risk': risk.value,
        if (plannedWindow != null)
          'plannedWindow': plannedWindow!.toFirestore(),
        if (maintenancePublication != null)
          'maintenancePublication': maintenancePublication!.toFirestore(),
        'plans': plans.toFirestore(),
        if (implementationResult != null)
          'implementationResult': implementationResult!.toFirestore(),
        if (postImplementationReview != null)
          'postImplementationReview': postImplementationReview!.toFirestore(),
        if (workflowDefinitionId != null)
          'workflowDefinitionId': workflowDefinitionId,
        if (workflowVersion != null) 'workflowVersion': workflowVersion,
        if (workflowInstanceId != null)
          'workflowInstanceId': workflowInstanceId,
        if (activeApprovalId != null) 'activeApprovalId': activeApprovalId,
        if (approvalGroupId != null) 'approvalGroupId': approvalGroupId,
        if (rejectionReason != null) 'rejectionReason': rejectionReason,
        if (cancellationReason != null)
          'cancellationReason': cancellationReason,
        'createdAt': createdAt,
        'createdBy': createdBy,
        'updatedAt': updatedAt,
        'updatedBy': updatedBy,
        'revision': revision,
        if (closedAt != null) 'closedAt': closedAt!.toUtc(),
      });
}

ChangeWindow? _plannedWindowFromMap(Map<String, Object?> map) {
  final nested = changeMapFromValue(map['plannedWindow']);
  if (nested.isNotEmpty) return ChangeWindow.fromMap(nested);
  final startsAt = changeDateFromValue(map['plannedStartAt']);
  final endsAt = changeDateFromValue(map['plannedEndAt']);
  if (startsAt == null || endsAt == null) return null;
  return ChangeWindow(
    startsAt: startsAt,
    endsAt: endsAt,
    expectedDowntimeMinutes: changeInt(map['expectedDowntimeMinutes']),
  );
}

ChangePlans _plansFromMap(Map<String, Object?> map) {
  final nested = changeMapFromValue(map['plans']);
  return ChangePlans.fromMap(nested.isNotEmpty ? nested : map);
}

List<ChangeAffectedReference> _affectedServicesFromMap(
  Map<String, Object?> map,
) {
  final nested = changeModelList(
    map['affectedServices'],
    ChangeAffectedReference.fromMap,
  );
  if (nested.isNotEmpty) return nested;
  return changeStringList(map['affectedServiceIds'])
      .map((id) => ChangeAffectedReference(id: id, name: id))
      .toList(growable: false);
}

MaintenancePublication? _maintenancePublicationFromMap(
  Map<String, Object?> map,
) {
  final nested = changeMapFromValue(map['maintenancePublication']);
  if (nested.isNotEmpty) return MaintenancePublication.fromMap(nested);
  if (!changeBool(map['publishMaintenance'])) return null;
  final publishedAt = changeDateFromValue(
    map['maintenancePublishedAt'] ?? map['scheduledAt'] ?? map['updatedAt'],
  );
  final publishedBy = changeString(
    map['maintenancePublishedByUserId'] ??
        map['scheduledByUserId'] ??
        map['updatedByUserId'],
  );
  if (publishedAt == null || publishedBy.isEmpty) return null;
  return MaintenancePublication(
    isPublished: true,
    title: changeString(map['maintenanceTitle'] ?? map['title'], 'Maintenance'),
    message: changeString(
      map['maintenanceMessage'] ?? map['description'],
      'Scheduled maintenance',
    ),
    publishedAt: publishedAt,
    publishedBy: publishedBy,
  );
}

ChangeImplementationResult? _implementationResultFromMap(
  Map<String, Object?> map,
) {
  final nestedValue = map['implementationResult'];
  final nested = changeMapFromValue(nestedValue);
  if (nested.isNotEmpty) return ChangeImplementationResult.fromMap(nested);
  final outcome = changeString(map['implementationOutcome']);
  if (outcome.isEmpty || nestedValue is! String || nestedValue.trim().isEmpty) {
    return null;
  }
  final startedAt = changeDateFromValue(map['implementationStartedAt']);
  final endedAt = changeDateFromValue(map['implementationCompletedAt']);
  if (startedAt == null || endedAt == null) return null;
  final implementedBy = changeString(
    map['implementationCompletedByUserId'] ??
        map['implementationStartedByUserId'],
  );
  if (implementedBy.isEmpty) return null;
  return ChangeImplementationResult(
    outcome: ChangeImplementationOutcome.fromValue(outcome),
    summary: nestedValue,
    implementedBy: implementedBy,
    startedAt: startedAt,
    endedAt: endedAt,
    rollbackReason: outcome == 'rolled_back'
        ? changeString(
            map['implementationRollbackReason'],
            nestedValue,
          )
        : null,
    evidenceIds: changeStringList(map['implementationEvidenceAttachmentIds']),
  );
}

ItsmImpact _impactFromValue(Object? value) {
  final normalized = changeString(value).toLowerCase();
  return ItsmImpact.values.firstWhere(
    (impact) => impact.value == normalized,
    orElse: () => ItsmImpact.medium,
  );
}

ItsmUrgency _urgencyFromValue(Object? value) {
  final normalized = changeString(value).toLowerCase();
  return ItsmUrgency.values.firstWhere(
    (urgency) => urgency.value == normalized,
    orElse: () => ItsmUrgency.medium,
  );
}

List<String> _immutableIds(Iterable<String> values) =>
    List<String>.unmodifiable(
      values
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toSet(),
    );

final DateTime _epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
