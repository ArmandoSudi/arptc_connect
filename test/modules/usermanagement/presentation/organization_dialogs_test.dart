import 'dart:async';

import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/usermanagement/domain/agent_directory_entry.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization_unit.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_agent.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/widgets/organization_agent_dialogs.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/widgets/organization_dialogs.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/widgets/organization_unit_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('organization form requires code and name before creation',
      (tester) async {
    OrganizationFormResult? result;
    await tester.pumpWidget(
      _dialogApp<OrganizationFormResult>(
        open: (context) => showOrganizationFormDialog(context),
        onResult: (value) => result = value,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open-dialog')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pump();

    expect(find.text('This field is required.'), findsNWidgets(2));
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(result, isNull);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'ARPTC');
    await tester.enterText(fields.at(1), 'Regulatory Authority');
    await tester.enterText(fields.at(2), 'National communications regulator');
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(result?.code, 'ARPTC');
    expect(result?.name, 'Regulatory Authority');
    expect(result?.status, OrganizationStatus.active);
  });

  testWidgets('organization creation stays open and shows submission errors',
      (tester) async {
    final submission = Completer<void>();
    await tester.pumpWidget(
      _dialogApp<OrganizationFormResult>(
        open: (context) => showOrganizationFormDialog(
          context,
          onSubmit: (_) => submission.future,
          submissionErrorBuilder: (_) => 'Organization service unavailable',
        ),
        onResult: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open-dialog')));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'ARPTC');
    await tester.enterText(fields.at(1), 'Regulatory Authority');
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pump();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Cancel'))
            .onPressed,
        isNull);

    submission.completeError(StateError('internal'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.byKey(const Key('organization-form-submission-error')),
      findsOneWidget,
    );
    expect(find.text('Organization service unavailable'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Create'), findsOneWidget);
  });

  testWidgets('organization unit form validates the hierarchy node identity',
      (tester) async {
    OrganizationUnitFormResult? result;
    await tester.pumpWidget(
      _dialogApp<OrganizationUnitFormResult>(
        open: (context) => showOrganizationUnitFormDialog(
          context,
          type: OrganizationUnitType.service,
        ),
        onResult: (value) => result = value,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open-dialog')));
    await tester.pumpAndSettle();
    expect(find.text('Service'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pump();
    expect(find.text('This field is required.'), findsNWidgets(2));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'S-IT');
    await tester.enterText(fields.at(1), 'IT Service');
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pumpAndSettle();

    expect(result?.type, OrganizationUnitType.service);
    expect(result?.code, 'S-IT');
    expect(result?.name, 'IT Service');
  });

  testWidgets('archive reason dialog requires and trims an audit reason',
      (tester) async {
    String? result;
    await tester.pumpWidget(
      _dialogApp<String>(
        open: (context) => showOrganizationReasonDialog(
          context,
          title: 'Archive organization',
          description: 'This action is recorded in the audit history.',
          reasonLabel: 'Archive reason',
          confirmLabel: 'Archive now',
          destructive: true,
        ),
        onResult: (value) => result = value,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open-dialog')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Archive now'));
    await tester.pump();

    expect(find.text('This field is required.'), findsOneWidget);
    expect(result, isNull);

    await tester.enterText(
      find.byType(TextFormField),
      '  Organization is no longer operational  ',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Archive now'));
    await tester.pumpAndSettle();

    expect(result, 'Organization is no longer operational');
  });

  testWidgets('acting head assignment is blocked without an explicit end date',
      (tester) async {
    OrganizationHeadFormResult? result;
    await tester.pumpWidget(
      _dialogApp<OrganizationHeadFormResult>(
        open: (context) => showOrganizationHeadDialog(
          context,
          agents: const [_agent],
        ),
        onResult: (value) => result = value,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open-dialog')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aline Mbuyi').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SwitchListTile));
    await tester.enterText(
      find.byType(TextFormField),
      'Temporary leadership coverage',
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pump();

    expect(find.text('Acting end date'), findsWidgets);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(result, isNull);
  });

  testWidgets('head assignment waits for the server command before closing',
      (tester) async {
    final submission = Completer<void>();
    OrganizationHeadFormResult? result;
    await tester.pumpWidget(
      _dialogApp<OrganizationHeadFormResult>(
        open: (context) => showOrganizationHeadDialog(
          context,
          agents: const [_agent],
          onSubmit: (_) => submission.future,
        ),
        onResult: (value) => result = value,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open-dialog')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aline Mbuyi').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField),
      'Permanent appointment',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pump();

    expect(find.byKey(const Key('organization-head-progress')), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(result, isNull);

    submission.complete();
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(result?.agentId, _agent.id);
    expect(result?.isActing, isFalse);
  });

  testWidgets('head assignment displays a server error without closing',
      (tester) async {
    await tester.pumpWidget(
      _dialogApp<OrganizationHeadFormResult>(
        open: (context) => showOrganizationHeadDialog(
          context,
          agents: const [_agent],
          onSubmit: (_) async => throw StateError('conflict'),
          submissionErrorBuilder: (_) => 'A permanent head already exists.',
        ),
        onResult: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open-dialog')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aline Mbuyi').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Appointment');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.byKey(const Key('organization-head-submission-error')),
      findsOneWidget,
    );
    expect(find.text('A permanent head already exists.'), findsOneWidget);
  });

  testWidgets('unit move requires an eligible parent and an audit reason',
      (tester) async {
    OrganizationUnitMoveResult? result;
    await tester.pumpWidget(
      _dialogApp<OrganizationUnitMoveResult>(
        open: (context) => showOrganizationUnitMoveDialog(
          context,
          unit: _serviceUnit,
          eligibleParents: const [_administrationDepartment],
        ),
        onResult: (value) => result = value,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open-dialog')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Move unit'));
    await tester.pump();
    expect(find.text('This field is required.'), findsNWidgets(2));
    expect(result, isNull);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Administration').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField),
      '  Operations now reports to Administration  ',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Move unit'));
    await tester.pumpAndSettle();

    expect(result?.parentUnitId, 'department-administration');
    expect(result?.reason, 'Operations now reports to Administration');
  });

  testWidgets('agent creation offers active units and explains credentials',
      (tester) async {
    await tester.pumpWidget(
      _dialogApp<OrganizationAgentFormResult>(
        open: (context) => showCreateOrganizationAgentDialog(
          context,
          units: [
            _itDepartment,
            _itService,
            _unit(id: 'active', name: 'Active Bureau', active: true),
            _unit(id: 'inactive', name: 'Inactive Bureau', active: false),
          ],
        ),
        onResult: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open-dialog')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'The Firebase account will use the default password Arptc@1234. '
        'The agent should change it after signing in.',
      ),
      findsOneWidget,
    );
    await _selectUnit(tester, 'organization-department-dropdown', 'IT');
    await _selectUnit(
      tester,
      'organization-service-dropdown',
      'IT Service',
    );
    final bureauDropdown =
        find.byKey(const Key('organization-bureau-dropdown'));
    await tester.ensureVisible(bureauDropdown);
    await tester.tap(bureauDropdown);
    await tester.pumpAndSettle();

    expect(find.text('Active Bureau'), findsOneWidget);
    expect(find.text('Inactive Bureau'), findsNothing);
  });

  testWidgets('agent effective date supports 2002 through today',
      (tester) async {
    await tester.pumpWidget(
      _dialogApp<OrganizationAgentFormResult>(
        open: (context) => showCreateOrganizationAgentDialog(
          context,
          units: const [_itDepartment, _itService],
        ),
        onResult: (_) {},
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-dialog')));
    await tester.pumpAndSettle();

    final effectiveDate = find.widgetWithText(
      ListTile,
      'Effective date',
    );
    await tester.ensureVisible(effectiveDate);
    await tester.tap(effectiveDate);
    await tester.pumpAndSettle();

    final calendar = tester.widget<CalendarDatePicker>(
      find.byType(CalendarDatePicker),
    );
    final today = DateUtils.dateOnly(DateTime.now());
    expect(calendar.firstDate, DateTime(2002));
    expect(calendar.lastDate, today);
  });

  testWidgets(
      'hierarchy selector changes leadership level and clears child selections',
      (tester) async {
    await tester.pumpWidget(
      _dialogApp<OrganizationAgentFormResult>(
        open: (context) => showCreateOrganizationAgentDialog(
          context,
          units: [
            _itDepartment,
            _itService,
            _unit(id: 'active', name: 'Active Bureau', active: true),
          ],
        ),
        onResult: (_) {},
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-dialog')));
    await tester.pumpAndSettle();

    await _selectUnit(tester, 'organization-department-dropdown', 'IT');
    expect(find.text('Head of department'), findsOneWidget);

    await _selectUnit(
      tester,
      'organization-service-dropdown',
      'IT Service',
    );
    expect(find.text('Head of service'), findsOneWidget);

    await _selectUnit(
      tester,
      'organization-bureau-dropdown',
      'Active Bureau',
    );
    expect(find.text('Head of bureau'), findsOneWidget);

    final clearBureau = find.byKey(const Key('clear-organization-bureau'));
    await tester.ensureVisible(clearBureau);
    await tester.tap(clearBureau);
    await tester.pumpAndSettle();
    expect(find.text('Head of service'), findsOneWidget);
    expect(find.byKey(const Key('clear-organization-bureau')), findsNothing);

    final clearService = find.byKey(const Key('clear-organization-service'));
    await tester.ensureVisible(clearService);
    await tester.tap(clearService);
    await tester.pumpAndSettle();
    expect(find.text('Head of department'), findsOneWidget);
    expect(find.byKey(const Key('organization-bureau-dropdown')), findsNothing);
  });

  testWidgets('agent creation can assign department leadership',
      (tester) async {
    OrganizationAgentFormResult? result;
    await tester.pumpWidget(
      _dialogApp<OrganizationAgentFormResult>(
        open: (context) => showCreateOrganizationAgentDialog(
          context,
          units: const [_itDepartment, _itService],
        ),
        onResult: (value) => result = value,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-dialog')));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    for (var index = 0; index < 6; index++) {
      await tester.enterText(fields.at(index), 'value$index');
    }
    final sexDropdown =
        find.byKey(const Key('organization-agent-sex-dropdown'));
    await tester.ensureVisible(sexDropdown);
    await tester.tap(sexDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Male').last);
    await tester.pumpAndSettle();
    await _selectUnit(tester, 'organization-department-dropdown', 'IT');
    final leadership =
        find.byKey(const Key('organization-leadership-checkbox'));
    await tester.ensureVisible(leadership);
    await tester.tap(leadership);
    final create = find.widgetWithText(FilledButton, 'Create');
    await tester.ensureVisible(create);
    await tester.tap(create);
    await tester.pumpAndSettle();

    expect(result?.unitId, _itDepartment.id);
    expect(result?.assignAsHead, isTrue);
    expect(result?.sex, AgentSex.male);
  });

  testWidgets('agent transfer can stop at service and assign its leadership',
      (tester) async {
    OrganizationTransferFormResult? result;
    await tester.pumpWidget(
      _dialogApp<OrganizationTransferFormResult>(
        open: (context) => showTransferOrganizationAgentDialog(
          context,
          units: [
            _itDepartment,
            _itService,
            _unit(id: 'active', name: 'Active Bureau', active: true),
          ],
          currentUnitId: 'active',
        ),
        onResult: (value) => result = value,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-dialog')));
    await tester.pumpAndSettle();

    await _selectUnit(tester, 'organization-department-dropdown', 'IT');
    await _selectUnit(
      tester,
      'organization-service-dropdown',
      'IT Service',
    );
    final leadership =
        find.byKey(const Key('organization-leadership-checkbox'));
    await tester.ensureVisible(leadership);
    await tester.tap(leadership);
    await tester.enterText(
      find.byType(TextFormField),
      'Service leadership transfer',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
    await tester.pumpAndSettle();

    expect(result?.unitId, _itService.id);
    expect(result?.assignAsHead, isTrue);
    expect(result?.reason, 'Service leadership transfer');
  });
}

Future<void> _selectUnit(
  WidgetTester tester,
  String key,
  String label,
) async {
  final dropdown = find.byKey(Key(key));
  await tester.ensureVisible(dropdown);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

class _DialogLauncher<T> extends StatelessWidget {
  const _DialogLauncher({
    required this.open,
    required this.onResult,
  });

  final Future<T?> Function(BuildContext context) open;
  final ValueChanged<T?> onResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          key: const Key('open-dialog'),
          onPressed: () async => onResult(await open(context)),
          child: const Text('Open dialog'),
        ),
      ),
    );
  }
}

Widget _dialogApp<T>({
  required Future<T?> Function(BuildContext context) open,
  required ValueChanged<T?> onResult,
}) {
  return MaterialApp(
    localizationsDelegates: const [S.delegate],
    supportedLocales: S.delegate.supportedLocales,
    home: _DialogLauncher<T>(open: open, onResult: onResult),
  );
}

const _agent = AgentDirectoryEntry(
  id: 'uid-aline',
  displayName: 'Aline Mbuyi',
  firstName: 'Aline',
  name: 'Mbuyi',
  postName: '',
  email: 'aline@arptc.cd',
  profilePictureUrl: null,
  jobTitle: 'Support analyst',
  organizationId: 'org-arptc',
  organizationName: 'ARPTC',
  primaryOrganizationUnitId: 'bureau-support',
  primaryOrganizationUnitName: 'Support Desk',
  primaryOrganizationUnitType: 'BUREAU',
  organizationPathNames: ['IT', 'Support Desk'],
  scopeKeys: ['org:org-arptc', 'unit:bureau-support'],
  isActive: true,
);

const _serviceUnit = OrganizationUnit(
  id: 'service-operations',
  organizationId: 'org-arptc',
  type: OrganizationUnitType.service,
  code: 'S-OPS',
  name: 'Operations',
  description: '',
  parentUnitId: 'department-it',
  parentUnitType: OrganizationUnitType.department,
  ancestorUnitIds: ['department-it'],
  pathUnitIds: ['department-it', 'service-operations'],
  pathNames: ['IT', 'Operations'],
  depth: 1,
  scopeKeys: [
    'org:org-arptc',
    'unit:department-it',
    'unit:service-operations',
  ],
  status: OrganizationStatus.active,
);

const _administrationDepartment = OrganizationUnit(
  id: 'department-administration',
  organizationId: 'org-arptc',
  type: OrganizationUnitType.department,
  code: 'D-ADM',
  name: 'Administration',
  description: '',
  parentUnitId: null,
  parentUnitType: null,
  ancestorUnitIds: [],
  pathUnitIds: ['department-administration'],
  pathNames: ['Administration'],
  depth: 0,
  scopeKeys: ['org:org-arptc', 'unit:department-administration'],
  status: OrganizationStatus.active,
);

const _itDepartment = OrganizationUnit(
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

const _itService = OrganizationUnit(
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

OrganizationUnit _unit({
  required String id,
  required String name,
  required bool active,
}) {
  return OrganizationUnit(
    id: id,
    organizationId: 'org-arptc',
    type: OrganizationUnitType.bureau,
    code: id.toUpperCase(),
    name: name,
    description: '',
    parentUnitId: 'service-it',
    parentUnitType: OrganizationUnitType.service,
    ancestorUnitIds: const ['department-it', 'service-it'],
    pathUnitIds: ['department-it', 'service-it', id],
    pathNames: ['IT', 'IT Service', name],
    depth: 2,
    scopeKeys: ['org:org-arptc', 'unit:$id'],
    status: active ? OrganizationStatus.active : OrganizationStatus.inactive,
  );
}
