import 'package:cloud_firestore/cloud_firestore.dart';

class OrganizationAuditEvent {
  const OrganizationAuditEvent({
    required this.id,
    required this.eventType,
    required this.command,
    required this.commandId,
    required this.actorUid,
    required this.organizationId,
    required this.unitId,
    required this.agentId,
    required this.assignmentId,
    required this.reason,
    required this.before,
    required this.after,
    required this.createdAt,
  });

  final String id;
  final String eventType;
  final String command;
  final String commandId;
  final String actorUid;
  final String organizationId;
  final String unitId;
  final String agentId;
  final String assignmentId;
  final String reason;
  final Map<String, dynamic> before;
  final Map<String, dynamic> after;
  final DateTime createdAt;

  String get subjectId {
    for (final value in [agentId, unitId, assignmentId]) {
      if (value.isNotEmpty) return value;
    }
    return organizationId;
  }

  factory OrganizationAuditEvent.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    return OrganizationAuditEvent(
      id: id,
      eventType: _string(map['eventType']),
      command: _string(map['command']),
      commandId: _string(map['commandId']),
      actorUid: _string(map['actorUid']),
      organizationId: _string(map['organizationId']),
      unitId: _string(map['unitId']),
      agentId: _string(map['agentId']),
      assignmentId: _string(map['assignmentId']),
      reason: _string(map['reason']),
      before: _map(map['before']),
      after: _map(map['after']),
      createdAt: _dateTime(map['createdAt']),
    );
  }
}

String _string(Object? value) => value?.toString().trim() ?? '';

Map<String, dynamic> _map(Object? value) => value is Map
    ? Map<String, dynamic>.unmodifiable(Map<String, dynamic>.from(value))
    : const <String, dynamic>{};

DateTime _dateTime(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.tryParse(value?.toString() ?? '') ??
      DateTime.fromMillisecondsSinceEpoch(0);
}
