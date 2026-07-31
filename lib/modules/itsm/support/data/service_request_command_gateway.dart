import 'dart:collection';
import 'dart:typed_data';

import '../../shared/data/trusted_command_gateways.dart';
import '../../shared/domain/approval.dart';
import '../../shared/domain/collaboration.dart';
import '../domain/support_domain.dart';

class ServiceRequestTargetUser {
  ServiceRequestTargetUser({
    required this.userId,
    required this.name,
    required this.email,
    this.departmentId,
    this.departmentName,
    this.serviceId,
    this.serviceName,
  }) {
    supportRequire(userId, 'userId');
    supportRequire(email, 'email');
  }

  final String userId;
  final String name;
  final String email;
  final String? departmentId;
  final String? departmentName;
  final String? serviceId;
  final String? serviceName;

  Map<String, Object?> toPrimitiveMap() => {
        'userId': userId.trim(),
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        if (departmentId != null) 'departmentId': departmentId!.trim(),
        if (departmentName != null) 'departmentName': departmentName!.trim(),
        if (serviceId != null) 'serviceId': serviceId!.trim(),
        if (serviceName != null) 'serviceName': serviceName!.trim(),
      };
}

class ServiceRequestSubmissionDocument {
  ServiceRequestSubmissionDocument({
    required this.requirementId,
    required this.attachmentId,
    required this.fileName,
    required this.contentType,
    required Uint8List bytes,
  }) : bytes = Uint8List.fromList(bytes) {
    for (final entry in {
      'requirementId': requirementId,
      'attachmentId': attachmentId,
      'fileName': fileName,
      'contentType': contentType,
    }.entries) {
      supportRequire(entry.value, entry.key);
    }
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

  final String requirementId;
  final String attachmentId;
  final String fileName;
  final String contentType;
  final Uint8List bytes;

  int get sizeBytes => bytes.length;

  Map<String, Object?> toPrimitiveMap() => {
        'requirementId': requirementId.trim(),
        'attachmentId': attachmentId.trim(),
        'fileName': fileName.trim(),
        'contentType': contentType.trim().toLowerCase(),
        'sizeBytes': sizeBytes,
      };

  SubmittedDocument toSubmittedDocument() => SubmittedDocument(
        requirementKey: requirementId,
        contentType: contentType,
      );
}

class ServiceRequestDraftReceipt {
  const ServiceRequestDraftReceipt({
    required this.command,
    required this.requestId,
    required this.requestNumber,
    required this.status,
    required this.uploadPath,
  });

  final ItsmCommandReceipt command;
  final String requestId;
  final String requestNumber;
  final ServiceRequestStatus status;
  final String uploadPath;
}

class ServiceRequestAttachmentUpload {
  ServiceRequestAttachmentUpload({
    required this.requestId,
    required this.actorUserId,
    required this.document,
  }) {
    supportRequire(requestId, 'requestId');
    supportRequire(actorUserId, 'actorUserId');
  }

  final String requestId;
  final String actorUserId;
  final ServiceRequestSubmissionDocument document;

  String get storagePath =>
      'itsm/serviceRequests/${requestId.trim()}/attachments/'
      '${document.attachmentId.trim()}/${_safeFileName(document.fileName)}';

  Map<String, String> get customMetadata => {
        'workItemCollection': 'serviceRequests',
        'workItemId': requestId.trim(),
        'attachmentId': document.attachmentId.trim(),
        'uploadedByUserId': actorUserId.trim(),
        'documentRequirementKey': document.requirementId.trim(),
        'isInternal': 'false',
      };

  static String _safeFileName(String value) {
    return value.trim().replaceAll(RegExp(r'[/\\]'), '_');
  }
}

abstract interface class ServiceRequestAttachmentUploader {
  Future<void> upload(ServiceRequestAttachmentUpload upload);
}

abstract interface class ServiceRequestAttachmentRegistrationProbe {
  Future<bool> isRegistered({
    required String requestId,
    required String attachmentId,
  });
}

class ServiceRequestSubmissionReceipt {
  const ServiceRequestSubmissionReceipt({
    required this.command,
    required this.requestId,
    required this.requestNumber,
    required this.status,
    required this.workflowDefinitionId,
    required this.workflowVersion,
    required this.slaPolicyId,
    required this.slaPolicyVersion,
  });

  final ItsmCommandReceipt command;
  final String requestId;
  final String requestNumber;
  final ServiceRequestStatus status;
  final String workflowDefinitionId;
  final int workflowVersion;
  final String slaPolicyId;
  final int slaPolicyVersion;
}

class CreateServiceRequestCommand {
  CreateServiceRequestCommand({
    required this.context,
    required this.clientRequestId,
    required this.catalogueItem,
    required this.requestedFor,
    required this.title,
    required this.description,
    Map<String, Object?> responses = const {},
    Iterable<ServiceRequestSubmissionDocument> documents = const [],
  })  : responses = UnmodifiableMapView(Map<String, Object?>.from(responses)),
        documents = List<ServiceRequestSubmissionDocument>.unmodifiable(
          documents,
        ) {
    supportRequire(clientRequestId, 'clientRequestId');
    supportRequire(title, 'title');
  }

  final ItsmCommandContext context;
  final String clientRequestId;
  final ServiceCatalogueItem catalogueItem;
  final ServiceRequestTargetUser requestedFor;
  final String title;
  final String description;
  final Map<String, Object?> responses;
  final List<ServiceRequestSubmissionDocument> documents;
}

class TransitionServiceRequestCommand {
  TransitionServiceRequestCommand({
    required this.context,
    required this.request,
    required this.transitionId,
    required this.targetStatus,
    this.reason = '',
    Map<String, Object?> fields = const {},
  }) : fields = UnmodifiableMapView(Map<String, Object?>.from(fields)) {
    supportRequire(transitionId, 'transitionId');
    if (!request.canTransitionTo(targetStatus)) {
      throw StateError(
        '${request.status.value} cannot transition to ${targetStatus.value}.',
      );
    }
  }

  final ItsmCommandContext context;
  final ServiceRequest request;
  final String transitionId;
  final ServiceRequestStatus targetStatus;
  final String reason;
  final Map<String, Object?> fields;
}

class DecideServiceRequestApprovalCommand {
  DecideServiceRequestApprovalCommand({
    required this.context,
    required this.requestId,
    required this.approvalId,
    required this.decision,
    this.comment = '',
  }) {
    supportRequire(requestId, 'requestId');
    supportRequire(approvalId, 'approvalId');
    if (decision == ApprovalDecision.reject && comment.trim().isEmpty) {
      throw ArgumentError('A rejected approval requires a comment.');
    }
  }

  final ItsmCommandContext context;
  final String requestId;
  final String approvalId;
  final ApprovalDecision decision;
  final String comment;
}

class AssignServiceRequestCommand {
  AssignServiceRequestCommand({
    required this.context,
    required this.requestId,
    required this.expectedRevision,
    required this.assignedUserId,
    required this.assignedUserName,
    required this.assignedUserEmail,
  }) {
    for (final entry in {
      'requestId': requestId,
      'assignedUserId': assignedUserId,
      'assignedUserName': assignedUserName,
      'assignedUserEmail': assignedUserEmail,
    }.entries) {
      supportRequire(entry.value, entry.key);
    }
    if (expectedRevision < 0) {
      throw RangeError.value(expectedRevision, 'expectedRevision');
    }
  }

  final ItsmCommandContext context;
  final String requestId;
  final int expectedRevision;
  final String assignedUserId;
  final String assignedUserName;
  final String assignedUserEmail;
}

class UpdateServiceRequestTaskCommand {
  UpdateServiceRequestTaskCommand({
    required this.context,
    required this.requestId,
    required this.taskId,
    required this.status,
    this.comment = '',
  }) {
    supportRequire(requestId, 'requestId');
    supportRequire(taskId, 'taskId');
  }

  final ItsmCommandContext context;
  final String requestId;
  final String taskId;
  final ItsmTaskStatus status;
  final String comment;
}

class AddServiceRequestCommentCommand {
  AddServiceRequestCommentCommand({
    required this.context,
    required this.requestId,
    required this.body,
    required this.visibility,
  }) {
    supportRequire(requestId, 'requestId');
    supportRequire(body, 'body');
  }

  final ItsmCommandContext context;
  final String requestId;
  final String body;
  final ItsmCommentVisibility visibility;
}

class LinkServiceRequestRecordCommand {
  LinkServiceRequestRecordCommand({
    required this.context,
    required this.requestId,
    required this.record,
  }) {
    supportRequire(requestId, 'requestId');
  }

  final ItsmCommandContext context;
  final String requestId;
  final ServiceRequestLinkSummary record;
}

abstract interface class ServiceRequestCommandGateway {
  Future<ServiceRequestSubmissionReceipt> create(
    CreateServiceRequestCommand command,
  );

  Future<ItsmCommandReceipt> transition(
    TransitionServiceRequestCommand command,
  );

  Future<ItsmCommandReceipt> decideApproval(
    DecideServiceRequestApprovalCommand command,
  );

  Future<ItsmCommandReceipt> assign(AssignServiceRequestCommand command);

  Future<ItsmCommandReceipt> updateTask(
    UpdateServiceRequestTaskCommand command,
  );

  Future<ItsmCommandReceipt> addComment(
    AddServiceRequestCommentCommand command,
  );

  Future<ItsmCommandReceipt> linkRecord(
    LinkServiceRequestRecordCommand command,
  );
}

abstract interface class CallableInvoker {
  Future<Object?> invoke(
    String functionName,
    Map<String, Object?> payload,
  );
}

typedef ServiceRequestDelay = Future<void> Function(Duration duration);

class ServiceRequestGatewayException implements Exception {
  const ServiceRequestGatewayException(this.message);

  final String message;

  @override
  String toString() => 'ServiceRequestGatewayException($message)';
}

class ServiceRequestAttachmentRegistrationTimeoutException
    extends ServiceRequestGatewayException {
  const ServiceRequestAttachmentRegistrationTimeoutException({
    required this.requestId,
    required this.attachmentId,
  }) : super(
          'Attachment $attachmentId was not registered for request '
          '$requestId in time.',
        );

  final String requestId;
  final String attachmentId;
}

class ServiceRequestAttachmentUploadException
    extends ServiceRequestGatewayException {
  const ServiceRequestAttachmentUploadException({
    required this.attachmentId,
    required String message,
  }) : super(message);

  final String attachmentId;
}
