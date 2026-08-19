import 'dart:async';

import 'package:arptc_connect/generated/l10n.dart';
import 'package:arptc_connect/modules/authentication/providers/authorized_session_provider.dart';
import 'package:arptc_connect/modules/usermanagement/domain/agent_directory_entry.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization_unit.dart';
import 'package:arptc_connect/modules/usermanagement/domain/unplaced_agent_summary.dart';
import 'package:arptc_connect/modules/usermanagement/domain/user_management_access.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/controllers/management_providers.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/screens/agent_directory_screen.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/screens/organization_structure_screen.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/screens/organization_unit_details_screen.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/screens/organizations_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('organization list rebuilds from live provider emissions',
      (tester) async {
    final organizations = StreamController<List<Organization>>();
    addTearDown(organizations.close);
    await _setWideSurface(tester);

    await tester.pumpWidget(
      _testApp(
        overrides: [
          umFilteredOrganizationsProvider.overrideWith(
            (ref, query) => organizations.stream,
          ),
        ],
        child: const OrganizationsScreen(),
      ),
    );
    organizations.add([_organization(name: 'ARPTC')]);
    await tester.pumpAndSettle();
    expect(find.text('ARPTC'), findsOneWidget);

    organizations.add([_organization(name: 'ARPTC Connect')]);
    await tester.pumpAndSettle();
    expect(find.text('ARPTC'), findsNothing);
    expect(find.text('ARPTC Connect'), findsOneWidget);
  });

  testWidgets('hierarchy list rebuilds from live unit emissions',
      (tester) async {
    final units = StreamController<List<OrganizationUnit>>();
    addTearDown(units.close);
    await _setWideSurface(tester);

    await tester.pumpWidget(
      _testApp(
        overrides: [
          umOrganizationsProvider.overrideWith(
            (ref) => Stream.value([_organization(name: 'ARPTC')]),
          ),
          umFilteredOrganizationUnitsProvider.overrideWith(
            (ref, query) => units.stream,
          ),
        ],
        child: const OrganizationStructureScreen(),
      ),
    );
    units.add([_department(name: 'Information Technology')]);
    await tester.pumpAndSettle();
    expect(find.text('Information Technology'), findsOneWidget);

    units.add([_department(name: 'Digital Technologies')]);
    await tester.pumpAndSettle();
    expect(find.text('Information Technology'), findsNothing);
    expect(find.text('Digital Technologies'), findsOneWidget);
  });

  testWidgets('structure expands departments into services and bureaux',
      (tester) async {
    await _setWideSurface(tester);
    final department = _department(name: 'Information Technology');
    final service = _service(
      department: department,
      name: 'Infrastructure Service',
    );
    final bureau = _bureau(
      department: department,
      service: service,
      name: 'Network Bureau',
    );

    await tester.pumpWidget(
      _testApp(
        overrides: [
          umOrganizationsProvider.overrideWith(
            (ref) => Stream.value([_organization(name: 'ARPTC')]),
          ),
          umFilteredOrganizationUnitsProvider.overrideWith(
            (ref, query) => Stream.value([department, service, bureau]),
          ),
        ],
        child: const OrganizationStructureScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(department.name), findsOneWidget);
    expect(find.text(service.name), findsNothing);
    expect(find.text(bureau.name), findsNothing);
    expect(find.text(department.code), findsNothing);
    expect(find.text(department.description), findsNothing);

    await tester.tap(find.byKey(Key('expand-unit-${department.id}')));
    await tester.pumpAndSettle();
    expect(find.text(service.name), findsOneWidget);
    expect(find.text(bureau.name), findsNothing);

    await tester.tap(find.byKey(Key('expand-unit-${service.id}')));
    await tester.pumpAndSettle();
    expect(find.text(bureau.name), findsOneWidget);

    await tester.tap(find.byKey(Key('expand-unit-${department.id}')));
    await tester.pumpAndSettle();
    expect(find.text(service.name), findsNothing);
    expect(find.text(bureau.name), findsNothing);

    await tester.enterText(find.byType(TextFormField), 'Network');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(find.text(department.name), findsOneWidget);
    expect(find.text(service.name), findsOneWidget);
    expect(find.text(bureau.name), findsOneWidget);
  });

  testWidgets('agent directory rebuilds from live projection emissions',
      (tester) async {
    final agents = StreamController<List<AgentDirectoryEntry>>();
    addTearDown(agents.close);
    await _setWideSurface(tester);

    await tester.pumpWidget(
      _testApp(
        overrides: [
          umOrganizationsProvider.overrideWith(
            (ref) => Stream.value([_organization(name: 'ARPTC')]),
          ),
          umOrganizationUnitsProvider.overrideWith(
            (ref, organizationId) => Stream.value(const <OrganizationUnit>[]),
          ),
          umFilteredAgentDirectoryProvider.overrideWith(
            (ref, query) => agents.stream,
          ),
          umUnplacedAgentsProvider.overrideWith(
            (ref) async => const UnplacedAgentPage(
              items: [],
              nextCursor: null,
              scannedCount: 0,
            ),
          ),
        ],
        child: const AgentDirectoryScreen(),
      ),
    );
    agents.add([_agent(displayName: 'Aline Mbuyi')]);
    await tester.pumpAndSettle();
    expect(find.text('Aline Mbuyi'), findsOneWidget);

    agents.add([_agent(displayName: 'Aline Kabongo')]);
    await tester.pumpAndSettle();
    expect(find.text('Aline Mbuyi'), findsNothing);
    expect(find.text('Aline Kabongo'), findsOneWidget);
  });

  testWidgets('manager can assign leadership from the unit details card',
      (tester) async {
    await _setWideSurface(tester);
    final unit = _department(name: 'Information Technology');

    await tester.pumpWidget(
      _testApp(
        overrides: [
          umOrganizationUnitDetailsProvider.overrideWith(
            (ref, identity) => Stream.value(unit),
          ),
          umUnitOrganizationAssignmentsProvider.overrideWith(
            (ref, query) => Stream.value(const []),
          ),
          umFilteredAgentDirectoryProvider.overrideWith(
            (ref, query) => Stream.value([
              _agent(displayName: 'Aline Mbuyi'),
            ]),
          ),
        ],
        child: OrganizationUnitDetailsScreen(
          organizationId: unit.organizationId,
          unitId: unit.id,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('assign-unit-leadership')), findsOneWidget);
    await tester.tap(find.byKey(const Key('assign-unit-leadership')));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    expect(find.text('Aline Mbuyi'), findsOneWidget);
  });

  testWidgets('read-only administrator cannot assign unit leadership',
      (tester) async {
    await _setWideSurface(tester);
    final unit = _department(name: 'Information Technology');

    await tester.pumpWidget(
      _testApp(
        role: UserManagementRole.admin,
        overrides: [
          umOrganizationUnitDetailsProvider.overrideWith(
            (ref, identity) => Stream.value(unit),
          ),
          umUnitOrganizationAssignmentsProvider.overrideWith(
            (ref, query) => Stream.value(const []),
          ),
        ],
        child: OrganizationUnitDetailsScreen(
          organizationId: unit.organizationId,
          unitId: unit.id,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('assign-unit-leadership')), findsNothing);
  });
}

Future<void> _setWideSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1200, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Widget _testApp({
  required List<Override> overrides,
  required Widget child,
  UserManagementRole role = UserManagementRole.manager,
}) {
  final profile = <String, dynamic>{
    'isActive': true,
    'organizationId': 'org-arptc',
    'modulePermissions': <String, String>{
      'usermanagement': role.name.toUpperCase(),
    },
  };
  return ProviderScope(
    overrides: [
      authorizedAgentProfileProvider.overrideWithValue(
        AsyncValue.data(profile),
      ),
      userManagementAccessPolicyProvider.overrideWithValue(
        UserManagementAccessPolicy(role),
      ),
      ...overrides,
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [S.delegate],
      supportedLocales: S.delegate.supportedLocales,
      home: child,
    ),
  );
}

Organization _organization({required String name}) => Organization(
      id: 'org-arptc',
      code: 'ARPTC',
      name: name,
      description: 'National regulator',
      status: OrganizationStatus.active,
    );

OrganizationUnit _department({required String name}) => OrganizationUnit(
      id: 'department-it',
      organizationId: 'org-arptc',
      type: OrganizationUnitType.department,
      code: 'D-IT',
      name: name,
      description: 'Responsible for enterprise technology operations',
      parentUnitId: null,
      parentUnitType: null,
      ancestorUnitIds: const [],
      pathUnitIds: const ['department-it'],
      pathNames: [name],
      depth: 0,
      scopeKeys: const ['org:org-arptc', 'unit:department-it'],
      status: OrganizationStatus.active,
    );

OrganizationUnit _service({
  required OrganizationUnit department,
  required String name,
}) =>
    OrganizationUnit(
      id: 'service-infrastructure',
      organizationId: department.organizationId,
      type: OrganizationUnitType.service,
      code: 'S-INFRA',
      name: name,
      description: 'Infrastructure operations',
      parentUnitId: department.id,
      parentUnitType: OrganizationUnitType.department,
      ancestorUnitIds: [department.id],
      pathUnitIds: [department.id, 'service-infrastructure'],
      pathNames: [department.name, name],
      depth: 1,
      scopeKeys: [
        'org:${department.organizationId}',
        'unit:${department.id}',
        'unit:service-infrastructure',
      ],
      status: OrganizationStatus.active,
    );

OrganizationUnit _bureau({
  required OrganizationUnit department,
  required OrganizationUnit service,
  required String name,
}) =>
    OrganizationUnit(
      id: 'bureau-network',
      organizationId: department.organizationId,
      type: OrganizationUnitType.bureau,
      code: 'B-NET',
      name: name,
      description: 'Network operations',
      parentUnitId: service.id,
      parentUnitType: OrganizationUnitType.service,
      ancestorUnitIds: [department.id, service.id],
      pathUnitIds: [department.id, service.id, 'bureau-network'],
      pathNames: [department.name, service.name, name],
      depth: 2,
      scopeKeys: [
        'org:${department.organizationId}',
        'unit:${department.id}',
        'unit:${service.id}',
        'unit:bureau-network',
      ],
      status: OrganizationStatus.active,
    );

AgentDirectoryEntry _agent({required String displayName}) =>
    AgentDirectoryEntry(
      id: 'agent-aline',
      displayName: displayName,
      firstName: 'Aline',
      name: 'Kabongo',
      postName: '',
      email: 'aline@example.com',
      profilePictureUrl: null,
      jobTitle: 'Support analyst',
      organizationId: 'org-arptc',
      organizationName: 'ARPTC',
      primaryOrganizationUnitId: 'bureau-support',
      primaryOrganizationUnitName: 'Support',
      primaryOrganizationUnitType: 'BUREAU',
      organizationPathNames: const ['IT', 'Operations', 'Support'],
      scopeKeys: const [
        'org:org-arptc',
        'unit:department-it',
        'unit:service-operations',
        'unit:bureau-support',
      ],
      isActive: true,
    );
