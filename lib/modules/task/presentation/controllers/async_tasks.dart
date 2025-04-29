import 'package:arptc_connect/modules/task/data/task_repository.dart';
import 'package:arptc_connect/modules/task/domain/task_two.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'async_tasks.g.dart';
@riverpod
class AsyncTasks extends _$AsyncTasks {

  List<Task> tasks = [];

  @override
  FutureOr<List<Task>> build() async {
    tasks = await fetchProducts();
    return tasks;
  }

  Future<List<Task>> fetchProducts() {
    return ref.read(taskRepositoryProvider).getTasks();
  }

  Future<void> addTask(Task task) async {
    state = const AsyncValue.loading();
    ref.read(taskRepositoryProvider).addTask(task);
    state = AsyncValue.data( await fetchProducts());
  }
}