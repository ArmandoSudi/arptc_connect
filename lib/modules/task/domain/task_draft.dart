import 'package:arptc_connect/modules/task/domain/task.dart';
import 'package:arptc_connect/modules/task/domain/task_access.dart';

enum TaskDraftIssue {
  labelRequired,
  observationRequired,
  senderRequired,
  receiverRequired,
  departmentRequired,
}

class TaskDraft {
  const TaskDraft({
    required this.label,
    required this.observation,
    required this.status,
    required this.type,
    this.sender = '',
    this.receiver = '',
  });

  final String label;
  final String observation;
  final TaskStatus status;
  final TaskType type;
  final String sender;
  final String receiver;

  List<TaskDraftIssue> validate({
    required TaskPrincipal principal,
    Task? existingTask,
  }) {
    final issues = <TaskDraftIssue>[
      if (label.trim().isEmpty) TaskDraftIssue.labelRequired,
      if (observation.trim().isEmpty) TaskDraftIssue.observationRequired,
      if (type == TaskType.mail && sender.trim().isEmpty)
        TaskDraftIssue.senderRequired,
      if (type == TaskType.mail && receiver.trim().isEmpty)
        TaskDraftIssue.receiverRequired,
      if (existingTask == null && !principal.hasDepartment)
        TaskDraftIssue.departmentRequired,
    ];
    return List.unmodifiable(issues);
  }

  Task toTask({
    required TaskPrincipal principal,
    Task? existingTask,
    required DateTime now,
  }) {
    final issues = validate(
      principal: principal,
      existingTask: existingTask,
    );
    if (issues.isNotEmpty) {
      throw TaskDraftValidationException(issues);
    }

    return Task(
      id: existingTask?.id ?? '',
      label: label.trim(),
      observation: observation.trim(),
      creationDate: existingTask?.creationDate ?? now,
      updatedAt: now,
      status: status,
      type: type,
      sender: type == TaskType.mail ? sender.trim() : '',
      receiver: type == TaskType.mail ? receiver.trim() : '',
      mailScan: existingTask?.mailScan,
      reportFile: existingTask?.reportFile,
      departmentId: existingTask?.departmentId ?? principal.departmentId,
      departmentName: existingTask?.departmentName ?? principal.departmentName,
      createdByUserId: _preserveOr(
        existingTask?.createdByUserId,
        principal.userId,
      ),
      createdByName: _preserveOr(
        existingTask?.createdByName,
        principal.displayName,
      ),
      createdByEmail: _preserveOr(
        existingTask?.createdByEmail,
        principal.email,
      ),
      emissionDate: existingTask?.emissionDate,
      receptionDate: existingTask?.receptionDate,
      annotations: existingTask?.annotations,
    );
  }
}

class TaskDraftValidationException implements Exception {
  const TaskDraftValidationException(this.issues);

  final List<TaskDraftIssue> issues;

  @override
  String toString() => 'Invalid task draft: ${issues.join(', ')}';
}

String _preserveOr(String? existingValue, String fallback) {
  final normalized = existingValue?.trim() ?? '';
  return normalized.isNotEmpty ? normalized : fallback;
}
