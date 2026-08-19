import 'package:arptc_connect/modules/usermanagement/application/organization_hierarchy_loader.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization_query.dart';
import 'package:arptc_connect/modules/usermanagement/domain/organization_unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads every active hierarchy page instead of truncating at 100 units',
      () async {
    final requestedCursors = <String?>[];
    final loader = OrganizationHierarchyLoader(
      fetchPage: ({required query, required page}) async {
        expect(query.organizationId, 'org-arptc');
        expect(query.status, OrganizationListStatusFilter.active);
        expect(page.limit, 100);
        requestedCursors.add(page.afterId);
        if (page.afterId == null) {
          return OrganizationPage(
            items: List.generate(
              100,
              (index) => _unit('bureau-$index', 'Bureau $index'),
            ),
            nextCursor: const OrganizationPageCursor(
              nameLower: 'bureau 99',
              id: 'bureau-99',
            ),
          );
        }
        return const OrganizationPage(
          items: [
            _department,
            _serviceOne,
            _serviceTwo,
            _serviceThree,
            _serviceFour,
          ],
          nextCursor: null,
        );
      },
    );

    final units = await loader.load(' org-arptc ');

    expect(requestedCursors, [null, 'bureau-99']);
    expect(
      units.where((unit) => unit.type == OrganizationUnitType.service).length,
      4,
    );
    expect(units.map((unit) => unit.id), contains('service-four'));
  });

  test('fails rather than silently truncating an oversized hierarchy',
      () async {
    final loader = OrganizationHierarchyLoader(
      pageSize: 2,
      maximumUnits: 2,
      fetchPage: ({required query, required page}) async =>
          const OrganizationPage(
        items: [_department, _serviceOne],
        nextCursor: OrganizationPageCursor(
          nameLower: 'service one',
          id: 'service-one',
        ),
      ),
    );

    await expectLater(
      loader.load('org-arptc'),
      throwsA(isA<StateError>()),
    );
  });
}

OrganizationUnit _unit(String id, String name) => OrganizationUnit(
      id: id,
      organizationId: 'org-arptc',
      type: OrganizationUnitType.bureau,
      code: id.toUpperCase(),
      name: name,
      description: '',
      parentUnitId: 'service-one',
      parentUnitType: OrganizationUnitType.service,
      ancestorUnitIds: const ['department-it', 'service-one'],
      pathUnitIds: ['department-it', 'service-one', id],
      pathNames: ['IT', 'Service One', name],
      depth: 2,
      scopeKeys: ['org:org-arptc', 'unit:$id'],
      status: OrganizationStatus.active,
    );

const _department = OrganizationUnit(
  id: 'department-it',
  organizationId: 'org-arptc',
  type: OrganizationUnitType.department,
  code: 'D-IT',
  name: "Direction des systemes d'informations",
  description: '',
  parentUnitId: null,
  parentUnitType: null,
  ancestorUnitIds: [],
  pathUnitIds: ['department-it'],
  pathNames: ["Direction des systemes d'informations"],
  depth: 0,
  scopeKeys: ['org:org-arptc', 'unit:department-it'],
  status: OrganizationStatus.active,
);

const _serviceOne = OrganizationUnit(
  id: 'service-one',
  organizationId: 'org-arptc',
  type: OrganizationUnitType.service,
  code: 'S-1',
  name: 'Service One',
  description: '',
  parentUnitId: 'department-it',
  parentUnitType: OrganizationUnitType.department,
  ancestorUnitIds: ['department-it'],
  pathUnitIds: ['department-it', 'service-one'],
  pathNames: ["Direction des systemes d'informations", 'Service One'],
  depth: 1,
  scopeKeys: ['org:org-arptc', 'unit:service-one'],
  status: OrganizationStatus.active,
);

const _serviceTwo = OrganizationUnit(
  id: 'service-two',
  organizationId: 'org-arptc',
  type: OrganizationUnitType.service,
  code: 'S-2',
  name: 'Service Two',
  description: '',
  parentUnitId: 'department-it',
  parentUnitType: OrganizationUnitType.department,
  ancestorUnitIds: ['department-it'],
  pathUnitIds: ['department-it', 'service-two'],
  pathNames: ["Direction des systemes d'informations", 'Service Two'],
  depth: 1,
  scopeKeys: ['org:org-arptc', 'unit:service-two'],
  status: OrganizationStatus.active,
);

const _serviceThree = OrganizationUnit(
  id: 'service-three',
  organizationId: 'org-arptc',
  type: OrganizationUnitType.service,
  code: 'S-3',
  name: 'Service Three',
  description: '',
  parentUnitId: 'department-it',
  parentUnitType: OrganizationUnitType.department,
  ancestorUnitIds: ['department-it'],
  pathUnitIds: ['department-it', 'service-three'],
  pathNames: ["Direction des systemes d'informations", 'Service Three'],
  depth: 1,
  scopeKeys: ['org:org-arptc', 'unit:service-three'],
  status: OrganizationStatus.active,
);

const _serviceFour = OrganizationUnit(
  id: 'service-four',
  organizationId: 'org-arptc',
  type: OrganizationUnitType.service,
  code: 'S-4',
  name: 'Service Four',
  description: '',
  parentUnitId: 'department-it',
  parentUnitType: OrganizationUnitType.department,
  ancestorUnitIds: ['department-it'],
  pathUnitIds: ['department-it', 'service-four'],
  pathNames: ["Direction des systemes d'informations", 'Service Four'],
  depth: 1,
  scopeKeys: ['org:org-arptc', 'unit:service-four'],
  status: OrganizationStatus.active,
);
