import 'dart:async';

import 'package:arptc_connect/modules/usermanagement/application/organization_command_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('read-only roles cannot execute organization commands', () async {
    final controller = OrganizationCommandController(canManage: false);
    var called = false;

    final result = await controller.runVoid(
      action: 'create',
      command: () async => called = true,
    );

    expect(result, isFalse);
    expect(called, isFalse);
    expect(controller.state.errorMessage, contains('read-only'));
  });

  test('read-only roles cannot execute value-returning commands', () async {
    final controller = OrganizationCommandController(canManage: false);
    var calls = 0;

    final result = await controller.run<String>(
      action: 'createOrganization',
      command: () async {
        calls += 1;
        return 'org-1';
      },
    );

    expect(result, isNull);
    expect(calls, 0);
    expect(controller.state.isSubmitting, isFalse);
    expect(controller.state.errorMessage, contains('read-only'));
  });

  test('manager command exposes submitting and completion state', () async {
    final controller = OrganizationCommandController(canManage: true);
    final blocker = Completer<void>();

    final future = controller.run<String>(
      action: 'create',
      command: () async {
        await blocker.future;
        return 'org-1';
      },
    );

    expect(controller.state.isSubmitting, isTrue);
    blocker.complete();
    expect(await future, 'org-1');
    expect(controller.state.isSubmitting, isFalse);
    expect(controller.state.completedAction, 'create');
  });

  test('runOrThrow preserves the original failure for inline UI feedback',
      () async {
    final controller = OrganizationCommandController(canManage: true);
    final failure = StateError('Callable is not deployed');

    await expectLater(
      controller.runOrThrow<String>(
        action: 'createOrganization',
        command: () async => throw failure,
      ),
      throwsA(same(failure)),
    );

    expect(controller.state.isSubmitting, isFalse);
    expect(controller.state.errorMessage, contains('not deployed'));
  });

  test('duplicate submissions are ignored while a command is running',
      () async {
    final controller = OrganizationCommandController(canManage: true);
    final blocker = Completer<void>();
    var calls = 0;

    final first = controller.runVoid(
      action: 'transfer',
      command: () async {
        calls += 1;
        await blocker.future;
      },
    );
    final second = await controller.runVoid(
      action: 'transfer',
      command: () async => calls += 1,
    );

    expect(second, isFalse);
    expect(calls, 1);
    blocker.complete();
    await first;
  });

  test('command failures become feedback without escaping the controller',
      () async {
    final controller = OrganizationCommandController(canManage: true);

    final result = await controller.run<String>(
      action: 'archiveOrganization',
      command: () async => throw StateError('Organization still has units'),
    );

    expect(result, isNull);
    expect(controller.state.isSubmitting, isFalse);
    expect(controller.state.completedAction, isNull);
    expect(controller.state.errorMessage, contains('still has units'));
  });

  test('clearFeedback resets completed and failed states', () async {
    final controller = OrganizationCommandController(canManage: true);

    await controller.runVoid(
      action: 'updateOrganization',
      command: () async {},
    );
    expect(controller.state.completedAction, 'updateOrganization');

    controller.clearFeedback();

    expect(controller.state.isSubmitting, isFalse);
    expect(controller.state.completedAction, isNull);
    expect(controller.state.errorMessage, isNull);
  });

  test('clearFeedback does not erase an in-flight command', () async {
    final controller = OrganizationCommandController(canManage: true);
    final blocker = Completer<void>();

    final command = controller.runVoid(
      action: 'transferAgentOrganization',
      command: () => blocker.future,
    );
    expect(controller.state.isSubmitting, isTrue);

    controller.clearFeedback();

    expect(controller.state.isSubmitting, isTrue);
    blocker.complete();
    expect(await command, isTrue);
  });

  test('an in-flight success does not write state after controller disposal',
      () async {
    final controller = OrganizationCommandController(canManage: true);
    final pending = Completer<int>();
    final result = controller.runOrThrow<int>(
      action: 'updateOrganization',
      command: () => pending.future,
    );

    controller.dispose();
    pending.complete(42);

    await expectLater(result, completion(42));
  });

  test('an in-flight failure preserves its error after controller disposal',
      () async {
    final controller = OrganizationCommandController(canManage: true);
    final pending = Completer<void>();
    final result = controller.runOrThrow<void>(
      action: 'updateOrganizationUnit',
      command: () => pending.future,
    );

    controller.dispose();
    pending.completeError(StateError('firebase write failed'));

    await expectLater(
      result,
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'firebase write failed',
        ),
      ),
    );
  });
}
