import 'itsm_common.dart';

abstract interface class ItsmWorkItemSubresource {
  String get id;
  ItsmWorkItemType get workItemType;
  String get workItemId;
  DateTime get createdAt;
  String get createdBy;
}

enum ItsmCommentVisibility { requesterVisible, internal, restricted }

class ItsmComment implements ItsmWorkItemSubresource {
  ItsmComment({
    required this.id,
    required this.workItemType,
    required this.workItemId,
    required this.authorDisplayName,
    required this.body,
    required this.visibility,
    required this.createdAt,
    required this.createdBy,
    this.editedAt,
  }) {
    _requireNonEmpty(id, 'id');
    _requireNonEmpty(workItemId, 'workItemId');
    _requireNonEmpty(body, 'body');
    _requireNonEmpty(createdBy, 'createdBy');
  }

  @override
  final String id;
  @override
  final ItsmWorkItemType workItemType;
  @override
  final String workItemId;
  final String authorDisplayName;
  final String body;
  final ItsmCommentVisibility visibility;
  @override
  final DateTime createdAt;
  @override
  final String createdBy;
  final DateTime? editedAt;

  bool get isEdited => editedAt != null;
}

enum ItsmAttachmentVisibility { requesterVisible, internal, restricted }

class ItsmAttachment implements ItsmWorkItemSubresource {
  ItsmAttachment({
    required this.id,
    required this.workItemType,
    required this.workItemId,
    required this.fileName,
    required this.contentType,
    required this.sizeBytes,
    required this.storagePath,
    required this.visibility,
    required this.createdAt,
    required this.createdBy,
    this.downloadUrl,
    this.checksum,
  }) {
    _requireNonEmpty(id, 'id');
    _requireNonEmpty(workItemId, 'workItemId');
    _requireNonEmpty(fileName, 'fileName');
    _requireNonEmpty(contentType, 'contentType');
    _requireNonEmpty(storagePath, 'storagePath');
    _requireNonEmpty(createdBy, 'createdBy');
    if (sizeBytes < 0) throw RangeError.value(sizeBytes, 'sizeBytes');
  }

  @override
  final String id;
  @override
  final ItsmWorkItemType workItemType;
  @override
  final String workItemId;
  final String fileName;
  final String contentType;
  final int sizeBytes;
  final String storagePath;
  final String? downloadUrl;
  final String? checksum;
  final ItsmAttachmentVisibility visibility;
  @override
  final DateTime createdAt;
  @override
  final String createdBy;
}

enum ItsmTaskStatus { pending, inProgress, completed, cancelled }

class ItsmFulfilmentTask implements ItsmWorkItemSubresource {
  ItsmFulfilmentTask({
    required this.id,
    required this.workItemType,
    required this.workItemId,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.createdBy,
    this.description = '',
    this.assignedGroupId,
    this.assignedUserId,
    this.dueAt,
    this.completedAt,
    this.completedBy,
  }) {
    _requireNonEmpty(id, 'id');
    _requireNonEmpty(workItemId, 'workItemId');
    _requireNonEmpty(title, 'title');
    _requireNonEmpty(createdBy, 'createdBy');
    if (status == ItsmTaskStatus.completed &&
        (completedAt == null || completedBy?.trim().isEmpty != false)) {
      throw ArgumentError(
        'Completed tasks require completion time and actor.',
      );
    }
  }

  @override
  final String id;
  @override
  final ItsmWorkItemType workItemType;
  @override
  final String workItemId;
  final String title;
  final String description;
  final ItsmTaskStatus status;
  final String? assignedGroupId;
  final String? assignedUserId;
  final DateTime? dueAt;
  final DateTime? completedAt;
  final String? completedBy;
  @override
  final DateTime createdAt;
  @override
  final String createdBy;

  bool isOverdueAt(DateTime now) {
    final dueDate = dueAt;
    return dueDate != null &&
        status != ItsmTaskStatus.completed &&
        status != ItsmTaskStatus.cancelled &&
        now.isAfter(dueDate);
  }
}

void _requireNonEmpty(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, 'A non-empty value is required.');
  }
}
