import 'dart:collection';

import 'itsm_common.dart';

class ItsmWorkItemSummary {
  ItsmWorkItemSummary({
    required this.id,
    required this.reference,
    required this.type,
    required this.title,
    required this.requesterId,
    required this.status,
    required this.lifecycleState,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    this.description = '',
    this.affectedUserId,
    this.departmentId,
    this.serviceId,
    this.locationId,
    this.assignedGroupId,
    this.assignedUserId,
    this.priority = ItsmPriority.unprioritized,
    this.impact,
    this.urgency,
    this.workflowDefinitionId,
    this.workflowVersion,
    this.dueAt,
    this.closedAt,
    this.confidentiality = ItsmConfidentiality.internal,
    Iterable<String> linkedAssetIds = const [],
    Iterable<String> linkedCiIds = const [],
  })  : linkedAssetIds = List<String>.unmodifiable(linkedAssetIds),
        linkedCiIds = List<String>.unmodifiable(linkedCiIds) {
    _requireValue(id, 'id');
    _requireValue(reference, 'reference');
    _requireValue(title, 'title');
    _requireValue(requesterId, 'requesterId');
    _requireValue(status, 'status');
    _requireValue(createdBy, 'createdBy');
    _requireValue(updatedBy, 'updatedBy');
    final version = workflowVersion;
    if (version != null && version < 1) {
      throw RangeError.value(version, 'workflowVersion');
    }
  }

  final String id;
  final String reference;
  final ItsmWorkItemType type;
  final String title;
  final String description;
  final String requesterId;
  final String? affectedUserId;
  final String? departmentId;
  final String? serviceId;
  final String? locationId;
  final String? assignedGroupId;
  final String? assignedUserId;
  final ItsmPriority priority;
  final ItsmImpact? impact;
  final ItsmUrgency? urgency;
  final String status;
  final ItsmLifecycleState lifecycleState;
  final String? workflowDefinitionId;
  final int? workflowVersion;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;
  final DateTime? dueAt;
  final DateTime? closedAt;
  final ItsmConfidentiality confidentiality;
  final List<String> linkedAssetIds;
  final List<String> linkedCiIds;

  bool isOwnedBy(String userId) => requesterId == userId.trim();

  bool get isClosed =>
      lifecycleState == ItsmLifecycleState.closed ||
      lifecycleState == ItsmLifecycleState.archived ||
      lifecycleState == ItsmLifecycleState.cancelled;

  Map<String, Object?> toPrimitiveMap() {
    return UnmodifiableMapView({
      'id': id,
      'reference': reference,
      'type': type.value,
      'title': title,
      'description': description,
      'requesterId': requesterId,
      'affectedUserId': affectedUserId,
      'departmentId': departmentId,
      'serviceId': serviceId,
      'locationId': locationId,
      'assignedGroupId': assignedGroupId,
      'assignedUserId': assignedUserId,
      'priority': priority.value,
      'impact': impact?.value,
      'urgency': urgency?.value,
      'status': status,
      'lifecycleState': lifecycleState.value,
      'workflowDefinitionId': workflowDefinitionId,
      'workflowVersion': workflowVersion,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'createdBy': createdBy,
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'updatedBy': updatedBy,
      'dueAt': dueAt?.toUtc().toIso8601String(),
      'closedAt': closedAt?.toUtc().toIso8601String(),
      'confidentiality': confidentiality.value,
      'linkedAssetIds': linkedAssetIds,
      'linkedCiIds': linkedCiIds,
    });
  }
}

void _requireValue(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, 'A non-empty value is required.');
  }
}
