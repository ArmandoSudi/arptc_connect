import 'package:arptc_connect/modules/task/domain/task.dart';
import 'package:arptc_connect/modules/task/domain/task_access.dart';
import 'package:arptc_connect/modules/task/domain/task_draft.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Task', () {
    test('reads canonical Firestore fields and attachment metadata', () {
      final createdAt = DateTime.utc(2026, 7, 10, 9, 30);
      final task = Task.fromMap({
        'label': 'Process incoming mail',
        'observation': 'Forward to the legal team',
        'creation_date': Timestamp.fromDate(createdAt),
        'updated_at': Timestamp.fromDate(createdAt),
        'status': 'doing',
        'type': 'mail',
        'sender': 'Executive office',
        'receiver': 'Legal',
        'department': 'department-1',
        'department_name': 'Administration',
        'mail_scan_url': 'https://example.test/mail.pdf',
        'mail_scan_path': 'tasks/task-1/mail-scans/mail.pdf',
        'mail_scan_name': 'mail.pdf',
        'mail_scan_content_type': 'application/pdf',
        'created_by_user_id': 'user-1',
        'created_by_name': 'Jane Agent',
        'created_by_email': 'jane@example.test',
      }, id: 'task-1');

      expect(task.id, 'task-1');
      expect(task.status, TaskStatus.doing);
      expect(task.type, TaskType.mail);
      expect(task.creationDate.toUtc(), createdAt);
      expect(task.departmentId, 'department-1');
      expect(task.mailScan?.storagePath, 'tasks/task-1/mail-scans/mail.pdf');
    });

    test('writes canonical department, role-neutral fields, and URLs', () {
      final task = _task(type: TaskType.task).copyWith(
        reportFile: const TaskAttachment(
          url: 'https://example.test/report.pdf',
          storagePath: 'tasks/task-1/reports/report.pdf',
          fileName: 'report.pdf',
          contentType: 'application/pdf',
        ),
      );

      final map = task.toFirestore();

      expect(map['department'], 'department-1');
      expect(map['type'], 'task');
      expect(map['mail_scan_url'], '');
      expect(map['report_file_url'], 'https://example.test/report.pdf');
      expect(map['created_by_email'], 'agent@example.test');
    });
  });

  group('TaskDraft', () {
    test('requires sender and receiver only for mail tasks', () {
      const draft = TaskDraft(
        label: 'Mail',
        observation: 'Review',
        status: TaskStatus.newTask,
        type: TaskType.mail,
      );

      expect(
        draft.validate(principal: _principal(TaskRole.user)),
        containsAll([
          TaskDraftIssue.senderRequired,
          TaskDraftIssue.receiverRequired,
        ]),
      );
    });

    test('normalizes form values and derives immutable metadata', () {
      final now = DateTime.utc(2026, 7, 31, 8);
      const draft = TaskDraft(
        label: '  Weekly report  ',
        observation: '  Completed  ',
        status: TaskStatus.done,
        type: TaskType.task,
      );

      final task = draft.toTask(
        principal: _principal(TaskRole.manager),
        now: now,
      );

      expect(task.label, 'Weekly report');
      expect(task.observation, 'Completed');
      expect(task.departmentId, 'department-1');
      expect(task.createdByUserId, 'user-1');
      expect(task.creationDate, now);
    });
  });

  group('TaskAccessPolicy', () {
    test('USER can view and mutate same-department tasks only', () {
      final principal = _principal(TaskRole.user);

      expect(TaskAccessPolicy.canViewTask(principal, _task()), isTrue);
      expect(TaskAccessPolicy.canMutateTask(principal, _task()), isTrue);
      expect(
        TaskAccessPolicy.canViewTask(
          principal,
          _task(departmentId: 'department-2'),
        ),
        isFalse,
      );
    });

    test('ADMIN can view every department but cannot mutate or delete', () {
      final admin = _principal(TaskRole.admin, departmentId: '');
      final foreignTask = _task(departmentId: 'department-2');

      expect(TaskAccessPolicy.canViewTask(admin, foreignTask), isTrue);
      expect(TaskAccessPolicy.canMutateTask(admin, foreignTask), isFalse);
      expect(TaskAccessPolicy.canDeleteTask(admin, foreignTask), isFalse);
    });
  });
}

TaskPrincipal _principal(
  TaskRole role, {
  String departmentId = 'department-1',
}) {
  return TaskPrincipal(
    userId: 'user-1',
    profileId: 'user-1',
    displayName: 'Test Agent',
    email: 'agent@example.test',
    departmentId: departmentId,
    departmentName: 'Administration',
    role: role,
  );
}

Task _task({
  String departmentId = 'department-1',
  TaskType type = TaskType.task,
}) {
  return Task(
    id: 'task-1',
    label: 'Task',
    observation: 'Observation',
    creationDate: DateTime.utc(2026, 7, 1),
    status: TaskStatus.newTask,
    type: type,
    departmentId: departmentId,
    departmentName: 'Administration',
    createdByUserId: 'user-1',
    createdByName: 'Test Agent',
    createdByEmail: 'agent@example.test',
  );
}
