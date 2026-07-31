import 'dart:collection';
import 'dart:typed_data';

import '../../shared/data/trusted_command_gateways.dart';
import '../domain/knowledge_domain.dart';

class KnowledgeDraftInput {
  KnowledgeDraftInput({
    required this.categoryId,
    required this.title,
    required this.summary,
    required this.content,
    required this.languageCode,
    this.visibility = KnowledgeVisibility.employee,
    this.isFeatured = false,
    Iterable<String> relatedServiceIds = const [],
    Iterable<String> relatedCatalogueItemIds = const [],
    Iterable<String> relatedIncidentCategoryIds = const [],
    Iterable<KnowledgeDraftAttachment> attachments = const [],
  })  : relatedServiceIds = _normalizedIds(relatedServiceIds),
        relatedCatalogueItemIds = _normalizedIds(relatedCatalogueItemIds),
        relatedIncidentCategoryIds = _normalizedIds(relatedIncidentCategoryIds),
        attachments = List<KnowledgeDraftAttachment>.unmodifiable(attachments) {
    _require(categoryId, 'categoryId');
    _require(title, 'title');
    _require(content, 'content');
    _require(languageCode, 'languageCode');
  }

  final String categoryId;
  final String title;
  final String summary;
  final String content;
  final String languageCode;
  final KnowledgeVisibility visibility;
  final bool isFeatured;
  final Set<String> relatedServiceIds;
  final Set<String> relatedCatalogueItemIds;
  final Set<String> relatedIncidentCategoryIds;
  final List<KnowledgeDraftAttachment> attachments;

  Map<String, Object?> toPrimitiveMap() => {
        'categoryId': categoryId.trim(),
        'title': title.trim(),
        'summary': summary.trim(),
        'content': content.trim(),
        'languageCode': languageCode.trim().toLowerCase(),
        'visibility': visibility.value,
        'isFeatured': isFeatured,
        'relatedServiceIds': relatedServiceIds.toList(growable: false),
        'relatedCatalogueItemIds':
            relatedCatalogueItemIds.toList(growable: false),
        'relatedIncidentCategoryIds':
            relatedIncidentCategoryIds.toList(growable: false),
      };
}

class KnowledgeDraftAttachment {
  KnowledgeDraftAttachment({
    required String id,
    required String fileName,
    required String contentType,
    required Uint8List bytes,
    this.isInternal = false,
  })  : id = id.trim(),
        fileName = fileName.trim(),
        contentType = contentType.trim().toLowerCase(),
        bytes = Uint8List.fromList(bytes) {
    _require(this.id, 'id');
    _require(this.fileName, 'fileName');
    _require(this.contentType, 'contentType');
    if (this.bytes.isEmpty || this.bytes.length > maximumSizeBytes) {
      throw RangeError.range(
        this.bytes.length,
        1,
        maximumSizeBytes,
        'bytes.length',
      );
    }
  }

  static const maximumSizeBytes = 20 * 1024 * 1024;

  final String id;
  final String fileName;
  final String contentType;
  final Uint8List bytes;
  final bool isInternal;

  int get sizeBytes => bytes.length;
}

class KnowledgeAttachmentUpload {
  KnowledgeAttachmentUpload({
    required this.articleId,
    required this.versionId,
    required this.actorUserId,
    required this.attachment,
  }) {
    _require(articleId, 'articleId');
    _require(versionId, 'versionId');
    _require(actorUserId, 'actorUserId');
  }

  final String articleId;
  final String versionId;
  final String actorUserId;
  final KnowledgeDraftAttachment attachment;

  String get storagePath =>
      'itsm/knowledgeArticles/${articleId.trim()}/versions/'
      '${versionId.trim()}/attachments/${attachment.id}/'
      '${attachment.fileName.replaceAll(RegExp(r'[/\\]'), '_')}';

  Map<String, String> get customMetadata => {
        'articleId': articleId.trim(),
        'versionId': versionId.trim(),
        'attachmentId': attachment.id,
        'uploadedByUserId': actorUserId.trim(),
        'isInternal': attachment.isInternal.toString(),
      };
}

abstract interface class KnowledgeAttachmentUploader {
  Future<void> upload(KnowledgeAttachmentUpload upload);
}

abstract interface class KnowledgeAttachmentRegistrationProbe {
  Future<bool> isRegistered({
    required String articleId,
    required String versionId,
    required String attachmentId,
  });
}

typedef KnowledgeAttachmentDelay = Future<void> Function(Duration duration);

class KnowledgeAttachmentUploadException extends KnowledgeGatewayException {
  const KnowledgeAttachmentUploadException({
    required this.attachmentId,
    required String message,
  }) : super(message);

  final String attachmentId;
}

class KnowledgeAttachmentRegistrationTimeoutException
    extends KnowledgeGatewayException {
  const KnowledgeAttachmentRegistrationTimeoutException({
    required this.articleId,
    required this.attachmentId,
  }) : super(
          'Attachment $attachmentId was not registered for article '
          '$articleId in time.',
        );

  final String articleId;
  final String attachmentId;
}

class SaveKnowledgeDraftCommand {
  SaveKnowledgeDraftCommand({
    required this.context,
    required this.input,
    this.articleId = '',
    this.expectedState,
    this.expectedVersionNumber,
  }) {
    final versionNumber = expectedVersionNumber;
    if (versionNumber != null && versionNumber < 1) {
      throw RangeError.range(
        versionNumber,
        1,
        null,
        'expectedVersionNumber',
      );
    }
  }

  final ItsmCommandContext context;
  final KnowledgeDraftInput input;
  final String articleId;
  final KnowledgeArticleState? expectedState;
  final int? expectedVersionNumber;

  bool get createsArticle => articleId.trim().isEmpty;
}

class KnowledgeLifecycleCommand {
  KnowledgeLifecycleCommand({
    required this.context,
    required this.article,
    required this.version,
    required this.action,
    this.reason = '',
  }) {
    if (action == KnowledgeTransitionAction.rejectToDraft &&
        reason.trim().isEmpty) {
      throw ArgumentError.value(
        reason,
        'reason',
        'A rejection reason is required.',
      );
    }
  }

  final ItsmCommandContext context;
  final KnowledgeArticle article;
  final KnowledgeArticleVersion version;
  final KnowledgeTransitionAction action;
  final String reason;
}

class KnowledgeFeedbackCommand {
  const KnowledgeFeedbackCommand({
    required this.context,
    required this.article,
    required this.helpful,
    this.comment = '',
  });

  final ItsmCommandContext context;
  final KnowledgeArticle article;
  final bool helpful;
  final String comment;
}

class KnowledgeViewCommand {
  const KnowledgeViewCommand({
    required this.context,
    required this.article,
  });

  final ItsmCommandContext context;
  final KnowledgeArticle article;
}

class KnowledgeCommandReceipt extends ItsmCommandReceipt {
  const KnowledgeCommandReceipt({
    required super.commandId,
    required super.acceptedAt,
    required super.wasDuplicate,
    this.articleId = '',
    this.versionNumber,
    this.state = '',
    this.recorded = false,
    this.helpful,
  });

  final String articleId;
  final int? versionNumber;
  final String state;
  final bool recorded;
  final bool? helpful;
}

abstract interface class KnowledgeCommandGateway {
  Future<KnowledgeCommandReceipt> recordView(KnowledgeViewCommand command);

  Future<KnowledgeCommandReceipt> submitFeedback(
    KnowledgeFeedbackCommand command,
  );

  Future<KnowledgeCommandReceipt> saveDraft(
    SaveKnowledgeDraftCommand command,
  );

  Future<KnowledgeCommandReceipt> transition(
    KnowledgeLifecycleCommand command,
  );
}

class KnowledgeGatewayException implements Exception {
  const KnowledgeGatewayException(this.message);

  final String message;

  @override
  String toString() => 'KnowledgeGatewayException($message)';
}

Set<String> _normalizedIds(Iterable<String> values) {
  return UnmodifiableSetView(
    values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet(),
  );
}

void _require(String value, String field) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, field, 'A non-empty value is required.');
  }
}
