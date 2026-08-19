import 'package:arptc_connect/modules/usermanagement/domain/user_management_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserManagement role user stories', () {
    test('only MANAGER receives organization mutation authority', () {
      final policies = {
        for (final role in UserManagementRole.values)
          role: UserManagementAccessPolicy(role),
      };

      expect(
          policies[UserManagementRole.manager]!.canManageOrganization, isTrue);
      for (final role in const [
        UserManagementRole.none,
        UserManagementRole.user,
        UserManagementRole.admin,
      ]) {
        expect(
          policies[role]!.canManageOrganization,
          isFalse,
          reason: '$role must not mutate organizations, units, or agents',
        );
      }
    });

    test('ADMIN supervises private profiles and audit data read-only', () {
      const policy = UserManagementAccessPolicy(UserManagementRole.admin);

      expect(policy.canOpenModule, isTrue);
      expect(policy.canReadDirectory, isTrue);
      expect(policy.canReadPrivateProfiles, isTrue);
      expect(policy.canReadAudit, isTrue);
      expect(policy.canManageOrganization, isFalse);
      expect(policy.isReadOnlySupervisor, isTrue);
    });

    test('USER receives safe-directory access without private or audit access',
        () {
      const policy = UserManagementAccessPolicy(UserManagementRole.user);

      expect(policy.canOpenModule, isTrue);
      expect(policy.canReadDirectory, isTrue);
      expect(policy.canReadPrivateProfiles, isFalse);
      expect(policy.canReadAudit, isFalse);
      expect(policy.canManageOrganization, isFalse);
      expect(policy.isReadOnlySupervisor, isFalse);
    });

    test('NONE fails closed for every UserManagement capability', () {
      const policy = UserManagementAccessPolicy(UserManagementRole.none);

      expect(policy.canOpenModule, isFalse);
      expect(policy.canReadDirectory, isFalse);
      expect(policy.canReadPrivateProfiles, isFalse);
      expect(policy.canReadAudit, isFalse);
      expect(policy.canManageOrganization, isFalse);
      expect(policy.isReadOnlySupervisor, isFalse);
    });

    test('profile parsing accepts role casing and the compatibility key', () {
      for (final value in ['manager', ' Manager ', 'MANAGER']) {
        expect(
          UserManagementAccessPolicy.fromProfile({
            'modulePermissions': {'usermanagement': value},
          }).role,
          UserManagementRole.manager,
        );
      }
      expect(
        UserManagementAccessPolicy.fromProfile({
          'modulePermissions': {'user_management': 'ADMIN'},
        }).role,
        UserManagementRole.admin,
      );
    });

    test(
        'canonical permission is authoritative and malformed data fails closed',
        () {
      expect(
        UserManagementAccessPolicy.fromProfile({
          'modulePermissions': {
            'usermanagement': 'NONE',
            'user_management': 'MANAGER',
          },
        }).role,
        UserManagementRole.none,
      );
      for (final permissions in <Object?>[
        null,
        'MANAGER',
        ['MANAGER'],
        42,
      ]) {
        expect(
          UserManagementAccessPolicy.fromProfile({
            'modulePermissions': permissions,
          }).role,
          UserManagementRole.none,
        );
      }
      expect(
        UserManagementAccessPolicy.fromProfile({
          'modulePermissions': {'usermanagement': true},
        }).role,
        UserManagementRole.none,
      );
    });
  });
}
