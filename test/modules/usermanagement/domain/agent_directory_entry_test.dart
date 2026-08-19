import 'package:arptc_connect/modules/usermanagement/domain/agent_directory_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AgentDirectoryEntry safe projection', () {
    test('parses only directory fields and normalizes optional values', () {
      final entry = AgentDirectoryEntry.fromMap(
        {
          'displayName': '  Aline Mbuyi  ',
          'firstName': ' Aline ',
          'name': ' Mbuyi ',
          'postName': ' Kanku ',
          'email': ' aline@arptc.cd ',
          'profilePictureUrl': '   ',
          'jobTitle': ' Support analyst ',
          'organizationId': ' org-arptc ',
          'organizationName': ' ARPTC ',
          'primaryOrganizationUnitId': ' bureau-support ',
          'primaryOrganizationUnitName': ' Support Desk ',
          'primaryOrganizationUnitType': ' BUREAU ',
          'organizationPathNames': [
            ' IT ',
            '',
            ' Support Desk ',
          ],
          'scopeKeys': [' org:org-arptc ', '', ' unit:bureau-support '],
          'isActive': true,
        },
        id: 'uid-1',
      );

      expect(entry.id, 'uid-1');
      expect(entry.displayName, 'Aline Mbuyi');
      expect(entry.displayNameLower, 'aline mbuyi');
      expect(entry.profilePictureUrl, isNull);
      expect(entry.organizationPathNames, ['IT', 'Support Desk']);
      expect(entry.organizationBreadcrumb, 'IT / Support Desk');
      expect(entry.scopeKeys, ['org:org-arptc', 'unit:bureau-support']);
      expect(entry.isActive, isTrue);
      expect(
        () => entry.scopeKeys.add('unit:forged'),
        throwsUnsupportedError,
      );
    });

    test('private input fields cannot influence the safe directory model', () {
      const safeFields = <String, dynamic>{
        'displayName': 'Aline Mbuyi',
        'firstName': 'Aline',
        'name': 'Mbuyi',
        'postName': 'Kanku',
        'email': 'aline@arptc.cd',
        'jobTitle': 'Support analyst',
        'organizationId': 'org-arptc',
        'organizationName': 'ARPTC',
        'primaryOrganizationUnitId': 'bureau-support',
        'primaryOrganizationUnitName': 'Support Desk',
        'primaryOrganizationUnitType': 'BUREAU',
        'organizationPathNames': ['IT', 'Support Desk'],
        'scopeKeys': ['org:org-arptc', 'unit:bureau-support'],
        'isActive': true,
      };
      final baseline = AgentDirectoryEntry.fromMap(
        safeFields,
        id: 'uid-1',
      );
      final withPrivateFields = AgentDirectoryEntry.fromMap(
        {
          ...safeFields,
          'matricule': 'SECRET-001',
          'modulePermissions': {'usermanagement': 'ADMIN'},
          'primaryAssignmentId': 'private-assignment-id',
          'notificationTokens': ['private-token'],
        },
        id: 'uid-1',
      );

      expect(_visibleValues(withPrivateFields), _visibleValues(baseline));
    });

    test('active state is strict instead of accepting truthy values', () {
      final entry = AgentDirectoryEntry.fromMap(
        const {'isActive': 'true'},
        id: 'uid-1',
      );

      expect(entry.isActive, isFalse);
    });
  });
}

List<Object?> _visibleValues(AgentDirectoryEntry entry) => [
      entry.id,
      entry.displayName,
      entry.firstName,
      entry.name,
      entry.postName,
      entry.email,
      entry.profilePictureUrl,
      entry.jobTitle,
      entry.organizationId,
      entry.organizationName,
      entry.primaryOrganizationUnitId,
      entry.primaryOrganizationUnitName,
      entry.primaryOrganizationUnitType,
      entry.organizationPathNames,
      entry.scopeKeys,
      entry.isActive,
    ];
