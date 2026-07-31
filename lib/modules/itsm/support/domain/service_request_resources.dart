import '../../shared/domain/approval.dart';
import '../../shared/domain/collaboration.dart';
import '../../shared/domain/sla.dart';
import 'support_serialization.dart';

class ServiceRequestApprovalSummary {
  ServiceRequestApprovalSummary({
    required this.id,
    required this.step,
    required this.status,
    required this.requestedAt,
    this.approverUserId,
    this.approverGroupId,
    this.decision,
    this.comment = '',
    this.dueAt,
    this.decidedAt,
    this.decidedByUserId,
  }) {
    supportRequire(id, 'id');
    if (step < 1) throw RangeError.value(step, 'step');
    if ((approverUserId?.trim().isEmpty ?? true) &&
        (approverGroupId?.trim().isEmpty ?? true)) {
      throw ArgumentError(
        'An approval requires an approver user or group.',
      );
    }
    if (status == ApprovalStatus.rejected && comment.trim().isEmpty) {
      throw ArgumentError('Rejected approvals require a comment.');
    }
  }

  factory ServiceRequestApprovalSummary.fromMap(
    String id,
    Map<String, Object?> map,
  ) {
    return ServiceRequestApprovalSummary(
      id: id,
      step: supportInt(map['step'], 1),
      status: _approvalStatus(map['status']),
      approverUserId: supportNullableString(map['approverUserId']),
      approverGroupId: supportNullableString(map['approverGroupId']),
      decision: _approvalDecision(map['decision']),
      comment: supportString(map['comment']),
      requestedAt: supportDateFromValue(map['requestedAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      dueAt: supportDateFromValue(map['dueAt']),
      decidedAt: supportDateFromValue(map['decidedAt']),
      decidedByUserId: supportNullableString(
        map['decidedByUserId'] ?? map['decidedBy'],
      ),
    );
  }

  final String id;
  final int step;
  final ApprovalStatus status;
  final String? approverUserId;
  final String? approverGroupId;
  final ApprovalDecision? decision;
  final String comment;
  final DateTime requestedAt;
  final DateTime? dueAt;
  final DateTime? decidedAt;
  final String? decidedByUserId;

  Map<String, Object?> toFirestore() => {
        'step': step,
        'status': status.name,
        if (approverUserId != null) 'approverUserId': approverUserId,
        if (approverGroupId != null) 'approverGroupId': approverGroupId,
        if (decision != null) 'decision': decision!.name,
        'comment': comment.trim(),
        'requestedAt': requestedAt,
        if (dueAt != null) 'dueAt': dueAt,
        if (decidedAt != null) 'decidedAt': decidedAt,
        if (decidedByUserId != null) 'decidedByUserId': decidedByUserId!.trim(),
      };
}

class ServiceRequestTaskSummary {
  ServiceRequestTaskSummary({
    required this.id,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.createdByUserId,
    this.description = '',
    this.assignedGroupId,
    this.assignedUserId,
    this.dueAt,
    this.completedAt,
    this.completedByUserId,
    this.isInternal = false,
  }) {
    supportRequire(id, 'id');
    supportRequire(title, 'title');
    supportRequire(createdByUserId, 'createdByUserId');
    if (status == ItsmTaskStatus.completed &&
        (completedAt == null || (completedByUserId?.trim().isEmpty ?? true))) {
      throw ArgumentError('Completed tasks require time and actor.');
    }
  }

  factory ServiceRequestTaskSummary.fromMap(
    String id,
    Map<String, Object?> map,
  ) {
    return ServiceRequestTaskSummary(
      id: id,
      title: supportString(map['title']),
      description: supportString(map['description']),
      status: _taskStatus(map['status']),
      assignedGroupId: supportNullableString(map['assignedGroupId']),
      assignedUserId: supportNullableString(map['assignedUserId']),
      dueAt: supportDateFromValue(map['dueAt']),
      completedAt: supportDateFromValue(map['completedAt']),
      completedByUserId: supportNullableString(
        map['completedByUserId'] ?? map['completedBy'],
      ),
      isInternal: supportBool(map['isInternal']),
      createdAt: supportDateFromValue(map['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      createdByUserId: supportString(
        map['createdByUserId'] ?? map['createdBy'],
        'unknown',
      ),
    );
  }

  final String id;
  final String title;
  final String description;
  final ItsmTaskStatus status;
  final String? assignedGroupId;
  final String? assignedUserId;
  final DateTime? dueAt;
  final DateTime? completedAt;
  final String? completedByUserId;
  final bool isInternal;
  final DateTime createdAt;
  final String createdByUserId;

  Map<String, Object?> toFirestore() => {
        'title': title.trim(),
        'description': description.trim(),
        'status': _taskStatusValue(status),
        if (assignedGroupId != null) 'assignedGroupId': assignedGroupId!.trim(),
        if (assignedUserId != null) 'assignedUserId': assignedUserId!.trim(),
        if (dueAt != null) 'dueAt': dueAt,
        if (completedAt != null) 'completedAt': completedAt,
        if (completedByUserId != null)
          'completedByUserId': completedByUserId!.trim(),
        'isInternal': isInternal,
        'createdAt': createdAt,
        'createdByUserId': createdByUserId.trim(),
      };
}

class ServiceRequestComment {
  ServiceRequestComment({
    required this.id,
    required this.body,
    required this.authorDisplayName,
    required this.visibility,
    required this.createdAt,
    required this.createdByUserId,
    this.editedAt,
  }) {
    supportRequire(id, 'id');
    supportRequire(body, 'body');
    supportRequire(createdByUserId, 'createdByUserId');
  }

  factory ServiceRequestComment.fromMap(
    String id,
    Map<String, Object?> map,
  ) {
    return ServiceRequestComment(
      id: id,
      body: supportString(map['body'] ?? map['content']),
      authorDisplayName: supportString(map['authorDisplayName']),
      visibility: _commentVisibility(
        map['visibility'],
        supportBool(map['isInternal']),
      ),
      createdAt: supportDateFromValue(map['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      createdByUserId: supportString(
        map['createdByUserId'] ?? map['createdBy'],
        'unknown',
      ),
      editedAt: supportDateFromValue(map['editedAt']),
    );
  }

  final String id;
  final String body;
  final String authorDisplayName;
  final ItsmCommentVisibility visibility;
  final DateTime createdAt;
  final String createdByUserId;
  final DateTime? editedAt;

  bool get isInternal => visibility != ItsmCommentVisibility.requesterVisible;

  Map<String, Object?> toFirestore() => {
        'body': body.trim(),
        'authorDisplayName': authorDisplayName.trim(),
        'visibility': visibility.name,
        'isInternal': isInternal,
        'createdAt': createdAt,
        'createdByUserId': createdByUserId.trim(),
        if (editedAt != null) 'editedAt': editedAt,
      };
}

class ServiceRequestAttachment {
  ServiceRequestAttachment({
    required this.id,
    required this.workItemId,
    required this.fileName,
    required this.contentType,
    required this.sizeBytes,
    required this.storagePath,
    required this.visibility,
    required this.createdAt,
    required this.uploadedByUserId,
    this.downloadUrl,
    this.checksum,
    this.documentRequirementKey,
  }) {
    for (final entry in {
      'id': id,
      'workItemId': workItemId,
      'fileName': fileName,
      'contentType': contentType,
      'storagePath': storagePath,
      'uploadedByUserId': uploadedByUserId,
    }.entries) {
      supportRequire(entry.value, entry.key);
    }
    if (sizeBytes < 0) throw RangeError.value(sizeBytes, 'sizeBytes');
  }

  factory ServiceRequestAttachment.fromMap(
    String id,
    String workItemId,
    Map<String, Object?> map,
  ) {
    return ServiceRequestAttachment(
      id: id,
      workItemId: workItemId,
      fileName: supportString(map['fileName']),
      contentType: supportString(map['contentType']),
      sizeBytes: supportInt(map['sizeBytes']),
      storagePath: supportString(map['storagePath']),
      downloadUrl: supportNullableString(map['downloadUrl']),
      checksum: supportNullableString(map['checksum']),
      documentRequirementKey:
          supportNullableString(map['documentRequirementKey']),
      visibility: _attachmentVisibility(
        map['visibility'],
        supportBool(map['isInternal']),
      ),
      createdAt: supportDateFromValue(map['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      uploadedByUserId: supportString(
        map['uploadedByUserId'] ?? map['createdByUserId'],
        'unknown',
      ),
    );
  }

  final String id;
  final String workItemId;
  final String fileName;
  final String contentType;
  final int sizeBytes;
  final String storagePath;
  final String? downloadUrl;
  final String? checksum;
  final String? documentRequirementKey;
  final ItsmAttachmentVisibility visibility;
  final DateTime createdAt;
  final String uploadedByUserId;

  bool get isInternal =>
      visibility != ItsmAttachmentVisibility.requesterVisible;

  Map<String, Object?> toFirestore() => {
        'workItemCollection': 'serviceRequests',
        'workItemId': workItemId.trim(),
        'fileName': fileName.trim(),
        'contentType': contentType.trim(),
        'sizeBytes': sizeBytes,
        'storagePath': storagePath.trim(),
        if (downloadUrl != null) 'downloadUrl': downloadUrl!.trim(),
        if (checksum != null) 'checksum': checksum!.trim(),
        if (documentRequirementKey != null)
          'documentRequirementKey': documentRequirementKey!.trim(),
        'visibility': visibility.name,
        'isInternal': isInternal,
        'createdAt': createdAt,
        'uploadedByUserId': uploadedByUserId.trim(),
      };
}

enum ServiceRequestLinkType {
  asset('asset'),
  configurationItem('configuration_item'),
  incident('incident'),
  change('change'),
  knowledgeArticle('knowledge_article'),
  serviceRequest('service_request');

  const ServiceRequestLinkType(this.value);

  final String value;

  static ServiceRequestLinkType fromValue(Object? value) {
    final normalized = supportString(value).toLowerCase().replaceAll('-', '_');
    return values.firstWhere(
      (type) => type.value == normalized,
      orElse: () => ServiceRequestLinkType.serviceRequest,
    );
  }
}

class ServiceRequestLinkSummary {
  ServiceRequestLinkSummary({
    required this.type,
    required this.recordId,
    required this.reference,
    required this.title,
  }) {
    supportRequire(recordId, 'recordId');
    supportRequire(reference, 'reference');
  }

  factory ServiceRequestLinkSummary.fromMap(Map<String, Object?> map) {
    return ServiceRequestLinkSummary(
      type: ServiceRequestLinkType.fromValue(map['type']),
      recordId: supportString(map['recordId']),
      reference: supportString(map['reference']),
      title: supportString(map['title']),
    );
  }

  final ServiceRequestLinkType type;
  final String recordId;
  final String reference;
  final String title;

  Map<String, Object?> toFirestore() => {
        'type': type.value,
        'recordId': recordId.trim(),
        'reference': reference.trim(),
        'title': title.trim(),
      };
}

class ServiceRequestSlaSummary {
  ServiceRequestSlaSummary({
    required this.policyId,
    required this.policyVersion,
    required this.status,
    required this.responseDueAt,
    required this.fulfilmentDueAt,
    this.respondedAt,
    this.fulfilledAt,
    this.pausedAt,
  }) {
    supportRequire(policyId, 'policyId');
    if (policyVersion < 1) {
      throw RangeError.value(policyVersion, 'policyVersion');
    }
    if (fulfilmentDueAt.isBefore(responseDueAt)) {
      throw ArgumentError('Fulfilment cannot be due before response.');
    }
  }

  factory ServiceRequestSlaSummary.fromMap(Map<String, Object?> map) {
    final responseDueAt = supportDateFromValue(map['responseDueAt']) ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    return ServiceRequestSlaSummary(
      policyId: supportString(map['policyId']),
      policyVersion: supportInt(map['policyVersion'], 1),
      status: _slaStatus(map['status']),
      responseDueAt: responseDueAt,
      fulfilmentDueAt:
          supportDateFromValue(map['fulfilmentDueAt']) ?? responseDueAt,
      respondedAt: supportDateFromValue(map['respondedAt']),
      fulfilledAt: supportDateFromValue(map['fulfilledAt']),
      pausedAt: supportDateFromValue(map['pausedAt']),
    );
  }

  final String policyId;
  final int policyVersion;
  final SlaComplianceStatus status;
  final DateTime responseDueAt;
  final DateTime fulfilmentDueAt;
  final DateTime? respondedAt;
  final DateTime? fulfilledAt;
  final DateTime? pausedAt;

  Map<String, Object?> toFirestore() => {
        'policyId': policyId.trim(),
        'policyVersion': policyVersion,
        'status': _slaStatusValue(status),
        'responseDueAt': responseDueAt,
        'fulfilmentDueAt': fulfilmentDueAt,
        if (respondedAt != null) 'respondedAt': respondedAt,
        if (fulfilledAt != null) 'fulfilledAt': fulfilledAt,
        if (pausedAt != null) 'pausedAt': pausedAt,
      };
}

ApprovalStatus _approvalStatus(Object? value) {
  final normalized = supportString(value).toLowerCase().replaceAll('-', '_');
  return ApprovalStatus.values.firstWhere(
    (status) => _enumName(status.name) == normalized,
    orElse: () => ApprovalStatus.pending,
  );
}

ApprovalDecision? _approvalDecision(Object? value) {
  final normalized = supportString(value).toLowerCase().replaceAll('-', '_');
  if (normalized.isEmpty) return null;
  for (final decision in ApprovalDecision.values) {
    if (_enumName(decision.name) == normalized) return decision;
  }
  return null;
}

ItsmTaskStatus _taskStatus(Object? value) {
  final normalized = supportString(value).toLowerCase().replaceAll('-', '_');
  return switch (normalized) {
    'in_progress' || 'inprogress' => ItsmTaskStatus.inProgress,
    'completed' => ItsmTaskStatus.completed,
    'cancelled' => ItsmTaskStatus.cancelled,
    _ => ItsmTaskStatus.pending,
  };
}

String _taskStatusValue(ItsmTaskStatus status) {
  return switch (status) {
    ItsmTaskStatus.inProgress => 'in_progress',
    _ => status.name,
  };
}

ItsmCommentVisibility _commentVisibility(Object? value, bool isInternal) {
  if (isInternal) return ItsmCommentVisibility.internal;
  final normalized = supportString(value).toLowerCase();
  return switch (normalized) {
    'internal' => ItsmCommentVisibility.internal,
    'restricted' => ItsmCommentVisibility.restricted,
    _ => ItsmCommentVisibility.requesterVisible,
  };
}

ItsmAttachmentVisibility _attachmentVisibility(
  Object? value,
  bool isInternal,
) {
  if (isInternal) return ItsmAttachmentVisibility.internal;
  final normalized = supportString(value).toLowerCase();
  return switch (normalized) {
    'internal' => ItsmAttachmentVisibility.internal,
    'restricted' => ItsmAttachmentVisibility.restricted,
    _ => ItsmAttachmentVisibility.requesterVisible,
  };
}

SlaComplianceStatus _slaStatus(Object? value) {
  final normalized = supportString(value).toLowerCase().replaceAll('-', '_');
  return switch (normalized) {
    'at_risk' || 'atrisk' => SlaComplianceStatus.atRisk,
    'breached' => SlaComplianceStatus.breached,
    'paused' => SlaComplianceStatus.paused,
    'met' => SlaComplianceStatus.met,
    _ => SlaComplianceStatus.onTrack,
  };
}

String _slaStatusValue(SlaComplianceStatus status) {
  return switch (status) {
    SlaComplianceStatus.onTrack => 'on_track',
    SlaComplianceStatus.atRisk => 'at_risk',
    _ => status.name,
  };
}

String _enumName(String name) {
  return name.replaceAllMapped(
    RegExp('[A-Z]'),
    (match) => '_${match.group(0)!.toLowerCase()}',
  );
}
