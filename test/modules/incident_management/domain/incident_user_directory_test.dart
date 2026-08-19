import 'package:arptc_connect/modules/incident_management/domain/incident_enums.dart';
import 'package:arptc_connect/modules/incident_management/domain/incident_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('safe directory data maps to an incident user without private fields',
      () {
    final user = IncidentUser.fromDirectoryMap({
      'id': 'uid-1',
      'displayName': 'Aline Mbuyi',
      'email': 'aline@arptc.cd',
      'departmentId': 'department-it',
      'serviceId': 'service-support',
      'organizationPathNames': [
        'Information Technology',
        'IT Support',
        'Help Desk',
      ],
      'incidentRole': 'MANAGER',
      'matricule': 'must-not-be-exposed',
      'modulePermissions': {'ticketing': 'ADMIN'},
    });

    expect(user.id, 'uid-1');
    expect(user.departmentName, 'Information Technology');
    expect(user.serviceName, 'IT Support');
    expect(user.role, IncidentRole.manager);
    expect(user.matricule, isEmpty);
  });
}
