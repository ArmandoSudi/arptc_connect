import 'package:arptc_connect/core/fallback_framework_localizations.dart';
import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/task/domain/task.dart';
import 'package:arptc_connect/modules/task/domain/task_access.dart';
import 'package:arptc_connect/modules/task/presentation/widgets/task_details_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await Future.wait([
      initializeDateFormatting('en'),
      initializeDateFormatting('fr'),
    ]);
  });

  testWidgets('same-department USER sees details and delete confirmation',
      (tester) async {
    await tester.pumpWidget(
      _testApp(
        TaskDetailsView(
          task: _task(),
          principal: _principal(TaskRole.user),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Task ID'), findsOneWidget);
    expect(find.text('task-1'), findsOneWidget);
    expect(find.text('creator@example.test'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.text('Do you really want to delete "Department task"?'),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('ADMIN sees cross-department details without mutation controls',
      (tester) async {
    await tester.pumpWidget(
      _testApp(
        TaskDetailsView(
          task: _task(departmentId: 'department-2'),
          principal: _principal(TaskRole.admin, departmentId: ''),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Administrator access is read-only. '
        'You can review tasks from every department.',
      ),
      findsOneWidget,
    );
    expect(find.text('Edit'), findsNothing);
    expect(find.text('Delete'), findsNothing);
    expect(find.text('department-2'), findsOneWidget);
  });

  testWidgets('mobile French actions wrap without overflow', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      _testApp(
        TaskDetailsView(
          task: _task(),
          principal: _principal(TaskRole.manager),
        ),
        locale: const Locale('fr'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Modifier'), findsOneWidget);
    expect(find.text('Supprimer'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _testApp(
  Widget child, {
  Locale locale = const Locale('en'),
}) {
  return ProviderScope(
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        S.delegate,
        FallbackMaterialLocalizationsDelegate(),
        FallbackCupertinoLocalizationsDelegate(),
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

TaskPrincipal _principal(
  TaskRole role, {
  String departmentId = 'department-1',
}) {
  return TaskPrincipal(
    userId: 'user-1',
    profileId: 'user-1',
    displayName: 'Test Agent',
    email: 'user@example.test',
    departmentId: departmentId,
    departmentName: 'Administration',
    role: role,
  );
}

Task _task({String departmentId = 'department-1'}) {
  return Task(
    id: 'task-1',
    label: 'Department task',
    observation: 'Completed',
    creationDate: DateTime.utc(2026, 7, 10, 9),
    updatedAt: DateTime.utc(2026, 7, 10, 10),
    status: TaskStatus.done,
    type: TaskType.task,
    departmentId: departmentId,
    departmentName: 'Administration',
    createdByUserId: 'creator-1',
    createdByName: 'Creator Agent',
    createdByEmail: 'creator@example.test',
  );
}
