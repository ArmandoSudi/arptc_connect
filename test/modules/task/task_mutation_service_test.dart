import 'package:arptc_connect/modules/task/application/task_mutation_service.dart';
import 'package:arptc_connect/modules/task/data/task_repository.dart';
import 'package:arptc_connect/modules/task/domain/task.dart';
import 'package:arptc_connect/modules/task/domain/task_access.dart';
import 'package:arptc_connect/modules/task/domain/task_attachment_upload.dart';
import 'package:arptc_connect/modules/task/domain/task_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeTaskRepository repository;
  late TaskMutationService service;

  setUp(() {
    repository = _FakeTaskRepository();
    service = TaskMutationService(
      repository: repository,
      now: () => DateTime.utc(2026, 7, 31, 12),
    );
  });

  test('create delegates normalized data and acting UID to repository',
      () async {
    final result = await service.save(
      principal: _principal(TaskRole.manager, userId: 'manager-1'),
      draft: const TaskDraft(
        label: ' New task ',
        observation: ' Completed ',
        status: TaskStatus.done,
        type: TaskType.task,
      ),
    );

    expect(result.created, isTrue);
    expect(result.taskId, 'created-task');
    expect(repository.createdTask?.label, 'New task');
    expect(repository.createActingUserId, 'manager-1');
  });

  test('update preserves creator but tags uploads with acting UID', () async {
    final existing = _task(createdByUserId: 'creator-1');
    final result = await service.save(
      principal: _principal(TaskRole.user, userId: 'editor-2'),
      existingTask: existing,
      draft: const TaskDraft(
        label: 'Updated',
        observation: 'Updated observation',
        status: TaskStatus.doing,
        type: TaskType.task,
      ),
    );

    expect(result.created, isFalse);
    expect(repository.updatedTask?.createdByUserId, 'creator-1');
    expect(repository.updateActingUserId, 'editor-2');
  });

  test('ADMIN mutation is rejected before repository access', () async {
    expect(
      () => service.save(
        principal: _principal(TaskRole.admin),
        draft: const TaskDraft(
          label: 'Task',
          observation: 'Observation',
          status: TaskStatus.newTask,
          type: TaskType.task,
        ),
      ),
      throwsA(isA<TaskAuthorizationException>()),
    );
    expect(repository.createdTask, isNull);
  });

  test('cross-department update is rejected', () async {
    expect(
      () => service.save(
        principal: _principal(TaskRole.manager),
        existingTask: _task(departmentId: 'department-2'),
        draft: const TaskDraft(
          label: 'Task',
          observation: 'Observation',
          status: TaskStatus.doing,
          type: TaskType.task,
        ),
      ),
      throwsA(isA<TaskAuthorizationException>()),
    );
    expect(repository.updatedTask, isNull);
  });

  test('delete delegates only for an authorized department user', () async {
    final task = _task();

    await service.delete(
      principal: _principal(TaskRole.user),
      task: task,
    );

    expect(repository.deletedTask, same(task));
  });
}

class _FakeTaskRepository implements TaskRepository {
  Task? createdTask;
  Task? updatedTask;
  Task? deletedTask;
  String? createActingUserId;
  String? updateActingUserId;

  @override
  Future<String> createTask(
    Task task, {
    required String actingUserId,
    TaskAttachmentUpload? mailScan,
    TaskAttachmentUpload? reportFile,
  }) async {
    createdTask = task;
    createActingUserId = actingUserId;
    return 'created-task';
  }

  @override
  Future<void> updateTask(
    Task task, {
    required String actingUserId,
    TaskAttachmentUpload? mailScan,
    bool removeMailScan = false,
    TaskAttachmentUpload? reportFile,
    bool removeReportFile = false,
  }) async {
    updatedTask = task;
    updateActingUserId = actingUserId;
  }

  @override
  Future<void> deleteTask(Task task) async {
    deletedTask = task;
  }

  @override
  Future<Task?> getTask(String taskId) async => null;

  @override
  Stream<Task?> watchTask(String taskId) => const Stream.empty();

  @override
  Stream<List<Task>> watchTasks(TaskPrincipal principal) =>
      Stream.value(const <Task>[]);
}

TaskPrincipal _principal(
  TaskRole role, {
  String userId = 'user-1',
}) {
  return TaskPrincipal(
    userId: userId,
    profileId: userId,
    displayName: 'Test Agent',
    email: '$userId@example.test',
    departmentId: 'department-1',
    departmentName: 'Administration',
    role: role,
  );
}

Task _task({
  String departmentId = 'department-1',
  String createdByUserId = 'user-1',
}) {
  return Task(
    id: 'task-1',
    label: 'Task',
    observation: 'Observation',
    creationDate: DateTime.utc(2026, 7, 1),
    status: TaskStatus.newTask,
    type: TaskType.task,
    departmentId: departmentId,
    createdByUserId: createdByUserId,
    createdByName: 'Creator',
    createdByEmail: 'creator@example.test',
  );
}
