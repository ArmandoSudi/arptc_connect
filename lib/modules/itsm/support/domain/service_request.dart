import 'dart:collection';

import '../../shared/domain/itsm_common.dart';
import 'service_request_resources.dart';
import 'support_serialization.dart';

enum ServiceRequestStatus {
  draft('draft'),
  submitted('submitted'),
  awaitingApproval('awaiting_approval'),
  approved('approved'),
  assigned('assigned'),
  inFulfilment('in_fulfilment'),
  awaitingUser('awaiting_user'),
  fulfilled('fulfilled'),
  closed('closed'),
  rejected('rejected'),
  cancelled('cancelled');

  const ServiceRequestStatus(this.value);

  final String value;

  static ServiceRequestStatus fromValue(Object? value) {
    final normalized = supportString(value).toLowerCase().replaceAll('-', '_');
    return values.firstWhere(
      (status) => status.value == normalized,
      orElse: () => ServiceRequestStatus.draft,
    );
  }
}

class ServiceRequest {
  ServiceRequest({
    required this.id,
    required this.requestNumber,
    required this.catalogueItemId,
    required this.catalogueItemCode,
    required this.catalogueItemVersion,
    required this.catalogueItemName,
    required this.title,
    required this.requesterId,
    required this.requesterName,
    required this.requesterEmail,
    required this.requestedForUserId,
    required this.requestedForName,
    required this.requestedForEmail,
    required this.workflowDefinitionId,
    required this.workflowVersion,
    required this.workflowInstanceId,
    required this.workflowRevision,
    required this.fulfilmentGroupId,
    required this.slaPolicyId,
    required this.slaPolicyVersion,
    required this.status,
    required this.lifecycleState,
    required this.workflowAllowsCancellation,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    this.description = '',
    this.departmentId,
    this.departmentName,
    this.serviceId,
    this.serviceName,
    this.approvalPolicyId,
    this.assignedGroupId,
    this.assignedUserId,
    this.assignedUserName,
    this.rejectionReason,
    this.cancellationReason,
    this.submittedAt,
    this.fulfilledAt,
    this.fulfilledBy,
    this.completionConfirmedAt,
    this.completionConfirmedBy,
    this.closedAt,
    this.cancelledAt,
    this.cancelledBy,
    this.rejectedAt,
    this.rejectedBy,
    this.sla,
    this.selfServiceVisible = true,
    this.confidentiality = ItsmConfidentiality.internal,
    this.commentCount = 0,
    this.attachmentCount = 0,
    this.taskCount = 0,
    this.completedTaskCount = 0,
    this.pendingApprovalCount = 0,
    Map<String, Object?> responses = const {},
    Iterable<ServiceRequestLinkSummary> relatedRecords = const [],
  })  : responses = UnmodifiableMapView(Map<String, Object?>.from(responses)),
        relatedRecords =
            List<ServiceRequestLinkSummary>.unmodifiable(relatedRecords) {
    for (final entry in {
      'id': id,
      'requestNumber': requestNumber,
      'catalogueItemId': catalogueItemId,
      'catalogueItemCode': catalogueItemCode,
      'catalogueItemName': catalogueItemName,
      'title': title,
      'requesterId': requesterId,
      'requesterEmail': requesterEmail,
      'requestedForUserId': requestedForUserId,
      'requestedForEmail': requestedForEmail,
      'workflowDefinitionId': workflowDefinitionId,
      'workflowInstanceId': workflowInstanceId,
      'fulfilmentGroupId': fulfilmentGroupId,
      'slaPolicyId': slaPolicyId,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
    }.entries) {
      supportRequire(entry.value, entry.key);
    }
    if (workflowRevision < 0) {
      throw RangeError.value(workflowRevision, 'workflowRevision');
    }
    for (final version in {
      'catalogueItemVersion': catalogueItemVersion,
      'workflowVersion': workflowVersion,
      'slaPolicyVersion': slaPolicyVersion,
    }.entries) {
      if (version.value < 1) {
        throw RangeError.value(version.value, version.key);
      }
    }
    if (status == ServiceRequestStatus.rejected &&
        (rejectionReason?.trim().isEmpty ?? true)) {
      throw ArgumentError('Rejected requests require a rejection reason.');
    }
    if (status == ServiceRequestStatus.cancelled &&
        (cancellationReason?.trim().isEmpty ?? true)) {
      throw ArgumentError('Cancelled requests require a cancellation reason.');
    }
    if (commentCount < 0 ||
        attachmentCount < 0 ||
        taskCount < 0 ||
        completedTaskCount < 0 ||
        pendingApprovalCount < 0 ||
        completedTaskCount > taskCount) {
      throw ArgumentError('Request counters are inconsistent.');
    }
  }

  factory ServiceRequest.fromMap(String id, Map<String, Object?> map) {
    final status = ServiceRequestStatus.fromValue(map['status']);
    return ServiceRequest(
      id: id,
      requestNumber: supportString(map['requestNumber'], id),
      catalogueItemId: supportString(map['catalogueItemId']),
      catalogueItemCode: supportString(map['catalogueItemCode']),
      catalogueItemVersion: supportInt(map['catalogueItemVersion'], 1),
      catalogueItemName: supportString(map['catalogueItemName']),
      title: supportString(map['title']),
      description: supportString(map['description']),
      requesterId: supportString(map['requesterId']),
      requesterName: supportString(map['requesterName']),
      requesterEmail: supportString(map['requesterEmail']),
      requestedForUserId: supportString(
        map['requestedForUserId'] ?? map['affectedUserId'],
      ),
      requestedForName: supportString(
        map['requestedForName'] ?? map['affectedUserName'],
      ),
      requestedForEmail: supportString(
        map['requestedForEmail'] ?? map['affectedUserEmail'],
      ),
      departmentId: supportNullableString(map['departmentId']),
      departmentName: supportNullableString(map['departmentName']),
      serviceId: supportNullableString(map['serviceId']),
      serviceName: supportNullableString(map['serviceName']),
      responses: supportMapFromValue(map['responses']),
      workflowDefinitionId: supportString(map['workflowDefinitionId']),
      workflowVersion: supportInt(map['workflowVersion'], 1),
      workflowInstanceId: supportString(map['workflowInstanceId']),
      workflowRevision: supportInt(map['workflowRevision']),
      approvalPolicyId: supportNullableString(map['approvalPolicyId']),
      fulfilmentGroupId: supportString(map['fulfilmentGroupId']),
      assignedGroupId: supportNullableString(map['assignedGroupId']),
      assignedUserId: supportNullableString(map['assignedUserId']),
      assignedUserName: supportNullableString(map['assignedUserName']),
      slaPolicyId: supportString(map['slaPolicyId']),
      slaPolicyVersion: supportInt(map['slaPolicyVersion'], 1),
      sla: supportMapFromValue(map['slaSummary']).isEmpty
          ? null
          : ServiceRequestSlaSummary.fromMap(
              supportMapFromValue(map['slaSummary']),
            ),
      status: status,
      lifecycleState: _lifecycleState(map['lifecycleState'], status),
      workflowAllowsCancellation:
          supportBool(map['workflowAllowsCancellation'], true),
      rejectionReason: supportNullableString(map['rejectionReason']),
      cancellationReason: supportNullableString(map['cancellationReason']),
      submittedAt: supportDateFromValue(map['submittedAt']),
      fulfilledAt: supportDateFromValue(map['fulfilledAt']),
      fulfilledBy: supportNullableString(map['fulfilledBy']),
      completionConfirmedAt: supportDateFromValue(map['completionConfirmedAt']),
      completionConfirmedBy:
          supportNullableString(map['completionConfirmedBy']),
      closedAt: supportDateFromValue(map['closedAt']),
      cancelledAt: supportDateFromValue(map['cancelledAt']),
      cancelledBy: supportNullableString(map['cancelledBy']),
      rejectedAt: supportDateFromValue(map['rejectedAt']),
      rejectedBy: supportNullableString(map['rejectedBy']),
      selfServiceVisible: supportBool(map['selfServiceVisible'], true),
      confidentiality: ItsmConfidentiality.fromValue(map['confidentiality']),
      commentCount: supportInt(map['commentCount']),
      attachmentCount: supportInt(map['attachmentCount']),
      taskCount: supportInt(map['taskCount']),
      completedTaskCount: supportInt(map['completedTaskCount']),
      pendingApprovalCount: supportInt(map['pendingApprovalCount']),
      relatedRecords: supportListFromValue(map['relatedRecords'])
          .map(supportMapFromValue)
          .where((record) => record.isNotEmpty)
          .map(ServiceRequestLinkSummary.fromMap),
      createdAt: supportDateFromValue(map['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      createdBy: supportString(map['createdBy'], 'unknown'),
      updatedAt: supportDateFromValue(map['updatedAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      updatedBy: supportString(map['updatedBy'], 'unknown'),
    );
  }

  final String id;
  final String requestNumber;
  final String catalogueItemId;
  final String catalogueItemCode;
  final int catalogueItemVersion;
  final String catalogueItemName;
  final String title;
  final String description;
  final String requesterId;
  final String requesterName;
  final String requesterEmail;
  final String requestedForUserId;
  final String requestedForName;
  final String requestedForEmail;
  final String? departmentId;
  final String? departmentName;
  final String? serviceId;
  final String? serviceName;
  final Map<String, Object?> responses;
  final String workflowDefinitionId;
  final int workflowVersion;
  final String workflowInstanceId;
  final int workflowRevision;
  final String? approvalPolicyId;
  final String fulfilmentGroupId;
  final String? assignedGroupId;
  final String? assignedUserId;
  final String? assignedUserName;
  final String slaPolicyId;
  final int slaPolicyVersion;
  final ServiceRequestSlaSummary? sla;
  final ServiceRequestStatus status;
  final ItsmLifecycleState lifecycleState;
  final bool workflowAllowsCancellation;
  final String? rejectionReason;
  final String? cancellationReason;
  final DateTime? submittedAt;
  final DateTime? fulfilledAt;
  final String? fulfilledBy;
  final DateTime? completionConfirmedAt;
  final String? completionConfirmedBy;
  final DateTime? closedAt;
  final DateTime? cancelledAt;
  final String? cancelledBy;
  final DateTime? rejectedAt;
  final String? rejectedBy;
  final bool selfServiceVisible;
  final ItsmConfidentiality confidentiality;
  final int commentCount;
  final int attachmentCount;
  final int taskCount;
  final int completedTaskCount;
  final int pendingApprovalCount;
  final List<ServiceRequestLinkSummary> relatedRecords;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;

  bool get isOnBehalf => requesterId != requestedForUserId;

  bool get isTerminal =>
      status == ServiceRequestStatus.closed ||
      status == ServiceRequestStatus.rejected ||
      status == ServiceRequestStatus.cancelled;

  bool canTransitionTo(ServiceRequestStatus next) {
    return _allowedTransitions[status]?.contains(next) ?? false;
  }

  Map<String, Object?> toFirestore() => {
        'requestNumber': requestNumber.trim(),
        'catalogueItemId': catalogueItemId.trim(),
        'catalogueItemCode': catalogueItemCode.trim(),
        'catalogueItemVersion': catalogueItemVersion,
        'catalogueItemName': catalogueItemName.trim(),
        'title': title.trim(),
        'description': description.trim(),
        'requesterId': requesterId.trim(),
        'requesterName': requesterName.trim(),
        'requesterEmail': requesterEmail.trim().toLowerCase(),
        'requestedForUserId': requestedForUserId.trim(),
        'requestedForName': requestedForName.trim(),
        'requestedForEmail': requestedForEmail.trim().toLowerCase(),
        // Phase 1 rules recognize affected-user fields as self-service owners.
        'affectedUserId': requestedForUserId.trim(),
        'affectedUserName': requestedForName.trim(),
        'affectedUserEmail': requestedForEmail.trim().toLowerCase(),
        if (departmentId != null) 'departmentId': departmentId!.trim(),
        if (departmentName != null) 'departmentName': departmentName!.trim(),
        if (serviceId != null) 'serviceId': serviceId!.trim(),
        if (serviceName != null) 'serviceName': serviceName!.trim(),
        'responses': responses,
        'workflowDefinitionId': workflowDefinitionId.trim(),
        'workflowVersion': workflowVersion,
        'workflowInstanceId': workflowInstanceId.trim(),
        'workflowRevision': workflowRevision,
        if (approvalPolicyId != null)
          'approvalPolicyId': approvalPolicyId!.trim(),
        'fulfilmentGroupId': fulfilmentGroupId.trim(),
        if (assignedGroupId != null) 'assignedGroupId': assignedGroupId!.trim(),
        if (assignedUserId != null) 'assignedUserId': assignedUserId!.trim(),
        if (assignedUserName != null)
          'assignedUserName': assignedUserName!.trim(),
        'slaPolicyId': slaPolicyId.trim(),
        'slaPolicyVersion': slaPolicyVersion,
        if (sla != null) 'slaSummary': sla!.toFirestore(),
        'status': status.value,
        'lifecycleState': lifecycleState.value,
        'workflowAllowsCancellation': workflowAllowsCancellation,
        if (rejectionReason != null) 'rejectionReason': rejectionReason!.trim(),
        if (cancellationReason != null)
          'cancellationReason': cancellationReason!.trim(),
        if (submittedAt != null) 'submittedAt': submittedAt,
        if (fulfilledAt != null) 'fulfilledAt': fulfilledAt,
        if (fulfilledBy != null) 'fulfilledBy': fulfilledBy!.trim(),
        if (completionConfirmedAt != null)
          'completionConfirmedAt': completionConfirmedAt,
        if (completionConfirmedBy != null)
          'completionConfirmedBy': completionConfirmedBy!.trim(),
        if (closedAt != null) 'closedAt': closedAt,
        if (cancelledAt != null) 'cancelledAt': cancelledAt,
        if (cancelledBy != null) 'cancelledBy': cancelledBy!.trim(),
        if (rejectedAt != null) 'rejectedAt': rejectedAt,
        if (rejectedBy != null) 'rejectedBy': rejectedBy!.trim(),
        'selfServiceVisible': selfServiceVisible,
        'confidentiality': confidentiality.value,
        'commentCount': commentCount,
        'attachmentCount': attachmentCount,
        'taskCount': taskCount,
        'completedTaskCount': completedTaskCount,
        'pendingApprovalCount': pendingApprovalCount,
        'relatedRecords': relatedRecords
            .map((record) => record.toFirestore())
            .toList(growable: false),
        'createdAt': createdAt,
        'createdBy': createdBy.trim(),
        'updatedAt': updatedAt,
        'updatedBy': updatedBy.trim(),
      };
}

class ServiceRequestDetail {
  ServiceRequestDetail({
    required this.request,
    Iterable<ServiceRequestApprovalSummary> approvals = const [],
    Iterable<ServiceRequestTaskSummary> tasks = const [],
    Iterable<ServiceRequestComment> comments = const [],
    Iterable<ServiceRequestAttachment> attachments = const [],
  })  : approvals = List<ServiceRequestApprovalSummary>.unmodifiable(approvals),
        tasks = List<ServiceRequestTaskSummary>.unmodifiable(tasks),
        comments = List<ServiceRequestComment>.unmodifiable(comments),
        attachments = List<ServiceRequestAttachment>.unmodifiable(attachments);

  final ServiceRequest request;
  final List<ServiceRequestApprovalSummary> approvals;
  final List<ServiceRequestTaskSummary> tasks;
  final List<ServiceRequestComment> comments;
  final List<ServiceRequestAttachment> attachments;
}

const Map<ServiceRequestStatus, Set<ServiceRequestStatus>> _allowedTransitions =
    {
  ServiceRequestStatus.draft: {
    ServiceRequestStatus.submitted,
    ServiceRequestStatus.cancelled,
  },
  ServiceRequestStatus.submitted: {
    ServiceRequestStatus.awaitingApproval,
    ServiceRequestStatus.approved,
    ServiceRequestStatus.assigned,
    ServiceRequestStatus.rejected,
    ServiceRequestStatus.cancelled,
  },
  ServiceRequestStatus.awaitingApproval: {
    ServiceRequestStatus.approved,
    ServiceRequestStatus.rejected,
    ServiceRequestStatus.cancelled,
  },
  ServiceRequestStatus.approved: {
    ServiceRequestStatus.assigned,
    ServiceRequestStatus.inFulfilment,
    ServiceRequestStatus.cancelled,
  },
  ServiceRequestStatus.assigned: {
    ServiceRequestStatus.inFulfilment,
    ServiceRequestStatus.cancelled,
  },
  ServiceRequestStatus.inFulfilment: {
    ServiceRequestStatus.awaitingUser,
    ServiceRequestStatus.fulfilled,
    ServiceRequestStatus.cancelled,
  },
  ServiceRequestStatus.awaitingUser: {
    ServiceRequestStatus.inFulfilment,
    ServiceRequestStatus.fulfilled,
    ServiceRequestStatus.cancelled,
  },
  ServiceRequestStatus.fulfilled: {ServiceRequestStatus.closed},
  ServiceRequestStatus.closed: {},
  ServiceRequestStatus.rejected: {},
  ServiceRequestStatus.cancelled: {},
};

ItsmLifecycleState _lifecycleState(
  Object? value,
  ServiceRequestStatus status,
) {
  final parsed = ItsmLifecycleState.tryParse(value);
  if (parsed != null) return parsed;
  return switch (status) {
    ServiceRequestStatus.closed => ItsmLifecycleState.closed,
    ServiceRequestStatus.cancelled ||
    ServiceRequestStatus.rejected =>
      ItsmLifecycleState.cancelled,
    _ => ItsmLifecycleState.active,
  };
}
