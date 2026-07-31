import 'package:arptc_connect/modules/task/data/task_repository.dart';
import 'package:arptc_connect/modules/task/domain/task.dart';
import 'package:arptc_connect/modules/task/domain/task_access.dart';
import 'package:arptc_connect/modules/task/domain/task_attachment_upload.dart';
import 'package:arptc_connect/modules/task/domain/task_draft.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TaskSaveResult {
  const TaskSaveResult({
    required this.taskId,
    required this.created,
  });

  final String taskId;
  final bool created;
}

class TaskMutationService {
  TaskMutationService({
    required TaskRepository repository,
    DateTime Function()? now,
  })  : _repository = repository,
        _now = now ?? DateTime.now;

  final TaskRepository _repository;
  final DateTime Function() _now;

  Future<TaskSaveResult> save({
    required TaskPrincipal principal,
    required TaskDraft draft,
    Task? existingTask,
    TaskAttachmentUpload? mailScan,
    bool removeMailScan = false,
    TaskAttachmentUpload? reportFile,
    bool removeReportFile = false,
  }) async {
    if (existingTask == null && !principal.role.canCreate) {
      throw const TaskAuthorizationException();
    }
    if (existingTask != null &&
        !TaskAccessPolicy.canMutateTask(principal, existingTask)) {
      throw const TaskAuthorizationException();
    }

    final task = draft.toTask(
      principal: principal,
      existingTask: existingTask,
      now: _now(),
    );
    if (existingTask == null) {
      final taskId = await _repository.createTask(
        task,
        actingUserId: principal.userId,
        mailScan: draft.type == TaskType.mail ? mailScan : null,
        reportFile: reportFile,
      );
      return TaskSaveResult(taskId: taskId, created: true);
    }

    await _repository.updateTask(
      task,
      actingUserId: principal.userId,
      mailScan: draft.type == TaskType.mail ? mailScan : null,
      removeMailScan: removeMailScan || draft.type != TaskType.mail,
      reportFile: reportFile,
      removeReportFile: removeReportFile,
    );
    return TaskSaveResult(taskId: task.id, created: false);
  }

  Future<void> delete({
    required TaskPrincipal principal,
    required Task task,
  }) async {
    if (!TaskAccessPolicy.canDeleteTask(principal, task)) {
      throw const TaskAuthorizationException();
    }
    await _repository.deleteTask(task);
  }
}

class TaskAuthorizationException implements Exception {
  const TaskAuthorizationException();

  @override
  String toString() => 'The current user cannot modify this task.';
}

final taskMutationServiceProvider = Provider<TaskMutationService>((ref) {
  return TaskMutationService(
    repository: ref.read(taskRepositoryProvider),
  );
});
