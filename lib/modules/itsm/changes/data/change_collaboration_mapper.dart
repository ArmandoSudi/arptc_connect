import '../../shared/domain/collaboration.dart';
import '../../shared/domain/itsm_audit_event.dart';
import '../../shared/domain/itsm_common.dart';
import '../domain/change_serialization.dart';

class ChangeCollaborationMapper {
  const ChangeCollaborationMapper._();

  static ItsmComment comment(
    String id,
    String changeId,
    Map<String, Object?> data,
  ) {
    final author = changeMapFromValue(data['author']);
    return ItsmComment(
      id: id,
      workItemType: ItsmWorkItemType.changeRequest,
      workItemId: changeId,
      authorDisplayName: changeString(
        data['authorDisplayName'] ?? author['displayName'] ?? author['name'],
        'Unknown user',
      ),
      body: changeString(data['body'] ?? data['content'], 'Unavailable'),
      visibility: commentVisibility(data),
      createdAt: _date(data['createdAt']),
      createdBy: changeString(
        data['createdByUserId'] ??
            data['createdBy'] ??
            data['authorUserId'] ??
            author['userId'],
        'unknown',
      ),
      editedAt: changeDateFromValue(data['editedAt']),
    );
  }

  static ItsmAttachment attachment(
    String id,
    String changeId,
    Map<String, Object?> data,
  ) {
    final fileName = changeString(data['fileName'] ?? data['name'], 'file');
    return ItsmAttachment(
      id: id,
      workItemType: ItsmWorkItemType.changeRequest,
      workItemId: changeId,
      fileName: fileName,
      contentType: changeString(
        data['contentType'] ?? data['mimeType'],
        'application/octet-stream',
      ),
      sizeBytes: changeInt(data['sizeBytes'] ?? data['size']),
      storagePath: changeString(
        data['storagePath'],
        'itsm/changeRequests/$changeId/attachments/$id/$fileName',
      ),
      downloadUrl: changeNullableString(data['downloadUrl']),
      checksum: changeNullableString(data['checksum']),
      visibility: attachmentVisibility(data),
      createdAt: _date(data['createdAt'] ?? data['uploadedAt']),
      createdBy: changeString(
        data['uploadedByUserId'] ??
            data['createdByUserId'] ??
            data['createdBy'],
        'unknown',
      ),
    );
  }

  static ItsmAuditEvent auditEvent(
    String id,
    String changeId,
    Map<String, Object?> data,
  ) {
    final actor = changeMapFromValue(data['actor']);
    final before = changeMapFromValue(
      data['before'] ?? data['previousValues'],
    );
    final after = changeMapFromValue(data['after'] ?? data['newValues']);
    final action = changeString(data['action'] ?? data['eventType'], 'updated');
    return ItsmAuditEvent(
      id: id,
      actorUserId: changeString(
        data['actorUserId'] ?? actor['uid'] ?? actor['userId'],
        'system',
      ),
      actorDisplayName: changeString(
        data['actorDisplayName'] ?? actor['displayName'] ?? actor['name'],
        'System',
      ),
      action: action,
      targetEntityType: changeString(
        data['entityType'] ?? data['targetEntityType'],
        'change_request',
      ),
      targetEntityId: changeString(
        data['entityId'] ?? data['targetEntityId'],
        changeId,
      ),
      targetReference: changeNullableString(data['targetReference']),
      occurredAt: _date(data['occurredAt'] ?? data['createdAt']),
      previousValues: before,
      newValues: after,
      comment: changeNullableString(data['comment']),
      fromState: changeNullableString(data['fromState'] ?? before['status']),
      toState: changeNullableString(data['toState'] ?? after['status']),
      correlationId: changeString(
        data['correlationId'] ?? data['sourceIdempotencyKey'],
        id,
      ),
      source: changeString(data['source'] ?? data['sourceCommand'], 'system'),
      module: changeString(data['module'], 'itsm'),
      departmentId: changeNullableString(data['departmentId']),
    );
  }

  static ItsmCommentVisibility commentVisibility(Map<String, Object?> data) {
    final value = _visibility(data);
    return switch (value) {
      'internal' => ItsmCommentVisibility.internal,
      'restricted' => ItsmCommentVisibility.restricted,
      _ => ItsmCommentVisibility.requesterVisible,
    };
  }

  static ItsmAttachmentVisibility attachmentVisibility(
    Map<String, Object?> data,
  ) {
    final value = _visibility(data);
    return switch (value) {
      'internal' => ItsmAttachmentVisibility.internal,
      'restricted' => ItsmAttachmentVisibility.restricted,
      _ => ItsmAttachmentVisibility.requesterVisible,
    };
  }

  static String _visibility(Map<String, Object?> data) {
    final explicit =
        changeString(data['visibility']).toLowerCase().replaceAll('-', '_');
    if (explicit == 'internal' || explicit == 'restricted') return explicit;
    if (explicit == 'requestervisible' ||
        explicit == 'requester_visible' ||
        explicit == 'public') {
      return 'requester_visible';
    }
    return data['isInternal'] == true ? 'internal' : 'requester_visible';
  }

  static DateTime _date(Object? value) =>
      changeDateFromValue(value) ??
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}
