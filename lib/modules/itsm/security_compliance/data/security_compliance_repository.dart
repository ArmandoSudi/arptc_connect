import '../../shared/data/itsm_work_item_repository.dart';
import '../../shared/domain/pagination.dart';
import '../application/security_compliance_access.dart';
import '../domain/security_compliance_domain.dart';

class SecurityComplianceQuery {
  const SecurityComplianceQuery({
    required this.scope,
    this.status,
    this.secondaryFilter,
  }) : assert(
          status == null || secondaryFilter == null,
          'Use one indexed filter at a time.',
        );

  final SecurityComplianceScope scope;
  final String? status;
  final String? secondaryFilter;

  @override
  bool operator ==(Object other) =>
      other is SecurityComplianceQuery &&
      other.scope == scope &&
      other.status == status &&
      other.secondaryFilter == secondaryFilter;

  @override
  int get hashCode => Object.hash(scope, status, secondaryFilter);
}

class SecurityCompliancePageRequest {
  const SecurityCompliancePageRequest({
    required this.query,
    required this.page,
  });

  final SecurityComplianceQuery query;
  final PageRequest page;

  @override
  bool operator ==(Object other) =>
      other is SecurityCompliancePageRequest &&
      other.query == query &&
      other.page.limit == page.limit &&
      other.page.cursor == page.cursor &&
      other.page.direction == page.direction;

  @override
  int get hashCode => Object.hash(
        query,
        page.limit,
        page.cursor,
        page.direction,
      );
}

class SecurityComplianceFirstPageRequest {
  const SecurityComplianceFirstPageRequest({
    required this.query,
    this.limit = PageRequest.defaultLimit,
  });

  final SecurityComplianceQuery query;
  final int limit;

  @override
  bool operator ==(Object other) =>
      other is SecurityComplianceFirstPageRequest &&
      other.query == query &&
      other.limit == limit;

  @override
  int get hashCode => Object.hash(query, limit);
}

enum SecurityComplianceEntityType {
  finding,
  exception,
  campaign,
  reviewItem,
}

class SecurityComplianceIdentity {
  SecurityComplianceIdentity({
    required this.type,
    required String id,
    required this.scope,
  }) : id = id.trim() {
    if (this.id.isEmpty) throw ArgumentError.value(id, 'id');
  }

  final SecurityComplianceEntityType type;
  final String id;
  final SecurityComplianceScope scope;

  @override
  bool operator ==(Object other) =>
      other is SecurityComplianceIdentity &&
      other.type == type &&
      other.id == id &&
      other.scope == scope;

  @override
  int get hashCode => Object.hash(type, id, scope);
}

abstract interface class SecurityComplianceRepository {
  Future<int> fetchRevision({
    required ItsmQueryPrincipal principal,
    required SecurityComplianceIdentity identity,
  });

  Future<PageResult<SecurityFinding>> fetchFindings({
    required ItsmQueryPrincipal principal,
    required SecurityCompliancePageRequest request,
  });

  Stream<List<SecurityFinding>> watchFindings({
    required ItsmQueryPrincipal principal,
    required SecurityComplianceFirstPageRequest request,
  });

  Future<PageResult<SecurityException>> fetchExceptions({
    required ItsmQueryPrincipal principal,
    required SecurityCompliancePageRequest request,
  });

  Stream<List<SecurityException>> watchExceptions({
    required ItsmQueryPrincipal principal,
    required SecurityComplianceFirstPageRequest request,
  });

  Future<PageResult<AssetComplianceAssessment>> fetchAssessments({
    required ItsmQueryPrincipal principal,
    required SecurityCompliancePageRequest request,
  });

  Stream<List<AssetComplianceAssessment>> watchAssessments({
    required ItsmQueryPrincipal principal,
    required SecurityComplianceFirstPageRequest request,
  });

  Future<PageResult<OwnDeviceComplianceProjection>> fetchOwnCompliance({
    required ItsmQueryPrincipal principal,
    required PageRequest page,
  });

  Stream<List<OwnDeviceComplianceProjection>> watchOwnCompliance({
    required ItsmQueryPrincipal principal,
    int limit = PageRequest.defaultLimit,
  });

  Future<PageResult<AccessReviewCampaign>> fetchCampaigns({
    required ItsmQueryPrincipal principal,
    required SecurityCompliancePageRequest request,
  });

  Stream<List<AccessReviewCampaign>> watchCampaigns({
    required ItsmQueryPrincipal principal,
    required SecurityComplianceFirstPageRequest request,
  });

  Future<PageResult<AccessReviewItem>> fetchAccessReviewItems({
    required ItsmQueryPrincipal principal,
    required SecurityCompliancePageRequest request,
  });

  Stream<List<AccessReviewItem>> watchAccessReviewItems({
    required ItsmQueryPrincipal principal,
    required SecurityComplianceFirstPageRequest request,
  });

  Stream<List<AccessCorrectionRequest>> watchCorrectionRequests({
    required ItsmQueryPrincipal principal,
    int limit = PageRequest.defaultLimit,
  });
}

class SecurityComplianceRepositoryException implements Exception {
  const SecurityComplianceRepositoryException(this.message);

  final String message;

  @override
  String toString() => 'SecurityComplianceRepositoryException($message)';
}
