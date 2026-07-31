import 'dart:typed_data';

import 'package:arptc_connect/modules/itsm/knowledge/data/knowledge_data.dart';
import 'package:arptc_connect/modules/itsm/knowledge/domain/knowledge_domain.dart';
import 'package:arptc_connect/modules/itsm/shared/data/trusted_command_gateways.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_common.dart';
import 'package:flutter_test/flutter_test.dart';

import '../knowledge_test_fixtures.dart';

void main() {
  test('view contract matches itsmRecordKnowledgeView exactly', () async {
    final invoker = _RecordingInvoker();
    final gateway = FirebaseKnowledgeCommandGateway(invoker);
    final article = knowledgeArticle(
      state: KnowledgeArticleState.published,
      publishedVersionNumber: 1,
    );

    final receipt = await gateway.recordView(
      KnowledgeViewCommand(context: _context('view-key-123'), article: article),
    );
    expect(invoker.functionName, 'itsmRecordKnowledgeView');
    expect(invoker.payload, {
      'command': 'knowledge.view',
      'idempotencyKey': 'view-key-123',
      'payload': {'articleId': article.id},
    });
    expect(receipt.commandId, 'receipt-1');
  });

  test('feedback contract uses helpful and rejects the obsolete isHelpful key',
      () async {
    final invoker = _RecordingInvoker(
      result: {
        'articleId': 'kb-1',
        'helpful': false,
        'recorded': true,
      },
    );
    final gateway = FirebaseKnowledgeCommandGateway(invoker);
    final article = knowledgeArticle(
      state: KnowledgeArticleState.published,
      publishedVersionNumber: 1,
    );

    final receipt = await gateway.submitFeedback(
      KnowledgeFeedbackCommand(
        context: _context('feedback-key-123'),
        article: article,
        helpful: false,
        comment: 'Missing one step',
      ),
    );
    expect(invoker.functionName, 'itsmRecordKnowledgeFeedback');
    expect(invoker.payload, {
      'command': 'knowledge.feedback',
      'idempotencyKey': 'feedback-key-123',
      'payload': {
        'articleId': article.id,
        'helpful': false,
        'comment': 'Missing one step',
      },
    });
    expect(_payload(invoker.payload), isNot(contains('isHelpful')));
    expect(receipt.articleId, 'kb-1');
    expect(receipt.helpful, isFalse);
    expect(receipt.recorded, isTrue);
  });

  test('draft contract matches itsmSaveKnowledgeDraft validation fields',
      () async {
    final invoker = _RecordingInvoker();
    final gateway = FirebaseKnowledgeCommandGateway(invoker);
    final article = knowledgeArticle();

    await gateway.saveDraft(
      SaveKnowledgeDraftCommand(
        context: _context('save-key-123'),
        articleId: article.id,
        expectedState: article.state,
        expectedVersionNumber: 1,
        input: KnowledgeDraftInput(
          categoryId: 'identity',
          title: ' Reset access ',
          summary: ' Safe steps ',
          content: ' Use the portal ',
          languageCode: 'EN',
        ),
      ),
    );
    expect(invoker.functionName, 'itsmSaveKnowledgeDraft');
    expect(invoker.payload['command'], 'knowledge.article.save_draft');
    expect(_payload(invoker.payload), {
      'articleId': article.id,
      'expectedVersionNumber': 1,
      'categoryId': 'identity',
      'title': 'Reset access',
      'summary': 'Safe steps',
      'content': 'Use the portal',
      'languageCode': 'en',
      'visibility': 'employee',
      'isFeatured': false,
      'relatedServiceIds': <String>[],
      'relatedCatalogueItemIds': <String>[],
      'relatedIncidentCategoryIds': <String>[],
    });
    expect(_payload(invoker.payload), isNot(contains('expectedState')));
  });

  test('each lifecycle action uses its dedicated deployed callable contract',
      () async {
    final invoker = _RecordingInvoker();
    final gateway = FirebaseKnowledgeCommandGateway(invoker);
    final cases =
        <KnowledgeTransitionAction, ({String function, String command})>{
      KnowledgeTransitionAction.submitForReview: (
        function: 'itsmSubmitKnowledgeReview',
        command: 'knowledge.article.submit_review',
      ),
      KnowledgeTransitionAction.rejectToDraft: (
        function: 'itsmRejectKnowledgeReview',
        command: 'knowledge.article.reject',
      ),
      KnowledgeTransitionAction.publish: (
        function: 'itsmPublishKnowledgeArticle',
        command: 'knowledge.article.publish',
      ),
      KnowledgeTransitionAction.retire: (
        function: 'itsmRetireKnowledgeArticle',
        command: 'knowledge.article.retire',
      ),
      KnowledgeTransitionAction.archive: (
        function: 'itsmArchiveKnowledgeArticle',
        command: 'knowledge.article.archive',
      ),
    };

    for (final entry in cases.entries) {
      final state = switch (entry.key) {
        KnowledgeTransitionAction.submitForReview =>
          KnowledgeArticleState.draft,
        KnowledgeTransitionAction.rejectToDraft ||
        KnowledgeTransitionAction.publish =>
          KnowledgeArticleState.review,
        KnowledgeTransitionAction.retire => KnowledgeArticleState.published,
        KnowledgeTransitionAction.archive => KnowledgeArticleState.retired,
      };
      final article = knowledgeArticle(
        state: state,
        publishedVersionNumber:
            state == KnowledgeArticleState.published ? 1 : null,
      );
      await gateway.transition(
        KnowledgeLifecycleCommand(
          context: _context('transition-${entry.key.name}-123'),
          article: article,
          version: knowledgeVersion(
            state: state,
            publishedAt: state == KnowledgeArticleState.published
                ? DateTime.utc(2026, 7, 1)
                : null,
          ),
          action: entry.key,
          reason: entry.key == KnowledgeTransitionAction.rejectToDraft
              ? 'Needs more detail'
              : 'Must not be sent',
        ),
      );
      expect(invoker.functionName, entry.value.function);
      expect(invoker.payload['command'], entry.value.command);
      final payload = _payload(invoker.payload);
      expect(payload['articleId'], article.id);
      expect(payload, isNot(contains('expectedState')));
      final expectedPayload = switch (entry.key) {
        KnowledgeTransitionAction.submitForReview ||
        KnowledgeTransitionAction.publish =>
          {
            'articleId': article.id,
            'expectedVersionNumber': 1,
          },
        KnowledgeTransitionAction.rejectToDraft => {
            'articleId': article.id,
            'expectedVersionNumber': 1,
            'reason': 'Needs more detail',
          },
        KnowledgeTransitionAction.retire ||
        KnowledgeTransitionAction.archive =>
          {'articleId': article.id},
      };
      expect(payload, expectedPayload);
    }
  });

  test('parses the direct result map returned by support callables', () async {
    final invoker = _RecordingInvoker(
      result: {
        'articleId': 'kb-8',
        'versionNumber': 4,
        'state': 'draft',
        'wasDuplicate': false,
      },
    );
    final gateway = FirebaseKnowledgeCommandGateway(invoker);

    final receipt = await gateway.saveDraft(
      SaveKnowledgeDraftCommand(
        context: _context('create-key-123'),
        input: KnowledgeDraftInput(
          categoryId: 'identity',
          title: 'Title',
          summary: '',
          content: 'Content',
          languageCode: 'en',
        ),
      ),
    );

    expect(receipt.commandId, 'create-key-123');
    expect(receipt.wasDuplicate, isFalse);
    expect(receipt.articleId, 'kb-8');
    expect(receipt.versionNumber, 4);
    expect(receipt.state, 'draft');
  });

  test('uploads draft attachments and waits for trusted registration',
      () async {
    final invoker = _RecordingInvoker(
      result: const {
        'articleId': 'kb-8',
        'versionNumber': 4,
        'state': 'draft',
      },
    );
    final uploader = _RecordingUploader();
    final probe = _RegistrationProbe([false, true]);
    var delays = 0;
    final gateway = FirebaseKnowledgeCommandGateway(
      invoker,
      attachmentUploader: uploader,
      registrationProbe: probe,
      delay: (_) async => delays++,
      registrationPollInterval: Duration.zero,
    );
    final attachment = KnowledgeDraftAttachment(
      id: 'attachment-1',
      fileName: r'guide/reset.pdf',
      contentType: 'application/pdf',
      bytes: Uint8List.fromList([1, 2, 3]),
      isInternal: true,
    );

    await gateway.saveDraft(
      SaveKnowledgeDraftCommand(
        context: _context('attachment-save-123'),
        input: KnowledgeDraftInput(
          categoryId: 'identity',
          title: 'Title',
          summary: '',
          content: 'Content',
          languageCode: 'en',
          attachments: [attachment],
        ),
      ),
    );

    expect(uploader.uploads, hasLength(1));
    expect(
      uploader.uploads.single.storagePath,
      'itsm/knowledgeArticles/kb-8/versions/000004/attachments/'
      'attachment-1/guide_reset.pdf',
    );
    expect(uploader.uploads.single.customMetadata, {
      'articleId': 'kb-8',
      'versionId': '000004',
      'attachmentId': 'attachment-1',
      'uploadedByUserId': 'manager-1',
      'isInternal': 'true',
    });
    expect(probe.calls, 2);
    expect(delays, 1);
  });

  test('attachment registration polling is bounded', () async {
    final gateway = FirebaseKnowledgeCommandGateway(
      _RecordingInvoker(
        result: const {
          'articleId': 'kb-timeout',
          'versionNumber': 1,
          'state': 'draft',
        },
      ),
      attachmentUploader: _RecordingUploader(),
      registrationProbe: _RegistrationProbe([false]),
      delay: (_) async {},
      registrationAttempts: 2,
      registrationPollInterval: Duration.zero,
    );

    await expectLater(
      gateway.saveDraft(
        SaveKnowledgeDraftCommand(
          context: _context('attachment-timeout-123'),
          input: KnowledgeDraftInput(
            categoryId: 'identity',
            title: 'Title',
            summary: '',
            content: 'Content',
            languageCode: 'en',
            attachments: [
              KnowledgeDraftAttachment(
                id: 'attachment-1',
                fileName: 'guide.pdf',
                contentType: 'application/pdf',
                bytes: Uint8List.fromList([1]),
              ),
            ],
          ),
        ),
      ),
      throwsA(isA<KnowledgeAttachmentRegistrationTimeoutException>()),
    );
  });
}

ItsmCommandContext _context(String idempotencyKey) => ItsmCommandContext(
      idempotencyKey: idempotencyKey,
      correlationId: 'correlation-123',
      actorUserId: 'manager-1',
      actorRole: ItsmRole.manager,
    );

Map<String, Object?> _payload(Map<String, Object?> envelope) {
  return Map<String, Object?>.from(envelope['payload']! as Map);
}

class _RecordingInvoker implements KnowledgeCallableInvoker {
  _RecordingInvoker({
    this.result = const {
      'commandId': 'receipt-1',
      'wasDuplicate': false,
    },
  });

  final Object? result;
  String functionName = '';
  Map<String, Object?> payload = const {};

  @override
  Future<Object?> invoke(
    String functionName,
    Map<String, Object?> payload,
  ) async {
    this.functionName = functionName;
    this.payload = payload;
    return result;
  }
}

class _RecordingUploader implements KnowledgeAttachmentUploader {
  final List<KnowledgeAttachmentUpload> uploads = [];

  @override
  Future<void> upload(KnowledgeAttachmentUpload upload) async {
    uploads.add(upload);
  }
}

class _RegistrationProbe implements KnowledgeAttachmentRegistrationProbe {
  _RegistrationProbe(this.results);

  final List<bool> results;
  var calls = 0;

  @override
  Future<bool> isRegistered({
    required String articleId,
    required String versionId,
    required String attachmentId,
  }) async {
    final index = calls < results.length ? calls : results.length - 1;
    calls++;
    return results[index];
  }
}
