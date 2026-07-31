import 'dart:collection';

import 'change_request.dart';
import 'change_serialization.dart';

enum CabDecisionType {
  approved('approved'),
  approvedWithConditions('approved_with_conditions'),
  rejected('rejected'),
  clarificationRequested('clarification_requested'),
  emergencyApproved('emergency_approved'),
  emergencyRejected('emergency_rejected');

  const CabDecisionType(this.value);

  final String value;

  static CabDecisionType fromValue(Object? value) {
    final normalized = changeString(value).toLowerCase().replaceAll('-', '_');
    return values.firstWhere(
      (decision) => decision.value == normalized,
      orElse: () => CabDecisionType.clarificationRequested,
    );
  }

  bool get isEmergency =>
      this == CabDecisionType.emergencyApproved ||
      this == CabDecisionType.emergencyRejected;
}

class CabParticipant {
  CabParticipant({
    required String userId,
    required String name,
    this.groupId,
    this.isChair = false,
  })  : userId = requireChangeText(userId, 'userId'),
        name = requireChangeText(name, 'name');

  factory CabParticipant.fromMap(Map<String, Object?> map) => CabParticipant(
        userId: changeString(map['userId']),
        name: changeString(map['name']),
        groupId: changeNullableString(map['groupId']),
        isChair: changeBool(map['isChair']),
      );

  final String userId;
  final String name;
  final String? groupId;
  final bool isChair;

  Map<String, Object?> toFirestore() => {
        'userId': userId,
        'name': name,
        if (groupId != null) 'groupId': groupId,
        'isChair': isChair,
      };
}

class CabAgendaItem {
  CabAgendaItem({
    required String changeRequestId,
    required String changeNumber,
    required String title,
    required this.type,
    required this.risk,
    this.order = 0,
  })  : changeRequestId = requireChangeText(
          changeRequestId,
          'changeRequestId',
        ),
        changeNumber = requireChangeText(changeNumber, 'changeNumber'),
        title = requireChangeText(title, 'title') {
    if (order < 0) throw RangeError.value(order, 'order');
  }

  factory CabAgendaItem.fromMap(Map<String, Object?> map) => CabAgendaItem(
        changeRequestId: changeString(map['changeRequestId']),
        changeNumber: changeString(map['changeNumber']),
        title: changeString(map['title']),
        type: ChangeType.fromValue(map['changeType']),
        risk: ChangeRiskLevel.fromValue(map['risk']),
        order: changeInt(map['order']),
      );

  final String changeRequestId;
  final String changeNumber;
  final String title;
  final ChangeType type;
  final ChangeRiskLevel risk;
  final int order;

  Map<String, Object?> toFirestore() => {
        'changeRequestId': changeRequestId,
        'changeNumber': changeNumber,
        'title': title,
        'changeType': type.value,
        'risk': risk.value,
        'order': order,
      };
}

class CabDecisionRecord {
  CabDecisionRecord({
    required String id,
    required String changeRequestId,
    required this.sequence,
    required this.type,
    required String decidedByUserId,
    required String decidedByName,
    required DateTime decidedAt,
    required String comment,
    this.clarificationRequest,
    DateTime? deadline,
    Iterable<String> conditions = const [],
  })  : id = requireChangeText(id, 'id'),
        changeRequestId = requireChangeText(
          changeRequestId,
          'changeRequestId',
        ),
        decidedByUserId = requireChangeText(
          decidedByUserId,
          'decidedByUserId',
        ),
        decidedByName = requireChangeText(decidedByName, 'decidedByName'),
        decidedAt = decidedAt.toUtc(),
        comment = requireChangeText(comment, 'comment'),
        deadline = deadline?.toUtc(),
        conditions = List<String>.unmodifiable(
          conditions
              .map((condition) => condition.trim())
              .where((condition) => condition.isNotEmpty),
        ) {
    if (sequence < 1) throw RangeError.value(sequence, 'sequence');
    if (type == CabDecisionType.approvedWithConditions &&
        this.conditions.isEmpty) {
      throw ArgumentError('Conditional approval requires conditions.');
    }
    if (type == CabDecisionType.clarificationRequested &&
        changeString(clarificationRequest).isEmpty) {
      throw ArgumentError('Clarification requires a question or request.');
    }
    if (type.isEmergency && deadline == null) {
      throw ArgumentError('An emergency decision requires a deadline.');
    }
  }

  factory CabDecisionRecord.fromMap(Map<String, Object?> map) =>
      CabDecisionRecord(
        id: changeString(map['id']),
        changeRequestId: changeString(map['changeRequestId']),
        sequence: changeInt(map['sequence'], 1),
        type: CabDecisionType.fromValue(map['decisionType']),
        decidedByUserId: changeString(map['decidedByUserId']),
        decidedByName: changeString(map['decidedByName']),
        decidedAt: requireChangeDate(map['decidedAt'], 'decidedAt'),
        comment: changeString(map['comment']),
        clarificationRequest: changeNullableString(map['clarificationRequest']),
        conditions: changeStringList(map['conditions']),
        deadline: changeDateFromValue(map['deadline']),
      );

  final String id;
  final String changeRequestId;
  final int sequence;
  final CabDecisionType type;
  final String decidedByUserId;
  final String decidedByName;
  final DateTime decidedAt;
  final String comment;
  final String? clarificationRequest;
  final List<String> conditions;
  final DateTime? deadline;

  Map<String, Object?> toFirestore() => UnmodifiableMapView({
        'id': id,
        'changeRequestId': changeRequestId,
        'sequence': sequence,
        'decisionType': type.value,
        'decidedByUserId': decidedByUserId,
        'decidedByName': decidedByName,
        'decidedAt': decidedAt,
        'comment': comment,
        if (clarificationRequest != null)
          'clarificationRequest': clarificationRequest,
        'conditions': conditions,
        if (deadline != null) 'deadline': deadline,
      });
}

class CabMeeting {
  CabMeeting({
    required String id,
    required String groupId,
    required String title,
    required DateTime scheduledAt,
    required DateTime decisionDeadline,
    required String createdBy,
    required DateTime createdAt,
    this.notes = '',
    this.agendaText = '',
    Iterable<CabParticipant> participants = const [],
    Iterable<CabAgendaItem> agenda = const [],
    Iterable<CabDecisionRecord> decisionHistory = const [],
  })  : id = requireChangeText(id, 'id'),
        groupId = requireChangeText(groupId, 'groupId'),
        title = requireChangeText(title, 'title'),
        scheduledAt = scheduledAt.toUtc(),
        decisionDeadline = decisionDeadline.toUtc(),
        createdBy = requireChangeText(createdBy, 'createdBy'),
        createdAt = createdAt.toUtc(),
        participants = List<CabParticipant>.unmodifiable(participants),
        agenda = List<CabAgendaItem>.unmodifiable(agenda),
        decisionHistory = List<CabDecisionRecord>.unmodifiable(
          decisionHistory,
        ) {
    if (this.decisionDeadline.isBefore(this.scheduledAt)) {
      throw ArgumentError('Decision deadline cannot precede the CAB meeting.');
    }
    final sequences = <int>{};
    for (final decision in this.decisionHistory) {
      if (!sequences.add(decision.sequence)) {
        throw ArgumentError('CAB decision sequence numbers must be unique.');
      }
    }
  }

  factory CabMeeting.fromMap(String id, Map<String, Object?> map) => CabMeeting(
        id: id,
        groupId: changeString(map['groupId'] ?? map['approvalGroupId']),
        title: changeString(map['title']),
        scheduledAt: requireChangeDate(
          map['scheduledAt'] ?? map['scheduledStartAt'],
          'scheduledAt',
        ),
        decisionDeadline: requireChangeDate(
          map['decisionDeadline'] ?? map['decisionDeadlineAt'],
          'decisionDeadline',
        ),
        notes: changeString(map['notes']),
        participants: changeModelList(
          map['participants'],
          CabParticipant.fromMap,
        ),
        agenda: map['agenda'] is String
            ? const []
            : changeModelList(map['agenda'], CabAgendaItem.fromMap),
        agendaText: map['agenda'] is String ? changeString(map['agenda']) : '',
        decisionHistory: changeModelList(
          map['decisionHistory'],
          CabDecisionRecord.fromMap,
        ),
        createdBy: changeString(
          map['createdBy'] ?? map['createdByUserId'],
          'unknown',
        ),
        createdAt: requireChangeDate(map['createdAt'], 'createdAt'),
      );

  final String id;
  final String groupId;
  final String title;
  final DateTime scheduledAt;
  final DateTime decisionDeadline;
  final String notes;
  final String agendaText;
  final List<CabParticipant> participants;
  final List<CabAgendaItem> agenda;
  final List<CabDecisionRecord> decisionHistory;
  final String createdBy;
  final DateTime createdAt;

  CabMeeting recordDecision(CabDecisionRecord decision) {
    if (decisionHistory.any((item) => item.id == decision.id)) {
      throw StateError('A CAB decision with this ID already exists.');
    }
    final expectedSequence = decisionHistory.length + 1;
    if (decision.sequence != expectedSequence) {
      throw StateError('The next CAB decision sequence is $expectedSequence.');
    }
    if (!agenda.any(
      (item) => item.changeRequestId == decision.changeRequestId,
    )) {
      throw ArgumentError('The change is not on this CAB agenda.');
    }

    return CabMeeting(
      id: id,
      groupId: groupId,
      title: title,
      scheduledAt: scheduledAt,
      decisionDeadline: decisionDeadline,
      notes: notes,
      agendaText: agendaText,
      participants: participants,
      agenda: agenda,
      decisionHistory: [...decisionHistory, decision],
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }

  Map<String, Object?> toFirestore() => UnmodifiableMapView({
        'groupId': groupId,
        'title': title,
        'scheduledAt': scheduledAt,
        'decisionDeadline': decisionDeadline,
        'notes': notes.trim(),
        'participants': participants
            .map((participant) => participant.toFirestore())
            .toList(growable: false),
        'agenda': agendaText.trim().isNotEmpty
            ? agendaText.trim()
            : agenda.map((item) => item.toFirestore()).toList(growable: false),
        'decisionHistory': decisionHistory
            .map((decision) => decision.toFirestore())
            .toList(growable: false),
        'createdBy': createdBy,
        'createdAt': createdAt,
      });
}
