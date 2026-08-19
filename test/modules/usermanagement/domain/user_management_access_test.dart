import 'package:arptc_connect/modules/usermanagement/domain/user_management_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserManagementRole.parse', () {
    test('normalizes supported roles and rejects unknown values', () {
      expect(UserManagementRole.parse(' user '), UserManagementRole.user);
      expect(UserManagementRole.parse('manager'), UserManagementRole.manager);
      expect(UserManagementRole.parse('ADMIN'), UserManagementRole.admin);
      expect(UserManagementRole.parse('reviewer'), UserManagementRole.none);
      expect(UserManagementRole.parse(null), UserManagementRole.none);
    });
  });

  group('UserManagementAccessPolicy', () {
    test('NONE cannot open or inspect User Management', () {
      const policy = UserManagementAccessPolicy(UserManagementRole.none);

      expect(policy.canOpenModule, isFalse);
      expect(policy.canReadDirectory, isFalse);
      expect(policy.canReadPrivateProfiles, isFalse);
      expect(policy.canReadAudit, isFalse);
      expect(policy.canManageOrganization, isFalse);
      expect(policy.isReadOnlySupervisor, isFalse);
    });

    test('USER can access only safe directory capabilities', () {
      const policy = UserManagementAccessPolicy(UserManagementRole.user);

      expect(policy.canOpenModule, isTrue);
      expect(policy.canReadDirectory, isTrue);
      expect(policy.canReadPrivateProfiles, isFalse);
      expect(policy.canReadAudit, isFalse);
      expect(policy.canManageOrganization, isFalse);
      expect(policy.isReadOnlySupervisor, isFalse);
    });

    test('MANAGER can inspect private data and mutate organizations', () {
      const policy = UserManagementAccessPolicy(UserManagementRole.manager);

      expect(policy.canOpenModule, isTrue);
      expect(policy.canReadDirectory, isTrue);
      expect(policy.canReadPrivateProfiles, isTrue);
      expect(policy.canReadAudit, isTrue);
      expect(policy.canManageOrganization, isTrue);
      expect(policy.isReadOnlySupervisor, isFalse);
    });

    test('ADMIN is a private-data supervisor without mutation rights', () {
      const policy = UserManagementAccessPolicy(UserManagementRole.admin);

      expect(policy.canOpenModule, isTrue);
      expect(policy.canReadDirectory, isTrue);
      expect(policy.canReadPrivateProfiles, isTrue);
      expect(policy.canReadAudit, isTrue);
      expect(policy.canManageOrganization, isFalse);
      expect(policy.isReadOnlySupervisor, isTrue);
    });

    test('reads the canonical and compatibility permission keys', () {
      expect(
        UserManagementAccessPolicy.fromProfile({
          'modulePermissions': {'usermanagement': 'MANAGER'},
        }).role,
        UserManagementRole.manager,
      );
      expect(
        UserManagementAccessPolicy.fromProfile({
          'modulePermissions': {'user_management': 'ADMIN'},
        }).role,
        UserManagementRole.admin,
      );
    });

    test('canonical permission wins and malformed profiles fail closed', () {
      expect(
        UserManagementAccessPolicy.fromProfile({
          'modulePermissions': {
            'usermanagement': 'USER',
            'user_management': 'MANAGER',
          },
        }).role,
        UserManagementRole.user,
      );
      expect(
        UserManagementAccessPolicy.fromProfile({
          'modulePermissions': 'MANAGER',
        }).role,
        UserManagementRole.none,
      );
      expect(
        UserManagementAccessPolicy.fromProfile(const {}).role,
        UserManagementRole.none,
      );
    });
  });
}
