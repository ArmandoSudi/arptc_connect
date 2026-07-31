import 'dart:collection';

import '../domain/itsm_shared_domain.dart';

class ItsmCommandContext {
  ItsmCommandContext({
    required this.idempotencyKey,
    required this.correlationId,
    required this.actorUserId,
    required this.actorRole,
    this.actorDisplayName = '',
  }) {
    for (final entry in {
      'idempotencyKey': idempotencyKey,
      'correlationId': correlationId,
      'actorUserId': actorUserId,
    }.entries) {
      if (entry.value.trim().isEmpty) {
        throw ArgumentError.value(
          entry.value,
          entry.key,
          'A non-empty command value is required.',
        );
      }
    }
  }

  final String idempotencyKey;
  final String correlationId;
  final String actorUserId;
  final String actorDisplayName;
  final ItsmRole actorRole;
}

class ItsmCommandReceipt {
  const ItsmCommandReceipt({
    required this.commandId,
    required this.acceptedAt,
    required this.wasDuplicate,
  });

  final String commandId;
  final DateTime acceptedAt;
  final bool wasDuplicate;
}

class ItsmWorkflowTransitionCommand {
  ItsmWorkflowTransitionCommand({
    required this.context,
    required this.workItemType,
    required this.workItemId,
    required this.expectedState,
    required this.transitionId,
    Map<String, Object?> fields = const {},
  }) : fields = UnmodifiableMapView(Map<String, Object?>.from(fields));

  final ItsmCommandContext context;
  final ItsmWorkItemType workItemType;
  final String workItemId;
  final String expectedState;
  final String transitionId;
  final Map<String, Object?> fields;
}

abstract interface class ItsmWorkflowCommandGateway {
  Future<ItsmCommandReceipt> transition(ItsmWorkflowTransitionCommand command);
}

class ItsmApprovalDecisionCommand {
  const ItsmApprovalDecisionCommand({
    required this.context,
    required this.workItemType,
    required this.workItemId,
    required this.approvalId,
    required this.decision,
    this.comment = '',
  });

  final ItsmCommandContext context;
  final ItsmWorkItemType workItemType;
  final String workItemId;
  final String approvalId;
  final ApprovalDecision decision;
  final String comment;
}

abstract interface class ItsmApprovalCommandGateway {
  Future<ItsmCommandReceipt> decide(ItsmApprovalDecisionCommand command);
}

class ItsmAuditIndexCommand {
  const ItsmAuditIndexCommand({
    required this.context,
    required this.workItemType,
    required this.workItemId,
    required this.auditEventId,
  });

  final ItsmCommandContext context;
  final ItsmWorkItemType workItemType;
  final String workItemId;
  final String auditEventId;
}

abstract interface class ItsmAuditCommandGateway {
  Future<ItsmCommandReceipt> indexEvent(ItsmAuditIndexCommand command);
}

class ItsmWorkItemIndexCommand {
  const ItsmWorkItemIndexCommand({
    required this.context,
    required this.workItemType,
    required this.workItemId,
    this.remove = false,
  });

  final ItsmCommandContext context;
  final ItsmWorkItemType workItemType;
  final String workItemId;
  final bool remove;
}

abstract interface class ItsmWorkItemIndexCommandGateway {
  Future<ItsmCommandReceipt> synchronize(ItsmWorkItemIndexCommand command);
}

class ItsmSlaProcessingCommand {
  const ItsmSlaProcessingCommand({
    required this.context,
    required this.workItemType,
    required this.workItemId,
    required this.policyId,
  });

  final ItsmCommandContext context;
  final ItsmWorkItemType workItemType;
  final String workItemId;
  final String policyId;
}

abstract interface class ItsmSlaCommandGateway {
  Future<ItsmCommandReceipt> process(ItsmSlaProcessingCommand command);
}

class ItsmNotificationEventCommand {
  ItsmNotificationEventCommand({
    required this.context,
    required this.eventType,
    required this.workItemType,
    required this.workItemId,
    required this.deepLink,
    Iterable<String> recipientUserIds = const [],
    Map<String, Object?> payload = const {},
  })  : recipientUserIds = Set<String>.unmodifiable(
          recipientUserIds
              .map((userId) => userId.trim())
              .where((userId) => userId.isNotEmpty),
        ),
        payload = UnmodifiableMapView(Map<String, Object?>.from(payload));

  final ItsmCommandContext context;
  final String eventType;
  final ItsmWorkItemType workItemType;
  final String workItemId;
  final String deepLink;
  final Set<String> recipientUserIds;
  final Map<String, Object?> payload;
}

abstract interface class ItsmNotificationCommandGateway {
  Future<ItsmCommandReceipt> emit(ItsmNotificationEventCommand command);
}

class UnconfiguredItsmGatewayException implements Exception {
  const UnconfiguredItsmGatewayException(this.gateway);

  final String gateway;

  @override
  String toString() {
    return 'UnconfiguredItsmGatewayException('
        '$gateway must be backed by a trusted Cloud Function.)';
  }
}
