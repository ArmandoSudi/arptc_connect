import 'dart:collection';

import '../../shared/domain/itsm_common.dart';
import 'configuration_common.dart';

enum AuditEqualityDimension {
  actorUserId,
  module,
  entityType,
  entityId,
  reference,
  correlationId
}

class AuditQuery {
  AuditQuery({
    required this.from,
    required this.to,
    this.dimension,
    this.value,
  }) {
    if (to.isBefore(from)) {
      throw ArgumentError('Audit end cannot precede start.');
    }
    if (to.difference(from) > const Duration(days: 90)) {
      throw ArgumentError('Interactive audit queries are limited to 90 days.');
    }
    final hasValue = value?.trim().isNotEmpty == true;
    if ((dimension != null) != hasValue) {
      throw ArgumentError(
          'Audit dimension and value must be supplied together.');
    }
  }

  final DateTime from;
  final DateTime to;
  final AuditEqualityDimension? dimension;
  final String? value;

  Map<String, Object?> toPrimitiveMap() => {
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
        if (dimension != null) 'dimension': dimension!.name,
        if (value != null) 'value': value!.trim(),
      };
}

class GlobalAuditActor {
  const GlobalAuditActor({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.role,
    this.departmentId,
  });

  final String userId;
  final String displayName;
  final String email;
  final ItsmRole? role;
  final String? departmentId;
}

class GlobalAuditEvent {
  GlobalAuditEvent({
    required this.id,
    required this.eventType,
    required this.action,
    required this.module,
    required this.entityType,
    required this.entityId,
    required this.actor,
    required this.correlationId,
    required this.confidentiality,
    required this.isRestricted,
    required this.createdAt,
    this.entityReference,
    this.sourcePath,
    this.fromState,
    this.toState,
    this.comment,
    Map<String, Object?> before = const {},
    Map<String, Object?> after = const {},
    Iterable<String> authorizedManagerIds = const [],
  })  : before = UnmodifiableMapView(Map<String, Object?>.from(before)),
        after = UnmodifiableMapView(Map<String, Object?>.from(after)),
        authorizedManagerIds = Set<String>.unmodifiable(authorizedManagerIds);

  final String id;
  final String eventType;
  final String action;
  final String module;
  final String entityType;
  final String entityId;
  final String? entityReference;
  final String? sourcePath;
  final GlobalAuditActor actor;
  final Map<String, Object?> before;
  final Map<String, Object?> after;
  final String? fromState;
  final String? toState;
  final String? comment;
  final String correlationId;
  final ItsmConfidentiality confidentiality;
  final bool isRestricted;
  final Set<String> authorizedManagerIds;
  final DateTime createdAt;

  bool canBeReadBy({required ItsmRole role, required String userId}) {
    if (role == ItsmRole.user) return false;
    if (!isRestricted) return true;
    return role == ItsmRole.manager && authorizedManagerIds.contains(userId);
  }

  factory GlobalAuditEvent.fromMap(String id, Map<String, Object?> map) {
    final actorMap = configurationMap(map['actor']);
    return GlobalAuditEvent(
      id: id,
      eventType:
          configurationString(map['eventType'] ?? map['action'], 'event'),
      action: configurationString(map['action'] ?? map['eventType'], 'unknown'),
      module: configurationString(map['module'], 'itsm'),
      entityType: configurationString(
          map['entityType'] ?? map['targetEntityType'] ?? map['workItemType'],
          'unknown'),
      entityId: configurationString(
          map['entityId'] ?? map['targetEntityId'] ?? map['workItemId']),
      entityReference:
          _nullable(map['entityReference'] ?? map['targetReference']),
      sourcePath: _nullable(map['sourcePath']),
      actor: GlobalAuditActor(
        userId: configurationString(
            actorMap['userId'] ?? map['actorUserId'], 'system'),
        displayName: configurationString(
            actorMap['displayName'] ?? map['actorDisplayName'], 'System'),
        email: configurationString(actorMap['email']),
        role: ItsmRole.tryParse(actorMap['role'] ?? map['actorRole']),
        departmentId:
            _nullable(actorMap['departmentId'] ?? map['departmentId']),
      ),
      before: configurationMap(map['before'] ?? map['previousValues']),
      after: configurationMap(map['after'] ?? map['newValues']),
      fromState: _nullable(map['fromState']),
      toState: _nullable(map['toState']),
      comment: _nullable(map['comment']),
      correlationId: configurationString(map['correlationId'], id),
      confidentiality: ItsmConfidentiality.fromValue(map['confidentiality']),
      isRestricted: configurationBool(map['isRestricted']) ||
          ItsmConfidentiality.fromValue(map['confidentiality']) ==
              ItsmConfidentiality.restricted,
      authorizedManagerIds: configurationList(map['authorizedManagerIds'])
          .map(configurationString),
      createdAt: configurationDate(map['createdAt'] ?? map['occurredAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}

class AuditExportReceipt {
  const AuditExportReceipt({
    required this.exportId,
    required this.status,
    required this.requestedAt,
    this.expiresAt,
    this.rowCount,
    this.downloadUrl,
  });

  final String exportId;
  final String status;
  final DateTime requestedAt;
  final DateTime? expiresAt;
  final int? rowCount;
  final String? downloadUrl;
}

String? _nullable(Object? value) {
  final result = configurationString(value);
  return result.isEmpty ? null : result;
}
