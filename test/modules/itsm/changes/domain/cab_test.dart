import 'package:arptc_connect/modules/itsm/changes/domain/changes_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CAB decision records', () {
    test('models conditional, clarification and emergency decisions', () {
      final conditional = _decision(
        type: CabDecisionType.approvedWithConditions,
        conditions: const ['Complete a backup before implementation'],
      );
      final clarification = _decision(
        type: CabDecisionType.clarificationRequested,
        clarification: 'Provide load-test evidence.',
      );
      final emergency = _decision(
        type: CabDecisionType.emergencyApproved,
        deadline: DateTime.utc(2026, 8, 2, 12),
      );

      expect(conditional.conditions, hasLength(1));
      expect(clarification.clarificationRequest, contains('load-test'));
      expect(emergency.type.isEmergency, isTrue);
      expect(emergency.deadline, DateTime.utc(2026, 8, 2, 12));
    });

    test('enforces decision-specific required data', () {
      expect(
        () => _decision(type: CabDecisionType.approvedWithConditions),
        throwsArgumentError,
      );
      expect(
        () => _decision(type: CabDecisionType.clarificationRequested),
        throwsArgumentError,
      );
      expect(
        () => _decision(type: CabDecisionType.emergencyRejected),
        throwsArgumentError,
      );
    });

    test('round-trips decision details', () {
      final source = _decision(
        type: CabDecisionType.approvedWithConditions,
        conditions: const ['Notify service owner'],
      );

      final parsed = CabDecisionRecord.fromMap(source.toFirestore());

      expect(parsed.type, CabDecisionType.approvedWithConditions);
      expect(parsed.conditions, ['Notify service owner']);
      expect(parsed.decidedByUserId, 'manager-1');
    });
  });

  group('CabMeeting', () {
    test('adapts the trusted backend meeting shape', () {
      final meeting = CabMeeting.fromMap('meeting-backend', {
        'approvalGroupId': 'cab-network',
        'title': 'Network CAB',
        'agenda': 'Review the core network change.',
        'participants': [
          {'userId': 'manager-1', 'name': 'Manager One'},
        ],
        'scheduledStartAt': DateTime.utc(2026, 8, 4, 9),
        'scheduledEndAt': DateTime.utc(2026, 8, 4, 10),
        'decisionDeadlineAt': DateTime.utc(2026, 8, 5, 10),
        'createdByUserId': 'manager-1',
        'createdAt': DateTime.utc(2026, 8, 1),
      });

      expect(meeting.groupId, 'cab-network');
      expect(meeting.agendaText, 'Review the core network change.');
      expect(meeting.participants.single.userId, 'manager-1');
      expect(meeting.toFirestore()['agenda'], meeting.agendaText);
    });

    test('round-trips participants, agenda, notes and deadline', () {
      final source = _meeting();

      final parsed = CabMeeting.fromMap(source.id, source.toFirestore());

      expect(parsed.groupId, 'cab-network');
      expect(parsed.participants.single.isChair, isTrue);
      expect(parsed.agenda.single.changeRequestId, 'change-1');
      expect(parsed.notes, 'Review network production changes.');
      expect(parsed.decisionDeadline, DateTime.utc(2026, 8, 2, 18));
    });

    test('appends decisions without mutating prior history', () {
      final original = _meeting();
      final decided = original.recordDecision(
        _decision(type: CabDecisionType.approved),
      );

      expect(original.decisionHistory, isEmpty);
      expect(decided.decisionHistory, hasLength(1));
      expect(
        () => decided.decisionHistory.add(
          _decision(type: CabDecisionType.rejected),
        ),
        throwsUnsupportedError,
      );
    });

    test('rejects duplicate, out-of-order and off-agenda decisions', () {
      final first = _meeting().recordDecision(
        _decision(type: CabDecisionType.approved),
      );
      expect(
        () => first.recordDecision(
          _decision(type: CabDecisionType.rejected),
        ),
        throwsStateError,
      );
      expect(
        () => _meeting().recordDecision(
          _decision(
            type: CabDecisionType.approved,
            id: 'decision-2',
            sequence: 2,
          ),
        ),
        throwsStateError,
      );
      expect(
        () => _meeting().recordDecision(
          _decision(
            type: CabDecisionType.approved,
            id: 'decision-3',
            changeId: 'change-not-on-agenda',
          ),
        ),
        throwsArgumentError,
      );
    });

    test('requires deadline at or after the meeting date', () {
      expect(
        () => CabMeeting(
          id: 'meeting-1',
          groupId: 'cab',
          title: 'CAB',
          scheduledAt: DateTime.utc(2026, 8, 2, 10),
          decisionDeadline: DateTime.utc(2026, 8, 2, 9),
          createdBy: 'manager-1',
          createdAt: DateTime.utc(2026, 8, 1),
        ),
        throwsArgumentError,
      );
    });
  });
}

CabMeeting _meeting() => CabMeeting(
      id: 'meeting-1',
      groupId: 'cab-network',
      title: 'Network CAB',
      scheduledAt: DateTime.utc(2026, 8, 2, 14),
      decisionDeadline: DateTime.utc(2026, 8, 2, 18),
      participants: [
        CabParticipant(
          userId: 'manager-1',
          name: 'Manager One',
          groupId: 'cab-network',
          isChair: true,
        ),
      ],
      agenda: [
        CabAgendaItem(
          changeRequestId: 'change-1',
          changeNumber: 'CHG-1',
          title: 'Network upgrade',
          type: ChangeType.normal,
          risk: ChangeRiskLevel.high,
        ),
      ],
      notes: 'Review network production changes.',
      createdBy: 'manager-1',
      createdAt: DateTime.utc(2026, 8, 1),
    );

CabDecisionRecord _decision({
  required CabDecisionType type,
  String id = 'decision-1',
  String changeId = 'change-1',
  int sequence = 1,
  String? clarification,
  DateTime? deadline,
  List<String> conditions = const [],
}) {
  return CabDecisionRecord(
    id: id,
    changeRequestId: changeId,
    sequence: sequence,
    type: type,
    decidedByUserId: 'manager-1',
    decidedByName: 'Manager One',
    decidedAt: DateTime.utc(2026, 8, 2, 15),
    comment: 'Decision recorded by CAB.',
    clarificationRequest: clarification,
    deadline: deadline,
    conditions: conditions,
  );
}
