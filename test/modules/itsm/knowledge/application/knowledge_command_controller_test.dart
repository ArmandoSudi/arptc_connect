import 'dart:async';

import 'package:arptc_connect/modules/itsm/knowledge/application/knowledge_application.dart';
import 'package:arptc_connect/modules/itsm/knowledge/data/knowledge_data.dart';
import 'package:arptc_connect/modules/itsm/knowledge/domain/knowledge_domain.dart';
import 'package:arptc_connect/modules/itsm/shared/application/itsm_session.dart';
import 'package:arptc_connect/modules/itsm/shared/data/trusted_command_gateways.dart';
import 'package:arptc_connect/modules/itsm/shared/domain/itsm_common.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../knowledge_test_fixtures.dart';

void main() {
  test('USER and ADMIN can submit feedback only for visible published content',
      () async {
    final published = knowledgeArticle(
      state: KnowledgeArticleState.published,
      publishedVersionNumber: 1,
    );
    for (final role in [ItsmRole.user, ItsmRole.admin]) {
      final gateway = _FakeGateway();
      final controller = _controller(role, gateway);

      await controller.submitFeedback(
        KnowledgeFeedbackCommand(
          context: _context(role, 'feedback-${role.value}-123'),
          article: published,
          helpful: true,
        ),
        at: DateTime.utc(2026, 7, 31),
      );
      expect(gateway.feedbackCalls, 1);

      expect(
        () => controller.submitFeedback(
          KnowledgeFeedbackCommand(
            context: _context(role, 'draft-${role.value}-123'),
            article: knowledgeArticle(),
            helpful: false,
          ),
          at: DateTime.utc(2026, 7, 31),
        ),
        throwsA(isA<KnowledgeAccessDeniedException>()),
      );
    }
  });

  test('ADMIN cannot save drafts or perform lifecycle transitions', () async {
    final gateway = _FakeGateway();
    final controller = _controller(ItsmRole.admin, gateway);
    final command = SaveKnowledgeDraftCommand(
      context: _context(ItsmRole.admin, 'admin-save-123'),
      input: KnowledgeDraftInput(
        categoryId: 'identity',
        title: 'Title',
        summary: '',
        content: 'Content',
        languageCode: 'en',
      ),
    );

    expect(
      () => controller.saveDraft(command: command),
      throwsA(isA<KnowledgeAccessDeniedException>()),
    );
    expect(gateway.saveCalls, 0);
  });

  test('MANAGER can create a draft and revise immutable published content',
      () async {
    final gateway = _FakeGateway();
    final controller = _controller(ItsmRole.manager, gateway);
    final input = KnowledgeDraftInput(
      categoryId: 'identity',
      title: 'Title',
      summary: '',
      content: 'Content',
      languageCode: 'en',
    );

    await controller.saveDraft(
      command: SaveKnowledgeDraftCommand(
        context: _context(ItsmRole.manager, 'new-draft-123'),
        input: input,
      ),
    );

    final article = knowledgeArticle(
      state: KnowledgeArticleState.published,
      publishedVersionNumber: 1,
    );
    final version = knowledgeVersion(
      state: KnowledgeArticleState.published,
      publishedAt: DateTime.utc(2026, 7, 1),
    );
    await controller.saveDraft(
      command: SaveKnowledgeDraftCommand(
        context: _context(ItsmRole.manager, 'revision-draft-123'),
        input: input,
        articleId: article.id,
        expectedState: article.state,
        expectedVersionNumber: version.versionNumber,
      ),
      article: article,
      version: version,
    );

    expect(gateway.saveCalls, 2);
  });

  test('article under review cannot be edited and rejection requires a reason',
      () async {
    final gateway = _FakeGateway();
    final controller = _controller(ItsmRole.manager, gateway);
    final article = knowledgeArticle(state: KnowledgeArticleState.review);
    final version = knowledgeVersion(state: KnowledgeArticleState.review);
    final input = KnowledgeDraftInput(
      categoryId: 'identity',
      title: 'Title',
      summary: '',
      content: 'Content',
      languageCode: 'en',
    );

    expect(
      () => controller.saveDraft(
        command: SaveKnowledgeDraftCommand(
          context: _context(ItsmRole.manager, 'review-save-123'),
          input: input,
          articleId: article.id,
          expectedState: article.state,
          expectedVersionNumber: version.versionNumber,
        ),
        article: article,
        version: version,
      ),
      throwsA(isA<KnowledgeDraftValidationException>()),
    );
    expect(
      () => KnowledgeLifecycleCommand(
        context: _context(ItsmRole.manager, 'reject-article-123'),
        article: article,
        version: version,
        action: KnowledgeTransitionAction.rejectToDraft,
      ),
      throwsArgumentError,
    );
  });

  test('MANAGER lifecycle commands are validated before reaching gateway',
      () async {
    final gateway = _FakeGateway();
    final controller = _controller(ItsmRole.manager, gateway);
    final article = knowledgeArticle(state: KnowledgeArticleState.review);
    final version = knowledgeVersion(state: KnowledgeArticleState.review);

    await controller.transition(
      command: KnowledgeLifecycleCommand(
        context: _context(ItsmRole.manager, 'publish-review-123'),
        article: article,
        version: version,
        action: KnowledgeTransitionAction.publish,
      ),
      at: DateTime.utc(2026, 7, 31),
    );
    expect(gateway.transitionCalls, 1);

    expect(
      () => controller.transition(
        command: KnowledgeLifecycleCommand(
          context: _context(ItsmRole.manager, 'archive-review-123'),
          article: article,
          version: version,
          action: KnowledgeTransitionAction.archive,
        ),
        at: DateTime.utc(2026, 7, 31),
      ),
      throwsA(isA<KnowledgeTransitionException>()),
    );
    expect(gateway.transitionCalls, 1);
  });

  test('in-flight commands with the same idempotency key execute once',
      () async {
    final completer = Completer<KnowledgeCommandReceipt>();
    final gateway = _FakeGateway(viewResult: completer.future);
    final controller = _controller(ItsmRole.user, gateway);
    final article = knowledgeArticle(
      state: KnowledgeArticleState.published,
      publishedVersionNumber: 1,
    );
    final command = KnowledgeViewCommand(
      context: _context(ItsmRole.user, 'same-view-key-123'),
      article: article,
    );

    final first = controller.recordView(
      command,
      at: DateTime.utc(2026, 7, 31),
    );
    final second = controller.recordView(
      command,
      at: DateTime.utc(2026, 7, 31),
    );
    expect(gateway.viewCalls, 1);
    completer.complete(_receipt());

    await Future.wait([first, second]);
    expect(gateway.viewCalls, 1);
  });

  test('action notifier reports loading, data, and failure states', () async {
    final notifier = KnowledgeActionNotifier();
    addTearDown(notifier.dispose);
    final completer = Completer<KnowledgeCommandReceipt>();

    final pending = notifier.run(() => completer.future);
    expect(notifier.state.isLoading, isTrue);
    completer.complete(_receipt());
    await pending;
    expect(notifier.state.asData?.value?.commandId, 'receipt-1');

    await expectLater(
      notifier.run(() async => throw StateError('failed')),
      throwsStateError,
    );
    expect(
      notifier.state.when(
        data: (_) => false,
        error: (_, __) => true,
        loading: () => false,
      ),
      isTrue,
    );
  });
}

KnowledgeCommandController _controller(
  ItsmRole role,
  KnowledgeCommandGateway gateway,
) {
  return KnowledgeCommandController(
    session: ItsmSession(
      sessionKey: 'user-1|agent@example.com',
      userId: 'user-1',
      email: 'agent@example.com',
      displayName: 'Agent One',
      role: role,
    ),
    gateway: gateway,
    lifecycleService: const KnowledgeLifecycleService(),
  );
}

ItsmCommandContext _context(ItsmRole role, String key) => ItsmCommandContext(
      idempotencyKey: key,
      correlationId: 'correlation-123',
      actorUserId: 'user-1',
      actorRole: role,
    );

KnowledgeCommandReceipt _receipt() => KnowledgeCommandReceipt(
      commandId: 'receipt-1',
      acceptedAt: DateTime.utc(2026, 7, 31),
      wasDuplicate: false,
    );

class _FakeGateway implements KnowledgeCommandGateway {
  _FakeGateway({Future<KnowledgeCommandReceipt>? viewResult})
      : _viewResult = viewResult;

  final Future<KnowledgeCommandReceipt>? _viewResult;
  int viewCalls = 0;
  int feedbackCalls = 0;
  int saveCalls = 0;
  int transitionCalls = 0;

  @override
  Future<KnowledgeCommandReceipt> recordView(KnowledgeViewCommand command) {
    viewCalls++;
    return _viewResult ?? Future.value(_receipt());
  }

  @override
  Future<KnowledgeCommandReceipt> saveDraft(
    SaveKnowledgeDraftCommand command,
  ) async {
    saveCalls++;
    return _receipt();
  }

  @override
  Future<KnowledgeCommandReceipt> submitFeedback(
    KnowledgeFeedbackCommand command,
  ) async {
    feedbackCalls++;
    return _receipt();
  }

  @override
  Future<KnowledgeCommandReceipt> transition(
    KnowledgeLifecycleCommand command,
  ) async {
    transitionCalls++;
    return _receipt();
  }
}
