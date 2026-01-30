import 'package:arptc_connect/modules/task/data/task_repository.dart';
import 'package:arptc_connect/modules/task/domain/task.dart';
import 'package:arptc_connect/modules/task/presentation/screens/tasks_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'async_tasks.g.dart';
@riverpod
class AsyncTasks extends _$AsyncTasks {

  @override
  FutureOr<List<Task>> build() async {
    return fetchTasks();
  }

  Future<List<Task>> fetchTasks() async {
    // Watch the filter provider. When it changes, the 'build' method will be re-executed.
    final filter = ref.watch(taskFilter);
    final tasks = await ref.read(taskRepositoryProvider).getTasks();

    switch (filter) {
      case TaskState.New:
        return tasks;
      case TaskState.Doing:
        return tasks.where((task) => task.status == "doing").toList();
      case TaskState.Done:
        return tasks.where((task) => task.status == "done").toList();
      default:
        return tasks;
    }
  }

  Future<void> addTask(Task task) async {
    state = const AsyncValue.loading();
    ref.read(taskRepositoryProvider).addTask(task);
    state = AsyncValue.data( await fetchTasks());
  }

  Future<void> deleteTask(String id) async {
    state = const AsyncValue.loading();
    ref.read(taskRepositoryProvider).deleteTask(id);
    state = AsyncValue.data( await fetchTasks());
  }
}