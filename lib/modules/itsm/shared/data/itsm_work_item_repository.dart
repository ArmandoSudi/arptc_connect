import 'dart:collection';

import '../domain/itsm_shared_domain.dart';

enum ItsmWorkItemScope {
  myActive,
  myHistory,
  managerActive,
  managerClosed,
  assignedToMe,
  executiveSnapshot,
}

class ItsmQueryPrincipal {
  const ItsmQueryPrincipal({
    required this.sessionKey,
    required this.userId,
    required this.email,
    required this.role,
  });

  final String sessionKey;
  final String userId;
  final String email;
  final ItsmRole role;
}

class ItsmWorkItemQuery {
  ItsmWorkItemQuery({
    required this.scope,
    Iterable<ItsmWorkItemType> types = const [],
    Iterable<String> statuses = const [],
    Iterable<ItsmPriority> priorities = const [],
    Iterable<String> serviceIds = const [],
    this.searchTerm = '',
    this.createdFrom,
    this.createdTo,
  })  : types = Set<ItsmWorkItemType>.unmodifiable(types),
        statuses = Set<String>.unmodifiable(
          statuses
              .map((status) => status.trim().toLowerCase())
              .where((status) => status.isNotEmpty),
        ),
        priorities = Set<ItsmPriority>.unmodifiable(priorities),
        serviceIds = Set<String>.unmodifiable(
          serviceIds
              .map((serviceId) => serviceId.trim())
              .where((serviceId) => serviceId.isNotEmpty),
        ) {
    final from = createdFrom;
    final to = createdTo;
    if (from != null && to != null && from.isAfter(to)) {
      throw ArgumentError('createdFrom must not be after createdTo.');
    }
  }

  final ItsmWorkItemScope scope;
  final Set<ItsmWorkItemType> types;
  final Set<String> statuses;
  final Set<ItsmPriority> priorities;
  final Set<String> serviceIds;
  final String searchTerm;
  final DateTime? createdFrom;
  final DateTime? createdTo;

  bool includesType(ItsmWorkItemType type) {
    return types.isEmpty || types.contains(type);
  }

  bool matches(ItsmWorkItemSummary item) {
    if (!includesType(item.type)) return false;
    if (statuses.isNotEmpty && !statuses.contains(item.status.toLowerCase())) {
      return false;
    }
    if (priorities.isNotEmpty && !priorities.contains(item.priority)) {
      return false;
    }
    if (serviceIds.isNotEmpty && !serviceIds.contains(item.serviceId)) {
      return false;
    }
    if (createdFrom != null && item.createdAt.isBefore(createdFrom!)) {
      return false;
    }
    if (createdTo != null && item.createdAt.isAfter(createdTo!)) {
      return false;
    }

    final normalizedSearch = searchTerm.trim().toLowerCase();
    if (normalizedSearch.isEmpty) return true;
    return item.reference.toLowerCase().contains(normalizedSearch) ||
        item.title.toLowerCase().contains(normalizedSearch) ||
        item.description.toLowerCase().contains(normalizedSearch);
  }

  Map<String, Object?> toPrimitiveMap() {
    return UnmodifiableMapView({
      'scope': scope.name,
      'types': types.map((type) => type.value).toList(growable: false),
      'statuses': statuses.toList(growable: false),
      'priorities':
          priorities.map((priority) => priority.value).toList(growable: false),
      'serviceIds': serviceIds.toList(growable: false),
      'searchTerm': searchTerm.trim(),
      'createdFrom': createdFrom?.toUtc().toIso8601String(),
      'createdTo': createdTo?.toUtc().toIso8601String(),
    });
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ItsmWorkItemQuery &&
            scope == other.scope &&
            _setsEqual(types, other.types) &&
            _setsEqual(statuses, other.statuses) &&
            _setsEqual(priorities, other.priorities) &&
            _setsEqual(serviceIds, other.serviceIds) &&
            searchTerm.trim() == other.searchTerm.trim() &&
            createdFrom == other.createdFrom &&
            createdTo == other.createdTo;
  }

  @override
  int get hashCode => Object.hash(
        scope,
        Object.hashAllUnordered(types),
        Object.hashAllUnordered(statuses),
        Object.hashAllUnordered(priorities),
        Object.hashAllUnordered(serviceIds),
        searchTerm.trim(),
        createdFrom,
        createdTo,
      );
}

abstract interface class ItsmWorkItemRepository {
  Future<PageResult<ItsmWorkItemSummary>> fetchPage({
    required ItsmQueryPrincipal principal,
    required ItsmWorkItemQuery query,
    required PageRequest page,
  });

  Stream<List<ItsmWorkItemSummary>> watchFirstPage({
    required ItsmQueryPrincipal principal,
    required ItsmWorkItemQuery query,
    required int limit,
  });

  Stream<ItsmWorkItemSummary?> watchById({
    required ItsmQueryPrincipal principal,
    required ItsmWorkItemType type,
    required String id,
  });
}

class ItsmRepositoryException implements Exception {
  const ItsmRepositoryException(this.message);

  final String message;

  @override
  String toString() => 'ItsmRepositoryException($message)';
}

class ItsmUnsupportedQueryException extends ItsmRepositoryException {
  const ItsmUnsupportedQueryException(super.message);
}

bool _setsEqual<T>(Set<T> left, Set<T> right) {
  return left.length == right.length && left.containsAll(right);
}
