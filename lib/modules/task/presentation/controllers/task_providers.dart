import 'package:arptc_connect/modules/authentication/application/authorized_session.dart';
import 'package:arptc_connect/modules/authentication/providers/authorized_session_provider.dart';
import 'package:arptc_connect/modules/task/data/task_repository.dart';
import 'package:arptc_connect/modules/task/domain/task.dart';
import 'package:arptc_connect/modules/task/domain/task_access.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TaskFilters {
  const TaskFilters({
    this.status,
    this.type,
  });

  final TaskStatus? status;
  final TaskType? type;

  TaskFilters copyWith({
    TaskStatus? status,
    bool clearStatus = false,
    TaskType? type,
    bool clearType = false,
  }) {
    return TaskFilters(
      status: clearStatus ? null : status ?? this.status,
      type: clearType ? null : type ?? this.type,
    );
  }
}

final currentTaskPrincipalProvider =
    Provider.autoDispose<AsyncValue<TaskPrincipal>>((ref) {
  final sessionState = ref.watch(authorizedSessionProvider);
  final session = sessionState.session;
  if (session == null) {
    if (sessionState.status == AuthenticationStatus.initializing ||
        sessionState.status == AuthenticationStatus.profileLoading) {
      return const AsyncValue.loading();
    }
    return const AsyncValue.data(_unauthorizedTaskPrincipal);
  }

  return AsyncValue.data(
    TaskPrincipal.fromProfile(
      profile: Map<String, dynamic>.from(session.profile),
      authUserId: session.userId,
      authEmail: session.email,
    ),
  );
});

final taskFiltersProvider = StateProvider.autoDispose<TaskFilters>((ref) {
  return const TaskFilters();
});

final departmentTasksProvider = StreamProvider.autoDispose<List<Task>>((ref) {
  final sessionKey = ref.watch(currentAuthorizedSessionKeyProvider);
  final principal = ref.watch(currentTaskPrincipalProvider).valueOrNull;
  if (sessionKey == null ||
      principal == null ||
      !principal.role.canRead ||
      (!principal.role.canViewAllDepartments && !principal.hasDepartment)) {
    return Stream.value(const <Task>[]);
  }
  return ref.read(taskRepositoryProvider).watchTasks(principal);
});

final filteredDepartmentTasksProvider =
    Provider.autoDispose<AsyncValue<List<Task>>>((ref) {
  final filters = ref.watch(taskFiltersProvider);
  return ref.watch(departmentTasksProvider).whenData((tasks) {
    return filterTasks(tasks, filters);
  });
});

final taskDetailsProvider =
    StreamProvider.autoDispose.family<Task?, String>((ref, taskId) {
  final sessionKey = ref.watch(currentAuthorizedSessionKeyProvider);
  final principal = ref.watch(currentTaskPrincipalProvider).valueOrNull;
  if (sessionKey == null || principal == null || !principal.role.canRead) {
    return Stream.value(null);
  }
  return ref.read(taskRepositoryProvider).watchTask(taskId);
});

const _unauthorizedTaskPrincipal = TaskPrincipal(
  userId: '',
  profileId: '',
  displayName: '',
  email: '',
  departmentId: '',
  departmentName: '',
  role: TaskRole.none,
);

List<Task> filterTasks(List<Task> tasks, TaskFilters filters) {
  return tasks.where((task) {
    final statusMatches =
        filters.status == null || task.status == filters.status;
    final typeMatches = filters.type == null || task.type == filters.type;
    return statusMatches && typeMatches;
  }).toList();
}
