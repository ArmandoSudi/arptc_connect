import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/task/domain/task.dart';
import 'package:arptc_connect/modules/task/presentation/controllers/task_providers.dart';
import 'package:arptc_connect/modules/task/presentation/widgets/task_attachment_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('filterTasks', () {
    final tasks = [
      _task('mail-new', TaskStatus.newTask, TaskType.mail),
      _task('task-doing', TaskStatus.doing, TaskType.task),
      _task('mail-done', TaskStatus.done, TaskType.mail),
    ];

    test('combines status and type filters', () {
      final result = filterTasks(
        tasks,
        const TaskFilters(
          status: TaskStatus.newTask,
          type: TaskType.mail,
        ),
      );

      expect(result.map((task) => task.id), ['mail-new']);
    });

    test('returns every task when filters are empty', () {
      expect(filterTasks(tasks, const TaskFilters()), hasLength(3));
    });
  });

  test('maps supported attachment extensions to Storage content types', () {
    expect(taskAttachmentContentType('pdf'), 'application/pdf');
    expect(taskAttachmentContentType('JPG'), 'image/jpeg');
    expect(
      taskAttachmentContentType('docx'),
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    );
  });

  testWidgets('attachment field renders its empty reusable state',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          S.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: Scaffold(
          body: TaskAttachmentField(
            label: 'Report',
            onChanged: (_) {},
            onRemoveChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Report'), findsOneWidget);
    expect(find.text('No file selected'), findsOneWidget);
    expect(find.text('Select file'), findsOneWidget);
  });
}

Task _task(String id, TaskStatus status, TaskType type) {
  return Task(
    id: id,
    label: id,
    observation: 'Observation',
    creationDate: DateTime.utc(2026, 7, 1),
    status: status,
    type: type,
    departmentId: 'department-1',
  );
}
