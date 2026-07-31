import 'package:arptc_connect/modules/itsm/shared/domain/itsm_shared_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BusinessCalendar and SLA calculations', () {
    test('carries working time across days and skips holidays', () {
      final calendar = BusinessCalendar.standardWeek(
        holidays: [DateTime.utc(2026, 8, 4)],
      );
      final monday = DateTime.utc(2026, 8, 3, 16);

      expect(
        calendar.addWorkingDuration(monday, const Duration(hours: 2)),
        DateTime.utc(2026, 8, 5, 9),
      );
      expect(
        calendar.workingDurationBetween(
          monday,
          DateTime.utc(2026, 8, 5, 9),
        ),
        const Duration(hours: 2),
      );
    });

    test('starts, pauses, resumes, and shifts due dates by working time', () {
      final policy = _policy();
      final startedAt = DateTime.utc(2026, 8, 3, 8);
      final initial = SlaCalculator.start(
        policy: policy,
        startedAt: startedAt,
      );
      final paused = SlaCalculator.pause(initial, DateTime.utc(2026, 8, 3, 10));
      final resumed = SlaCalculator.resume(
        policy: policy,
        state: paused,
        resumedAt: DateTime.utc(2026, 8, 3, 12),
      );

      expect(initial.responseDueAt, DateTime.utc(2026, 8, 3, 12));
      expect(initial.resolutionDueAt, DateTime.utc(2026, 8, 3, 16));
      expect(resumed.responseDueAt, DateTime.utc(2026, 8, 3, 14));
      expect(resumed.resolutionDueAt, DateTime.utc(2026, 8, 4, 9));
      expect(
        resumed.accumulatedPausedBusinessTime,
        const Duration(hours: 2),
      );
    });

    test('reports on-track, at-risk, breached, paused, and met states', () {
      final policy = _policy(warningThreshold: 0.75);
      final state = SlaCalculator.start(
        policy: policy,
        startedAt: DateTime.utc(2026, 8, 3, 8),
      );

      expect(
        SlaCalculator.responseMeasurement(
          policy: policy,
          state: state,
          now: DateTime.utc(2026, 8, 3, 9),
        ).status,
        SlaComplianceStatus.onTrack,
      );
      expect(
        SlaCalculator.responseMeasurement(
          policy: policy,
          state: state,
          now: DateTime.utc(2026, 8, 3, 11),
        ).status,
        SlaComplianceStatus.atRisk,
      );
      expect(
        SlaCalculator.responseMeasurement(
          policy: policy,
          state: state,
          now: DateTime.utc(2026, 8, 3, 12),
        ).status,
        SlaComplianceStatus.breached,
      );

      final paused = SlaCalculator.pause(state, DateTime.utc(2026, 8, 3, 10));
      expect(
        SlaCalculator.responseMeasurement(
          policy: policy,
          state: paused,
          now: DateTime.utc(2026, 8, 3, 14),
        ).status,
        SlaComplianceStatus.paused,
      );

      final responded = SlaCalculator.recordResponse(
        state,
        DateTime.utc(2026, 8, 3, 10),
      );
      expect(
        SlaCalculator.responseMeasurement(
          policy: policy,
          state: responded,
          now: DateTime.utc(2026, 8, 3, 14),
        ).status,
        SlaComplianceStatus.met,
      );
    });
  });

  group('Audit and shared subresources', () {
    test('keeps audit snapshots immutable and identifies transitions', () {
      final previous = <String, Object?>{'status': 'submitted'};
      final event = ItsmAuditEvent(
        id: 'audit-1',
        actorUserId: 'manager-1',
        actorDisplayName: 'Manager',
        action: 'workflow.transitioned',
        targetEntityType: 'service_request',
        targetEntityId: 'request-1',
        occurredAt: DateTime.utc(2026, 8, 1),
        correlationId: 'command-1',
        source: 'cloud_function',
        module: 'support',
        previousValues: previous,
        newValues: const {'status': 'in_progress'},
        fromState: 'submitted',
        toState: 'in_progress',
      );
      previous['status'] = 'changed';

      expect(event.previousValues['status'], 'submitted');
      expect(event.representsTransition, isTrue);
      expect(
        () => event.newValues['status'] = 'closed',
        throwsUnsupportedError,
      );
    });

    test('validates comment, attachment, and fulfilment task contracts', () {
      final comment = ItsmComment(
        id: 'comment-1',
        workItemType: ItsmWorkItemType.incident,
        workItemId: 'incident-1',
        authorDisplayName: 'Agent',
        body: 'Please restart the device.',
        visibility: ItsmCommentVisibility.requesterVisible,
        createdAt: DateTime.utc(2026, 8, 1),
        createdBy: 'manager-1',
      );
      final attachment = ItsmAttachment(
        id: 'attachment-1',
        workItemType: ItsmWorkItemType.incident,
        workItemId: 'incident-1',
        fileName: 'evidence.pdf',
        contentType: 'application/pdf',
        sizeBytes: 1024,
        storagePath: 'incidents/incident-1/evidence.pdf',
        visibility: ItsmAttachmentVisibility.internal,
        createdAt: DateTime.utc(2026, 8, 1),
        createdBy: 'manager-1',
      );
      final task = ItsmFulfilmentTask(
        id: 'task-1',
        workItemType: ItsmWorkItemType.serviceRequest,
        workItemId: 'request-1',
        title: 'Configure laptop',
        status: ItsmTaskStatus.inProgress,
        dueAt: DateTime.utc(2026, 8, 2),
        createdAt: DateTime.utc(2026, 8, 1),
        createdBy: 'manager-1',
      );

      expect(comment.workItemId, 'incident-1');
      expect(attachment.sizeBytes, 1024);
      expect(task.isOverdueAt(DateTime.utc(2026, 8, 3)), isTrue);
      expect(
        () => ItsmFulfilmentTask(
          id: 'task-2',
          workItemType: ItsmWorkItemType.serviceRequest,
          workItemId: 'request-1',
          title: 'Deliver laptop',
          status: ItsmTaskStatus.completed,
          createdAt: DateTime.utc(2026, 8, 1),
          createdBy: 'manager-1',
        ),
        throwsArgumentError,
      );
    });
  });
}

SlaPolicy _policy({double warningThreshold = 0.8}) {
  return SlaPolicy(
    id: 'standard-request',
    name: 'Standard request',
    workItemType: ItsmWorkItemType.serviceRequest,
    version: 1,
    publicationState: ItsmPublicationState.published,
    responseTarget: const Duration(hours: 4),
    resolutionTarget: const Duration(hours: 8),
    calendar: BusinessCalendar.standardWeek(),
    warningThreshold: warningThreshold,
  );
}
