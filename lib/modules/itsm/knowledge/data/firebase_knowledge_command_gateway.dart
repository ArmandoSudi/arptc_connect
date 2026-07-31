import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../domain/knowledge_domain.dart';
import 'knowledge_command_gateway.dart';

abstract interface class KnowledgeCallableInvoker {
  Future<Object?> invoke(
    String functionName,
    Map<String, Object?> payload,
  );
}

class FirebaseKnowledgeCallableInvoker implements KnowledgeCallableInvoker {
  const FirebaseKnowledgeCallableInvoker(this._functions);

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

class FirebaseKnowledgeCommandGateway implements KnowledgeCommandGateway {
  FirebaseKnowledgeCommandGateway(
    this._invoker, {
    KnowledgeAttachmentUploader? attachmentUploader,
    KnowledgeAttachmentRegistrationProbe? registrationProbe,
    KnowledgeAttachmentDelay? delay,
    this.registrationAttempts = 12,
    this.registrationPollInterval = const Duration(milliseconds: 500),
  })  : _attachmentUploader = attachmentUploader,
        _registrationProbe = registrationProbe,
        _delay = delay ?? Future<void>.delayed {
    if (registrationAttempts < 1) {
      throw RangeError.value(registrationAttempts, 'registrationAttempts');
    }
  }

  static const viewFunctionName = 'itsmRecordKnowledgeView';
  static const feedbackFunctionName = 'itsmRecordKnowledgeFeedback';
  static const saveDraftFunctionName = 'itsmSaveKnowledgeDraft';
  static const submitReviewFunctionName = 'itsmSubmitKnowledgeReview';
  static const rejectReviewFunctionName = 'itsmRejectKnowledgeReview';
  static const publishFunctionName = 'itsmPublishKnowledgeArticle';
  static const retireFunctionName = 'itsmRetireKnowledgeArticle';
  static const archiveFunctionName = 'itsmArchiveKnowledgeArticle';

  final KnowledgeCallableInvoker _invoker;
  final KnowledgeAttachmentUploader? _attachmentUploader;
  final KnowledgeAttachmentRegistrationProbe? _registrationProbe;
  final KnowledgeAttachmentDelay _delay;
  final int registrationAttempts;
  final Duration registrationPollInterval;

  @override
  Future<KnowledgeCommandReceipt> recordView(
    KnowledgeViewCommand command,
  ) async {
    final result = await _invoker.invoke(
      viewFunctionName,
      _envelope(
        command: 'knowledge.view',
        idempotencyKey: command.context.idempotencyKey,
        payload: {'articleId': command.article.id},
      ),
    );
    return _receipt(command.context.idempotencyKey, result);
  }

  @override
  Future<KnowledgeCommandReceipt> submitFeedback(
    KnowledgeFeedbackCommand command,
  ) async {
    final result = await _invoker.invoke(
      feedbackFunctionName,
      _envelope(
        command: 'knowledge.feedback',
        idempotencyKey: command.context.idempotencyKey,
        payload: {
          'articleId': command.article.id,
          'helpful': command.helpful,
          'comment': command.comment.trim(),
        },
      ),
    );
    return _receipt(command.context.idempotencyKey, result);
  }

  @override
  Future<KnowledgeCommandReceipt> saveDraft(
    SaveKnowledgeDraftCommand command,
  ) async {
    final result = await _invoker.invoke(
      saveDraftFunctionName,
      _envelope(
        command: 'knowledge.article.save_draft',
        idempotencyKey: command.context.idempotencyKey,
        payload: {
          if (!command.createsArticle) 'articleId': command.articleId.trim(),
          if (command.expectedVersionNumber != null)
            'expectedVersionNumber': command.expectedVersionNumber,
          ...command.input.toPrimitiveMap(),
        },
      ),
    );
    final receipt = _receipt(command.context.idempotencyKey, result);
    final articleId = receipt.articleId.trim();
    final versionNumber = receipt.versionNumber;
    if (command.input.attachments.isNotEmpty &&
        (articleId.isEmpty || versionNumber == null)) {
      throw const KnowledgeGatewayException(
        'The draft response cannot accept attachments.',
      );
    }
    final versionId = versionNumber?.toString().padLeft(6, '0') ?? '';
    for (final attachment in command.input.attachments) {
      final upload = KnowledgeAttachmentUpload(
        articleId: articleId,
        versionId: versionId,
        actorUserId: command.context.actorUserId,
        attachment: attachment,
      );
      try {
        await (_attachmentUploader ??
                FirebaseKnowledgeAttachmentUploader(FirebaseStorage.instance))
            .upload(upload);
      } catch (error) {
        throw KnowledgeAttachmentUploadException(
          attachmentId: attachment.id,
          message: 'Could not upload ${attachment.fileName}: $error',
        );
      }
      await _waitUntilRegistered(
        articleId: articleId,
        versionId: versionId,
        attachmentId: attachment.id,
      );
    }
    return receipt;
  }

  Future<void> _waitUntilRegistered({
    required String articleId,
    required String versionId,
    required String attachmentId,
  }) async {
    for (var attempt = 0; attempt < registrationAttempts; attempt++) {
      try {
        if (await (_registrationProbe ??
                FirestoreKnowledgeAttachmentRegistrationProbe(
                  FirebaseFirestore.instance,
                ))
            .isRegistered(
          articleId: articleId,
          versionId: versionId,
          attachmentId: attachmentId,
        )) {
          return;
        }
      } catch (_) {
        // Storage finalization and Firestore registration converge briefly.
      }
      if (attempt + 1 < registrationAttempts) {
        await _delay(registrationPollInterval);
      }
    }
    throw KnowledgeAttachmentRegistrationTimeoutException(
      articleId: articleId,
      attachmentId: attachmentId,
    );
  }

  @override
  Future<KnowledgeCommandReceipt> transition(
    KnowledgeLifecycleCommand command,
  ) async {
    final contract = _lifecycleContract(command.action);
    final result = await _invoker.invoke(
      contract.functionName,
      _envelope(
        command: contract.command,
        idempotencyKey: command.context.idempotencyKey,
        payload: {
          'articleId': command.article.id,
          if (_usesExpectedVersion(command.action))
            'expectedVersionNumber': command.version.versionNumber,
          if (command.action == KnowledgeTransitionAction.rejectToDraft)
            'reason': command.reason.trim(),
        },
      ),
    );
    return _receipt(command.context.idempotencyKey, result);
  }

  Map<String, Object?> _envelope({
    required String command,
    required String idempotencyKey,
    required Map<String, Object?> payload,
  }) {
    return {
      'command': command,
      'idempotencyKey': idempotencyKey,
      'payload': payload,
    };
  }

  KnowledgeCommandReceipt _receipt(String fallbackId, Object? value) {
    final root = _map(value);
    return KnowledgeCommandReceipt(
      commandId: _string(root['commandId'] ?? root['receiptId'], fallbackId),
      acceptedAt: knowledgeDate(root['acceptedAt']) ?? DateTime.now().toUtc(),
      wasDuplicate: _bool(root['wasDuplicate'] ?? root['duplicate']),
      articleId: _string(root['articleId']),
      versionNumber: _integer(root['versionNumber']),
      state: _string(root['state']),
      recorded: _bool(root['recorded']),
      helpful: root['helpful'] is bool ? root['helpful']! as bool : null,
    );
  }

  ({String functionName, String command}) _lifecycleContract(
    KnowledgeTransitionAction action,
  ) =>
      switch (action) {
        KnowledgeTransitionAction.submitForReview => (
            functionName: submitReviewFunctionName,
            command: 'knowledge.article.submit_review',
          ),
        KnowledgeTransitionAction.rejectToDraft => (
            functionName: rejectReviewFunctionName,
            command: 'knowledge.article.reject',
          ),
        KnowledgeTransitionAction.publish => (
            functionName: publishFunctionName,
            command: 'knowledge.article.publish',
          ),
        KnowledgeTransitionAction.retire => (
            functionName: retireFunctionName,
            command: 'knowledge.article.retire',
          ),
        KnowledgeTransitionAction.archive => (
            functionName: archiveFunctionName,
            command: 'knowledge.article.archive',
          ),
      };

  bool _usesExpectedVersion(KnowledgeTransitionAction action) =>
      action == KnowledgeTransitionAction.submitForReview ||
      action == KnowledgeTransitionAction.rejectToDraft ||
      action == KnowledgeTransitionAction.publish;
}

class FirebaseKnowledgeAttachmentUploader
    implements KnowledgeAttachmentUploader {
  FirebaseKnowledgeAttachmentUploader(this._storage);

  final FirebaseStorage _storage;

  @override
  Future<void> upload(KnowledgeAttachmentUpload upload) async {
    await _storage.ref(upload.storagePath).putData(
          upload.attachment.bytes,
          SettableMetadata(
            contentType: upload.attachment.contentType,
            customMetadata: upload.customMetadata,
          ),
        );
  }
}

class FirestoreKnowledgeAttachmentRegistrationProbe
    implements KnowledgeAttachmentRegistrationProbe {
  FirestoreKnowledgeAttachmentRegistrationProbe(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<bool> isRegistered({
    required String articleId,
    required String versionId,
    required String attachmentId,
  }) async {
    final snapshot = await _firestore
        .collection('knowledgeArticles')
        .doc(articleId)
        .collection('versions')
        .doc(versionId)
        .collection('attachments')
        .doc(attachmentId)
        .get(const GetOptions(source: Source.server));
    return snapshot.exists;
  }
}

Map<String, Object?> _map(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return const {};
}

String _string(Object? value, [String fallback = '']) {
  final result = value?.toString().trim() ?? '';
  return result.isEmpty ? fallback : result;
}

bool _bool(Object? value) => value == true || value?.toString() == 'true';

int? _integer(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
