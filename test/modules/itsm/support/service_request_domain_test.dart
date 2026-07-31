import 'package:arptc_connect/modules/itsm/shared/domain/approval.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/collaboration.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_common.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/sla.dart';
import 'package:arptc_connect/modules/itsm/support/domain/support_domain.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support_test_fixtures.dart';

void main() {
  group('ServiceRequest', () {
    test('round-trips pinned versions, ownership aliases, and links', () {
      final original = fixtureRequest();
      final map = original.toFirestore();
      final restored = ServiceRequest.fromMap(original.id, map);

      expect(map['affectedUserId'], original.requestedForUserId);
      expect(restored.workflowVersion, 3);
      expect(restored.workflowRevision, 0);
      expect(restored.catalogueItemVersion, 2);
      expect(restored.slaPolicyVersion, 4);
      expect(restored.responses['title'], 'Unable to connect');
      expect(restored.lifecycleState.value, 'active');
    });

    test('requires a rejection reason and cancellation reason', () {
      expect(
        () => fixtureRequest(status: ServiceRequestStatus.rejected),
        throwsArgumentError,
      );
      expect(
        () => fixtureRequest(status: ServiceRequestStatus.cancelled),
        throwsArgumentError,
      );
      expect(
        fixtureRequest(
          status: ServiceRequestStatus.rejected,
          rejectionReason: 'Outside catalogue scope',
        ).rejectionReason,
        isNotEmpty,
      );
    });

    test('allows only declared lifecycle transitions', () {
      final submitted = fixtureRequest();
      expect(
        submitted.canTransitionTo(ServiceRequestStatus.awaitingApproval),
        isTrue,
      );
      expect(
        submitted.canTransitionTo(ServiceRequestStatus.fulfilled),
        isFalse,
      );
      final fulfilled = fixtureRequest(status: ServiceRequestStatus.fulfilled);
      expect(fulfilled.canTransitionTo(ServiceRequestStatus.closed), isTrue);
    });

    test('detects request-on-behalf records', () {
      expect(
        fixtureRequest(
          requesterId: 'manager-1',
          requestedForUserId: 'user-1',
        ).isOnBehalf,
        isTrue,
      );
    });
  });

  group('request child contracts', () {
    test('parses approval and enforces rejection comment', () {
      final approval = ServiceRequestApprovalSummary.fromMap(
        'approval-1',
        {
          'step': 1,
          'status': 'approved',
          'approverUserId': 'manager-1',
          'requestedAt': fixtureTime,
          'decision': 'approve',
        },
      );
      expect(approval.status, ApprovalStatus.approved);
      expect(approval.decision, ApprovalDecision.approve);

      expect(
        () => ServiceRequestApprovalSummary(
          id: 'approval-2',
          step: 1,
          status: ApprovalStatus.rejected,
          approverUserId: 'manager-1',
          requestedAt: fixtureTime,
        ),
        throwsArgumentError,
      );
    });

    test('preserves requester-visible comment and attachment flags', () {
      final comment = ServiceRequestComment.fromMap(
        'comment-1',
        {
          'body': 'Please confirm the model.',
          'createdByUserId': 'manager-1',
          'createdAt': fixtureTime,
          'isInternal': false,
        },
      );
      final attachment = ServiceRequestAttachment.fromMap(
        'attachment-1',
        'request-1',
        {
          'fileName': 'approval.pdf',
          'contentType': 'application/pdf',
          'sizeBytes': 100,
          'storagePath': 'itsm/serviceRequests/request-1/approval.pdf',
          'uploadedByUserId': 'user-1',
          'createdAt': fixtureTime,
          'isInternal': false,
        },
      );

      expect(comment.visibility, ItsmCommentVisibility.requesterVisible);
      expect(comment.toFirestore()['isInternal'], isFalse);
      expect(
        attachment.visibility,
        ItsmAttachmentVisibility.requesterVisible,
      );
      expect(
        attachment.toFirestore()['workItemCollection'],
        'serviceRequests',
      );
    });

    test('parses task and SLA summaries', () {
      final task = ServiceRequestTaskSummary.fromMap(
        'task-1',
        {
          'title': 'Install application',
          'status': 'in_progress',
          'createdByUserId': 'manager-1',
          'createdAt': fixtureTime,
        },
      );
      final sla = ServiceRequestSlaSummary(
        policyId: 'request-standard',
        policyVersion: 2,
        status: SlaComplianceStatus.onTrack,
        responseDueAt: fixtureTime.add(const Duration(hours: 4)),
        fulfilmentDueAt: fixtureTime.add(const Duration(days: 2)),
      );

      expect(task.status, ItsmTaskStatus.inProgress);
      expect(sla.toFirestore()['status'], 'on_track');
    });
  });

  group('cancellation and rejection guards', () {
    test('self-service cancellation requires ownership, state, and reason', () {
      final validation = ServiceRequestCancellationPolicy.validateSelfService(
        request: fixtureRequest(),
        actorUserId: 'another-user',
        reason: '',
      );
      expect(
        validation.issues,
        containsAll([
          ServiceRequestCancellationIssue.notOwner,
          ServiceRequestCancellationIssue.reasonRequired,
        ]),
      );
    });

    test('manager cannot cancel terminal or fulfilled request', () {
      final validation = ServiceRequestCancellationPolicy.validateManager(
        request: fixtureRequest(status: ServiceRequestStatus.fulfilled),
        reason: 'No longer required',
      );
      expect(
        validation.issues,
        contains(
          ServiceRequestCancellationIssue.statusDisallowsCancellation,
        ),
      );
    });

    test('only manager can reject and a reason is mandatory', () {
      expect(
        () => ServiceRequestRejectionPolicy.validate(
          actorRole: ItsmRole.user,
          request: fixtureRequest(),
          reason: 'Invalid',
        ),
        throwsStateError,
      );
      expect(
        () => ServiceRequestRejectionPolicy.validate(
          actorRole: ItsmRole.manager,
          request: fixtureRequest(),
          reason: '',
        ),
        throwsArgumentError,
      );
    });
  });
}
