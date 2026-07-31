import '../../shared/data/itsm_work_item_repository.dart';
import '../../shared/domain/pagination.dart';
import '../domain/service_request.dart';

enum ServiceRequestScope {
  myActive,
  myHistory,
  managerActive,
  managerClosed,
  assignedToMe,
}

class ServiceRequestQuery {
  ServiceRequestQuery({
    required this.scope,
    Iterable<ServiceRequestStatus> statuses = const [],
    Iterable<String> catalogueItemIds = const [],
    Iterable<String> assignedGroupIds = const [],
    this.searchTerm = '',
    this.createdFrom,
    this.createdTo,
  })  : statuses = Set<ServiceRequestStatus>.unmodifiable(statuses),
        catalogueItemIds = _normalizedSet(catalogueItemIds),
        assignedGroupIds = _normalizedSet(assignedGroupIds) {
    if (createdFrom != null &&
        createdTo != null &&
        createdFrom!.isAfter(createdTo!)) {
      throw ArgumentError('createdFrom cannot be after createdTo.');
    }
  }

  final ServiceRequestScope scope;
  final Set<ServiceRequestStatus> statuses;
  final Set<String> catalogueItemIds;
  final Set<String> assignedGroupIds;
  final String searchTerm;
  final DateTime? createdFrom;
  final DateTime? createdTo;

  bool matches(ServiceRequest request) {
    if (statuses.isNotEmpty && !statuses.contains(request.status)) return false;
    if (catalogueItemIds.isNotEmpty &&
        !catalogueItemIds.contains(request.catalogueItemId)) {
      return false;
    }
    if (assignedGroupIds.isNotEmpty &&
        !assignedGroupIds.contains(request.assignedGroupId)) {
      return false;
    }
    if (createdFrom != null && request.createdAt.isBefore(createdFrom!)) {
      return false;
    }
    if (createdTo != null && request.createdAt.isAfter(createdTo!)) {
      return false;
    }
    final search = searchTerm.trim().toLowerCase();
    return search.isEmpty ||
        request.requestNumber.toLowerCase().contains(search) ||
        request.title.toLowerCase().contains(search) ||
        request.description.toLowerCase().contains(search) ||
        request.requestedForName.toLowerCase().contains(search);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ServiceRequestQuery &&
            scope == other.scope &&
            _setsEqual(statuses, other.statuses) &&
            _setsEqual(catalogueItemIds, other.catalogueItemIds) &&
            _setsEqual(assignedGroupIds, other.assignedGroupIds) &&
            searchTerm.trim() == other.searchTerm.trim() &&
            createdFrom == other.createdFrom &&
            createdTo == other.createdTo;
  }

  @override
  int get hashCode => Object.hash(
        scope,
        Object.hashAllUnordered(statuses),
        Object.hashAllUnordered(catalogueItemIds),
        Object.hashAllUnordered(assignedGroupIds),
        searchTerm.trim(),
        createdFrom,
        createdTo,
      );
}

abstract interface class ServiceRequestRepository {
  Future<PageResult<ServiceRequest>> fetchPage({
    required ItsmQueryPrincipal principal,
    required ServiceRequestQuery query,
    required PageRequest page,
  });

  Stream<List<ServiceRequest>> watchFirstPage({
    required ItsmQueryPrincipal principal,
    required ServiceRequestQuery query,
    required int limit,
  });

  Stream<ServiceRequest?> watchById({
    required ItsmQueryPrincipal principal,
    required String id,
  });

  Stream<ServiceRequestDetail?> watchDetail({
    required ItsmQueryPrincipal principal,
    required String id,
    int childLimit = 100,
  });
}

class ServiceRequestRepositoryException implements Exception {
  const ServiceRequestRepositoryException(this.message);

  final String message;

  @override
  String toString() => 'ServiceRequestRepositoryException($message)';
}

Set<String> _normalizedSet(Iterable<String> values) {
  return Set<String>.unmodifiable(
    values.map((value) => value.trim()).where((value) => value.isNotEmpty),
  );
}

bool _setsEqual<T>(Set<T> left, Set<T> right) {
  return left.length == right.length && left.containsAll(right);
}
