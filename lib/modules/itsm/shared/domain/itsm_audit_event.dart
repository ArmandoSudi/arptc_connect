import 'dart:collection';

class ItsmAuditEvent {
  ItsmAuditEvent({
    required this.id,
    required this.actorUserId,
    required this.actorDisplayName,
    required this.action,
    required this.targetEntityType,
    required this.targetEntityId,
    required this.occurredAt,
    required this.correlationId,
    required this.source,
    required this.module,
    this.targetReference,
    Map<String, Object?> previousValues = const {},
    Map<String, Object?> newValues = const {},
    this.comment,
    this.fromState,
    this.toState,
    this.departmentId,
  })  : previousValues = UnmodifiableMapView(
          Map<String, Object?>.from(previousValues),
        ),
        newValues = UnmodifiableMapView(
          Map<String, Object?>.from(newValues),
        ) {
    for (final entry in {
      'id': id,
      'actorUserId': actorUserId,
      'action': action,
      'targetEntityType': targetEntityType,
      'targetEntityId': targetEntityId,
      'correlationId': correlationId,
      'source': source,
      'module': module,
    }.entries) {
      if (entry.value.trim().isEmpty) {
        throw ArgumentError.value(
          entry.value,
          entry.key,
          'Audit values cannot be empty.',
        );
      }
    }
  }

  final String id;
  final String actorUserId;
  final String actorDisplayName;
  final String action;
  final String targetEntityType;
  final String targetEntityId;
  final String? targetReference;
  final DateTime occurredAt;
  final Map<String, Object?> previousValues;
  final Map<String, Object?> newValues;
  final String? comment;
  final String? fromState;
  final String? toState;
  final String correlationId;
  final String source;
  final String module;
  final String? departmentId;

  bool get representsTransition =>
      fromState?.trim().isNotEmpty == true &&
      toState?.trim().isNotEmpty == true &&
      fromState != toState;
}
