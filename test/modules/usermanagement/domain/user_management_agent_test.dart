import 'package:arptc_connect/modules/usermanagement/domain/user_management_agent.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserManagementAgent organization fields', () {
    test('reads canonical names separately from Firestore IDs', () {
      final agent = UserManagementAgent.fromMap(
        {
          'firstName': 'Aline',
          'name': 'Mbuyi',
          'postName': 'Kanku',
          'matricule': 'ARP-001',
          'sex': 'female',
          'email': 'aline@arptc.cd',
          'position': 'BUREAU_ATTACHE',
          'department': 'Information Technology',
          'departmentId': 'dep-it',
          'service': 'IT Support',
          'serviceId': 'svc-support',
          'bureau': 'Help Desk',
          'bureauId': 'bureau-helpdesk',
          'organizationSchemaVersion': 2,
          'organizationId': 'org-arptc',
          'organizationName': 'ARPTC',
          'primaryOrganizationUnitId': 'bureau-helpdesk',
          'primaryOrganizationUnitName': 'Help Desk',
          'primaryOrganizationUnitType': 'BUREAU',
          'primaryAssignmentId': 'assignment-1',
          'organizationAncestorUnitIds': ['dep-it', 'svc-support'],
          'organizationPathUnitIds': [
            'dep-it',
            'svc-support',
            'bureau-helpdesk',
          ],
          'organizationPathNames': [
            'Information Technology',
            'IT Support',
            'Help Desk',
          ],
          'scopeKeys': ['org:org-arptc', 'unit:bureau-helpdesk'],
          'isActive': true,
          'modulePermissions': {'ticketing': 'USER'},
        },
        id: 'firebase-auth-uid',
      );

      expect(agent.id, 'firebase-auth-uid');
      expect(agent.sex, AgentSex.female);
      expect(agent.department, 'Information Technology');
      expect(agent.departmentId, 'dep-it');
      expect(agent.service, 'IT Support');
      expect(agent.serviceId, 'svc-support');
      expect(agent.bureau, 'Help Desk');
      expect(agent.bureauId, 'bureau-helpdesk');
      expect(agent.organizationId, 'org-arptc');
      expect(agent.primaryOrganizationUnitId, 'bureau-helpdesk');
      expect(agent.primaryAssignmentId, 'assignment-1');
      expect(agent.organizationPathNames.last, 'Help Desk');
    });

    test('does not interpret the legacy direction field as a department ID',
        () {
      final agent = UserManagementAgent.fromMap(
        {
          'email': 'legacy@arptc.cd',
          'direction': 'legacy-department-id',
        },
        id: 'firebase-auth-uid',
      );

      expect(agent.department, isEmpty);
      expect(agent.departmentId, isEmpty);
      expect(agent.sex, isNull);
    });

    test('reads legacy genre when the canonical sex field is absent', () {
      final agent = UserManagementAgent.fromMap(
        {
          'firstName': 'Aline',
          'name': 'Mbuyi',
          'postName': 'Kanku',
          'matricule': 'ARP-001',
          'genre': 'female',
          'email': 'aline@arptc.cd',
          'isActive': true,
          'modulePermissions': <String, String>{},
        },
        id: 'firebase-auth-uid',
      );

      expect(agent.sex, AgentSex.female);
    });

    test('writes canonical organization fields without direction', () {
      const agent = UserManagementAgent(
        id: 'firebase-auth-uid',
        firstName: 'Aline',
        name: 'Mbuyi',
        postName: 'Kanku',
        matricule: 'ARP-001',
        sex: AgentSex.female,
        email: 'aline@arptc.cd',
        emailLower: 'aline@arptc.cd',
        jobTitle: 'Support analyst',
        department: 'Information Technology',
        departmentId: 'dep-it',
        service: 'IT Support',
        serviceId: 'svc-support',
        bureau: 'Help Desk',
        bureauId: 'bureau-helpdesk',
        organizationId: 'org-arptc',
        organizationName: 'ARPTC',
        primaryOrganizationUnitId: 'bureau-helpdesk',
        primaryOrganizationUnitName: 'Help Desk',
        primaryOrganizationUnitType: 'BUREAU',
        primaryAssignmentId: 'assignment-1',
        organizationAncestorUnitIds: ['dep-it', 'svc-support'],
        organizationPathUnitIds: [
          'dep-it',
          'svc-support',
          'bureau-helpdesk',
        ],
        organizationPathNames: [
          'Information Technology',
          'IT Support',
          'Help Desk',
        ],
        scopeKeys: ['org:org-arptc', 'unit:bureau-helpdesk'],
        isActive: true,
        modulePermissions: {'ticketing': 'USER'},
      );

      final map = agent.toMap();

      expect(map['department'], 'Information Technology');
      expect(map['departmentId'], 'dep-it');
      expect(map['service'], 'IT Support');
      expect(map['serviceId'], 'svc-support');
      expect(map['bureau'], 'Help Desk');
      expect(map['bureauId'], 'bureau-helpdesk');
      expect(map['organizationId'], 'org-arptc');
      expect(map['sex'], 'female');
      expect(map['primaryOrganizationUnitId'], 'bureau-helpdesk');
      expect(map['primaryAssignmentId'], 'assignment-1');
      expect(map['organizationSchemaVersion'], 2);
      expect(map, isNot(contains('direction')));
    });
  });
}
