import 'dart:async';

import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization_unit.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_agent.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_module.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/widgets/module_form_sheet.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/widgets/organization_agent_dialogs.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/widgets/organization_dialogs.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/widgets/organization_unit_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('organization async form', () {
    testWidgets('create shows progress and closes only after persistence',
        (tester) async {
      final command = Completer<void>();
      OrganizationFormResult? submitted;
      OrganizationFormResult? result;
      await tester.pumpWidget(_dialogApp<OrganizationFormResult>(
        open: (context) => showOrganizationFormDialog(
          context,
          onSubmit: (value) {
            submitted = value;
            return command.future;
          },
        ),
        onResult: (value) => result = value,
      ));
      await _open(tester);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'ARPTC');
      await tester.enterText(fields.at(1), 'Regulatory Authority');

      await tester.tap(find.widgetWithText(FilledButton, 'Create'));
      await tester.pump();

      expect(submitted?.code, 'ARPTC');
      expect(
          find.byKey(const Key('organization-form-progress')), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);

      command.complete();
      await tester.pumpAndSettle();
      expect(result?.name, 'Regulatory Authority');
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('edit submits changed fields and remains open on failure',
        (tester) async {
      final command = Completer<void>();
      OrganizationFormResult? submitted;
      var errorReported = false;
      await tester.pumpWidget(_dialogApp<OrganizationFormResult>(
        open: (context) => showOrganizationFormDialog(
          context,
          organization: _organization,
          onSubmit: (value) {
            submitted = value;
            return command.future;
          },
          submissionErrorBuilder: (_) => 'Update failed',
          onSubmissionError: (_, __) => errorReported = true,
        ),
        onResult: (_) {},
      ));
      await _open(tester);
      await tester.enterText(find.byType(TextFormField).at(1), 'ARPTC Updated');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pump();
      expect(
          find.byKey(const Key('organization-form-progress')), findsOneWidget);

      command.completeError(StateError('write failed'));
      await tester.pumpAndSettle();
      expect(submitted?.name, 'ARPTC Updated');
      expect(errorReported, isTrue);
      expect(find.text('Update failed'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Save'), findsOneWidget);
    });
  });

  group('organization unit async form', () {
    testWidgets('create shows progress and closes after persistence',
        (tester) async {
      final command = Completer<void>();
      OrganizationUnitFormResult? submitted;
      await tester.pumpWidget(_dialogApp<OrganizationUnitFormResult>(
        open: (context) => showOrganizationUnitFormDialog(
          context,
          type: OrganizationUnitType.service,
          onSubmit: (value) {
            submitted = value;
            return command.future;
          },
        ),
        onResult: (_) {},
      ));
      await _open(tester);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'S-IT');
      await tester.enterText(fields.at(1), 'IT Service');
      await tester.tap(find.widgetWithText(FilledButton, 'Create'));
      await tester.pump();

      expect(submitted?.name, 'IT Service');
      expect(
        find.byKey(const Key('organization-unit-form-progress')),
        findsOneWidget,
      );
      expect(find.byType(AlertDialog), findsOneWidget);

      command.complete();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('edit reports failure and keeps changed data available',
        (tester) async {
      final command = Completer<void>();
      OrganizationUnitFormResult? submitted;
      var errorReported = false;
      await tester.pumpWidget(_dialogApp<OrganizationUnitFormResult>(
        open: (context) => showOrganizationUnitFormDialog(
          context,
          type: _unit.type,
          unit: _unit,
          onSubmit: (value) {
            submitted = value;
            return command.future;
          },
          submissionErrorBuilder: (_) => 'Unit update failed',
          onSubmissionError: (_, __) => errorReported = true,
        ),
        onResult: (_) {},
      ));
      await _open(tester);
      await tester.enterText(find.byType(TextFormField).at(1), 'Support Desk');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pump();

      command.completeError(StateError('write failed'));
      await tester.pumpAndSettle();
      expect(submitted?.name, 'Support Desk');
      expect(errorReported, isTrue);
      expect(
        find.byKey(const Key('organization-unit-form-submission-error')),
        findsOneWidget,
      );
      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });

  group('agent async form', () {
    testWidgets('create shows progress and submits the selected placement',
        (tester) async {
      final command = Completer<void>();
      OrganizationAgentFormResult? submitted;
      await tester.pumpWidget(_dialogApp<OrganizationAgentFormResult>(
        open: (context) => showCreateOrganizationAgentDialog(
          context,
          units: const [_departmentUnit, _serviceUnit, _unit],
          onSubmit: (value) {
            submitted = value;
            return command.future;
          },
        ),
        onResult: (_) {},
      ));
      await _open(tester);
      final fields = find.byType(TextFormField);
      for (var index = 0; index < 6; index++) {
        await tester.enterText(fields.at(index), 'value$index');
      }
      await _selectDropdown(
        tester,
        const Key('organization-agent-sex-dropdown'),
        'Female',
      );
      await _selectDropdown(
        tester,
        const Key('organization-department-dropdown'),
        _departmentUnit.name,
      );
      await _selectDropdown(
        tester,
        const Key('organization-service-dropdown'),
        _serviceUnit.name,
      );
      await _selectDropdown(
        tester,
        const Key('organization-bureau-dropdown'),
        _unit.name,
      );
      final create = find.widgetWithText(FilledButton, 'Create');
      await tester.ensureVisible(create);
      await tester.tap(create);
      await tester.pump();

      expect(submitted?.unitId, _unit.id);
      expect(submitted?.sex, AgentSex.female);
      expect(submitted?.assignAsHead, isFalse);
      expect(
        find.byKey(const Key('organization-agent-create-progress')),
        findsOneWidget,
      );
      expect(find.byType(AlertDialog), findsOneWidget);

      command.complete();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('edit reports failure and preserves the changed profile',
        (tester) async {
      final command = Completer<void>();
      OrganizationAgentEditResult? submitted;
      var errorReported = false;
      await tester.pumpWidget(_dialogApp<OrganizationAgentEditResult>(
        open: (context) => showEditOrganizationAgentDialog(
          context,
          agent: _agent,
          onSubmit: (value) {
            submitted = value;
            return command.future;
          },
          submissionErrorBuilder: (_) => 'Agent update failed',
          onSubmissionError: (_, __) => errorReported = true,
        ),
        onResult: (_) {},
      ));
      await _open(tester);
      await tester.enterText(find.byType(TextFormField).first, 'Amina');
      final save = find.widgetWithText(FilledButton, 'Save');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pump();

      expect(
        find.byKey(const Key('organization-agent-edit-progress')),
        findsOneWidget,
      );
      command.completeError(StateError('write failed'));
      await tester.pumpAndSettle();
      expect(submitted?.firstName, 'Amina');
      expect(errorReported, isTrue);
      expect(
        find.byKey(const Key('organization-agent-edit-error')),
        findsOneWidget,
      );
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('edit closes only after the profile update succeeds',
        (tester) async {
      final command = Completer<void>();
      OrganizationAgentEditResult? result;
      await tester.pumpWidget(_dialogApp<OrganizationAgentEditResult>(
        open: (context) => showEditOrganizationAgentDialog(
          context,
          agent: _agent,
          onSubmit: (_) => command.future,
        ),
        onResult: (value) => result = value,
      ));
      await _open(tester);
      final save = find.widgetWithText(FilledButton, 'Save');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pump();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.byKey(const Key('organization-agent-edit-progress')),
        findsOneWidget,
      );

      command.complete();
      await tester.pumpAndSettle();
      expect(result?.email, _agent.email);
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('module async form', () {
    testWidgets('create shows progress and closes after Firestore write',
        (tester) async {
      final command = Completer<void>();
      UserManagementModule? submitted;
      await tester.pumpWidget(_dialogApp<UserManagementModule>(
        open: (context) => showModuleFormSheet(
          context,
          onSubmit: (value) {
            submitted = value;
            return command.future;
          },
        ),
        onResult: (_) {},
      ));
      await _open(tester);
      await tester.tap(find.byKey(const Key('module-form-submit')));
      await tester.pump();

      expect(submitted?.key, 'tasks');
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(ModuleFormSheet), findsOneWidget);

      command.complete();
      await tester.pumpAndSettle();
      expect(find.byType(ModuleFormSheet), findsNothing);
    });

    testWidgets('edit reports failure and keeps the sheet open for retry',
        (tester) async {
      final command = Completer<void>();
      UserManagementModule? submitted;
      var errorReported = false;
      await tester.pumpWidget(_dialogApp<UserManagementModule>(
        open: (context) => showModuleFormSheet(
          context,
          module: _module,
          onSubmit: (value) {
            submitted = value;
            return command.future;
          },
          submissionErrorBuilder: (_) => 'Module update failed',
          onSubmissionError: (_, __) => errorReported = true,
        ),
        onResult: (_) {},
      ));
      await _open(tester);
      await tester.enterText(find.byType(TextFormField).first, 'Tasks Updated');
      await tester.tap(find.byKey(const Key('module-form-submit')));
      await tester.pump();

      command.completeError(StateError('write failed'));
      await tester.pumpAndSettle();
      expect(submitted?.id, _module.id);
      expect(submitted?.name, 'Tasks Updated');
      expect(errorReported, isTrue);
      expect(
        find.byKey(const Key('module-form-submission-error')),
        findsOneWidget,
      );
      expect(find.byType(ModuleFormSheet), findsOneWidget);
    });
  });
}

Future<void> _selectDropdown(
  WidgetTester tester,
  Key key,
  String label,
) async {
  final dropdown = find.byKey(key);
  await tester.ensureVisible(dropdown);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> _open(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('open-dialog')));
  await tester.pumpAndSettle();
}

Widget _dialogApp<T>({
  required Future<T?> Function(BuildContext context) open,
  required ValueChanged<T?> onResult,
}) {
  return MaterialApp(
    localizationsDelegates: const [S.delegate],
    supportedLocales: S.delegate.supportedLocales,
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: FilledButton(
            key: const Key('open-dialog'),
            onPressed: () async => onResult(await open(context)),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
}

const _organization = Organization(
  id: 'org-arptc',
  code: 'ARPTC',
  name: 'ARPTC',
  description: 'Regulatory authority',
  status: OrganizationStatus.active,
);

const _unit = OrganizationUnit(
  id: 'bureau-support',
  organizationId: 'org-arptc',
  type: OrganizationUnitType.bureau,
  code: 'B-SUPPORT',
  name: 'Support',
  description: '',
  parentUnitId: 'service-it',
  parentUnitType: OrganizationUnitType.service,
  ancestorUnitIds: ['department-it', 'service-it'],
  pathUnitIds: ['department-it', 'service-it', 'bureau-support'],
  pathNames: ['IT', 'IT Service', 'Support'],
  depth: 2,
  scopeKeys: ['org:org-arptc', 'unit:bureau-support'],
  status: OrganizationStatus.active,
);

const _departmentUnit = OrganizationUnit(
  id: 'department-it',
  organizationId: 'org-arptc',
  type: OrganizationUnitType.department,
  code: 'D-IT',
  name: 'IT',
  description: '',
  parentUnitId: null,
  parentUnitType: null,
  ancestorUnitIds: [],
  pathUnitIds: ['department-it'],
  pathNames: ['IT'],
  depth: 0,
  scopeKeys: ['org:org-arptc', 'unit:department-it'],
  status: OrganizationStatus.active,
);

const _serviceUnit = OrganizationUnit(
  id: 'service-it',
  organizationId: 'org-arptc',
  type: OrganizationUnitType.service,
  code: 'S-IT',
  name: 'IT Service',
  description: '',
  parentUnitId: 'department-it',
  parentUnitType: OrganizationUnitType.department,
  ancestorUnitIds: ['department-it'],
  pathUnitIds: ['department-it', 'service-it'],
  pathNames: ['IT', 'IT Service'],
  depth: 1,
  scopeKeys: [
    'org:org-arptc',
    'unit:department-it',
    'unit:service-it',
  ],
  status: OrganizationStatus.active,
);

const _agent = UserManagementAgent(
  id: 'uid-amina',
  firstName: 'Aline',
  name: 'Mbuyi',
  postName: 'Kanku',
  matricule: 'ARP-001',
  sex: AgentSex.female,
  email: 'aline@arptc.cd',
  emailLower: 'aline@arptc.cd',
  jobTitle: 'Support analyst',
  department: 'IT',
  departmentId: 'department-it',
  service: 'IT Service',
  serviceId: 'service-it',
  bureau: 'Support',
  bureauId: 'bureau-support',
  organizationId: 'org-arptc',
  primaryOrganizationUnitId: 'bureau-support',
  primaryOrganizationUnitName: 'Support',
  primaryOrganizationUnitType: 'BUREAU',
  isActive: true,
  modulePermissions: {'usermanagement': 'MANAGER'},
);

const _module = UserManagementModule(
  id: 'module-tasks',
  key: 'tasks',
  name: 'Tasks',
  nameLower: 'tasks',
  description: 'Task management',
  availableRoles: ['ADMIN', 'MANAGER', 'USER'],
  isActive: true,
);
