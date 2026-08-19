class OrganizationPageRequest {
  const OrganizationPageRequest({
    this.limit = 50,
    this.afterNameLower,
    this.afterId,
    this.search = '',
  }) : assert(limit > 0 && limit <= maximumLimit);

  static const int maximumLimit = 100;

  final int limit;
  final String? afterNameLower;
  final String? afterId;
  final String search;

  String get normalizedSearch => search.trim().toLowerCase();
}

enum OrganizationListStatusFilter {
  current,
  active,
  inactive,
  archived,
  all,
}

extension OrganizationListStatusFilterX on OrganizationListStatusFilter {
  List<String>? get firestoreValues => switch (this) {
        OrganizationListStatusFilter.current => const ['ACTIVE', 'INACTIVE'],
        OrganizationListStatusFilter.active => const ['ACTIVE'],
        OrganizationListStatusFilter.inactive => const ['INACTIVE'],
        OrganizationListStatusFilter.archived => const ['ARCHIVED'],
        OrganizationListStatusFilter.all => null,
      };
}

class OrganizationListQuery {
  const OrganizationListQuery({
    this.search = '',
    this.status = OrganizationListStatusFilter.current,
    this.limit = 40,
  }) : assert(limit > 0 && limit <= OrganizationPageRequest.maximumLimit);

  final String search;
  final OrganizationListStatusFilter status;
  final int limit;

  String get normalizedSearch => search.trim().toLowerCase();

  @override
  bool operator ==(Object other) =>
      other is OrganizationListQuery &&
      other.normalizedSearch == normalizedSearch &&
      other.status == status &&
      other.limit == limit;

  @override
  int get hashCode => Object.hash(normalizedSearch, status, limit);
}

class OrganizationUnitListQuery {
  const OrganizationUnitListQuery({
    required this.organizationId,
    this.search = '',
    this.type,
    this.status = OrganizationListStatusFilter.current,
    this.limit = 40,
  }) : assert(limit > 0 && limit <= OrganizationPageRequest.maximumLimit);

  final String organizationId;
  final String search;
  final String? type;
  final OrganizationListStatusFilter status;
  final int limit;

  String get normalizedSearch => search.trim().toLowerCase();
  String? get normalizedType {
    final value = type?.trim().toUpperCase() ?? '';
    return value.isEmpty ? null : value;
  }

  @override
  bool operator ==(Object other) =>
      other is OrganizationUnitListQuery &&
      other.organizationId == organizationId &&
      other.normalizedSearch == normalizedSearch &&
      other.normalizedType == normalizedType &&
      other.status == status &&
      other.limit == limit;

  @override
  int get hashCode => Object.hash(
        organizationId,
        normalizedSearch,
        normalizedType,
        status,
        limit,
      );
}

class OrganizationUnitIdentity {
  const OrganizationUnitIdentity({
    required this.organizationId,
    required this.unitId,
  });

  final String organizationId;
  final String unitId;

  bool get isValid =>
      organizationId.trim().isNotEmpty && unitId.trim().isNotEmpty;

  @override
  bool operator ==(Object other) =>
      other is OrganizationUnitIdentity &&
      other.organizationId == organizationId &&
      other.unitId == unitId;

  @override
  int get hashCode => Object.hash(organizationId, unitId);
}

enum AgentDirectoryStatusFilter { active, inactive, all }

class AgentDirectoryListQuery {
  const AgentDirectoryListQuery({
    required this.organizationId,
    this.search = '',
    this.scopeUnitId = '',
    this.status = AgentDirectoryStatusFilter.active,
    this.limit = 40,
  }) : assert(limit > 0 && limit <= OrganizationPageRequest.maximumLimit);

  final String organizationId;
  final String search;
  final String scopeUnitId;
  final AgentDirectoryStatusFilter status;
  final int limit;

  String get normalizedSearch => search.trim().toLowerCase();

  @override
  bool operator ==(Object other) =>
      other is AgentDirectoryListQuery &&
      other.organizationId == organizationId &&
      other.normalizedSearch == normalizedSearch &&
      other.scopeUnitId == scopeUnitId &&
      other.status == status &&
      other.limit == limit;

  @override
  int get hashCode => Object.hash(
        organizationId,
        normalizedSearch,
        scopeUnitId,
        status,
        limit,
      );
}

class OrganizationPageCursor {
  const OrganizationPageCursor({
    required this.nameLower,
    required this.id,
  });

  final String nameLower;
  final String id;
}

class OrganizationPage<T> {
  const OrganizationPage({
    required this.items,
    required this.nextCursor,
  });

  final List<T> items;
  final OrganizationPageCursor? nextCursor;
  bool get hasMore => nextCursor != null;
}

class OrganizationAssignmentQuery {
  const OrganizationAssignmentQuery.agent({
    required this.organizationId,
    required String agentId,
    this.limit = 40,
  })  : subjectId = agentId,
        isAgentQuery = true,
        assert(limit > 0 && limit <= OrganizationPageRequest.maximumLimit);

  const OrganizationAssignmentQuery.unit({
    required this.organizationId,
    required String unitId,
    this.limit = 40,
  })  : subjectId = unitId,
        isAgentQuery = false,
        assert(limit > 0 && limit <= OrganizationPageRequest.maximumLimit);

  final String organizationId;
  final String subjectId;
  final bool isAgentQuery;
  final int limit;

  String get agentId => isAgentQuery ? subjectId : '';
  String get unitId => isAgentQuery ? '' : subjectId;

  bool get isValid =>
      organizationId.trim().isNotEmpty && subjectId.trim().isNotEmpty;

  @override
  bool operator ==(Object other) =>
      other is OrganizationAssignmentQuery &&
      other.organizationId == organizationId &&
      other.subjectId == subjectId &&
      other.isAgentQuery == isAgentQuery &&
      other.limit == limit;

  @override
  int get hashCode =>
      Object.hash(organizationId, subjectId, isAgentQuery, limit);
}

class OrganizationTimelinePageRequest {
  const OrganizationTimelinePageRequest({
    this.limit = 40,
    this.afterTimestamp,
    this.afterId,
  }) : assert(limit > 0 && limit <= OrganizationPageRequest.maximumLimit);

  final int limit;
  final DateTime? afterTimestamp;
  final String? afterId;

  bool get hasCursor =>
      afterTimestamp != null && (afterId?.trim().isNotEmpty ?? false);
}

class OrganizationTimelineCursor {
  const OrganizationTimelineCursor({
    required this.timestamp,
    required this.id,
  });

  final DateTime timestamp;
  final String id;
}

class OrganizationTimelinePage<T> {
  const OrganizationTimelinePage({
    required this.items,
    required this.nextCursor,
  });

  final List<T> items;
  final OrganizationTimelineCursor? nextCursor;
  bool get hasMore => nextCursor != null;
}

class OrganizationAuditQuery {
  const OrganizationAuditQuery({
    required this.organizationId,
    this.limit = 40,
  }) : assert(limit > 0 && limit <= OrganizationPageRequest.maximumLimit);

  final String organizationId;
  final int limit;

  bool get isValid => organizationId.trim().isNotEmpty;

  @override
  bool operator ==(Object other) =>
      other is OrganizationAuditQuery &&
      other.organizationId == organizationId &&
      other.limit == limit;

  @override
  int get hashCode => Object.hash(organizationId, limit);
}
