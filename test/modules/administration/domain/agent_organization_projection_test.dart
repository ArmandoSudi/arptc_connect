import 'package:arptc_connect/modules/administration/domain/models/agent.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shared Agent round-trips the schema-v2 organization projection', () {
    final agent = Agent.fromJson(const <String, dynamic>{
      'name': 'Mabamba',
      'email': 'armando@example.com',
      'organizationSchemaVersion': 2,
      'organizationId': 'org-arptc',
      'organizationName': 'ARPTC',
      'primaryOrganizationUnitId': 'bureau-support',
      'primaryOrganizationUnitName': 'Support',
      'primaryOrganizationUnitType': 'BUREAU',
      'primaryAssignmentId': 'assignment-current',
      'organizationAncestorUnitIds': <String>[
        'department-it',
        'service-operations',
      ],
      'organizationPathUnitIds': <String>[
        'department-it',
        'service-operations',
        'bureau-support',
      ],
      'organizationPathNames': <String>['IT', 'Operations', 'Support'],
      'scopeKeys': <String>[
        'org:org-arptc',
        'unit:department-it',
        'unit:service-operations',
        'unit:bureau-support',
      ],
      'departmentId': 'department-it',
      'department': 'IT',
      'serviceId': 'service-operations',
      'service': 'Operations',
      'bureauId': 'bureau-support',
      'bureau': 'Support',
      'jobTitle': 'Support analyst',
      'isActive': true,
      'modulePermissions': <String, String>{
        'usermanagement': 'USER',
      },
    });

    expect(agent.organizationId, 'org-arptc');
    expect(agent.primaryOrganizationUnitId, 'bureau-support');
    expect(agent.organizationPathUnitIds, hasLength(3));
    expect(agent.scopeKeys, contains('unit:department-it'));
    expect(agent.modulePermissions['usermanagement'], 'USER');

    final encoded = agent.toJson();
    expect(encoded['primaryAssignmentId'], 'assignment-current');
    expect(encoded['departmentId'], 'department-it');
    expect(encoded, isNot(contains('direction')));
  });
}
