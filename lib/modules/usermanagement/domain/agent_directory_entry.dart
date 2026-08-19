class AgentDirectoryEntry {
  const AgentDirectoryEntry({
    required this.id,
    required this.displayName,
    required this.firstName,
    required this.name,
    required this.postName,
    required this.email,
    required this.profilePictureUrl,
    required this.jobTitle,
    required this.organizationId,
    required this.organizationName,
    required this.primaryOrganizationUnitId,
    required this.primaryOrganizationUnitName,
    required this.primaryOrganizationUnitType,
    this.departmentId = '',
    this.serviceId = '',
    this.bureauId = '',
    required this.organizationPathNames,
    required this.scopeKeys,
    required this.isActive,
  });

  final String id;
  final String displayName;
  final String firstName;
  final String name;
  final String postName;
  final String email;
  final String? profilePictureUrl;
  final String jobTitle;
  final String organizationId;
  final String organizationName;
  final String primaryOrganizationUnitId;
  final String primaryOrganizationUnitName;
  final String primaryOrganizationUnitType;
  final String departmentId;
  final String serviceId;
  final String bureauId;
  final List<String> organizationPathNames;
  final List<String> scopeKeys;
  final bool isActive;

  String get displayNameLower => displayName.toLowerCase();
  String get organizationBreadcrumb => organizationPathNames.join(' / ');

  factory AgentDirectoryEntry.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    return AgentDirectoryEntry(
      id: id,
      displayName: (map['displayName'] ?? '').toString().trim(),
      firstName: (map['firstName'] ?? '').toString().trim(),
      name: (map['name'] ?? '').toString().trim(),
      postName: (map['postName'] ?? '').toString().trim(),
      email: (map['email'] ?? '').toString().trim(),
      profilePictureUrl: _nullableString(map['profilePictureUrl']),
      jobTitle: (map['jobTitle'] ?? '').toString().trim(),
      organizationId: (map['organizationId'] ?? '').toString().trim(),
      organizationName: (map['organizationName'] ?? '').toString().trim(),
      primaryOrganizationUnitId:
          (map['primaryOrganizationUnitId'] ?? '').toString().trim(),
      primaryOrganizationUnitName:
          (map['primaryOrganizationUnitName'] ?? '').toString().trim(),
      primaryOrganizationUnitType:
          (map['primaryOrganizationUnitType'] ?? '').toString().trim(),
      departmentId: (map['departmentId'] ?? '').toString().trim(),
      serviceId: (map['serviceId'] ?? '').toString().trim(),
      bureauId: (map['bureauId'] ?? '').toString().trim(),
      organizationPathNames: _stringList(map['organizationPathNames']),
      scopeKeys: _stringList(map['scopeKeys']),
      isActive: map['isActive'] == true,
    );
  }
}

List<String> _stringList(Object? value) {
  if (value is! Iterable) return const [];
  return List.unmodifiable(
    value
        .map((entry) => entry.toString().trim())
        .where((entry) => entry.isNotEmpty),
  );
}

String? _nullableString(Object? value) {
  final normalized = value?.toString().trim() ?? '';
  return normalized.isEmpty ? null : normalized;
}
