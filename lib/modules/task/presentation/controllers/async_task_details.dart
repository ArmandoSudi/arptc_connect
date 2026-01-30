import 'package:arptc_connect/modules/task/data/task_repository.dart';
import 'package:arptc_connect/modules/task/domain/task.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'async_task_details.g.dart';

@riverpod
class AsyncTaskDetails extends _$AsyncTaskDetails {

  @override
  FutureOr<Task> build(String id) async {
    return fetchTask(id);
  }

  Future<Task> fetchTask(String id) async {
    return ref.read(taskRepositoryProvider).getTaskById(id);
  }

}
