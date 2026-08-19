import 'package:arptc_connect/core/firebase_providers.dart';
import 'package:arptc_connect/modules/authentication/application/authorized_session.dart';
import 'package:arptc_connect/modules/authentication/providers/authorized_session_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arptc_connect/modules/usermanagement/domain/agent_directory_entry.dart';
import 'package:arptc_connect/modules/usermanagement/presentation/controllers/management_providers.dart';

import '../../shared/application/itsm_session.dart';
import '../../shared/application/itsm_providers.dart';
import '../../shared/domain/pagination.dart';
import '../data/support_data.dart';
import '../domain/support_domain.dart';
import 'service_request_access_policy.dart';
import 'service_request_controller.dart';

final serviceCatalogueRepositoryProvider =
    Provider<ServiceCatalogueRepository>((ref) {
  return FirestoreServiceCatalogueRepository(ref.read(fireStoreProvider));
});

final serviceRequestRepositoryProvider =
    Provider<ServiceRequestRepository>((ref) {
  return FirestoreServiceRequestRepository(ref.read(fireStoreProvider));
});

final serviceRequestCommandGatewayProvider =
    Provider<ServiceRequestCommandGateway>((ref) {
  return FirebaseServiceRequestCommandGateway(
    FirebaseCallableInvoker(ref.read(firebaseFunctionsProvider)),
  );
});

final serviceRequestAccessPolicyProvider =
    Provider<ServiceRequestAccessPolicy>((ref) {
  return const ServiceRequestAccessPolicy();
});

class PublishedCataloguePageRequest {
  const PublishedCataloguePageRequest({
    required this.query,
    required this.page,
    this.languageCode = 'en',
    this.departmentId,
    this.serviceId,
    this.locationId,
    this.positionValue,
  });

  final ServiceCatalogueQuery query;
  final PageRequest page;
  final String languageCode;
  final String? departmentId;
  final String? serviceId;
  final String? locationId;
  final String? positionValue;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PublishedCataloguePageRequest &&
            query == other.query &&
            page.limit == other.page.limit &&
            page.cursor == other.page.cursor &&
            page.direction == other.page.direction &&
            languageCode == other.languageCode &&
            departmentId == other.departmentId &&
            serviceId == other.serviceId &&
            locationId == other.locationId &&
            positionValue == other.positionValue;
  }

  @override
  int get hashCode => Object.hash(
        query,
        page.limit,
        page.cursor,
        page.direction,
        languageCode,
        departmentId,
        serviceId,
        locationId,
        positionValue,
      );
}

final publishedServiceCataloguePageProvider = FutureProvider.autoDispose
    .family<PageResult<ServiceCatalogueItem>, PublishedCataloguePageRequest>(
  (ref, request) async {
    final policy = ref.read(serviceRequestAccessPolicyProvider);
    final repository = ref.watch(serviceCatalogueRepositoryProvider);
    final session = await _requireSession(ref);
    return repository.fetchPublishedPage(
      principal: session.queryPrincipal,
      cataloguePrincipal: policy.cataloguePrincipal(
        session,
        departmentId: request.departmentId,
        serviceId: request.serviceId,
        locationId: request.locationId,
        positionValue: request.positionValue,
      ),
      query: request.query,
      page: request.page,
      languageCode: request.languageCode,
    );
  },
);

class PublishedCatalogueFirstPageRequest {
  const PublishedCatalogueFirstPageRequest({
    this.query = const _DefaultCatalogueQuery(),
    this.limit = PageRequest.defaultLimit,
    this.languageCode = 'en',
    this.departmentId,
    this.serviceId,
    this.locationId,
    this.positionValue,
  });

  final ServiceCatalogueQuery query;
  final int limit;
  final String languageCode;
  final String? departmentId;
  final String? serviceId;
  final String? locationId;
  final String? positionValue;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PublishedCatalogueFirstPageRequest &&
            query == other.query &&
            limit == other.limit &&
            languageCode == other.languageCode &&
            departmentId == other.departmentId &&
            serviceId == other.serviceId &&
            locationId == other.locationId &&
            positionValue == other.positionValue;
  }

  @override
  int get hashCode => Object.hash(
        query,
        limit,
        languageCode,
        departmentId,
        serviceId,
        locationId,
        positionValue,
      );
}

class _DefaultCatalogueQuery extends ServiceCatalogueQuery {
  const _DefaultCatalogueQuery() : super();
}

final publishedServiceCatalogueFirstPageProvider = StreamProvider.autoDispose
    .family<List<ServiceCatalogueItem>, PublishedCatalogueFirstPageRequest>(
  (ref, request) {
    final policy = ref.read(serviceRequestAccessPolicyProvider);
    final repository = ref.watch(serviceCatalogueRepositoryProvider);
    return ref.watch(itsmSessionProvider).when(
          loading: _pendingStream,
          error: (error, stackTrace) => Stream.error(error, stackTrace),
          data: (session) {
            if (session == null) {
              return Stream.error(const ItsmSessionRequiredException());
            }
            return repository.watchPublishedFirstPage(
              principal: session.queryPrincipal,
              cataloguePrincipal: policy.cataloguePrincipal(
                session,
                departmentId: request.departmentId,
                serviceId: request.serviceId,
                locationId: request.locationId,
                positionValue: request.positionValue,
              ),
              query: request.query,
              limit: request.limit,
              languageCode: request.languageCode,
            );
          },
        );
  },
);

class PublishedCatalogueItemRequest {
  const PublishedCatalogueItemRequest({
    required this.id,
    required this.at,
    this.departmentId,
    this.serviceId,
    this.locationId,
    this.positionValue,
  });

  final String id;
  final DateTime at;
  final String? departmentId;
  final String? serviceId;
  final String? locationId;
  final String? positionValue;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PublishedCatalogueItemRequest &&
            id == other.id &&
            at == other.at &&
            departmentId == other.departmentId &&
            serviceId == other.serviceId &&
            locationId == other.locationId &&
            positionValue == other.positionValue;
  }

  @override
  int get hashCode => Object.hash(
        id,
        at,
        departmentId,
        serviceId,
        locationId,
        positionValue,
      );
}

final publishedServiceCatalogueItemProvider = FutureProvider.autoDispose
    .family<ServiceCatalogueItem?, PublishedCatalogueItemRequest>(
  (ref, request) async {
    final policy = ref.read(serviceRequestAccessPolicyProvider);
    final repository = ref.watch(serviceCatalogueRepositoryProvider);
    final session = await _requireSession(ref);
    return repository.getPublishedById(
      principal: session.queryPrincipal,
      cataloguePrincipal: policy.cataloguePrincipal(
        session,
        departmentId: request.departmentId,
        serviceId: request.serviceId,
        locationId: request.locationId,
        positionValue: request.positionValue,
      ),
      id: request.id,
      at: request.at,
    );
  },
);

class ServiceRequestPageRequest {
  const ServiceRequestPageRequest({
    required this.query,
    required this.page,
  });

  final ServiceRequestQuery query;
  final PageRequest page;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ServiceRequestPageRequest &&
            query == other.query &&
            page.limit == other.page.limit &&
            page.cursor == other.page.cursor &&
            page.direction == other.page.direction;
  }

  @override
  int get hashCode => Object.hash(
        query,
        page.limit,
        page.cursor,
        page.direction,
      );
}

final serviceRequestPageProvider = FutureProvider.autoDispose
    .family<PageResult<ServiceRequest>, ServiceRequestPageRequest>(
  (ref, request) async {
    final policy = ref.read(serviceRequestAccessPolicyProvider);
    final repository = ref.watch(serviceRequestRepositoryProvider);
    final session = await _requireSession(ref);
    policy.authorizeQuery(session, request.query.scope);
    return repository.fetchPage(
      principal: session.queryPrincipal,
      query: request.query,
      page: request.page,
    );
  },
);

class ServiceRequestFirstPageRequest {
  const ServiceRequestFirstPageRequest({
    required this.query,
    this.limit = PageRequest.defaultLimit,
  });

  final ServiceRequestQuery query;
  final int limit;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ServiceRequestFirstPageRequest &&
            query == other.query &&
            limit == other.limit;
  }

  @override
  int get hashCode => Object.hash(query, limit);
}

final serviceRequestFirstPageProvider = StreamProvider.autoDispose
    .family<List<ServiceRequest>, ServiceRequestFirstPageRequest>(
  (ref, request) {
    final policy = ref.read(serviceRequestAccessPolicyProvider);
    final repository = ref.watch(serviceRequestRepositoryProvider);
    return ref.watch(itsmSessionProvider).when(
          loading: _pendingStream,
          error: (error, stackTrace) => Stream.error(error, stackTrace),
          data: (session) {
            if (session == null) {
              return Stream.error(const ItsmSessionRequiredException());
            }
            policy.authorizeQuery(session, request.query.scope);
            return repository.watchFirstPage(
              principal: session.queryPrincipal,
              query: request.query,
              limit: request.limit,
            );
          },
        );
  },
);

final serviceRequestDetailProvider =
    StreamProvider.autoDispose.family<ServiceRequestDetail?, String>((ref, id) {
  final policy = ref.read(serviceRequestAccessPolicyProvider);
  final repository = ref.watch(serviceRequestRepositoryProvider);
  return ref.watch(itsmSessionProvider).when(
        loading: _pendingStream,
        error: (error, stackTrace) => Stream.error(error, stackTrace),
        data: (session) {
          if (session == null) {
            return Stream.error(const ItsmSessionRequiredException());
          }
          return repository
              .watchDetail(principal: session.queryPrincipal, id: id)
              .map((detail) {
            if (detail != null) policy.authorizeRead(session, detail.request);
            return detail;
          });
        },
      );
});

final serviceRequestControllerProvider =
    FutureProvider.autoDispose<ServiceRequestController>((ref) async {
  final accessPolicy = ref.read(serviceRequestAccessPolicyProvider);
  final gateway = ref.read(serviceRequestCommandGatewayProvider);
  final session = await _requireSession(ref);
  return ServiceRequestController(
    session: session,
    accessPolicy: accessPolicy,
    gateway: gateway,
  );
});

class ServiceRequestCatalogueContext {
  const ServiceRequestCatalogueContext({
    this.departmentId,
    this.serviceId,
    this.locationId,
    this.positionValue,
  });

  final String? departmentId;
  final String? serviceId;
  final String? locationId;
  final String? positionValue;
}

final serviceRequestCatalogueContextProvider =
    Provider.autoDispose<AsyncValue<ServiceRequestCatalogueContext>>((ref) {
  final sessionState = ref.watch(authorizedSessionProvider);
  final session = sessionState.session;
  if (session == null) {
    if (sessionState.status == AuthenticationStatus.initializing ||
        sessionState.status == AuthenticationStatus.profileLoading) {
      return const AsyncValue.loading();
    }
    return const AsyncValue.data(ServiceRequestCatalogueContext());
  }

  final profile = session.profile;
  final departmentId = profile['departmentId']?.toString().trim();
  final serviceId = profile['serviceId']?.toString().trim();
  final locationId = profile['locationId']?.toString().trim();
  final positionValue = profile['position']?.toString().trim();
  return AsyncValue.data(
    ServiceRequestCatalogueContext(
      departmentId: departmentId?.isEmpty == true ? null : departmentId,
      serviceId: serviceId?.isEmpty == true ? null : serviceId,
      locationId: locationId?.isEmpty == true ? null : locationId,
      positionValue: positionValue?.isEmpty == true ? null : positionValue,
    ),
  );
});

class ServiceRequestAgentSearch {
  const ServiceRequestAgentSearch(this.query);

  final String query;

  @override
  bool operator ==(Object other) =>
      other is ServiceRequestAgentSearch &&
      other.query.trim().toLowerCase() == query.trim().toLowerCase();

  @override
  int get hashCode => query.trim().toLowerCase().hashCode;
}

final serviceRequestAgentSearchProvider = Provider.autoDispose
    .family<AsyncValue<List<AgentDirectoryEntry>>, ServiceRequestAgentSearch>(
  (ref, search) {
    final query = search.query.trim().toLowerCase();
    return ref
        .watch(umCurrentOrganizationAgentDirectoryProvider)
        .whenData((agents) {
      return agents
          .where((agent) {
            if (!agent.isActive) return false;
            return query.isEmpty ||
                agent.displayNameLower.contains(query) ||
                agent.email.toLowerCase().contains(query);
          })
          .take(30)
          .toList(growable: false);
    });
  },
);

Future<ItsmSession> _requireSession(Ref ref) async {
  final session = await ref.watch(itsmSessionProvider.future);
  if (session == null) throw const ItsmSessionRequiredException();
  return session;
}

Stream<T> _pendingStream<T>() => Stream<T>.multi((_) {});
