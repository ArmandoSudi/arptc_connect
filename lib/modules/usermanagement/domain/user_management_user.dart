class UserManagementUser {
  final String id;
  final String firstName;
  final String name;
  final String postName;
  final String matricule;
  final String? email;
  final String? profilePictureUrl;
  final List<String> roles;

  const UserManagementUser({
    required this.id,
    required this.firstName,
    required this.name,
    required this.postName,
    required this.matricule,
    this.email,
    this.profilePictureUrl,
    required this.roles,
  });

  String get displayName {
    final chunks = [
      firstName.trim(),
      name.trim(),
      postName.trim(),
    ].where((chunk) => chunk.isNotEmpty).toList();
    return chunks.join(' ');
  }

  String get displayNameLower => displayName.toLowerCase();

  factory UserManagementUser.fromMap(Map<String, dynamic> map,
      {required String id}) {
    final rawRoles = (map['roles'] as List<dynamic>? ?? const []);
    final parsedRoles = rawRoles.map((role) => role.toString()).toList();
    final parsedName = _parseNames(map);

    return UserManagementUser(
      id: id,
      firstName: parsedName.firstName,
      name: parsedName.lastName,
      postName: (map['postName'] as String?)?.trim() ?? '',
      matricule: (map['matricule'] as String?)?.trim() ?? '',
      email: (map['email'] as String?)?.trim(),
      profilePictureUrl: _extractProfilePictureUrl(map),
      roles: parsedRoles,
    );
  }

  static String? _extractProfilePictureUrl(Map<String, dynamic> map) {
    final candidates = [
      map['profilePictureUrl'],
      map['photoUrl'],
      map['photoURL'],
      map['avatarUrl'],
      map['imageUrl'],
    ];

    for (final candidate in candidates) {
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }

    return null;
  }
}

class _NameParts {
  final String firstName;
  final String lastName;

  const _NameParts(this.firstName, this.lastName);
}

_NameParts _parseNames(Map<String, dynamic> map) {
  final firstName = (map['firstName'] as String?)?.trim();
  final lastName = (map['name'] as String?)?.trim();

  if (firstName != null &&
      firstName.isNotEmpty &&
      lastName != null &&
      lastName.isNotEmpty) {
    return _NameParts(firstName, lastName);
  }

  final fullNameFromMap =
      ((map['fullName'] as String?)?.trim().isNotEmpty == true)
          ? (map['fullName'] as String).trim()
          : ((map['name'] as String?)?.trim() ?? '');

  if (fullNameFromMap.isEmpty) {
    return const _NameParts('', '');
  }

  final parts = fullNameFromMap
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) {
    return const _NameParts('', '');
  }
  if (parts.length == 1) {
    return _NameParts(parts.first, '');
  }

  return _NameParts(parts.first, parts.sublist(1).join(' '));
}
