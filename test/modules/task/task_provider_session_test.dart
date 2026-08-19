import 'dart:async';

import 'package:arptc_connect/modules/authentication/application/authorized_session.dart';
import 'package:arptc_connect/modules/authentication/providers/authorized_session_provider.dart';
import 'package:arptc_connect/modules/task/data/task_repository.dart';
import 'package:arptc_connect/modules/task/domain/task.dart';
import 'package:arptc_connect/modules/task/domain/task_access.dart';
import 'package:arptc_connect/modules/task/presentation/controllers/task_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _sessionProvider = StateProvider<AuthorizedSessionState>((ref) {
  return const AuthorizedSessionState.unauthenticated();
});
final _principalProvider = StateProvider<AsyncValue<TaskPrincipal>>((ref) {
  return const AsyncValue.loading();
});

void main() {
  test('department task subscription follows authenticated sessions', () async {
    final repository = _TrackingTaskRepository();
    final container = ProviderContainer(
      overrides: [
        authorizedSessionProvider.overrideWith(
          (ref) => ref.watch(_sessionProvider),
        ),
        currentTaskPrincipalProvider.overrideWith(
          (ref) => ref.watch(_principalProvider),
        ),
        taskRepositoryProvider.overrideWithValue(repository),
      ],
    );
    final subscription = container.listen(
      departmentTasksProvider,
      (_, __) {},
      fireImmediately: true,
    );

    await container.pump();
    expect(repository.watchCallCount, 0);

    container.read(_sessionProvider.notifier).state =
        AuthorizedSessionState.authenticated(_session('user-a'));
    container.read(_principalProvider.notifier).state =
        AsyncValue.data(_principal('user-a', 'department-a'));
    await container.pump();
    expect(repository.watchCallCount, 1);
    expect(repository.principalIds, ['user-a']);
    expect(repository.activeListenerCount, 1);

    container.read(_sessionProvider.notifier).state =
        const AuthorizedSessionState.unauthenticated();
    container.read(_principalProvider.notifier).state =
        const AsyncValue.loading();
    await container.pump();
    expect(repository.activeListenerCount, 0);

    container.read(_sessionProvider.notifier).state =
        AuthorizedSessionState.authenticated(_session('user-b'));
    container.read(_principalProvider.notifier).state =
        AsyncValue.data(_principal('user-b', 'department-b'));
    await container.pump();
    expect(repository.watchCallCount, 2);
    expect(repository.principalIds, ['user-a', 'user-b']);
    expect(repository.activeListenerCount, 1);

    subscription.close();
    container.dispose();
    await repository.dispose();
  });
}

AuthorizedSession _session(String userId) {
  return AuthorizedSession(
    sessionKey: '$userId|$userId@example.test',
    userId: userId,
    email: '$userId@example.test',
    displayName: userId,
    profile: {
      'id': userId,
      'email': '$userId@example.test',
      'isActive': true,
      'modulePermissions': const {'tasks': 'USER'},
    },
    modulePermissions: const {'tasks': 'USER'},
  );
}

class _TrackingTaskRepository implements TaskRepository {
  final List<StreamController<List<Task>>> _controllers = [];

  int watchCallCount = 0;
  int activeListenerCount = 0;
  final List<String> principalIds = [];

  @override
  Stream<List<Task>> watchTasks(TaskPrincipal principal) {
    watchCallCount += 1;
    principalIds.add(principal.userId);
    final controller = StreamController<List<Task>>.broadcast(
      onListen: () => activeListenerCount += 1,
      onCancel: () => activeListenerCount -= 1,
    );
    _controllers.add(controller);
    return controller.stream;
  }

  Future<void> dispose() async {
    for (final controller in _controllers) {
      await controller.close();
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

TaskPrincipal _principal(String userId, String departmentId) {
  return TaskPrincipal(
    userId: userId,
    profileId: userId,
    displayName: userId,
    email: '$userId@example.test',
    departmentId: departmentId,
    departmentName: departmentId,
    role: TaskRole.user,
  );
}
