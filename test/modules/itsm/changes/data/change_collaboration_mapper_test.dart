import 'package:arptc_connect/modules/itsm/changes/data/change_collaboration_mapper.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/collaboration.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_common.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const changeId = 'change-1';
  final timestamp = DateTime.utc(2026, 7, 31, 10, 30);

  test('maps a requester-visible comment to the shared contract', () {
    final comment = ChangeCollaborationMapper.comment('comment-1', changeId, {
      'body': 'Implementation window confirmed.',
      'authorDisplayName': 'Agent One',
      'visibility': 'requesterVisible',
      'createdAt': timestamp,
      'createdByUserId': 'user-1',
    });

    expect(comment.workItemType, ItsmWorkItemType.changeRequest);
    expect(comment.workItemId, changeId);
    expect(comment.body, 'Implementation window confirmed.');
    expect(comment.visibility, ItsmCommentVisibility.requesterVisible);
    expect(comment.createdAt, timestamp);
  });

  test('maps legacy internal attachments to the shared contract', () {
    final attachment = ChangeCollaborationMapper.attachment(
      'attachment-1',
      changeId,
      {
        'fileName': 'rollback.pdf',
        'contentType': 'application/pdf',
        'sizeBytes': 2048,
        'storagePath': 'itsm/changeRequests/change-1/rollback.pdf',
        'isInternal': true,
        'createdAt': timestamp,
        'uploadedByUserId': 'manager-1',
      },
    );

    expect(attachment.workItemType, ItsmWorkItemType.changeRequest);
    expect(attachment.visibility, ItsmAttachmentVisibility.internal);
    expect(attachment.fileName, 'rollback.pdf');
    expect(attachment.sizeBytes, 2048);
  });

  test('maps trusted change audit records and transition states', () {
    final event = ChangeCollaborationMapper.auditEvent('audit-1', changeId, {
      'action': 'scheduled',
      'entityType': 'change_request',
      'entityId': changeId,
      'actor': {'uid': 'manager-1', 'displayName': 'Change Manager'},
      'before': {'status': 'approved'},
      'after': {'status': 'scheduled'},
      'sourceCommand': 'schedule_change',
      'correlationId': 'correlation-1',
      'createdAt': timestamp,
    });

    expect(event.actorUserId, 'manager-1');
    expect(event.actorDisplayName, 'Change Manager');
    expect(event.fromState, 'approved');
    expect(event.toState, 'scheduled');
    expect(event.representsTransition, isTrue);
  });
}
