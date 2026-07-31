import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../shared/data/trusted_command_gateways.dart';
import '../../shared/domain/approval.dart';
import '../../shared/domain/collaboration.dart';
import '../domain/support_domain.dart';
import 'service_request_command_gateway.dart';

class FirebaseCallableInvoker implements CallableInvoker {
  const FirebaseCallableInvoker(this._functions);

  final FirebaseFunctions _functions;

  @override
  Future<Object?> invoke(
    String functionName,
    Map<String, Object?> payload,
  ) async {
    final result = await _functions.httpsCallable(functionName).call(payload);
    return result.data;
  }
}

class FirebaseServiceRequestAttachmentUploader
    implements ServiceRequestAttachmentUploader {
  FirebaseServiceRequestAttachmentUploader(this._storage);

  final FirebaseStorage _storage;

  @override
  Future<void> upload(ServiceRequestAttachmentUpload upload) async {
    await _storage.ref(upload.storagePath).putData(
          upload.document.bytes,
          SettableMetadata(
            contentType: upload.document.contentType,
            customMetadata: upload.customMetadata,
          ),
        );
  }
}

class FirestoreServiceRequestAttachmentRegistrationProbe
    implements ServiceRequestAttachmentRegistrationProbe {
  FirestoreServiceRequestAttachmentRegistrationProbe(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<bool> isRegistered({
    required String requestId,
    required String attachmentId,
  }) async {
    final snapshot = await _firestore
        .collection('serviceRequests')
        .doc(requestId)
        .collection('attachments')
        .doc(attachmentId)
        .get(const GetOptions(source: Source.server));
    return snapshot.exists;
  }
}

class FirebaseServiceRequestCommandGateway
    implements ServiceRequestCommandGateway {
  FirebaseServiceRequestCommandGateway(
    this._invoker, {
    ServiceRequestAttachmentUploader? attachmentUploader,
    ServiceRequestAttachmentRegistrationProbe? registrationProbe,
    ServiceRequestDelay? delay,
    this.registrationAttempts = 12,
    this.registrationPollInterval = const Duration(milliseconds: 500),
  })  : _attachmentUploader = attachmentUploader ??
            FirebaseServiceRequestAttachmentUploader(FirebaseStorage.instance),
        _registrationProbe = registrationProbe ??
            FirestoreServiceRequestAttachmentRegistrationProbe(
              FirebaseFirestore.instance,
            ),
        _delay = delay ?? Future<void>.delayed {
    if (registrationAttempts < 1) {
      throw RangeError.value(
        registrationAttempts,
        'registrationAttempts',
        'At least one registration attempt is required.',
      );
    }
  }

  static const initializeDraftFunctionName =
      'itsmInitializeServiceRequestDraft';
  static const submitFunctionName = 'itsmSubmitServiceRequest';
  static const transitionFunctionName = 'itsmTransitionWorkItem';
  static const decideApprovalFunctionName = 'itsmDecideApproval';
  static const assignFunctionName = 'itsmAssignServiceRequest';
  static const updateTaskFunctionName = 'itsmUpdateServiceRequestTask';
  static const addCommentFunctionName = 'itsmAddServiceRequestComment';
  static const linkRecordFunctionName = 'itsmLinkServiceRequestRecord';

  final CallableInvoker _invoker;
  final ServiceRequestAttachmentUploader _attachmentUploader;
  final ServiceRequestAttachmentRegistrationProbe _registrationProbe;
  final ServiceRequestDelay _delay;
  final int registrationAttempts;
  final Duration registrationPollInterval;

  @override
  Future<ServiceRequestSubmissionReceipt> create(
    CreateServiceRequestCommand command,
  ) async {
    final draftResult = await _invoker.invoke(
      initializeDraftFunctionName,
      {
        'command': 'service_request.initialize_draft',
        'idempotencyKey': _stageKey(
          command.context.idempotencyKey,
          'draft',
        ),
        'payload': {
          'catalogueItemId': command.catalogueItem.id,
          'requestedForUserId': command.requestedFor.userId,
          'title': command.title.trim(),
          'description': command.description.trim(),
          'responses': command.responses,
        },
      },
    );
    final draft = _draftReceipt(command.context, draftResult);
    for (final document in command.documents) {
      final upload = ServiceRequestAttachmentUpload(
        requestId: draft.requestId,
        actorUserId: command.context.actorUserId,
        document: document,
      );
      try {
        await _attachmentUploader.upload(upload);
      } catch (error) {
        throw ServiceRequestAttachmentUploadException(
          attachmentId: document.attachmentId,
          message: 'Could not upload ${document.fileName}: $error',
        );
      }
      await _waitUntilRegistered(
        requestId: draft.requestId,
        attachmentId: document.attachmentId,
      );
    }

    final result = await _invoker.invoke(
      submitFunctionName,
      {
        'command': 'service_request.submit',
        'idempotencyKey': _stageKey(
          command.context.idempotencyKey,
          'submit',
        ),
        'payload': {
          'requestId': draft.requestId,
          'responses': command.responses,
          'attachmentIds': command.documents
              .map((document) => document.attachmentId)
              .toList(growable: false),
        },
      },
    );
    final map = supportMapFromValue(result);
    return ServiceRequestSubmissionReceipt(
      command: _receipt(command.context, result),
      requestId: supportString(map['requestId'], draft.requestId),
      requestNumber: supportString(
        map['requestNumber'],
        draft.requestNumber,
      ),
      status: ServiceRequestStatus.fromValue(map['status']),
      workflowDefinitionId: command.catalogueItem.workflow.id,
      workflowVersion: command.catalogueItem.workflow.version,
      slaPolicyId: command.catalogueItem.slaPolicy.id,
      slaPolicyVersion: command.catalogueItem.slaPolicy.version,
    );
  }

  ServiceRequestDraftReceipt _draftReceipt(
    ItsmCommandContext context,
    Object? result,
  ) {
    final map = supportMapFromValue(result);
    final requestId = supportString(map['requestId']);
    final requestNumber = supportString(map['requestNumber']);
    final uploadPath = supportString(map['uploadPath']);
    if (requestId.isEmpty || requestNumber.isEmpty || uploadPath.isEmpty) {
      throw const ServiceRequestGatewayException(
        'The draft initialization response is incomplete.',
      );
    }
    return ServiceRequestDraftReceipt(
      command: _receipt(context, result),
      requestId: requestId,
      requestNumber: requestNumber,
      status: ServiceRequestStatus.fromValue(map['status']),
      uploadPath: uploadPath,
    );
  }

  Future<void> _waitUntilRegistered({
    required String requestId,
    required String attachmentId,
  }) async {
    for (var attempt = 0; attempt < registrationAttempts; attempt++) {
      try {
        if (await _registrationProbe.isRegistered(
          requestId: requestId,
          attachmentId: attachmentId,
        )) {
          return;
        }
      } catch (_) {
        // The trigger document can briefly be unavailable while Firestore
        // converges. The bounded retry below still guarantees termination.
      }
      if (attempt + 1 < registrationAttempts) {
        await _delay(registrationPollInterval);
      }
    }
    throw ServiceRequestAttachmentRegistrationTimeoutException(
      requestId: requestId,
      attachmentId: attachmentId,
    );
  }

  String _stageKey(String base, String stage) {
    final suffix = '.$stage';
    final trimmed = base.trim();
    final available = 128 - suffix.length;
    final prefix =
        trimmed.length > available ? trimmed.substring(0, available) : trimmed;
    return '$prefix$suffix';
  }

  @override
  Future<ItsmCommandReceipt> transition(
    TransitionServiceRequestCommand command,
  ) async {
    final result = await _invoker.invoke(
      transitionFunctionName,
      {
        'command': 'workflow.transition',
        'idempotencyKey': command.context.idempotencyKey,
        'entityType': 'service_request',
        'entityId': command.request.id,
        'payload': {
          'transitionId': command.transitionId.trim(),
          'toState': command.targetStatus.value,
          'expectedRevision': command.request.workflowRevision,
          'reason': command.reason.trim(),
        },
      },
    );
    return _receipt(command.context, result);
  }

  @override
  Future<ItsmCommandReceipt> decideApproval(
    DecideServiceRequestApprovalCommand command,
  ) async {
    final result = await _invoker.invoke(
      decideApprovalFunctionName,
      {
        'command': 'approval.decide',
        'idempotencyKey': command.context.idempotencyKey,
        'entityType': 'service_request',
        'entityId': command.requestId,
        'payload': {
          'approvalId': command.approvalId,
          'decision': _decisionValue(command.decision),
          'comment': command.comment.trim(),
        },
      },
    );
    return _receipt(command.context, result);
  }

  @override
  Future<ItsmCommandReceipt> assign(AssignServiceRequestCommand command) async {
    final result = await _invoker.invoke(assignFunctionName, {
      'command': 'service_request.assign',
      'idempotencyKey': command.context.idempotencyKey,
      'payload': {
        'requestId': command.requestId,
        'expectedRevision': command.expectedRevision,
        'assignedUserId': command.assignedUserId,
        'assignedUserName': command.assignedUserName,
        'assignedUserEmail': command.assignedUserEmail,
      },
    });
    return _receipt(command.context, result);
  }

  @override
  Future<ItsmCommandReceipt> updateTask(
    UpdateServiceRequestTaskCommand command,
  ) async {
    final result = await _invoker.invoke(updateTaskFunctionName, {
      'command': 'service_request.task.update',
      'idempotencyKey': command.context.idempotencyKey,
      'payload': {
        'requestId': command.requestId,
        'taskId': command.taskId,
        'status': _taskStatus(command.status),
        'comment': command.comment.trim(),
      },
    });
    return _receipt(command.context, result);
  }

  @override
  Future<ItsmCommandReceipt> addComment(
    AddServiceRequestCommentCommand command,
  ) async {
    final result = await _invoker.invoke(addCommentFunctionName, {
      'command': 'service_request.comment.add',
      'idempotencyKey': command.context.idempotencyKey,
      'payload': {
        'requestId': command.requestId,
        'body': command.body.trim(),
        'visibility': command.visibility.name,
      },
    });
    return _receipt(command.context, result);
  }

  @override
  Future<ItsmCommandReceipt> linkRecord(
    LinkServiceRequestRecordCommand command,
  ) async {
    final result = await _invoker.invoke(linkRecordFunctionName, {
      'command': 'service_request.link.add',
      'idempotencyKey': command.context.idempotencyKey,
      'payload': {
        'requestId': command.requestId,
        'record': command.record.toFirestore(),
      },
    });
    return _receipt(command.context, result);
  }

  ItsmCommandReceipt _receipt(
    ItsmCommandContext context,
    Object? result,
  ) {
    final map = supportMapFromValue(result);
    final acceptedAt =
        supportDateFromValue(map['acceptedAt']) ?? DateTime.now().toUtc();
    final commandId = supportString(
      map['commandId'] ?? map['receiptId'],
      context.idempotencyKey,
    );
    return ItsmCommandReceipt(
      commandId: commandId,
      acceptedAt: acceptedAt,
      wasDuplicate: supportBool(map['wasDuplicate']),
    );
  }

  String _decisionValue(ApprovalDecision decision) {
    return switch (decision) {
      ApprovalDecision.approve => 'approved',
      ApprovalDecision.reject => 'rejected',
      ApprovalDecision.requestClarification => 'clarification_requested',
    };
  }

  String _taskStatus(ItsmTaskStatus status) => switch (status) {
        ItsmTaskStatus.pending => 'pending',
        ItsmTaskStatus.inProgress => 'in_progress',
        ItsmTaskStatus.completed => 'completed',
        ItsmTaskStatus.cancelled => 'cancelled',
      };
}
