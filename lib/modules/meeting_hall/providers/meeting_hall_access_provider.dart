import 'package:arptc_connect/core/firebase_providers.dart';
import 'package:arptc_connect/modules/profile/presentation/controllers/profile_provider.dart';
import 'package:arptc_connect/modules/usermanagement/domain/modules.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MeetingHallRole {
  none('NONE', 'No access'),
  user('USER', 'User'),
  manager('MANAGER', 'Manager'),
  admin('ADMIN', 'Admin');

  const MeetingHallRole(this.value, this.label);

  final String value;
  final String label;

  static MeetingHallRole fromValue(String? value) {
    final normalized = (value ?? '').trim().toUpperCase();
    for (final role in MeetingHallRole.values) {
      if (role.value == normalized) {
        return role;
      }
    }
    return MeetingHallRole.none;
  }
}

extension MeetingHallRoleX on MeetingHallRole {
  bool get canRead => this != MeetingHallRole.none;
  bool get canCreateReservation =>
      this == MeetingHallRole.user || this == MeetingHallRole.manager;
  bool get canManageReservations => this == MeetingHallRole.manager;
  bool get canManageHalls => this == MeetingHallRole.manager;
  bool get isReadOnlyAdmin => this == MeetingHallRole.admin;
}

class MeetingHallUser {
  const MeetingHallUser({
    required this.id,
    required this.displayName,
    required this.email,
    required this.role,
  });

  final String id;
  final String displayName;
  final String email;
  final MeetingHallRole role;
}

final currentMeetingHallRoleProvider =
    Provider<AsyncValue<MeetingHallRole>>((ref) {
  final profileAsync = ref.watch(liveAgentProfileProvider);
  return profileAsync.whenData(_roleFromProfile);
});

final currentMeetingHallUserProvider =
    Provider<AsyncValue<MeetingHallUser>>((ref) {
  final profileAsync = ref.watch(liveAgentProfileProvider);
  return profileAsync.whenData((profile) {
    final authUser = ref.read(firebaseAuthProvider).currentUser;
    final profileId = _string(profile['id']);
    final displayName = _displayNameFromProfile(profile);
    return MeetingHallUser(
      id: profileId.isNotEmpty ? profileId : authUser?.uid ?? '',
      displayName: displayName.isNotEmpty ? displayName : 'Agent',
      email: _string(profile['email']).isNotEmpty
          ? _string(profile['email'])
          : authUser?.email ?? '',
      role: _roleFromProfile(profile),
    );
  });
});

MeetingHallRole _roleFromProfile(Map<String, dynamic> profile) {
  final rawPermissions = profile['modulePermissions'];
  final permissions = Modules.normalizePermissions(
    rawPermissions is Map<String, dynamic>
        ? rawPermissions
        : rawPermissions is Map
            ? Map<String, dynamic>.from(rawPermissions)
            : null,
    includeDefaultModules: false,
  );

  final roleValue = permissions['meetinghall'] ??
      permissions['meeting_hall'] ??
      permissions['meeting-hall'] ??
      permissions['meeting'] ??
      ModuleAccessRole.none.value;

  return MeetingHallRole.fromValue(roleValue);
}

String _displayNameFromProfile(Map<String, dynamic> profile) {
  final pieces = [
    _string(profile['firstName']),
    _string(profile['name']),
    _string(profile['postName']),
  ].where((piece) => piece.isNotEmpty).toList();

  if (pieces.isNotEmpty) {
    return pieces.join(' ');
  }
  return _string(profile['fullName']);
}

String _string(dynamic value) => value?.toString().trim() ?? '';
