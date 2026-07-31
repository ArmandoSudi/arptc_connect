import 'package:arptc_connect/modules/incident_management/domain/incident_attachment.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_audit_log.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_comment.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_enums.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_ticket.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('incident ticket Firestore compatibility', () {
    test('parses a complete existing incident document without renaming fields',
        () {
      final createdAt = DateTime.utc(2026, 7, 1, 8);
      final ticket = IncidentTicket.fromMap(
        id: 'ticket-1',
        data: {
          'ticketNumber': ' INC-001 ',
          'title': ' Email unavailable ',
          'description': ' Cannot send email ',
          'status': 'IN_PROGRESS',
          'lifecycleState': 'ACTIVE',
          'createdByUserId': 'creator-1',
          'createdByName': 'Creator',
          'createdByEmail': 'creator@arptc.cd',
          'createdByDepartmentId': 'department-1',
          'createdByDepartmentName': 'Finance',
          'createdByServiceId': 'service-1',
          'createdByServiceName': 'Accounting',
          'affectedUserId': 'affected-1',
          'affectedUserName': 'Affected Agent',
          'affectedUserEmail': 'affected@arptc.cd',
          'affectedServiceId': 'email',
          'affectedServiceName': 'Professional Email',
          'location': 'Head office',
          'deviceType': 'Laptop',
          'assetId': 'asset-1',
          'configurationItemId': 'ci-1',
          'relatedServiceRequestId': 'request-1',
          'relatedChangeId': 'change-1',
          'suggestedKnowledgeArticleIds': [
            'article-1',
            '',
            'article-2',
          ],
          'userImpactDescription': 'Work is blocked',
          'isBlocking': 'true',
          'categoryId': 'messaging',
          'categoryName': 'Messaging',
          'subcategoryId': 'send',
          'subcategoryName': 'Sending',
          'impact': 'high',
          'urgency': 'medium',
          'priority': 'high',
          'assignedToUserId': 'manager-1',
          'assignedToName': 'Manager',
          'assignedToEmail': 'manager@arptc.cd',
          'resolutionSummary': '',
          'resolutionCode': '',
          'closedByUserId': '',
          'closedByName': '',
          'createdAt': Timestamp.fromDate(createdAt),
          'updatedAt': createdAt.toIso8601String(),
          'attachmentCount': '2',
          'commentCount': 3.0,
          'isDeleted': false,
        },
      );

      expect(ticket.id, 'ticket-1');
      expect(ticket.ticketNumber, 'INC-001');
      expect(ticket.title, 'Email unavailable');
      expect(ticket.status, IncidentStatus.inProgress.value);
      expect(ticket.lifecycleState, IncidentLifecycleState.active.value);
      expect(ticket.priority, IncidentPriority.p2.value);
      expect(ticket.isBlocking, isTrue);
      expect(ticket.createdAt?.toUtc(), createdAt);
      expect(ticket.updatedAt?.toUtc(), createdAt);
      expect(ticket.attachmentCount, 2);
      expect(ticket.commentCount, 3);
      expect(ticket.configurationItemId, 'ci-1');
      expect(ticket.relatedServiceRequestId, 'request-1');
      expect(ticket.relatedChangeId, 'change-1');
      expect(
        ticket.suggestedKnowledgeArticleIds,
        ['article-1', 'article-2'],
      );
    });

    test('missing additive fields retain safe defaults for legacy documents',
        () {
      final ticket = IncidentTicket.fromMap(
        id: 'legacy-ticket',
        data: {
          'ticketNumber': 'INC-LEGACY',
          'title': 'Legacy incident',
        },
      );

      expect(ticket.id, 'legacy-ticket');
      expect(ticket.status, IncidentStatus.open.value);
      expect(ticket.lifecycleState, IncidentLifecycleState.active.value);
      expect(ticket.priority, isEmpty);
      expect(ticket.createdByDepartmentId, isEmpty);
      expect(ticket.archiveEligibleAt, isNull);
      expect(ticket.attachmentCount, 0);
      expect(ticket.commentCount, 0);
      expect(ticket.isDeleted, isFalse);
      expect(ticket.configurationItemId, isEmpty);
      expect(ticket.relatedServiceRequestId, isEmpty);
      expect(ticket.relatedChangeId, isEmpty);
      expect(ticket.suggestedKnowledgeArticleIds, isEmpty);
    });

    test('serialization keeps the established authoritative field names', () {
      final fields = IncidentTicket.empty()
          .copyWith(
            ticketNumber: ' INC-002 ',
            title: ' Test ',
            priority: 'critical',
          )
          .toFirestore();

      expect(
        fields.keys.toSet(),
        containsAll({
          'ticketNumber',
          'title',
          'description',
          'status',
          'lifecycleState',
          'createdByUserId',
          'affectedUserId',
          'categoryId',
          'impact',
          'urgency',
          'priority',
          'assignedToUserId',
          'resolutionSummary',
          'resolutionCode',
          'closedAt',
          'archivedAt',
          'archiveEligibleAt',
          'createdAt',
          'updatedAt',
          'lastCommentAt',
          'lastStatusChangedAt',
          'attachmentCount',
          'commentCount',
          'isDeleted',
          'configurationItemId',
          'relatedServiceRequestId',
          'relatedChangeId',
          'suggestedKnowledgeArticleIds',
        }),
      );
      expect(fields['ticketNumber'], 'INC-002');
      expect(fields['title'], 'Test');
      expect(fields['priority'], 'P1');
    });
  });

  group('incident subcollection compatibility', () {
    test('comments preserve public/internal and actor fields', () {
      final comment = IncidentComment.fromMap(
        id: 'comment-1',
        data: {
          'body': ' Internal note ',
          'createdByUserId': 'manager-1',
          'createdByName': 'Manager',
          'createdByRole': 'MANAGER',
          'isInternal': true,
          'createdAt': '2026-07-01T08:00:00.000Z',
        },
        ticketId: 'ticket-1',
      );

      expect(comment.ticketId, 'ticket-1');
      expect(comment.body, 'Internal note');
      expect(comment.isInternal, isTrue);
      expect(comment.createdByRole, 'MANAGER');
    });

    test('attachments accept numeric strings and preserve parent ticket ID',
        () {
      final attachment = IncidentAttachment.fromMap(
        id: 'attachment-1',
        data: {
          'fileName': ' evidence.pdf ',
          'fileUrl': 'https://example.test/evidence.pdf',
          'contentType': 'application/pdf',
          'sizeBytes': '2048',
          'uploadedByUserId': 'agent-1',
          'uploadedByName': 'Agent',
        },
        ticketId: 'ticket-1',
      );

      expect(attachment.ticketId, 'ticket-1');
      expect(attachment.fileName, 'evidence.pdf');
      expect(attachment.sizeBytes, 2048);
    });

    test('audit logs tolerate absent or malformed changes maps', () {
      final audit = IncidentAuditLog.fromMap(
        id: 'audit-1',
        data: {
          'action': 'created',
          'message': 'Created',
          'actorUserId': 'agent-1',
          'actorName': 'Agent',
          'actorRole': 'USER',
          'changes': 'legacy-value',
        },
        ticketId: 'ticket-1',
      );

      expect(audit.ticketId, 'ticket-1');
      expect(audit.changes, isEmpty);
    });
  });
}
