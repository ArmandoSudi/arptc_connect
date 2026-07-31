import 'package:arptc_connect/modules/authentication/providers/authentication_provider.dart';
import 'package:arptc_connect/modules/incident_management/data/firestore_incident_repository.dart';
import 'package:arptc_connect/modules/profile/presentation/controllers/profile_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/itsm_shared_data.dart';
import '../domain/itsm_shared_domain.dart';
import 'itsm_command_executor.dart';
import 'itsm_session.dart';

final itsmSessionResolverProvider = Provider<ItsmSessionResolver>(
  (ref) => const ItsmSessionResolver(),
);

final itsmSessionProvider =
    StreamProvider.autoDispose<ItsmSession?>((ref) async* {
  ref.watch(currentAuthSessionKeyProvider);
  final authState = ref.watch(authStateProvider);
  if (authState.isLoading) return;
  if (authState.hasError) {
    Error.throwWithStackTrace(authState.error!, authState.stackTrace!);
  }

  final authUser = authState.valueOrNull;
  if (authUser == null) {
    yield null;
    return;
  }

  final profileState = ref.watch(liveAgentProfileProvider);
  if (profileState.isLoading) return;
  if (profileState.hasError) {
    Error.throwWithStackTrace(profileState.error!, profileState.stackTrace!);
  }

  final rawProfile = profileState.valueOrNull ?? const <String, dynamic>{};
  yield ref.read(itsmSessionResolverProvider).resolve(
        authUserId: authUser.uid,
        authEmail: authUser.email,
        profile: Map<String, Object?>.from(rawProfile),
      );
});

final itsmPermissionPolicyProvider =
    Provider.autoDispose<AsyncValue<ItsmPermissionPolicy?>>((ref) {
  return ref.watch(itsmSessionProvider).whenData(
        (session) => session?.permissionPolicy,
      );
});

final legacyIncidentItsmWorkItemRepositoryProvider =
    Provider<ItsmWorkItemRepository>((ref) {
  final incidentRepository = ref.watch(incidentRepositoryProvider);
  return IncidentItsmWorkItemRepository(
    ExistingIncidentWorkItemReadSource(incidentRepository),
  );
});

final itsmWorkItemRepositoryProvider = Provider<ItsmWorkItemRepository>((ref) {
  return ref.watch(legacyIncidentItsmWorkItemRepositoryProvider);
});

final itsmAccessPolicyProvider = Provider<ItsmAccessPolicy>(
  (ref) => const ItsmAccessPolicy(),
);

class ItsmWorkItemPageRequest {
  const ItsmWorkItemPageRequest({
    required this.query,
    required this.page,
  });

  final ItsmWorkItemQuery query;
  final PageRequest page;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ItsmWorkItemPageRequest &&
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

final itsmWorkItemPageProvider = FutureProvider.autoDispose
    .family<PageResult<ItsmWorkItemSummary>, ItsmWorkItemPageRequest>(
  (ref, request) async {
    final session = await ref.watch(itsmSessionProvider.future);
    if (session == null) throw const ItsmSessionRequiredException();
    ref.read(itsmAccessPolicyProvider).authorize(session, request.query.scope);
    return ref.watch(itsmWorkItemRepositoryProvider).fetchPage(
          principal: session.queryPrincipal,
          query: request.query,
          page: request.page,
        );
  },
);

class ItsmFirstPageRequest {
  factory ItsmFirstPageRequest({
    required ItsmWorkItemQuery query,
    int limit = PageRequest.defaultLimit,
  }) {
    if (limit < 1 || limit > PageRequest.maximumLimit) {
      throw RangeError.range(
        limit,
        1,
        PageRequest.maximumLimit,
        'limit',
      );
    }
    return ItsmFirstPageRequest._(query: query, limit: limit);
  }

  const ItsmFirstPageRequest._({
    required this.query,
    required this.limit,
  });

  final ItsmWorkItemQuery query;
  final int limit;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ItsmFirstPageRequest &&
            query == other.query &&
            limit == other.limit;
  }

  @override
  int get hashCode => Object.hash(query, limit);
}

final itsmWorkItemFirstPageProvider = StreamProvider.autoDispose
    .family<List<ItsmWorkItemSummary>, ItsmFirstPageRequest>(
  (ref, request) async* {
    final session = await ref.watch(itsmSessionProvider.future);
    if (session == null) throw const ItsmSessionRequiredException();
    ref.read(itsmAccessPolicyProvider).authorize(session, request.query.scope);
    yield* ref.watch(itsmWorkItemRepositoryProvider).watchFirstPage(
          principal: session.queryPrincipal,
          query: request.query,
          limit: request.limit,
        );
  },
);

class ItsmWorkItemIdentity {
  factory ItsmWorkItemIdentity({
    required ItsmWorkItemType type,
    required String id,
  }) {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) {
      throw ArgumentError.value(id, 'id', 'A work-item ID is required.');
    }
    return ItsmWorkItemIdentity._(type: type, id: normalizedId);
  }

  const ItsmWorkItemIdentity._({
    required this.type,
    required this.id,
  });

  final ItsmWorkItemType type;
  final String id;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ItsmWorkItemIdentity && type == other.type && id == other.id;
  }

  @override
  int get hashCode => Object.hash(type, id);
}

final itsmWorkItemProvider = StreamProvider.autoDispose
    .family<ItsmWorkItemSummary?, ItsmWorkItemIdentity>(
  (ref, identity) async* {
    final session = await ref.watch(itsmSessionProvider.future);
    if (session == null) throw const ItsmSessionRequiredException();
    yield* ref.watch(itsmWorkItemRepositoryProvider).watchById(
          principal: session.queryPrincipal,
          type: identity.type,
          id: identity.id,
        );
  },
);

final itsmCommandExecutorProvider = Provider<ItsmCommandExecutor>(
  (ref) => ItsmCommandExecutor(),
);

final itsmWorkflowCommandGatewayProvider =
    Provider<ItsmWorkflowCommandGateway>((ref) {
  return const _UnconfiguredCommandGateways();
});

final itsmApprovalCommandGatewayProvider =
    Provider<ItsmApprovalCommandGateway>((ref) {
  return const _UnconfiguredCommandGateways();
});

final itsmAuditCommandGatewayProvider =
    Provider<ItsmAuditCommandGateway>((ref) {
  return const _UnconfiguredCommandGateways();
});

final itsmWorkItemIndexCommandGatewayProvider =
    Provider<ItsmWorkItemIndexCommandGateway>((ref) {
  return const _UnconfiguredCommandGateways();
});

final itsmSlaCommandGatewayProvider = Provider<ItsmSlaCommandGateway>((ref) {
  return const _UnconfiguredCommandGateways();
});

final itsmNotificationCommandGatewayProvider =
    Provider<ItsmNotificationCommandGateway>((ref) {
  return const _UnconfiguredCommandGateways();
});

class _UnconfiguredCommandGateways
    implements
        ItsmWorkflowCommandGateway,
        ItsmApprovalCommandGateway,
        ItsmAuditCommandGateway,
        ItsmWorkItemIndexCommandGateway,
        ItsmSlaCommandGateway,
        ItsmNotificationCommandGateway {
  const _UnconfiguredCommandGateways();

  @override
  Future<ItsmCommandReceipt> transition(
    ItsmWorkflowTransitionCommand command,
  ) {
    throw const UnconfiguredItsmGatewayException('workflow');
  }

  @override
  Future<ItsmCommandReceipt> decide(ItsmApprovalDecisionCommand command) {
    throw const UnconfiguredItsmGatewayException('approval');
  }

  @override
  Future<ItsmCommandReceipt> indexEvent(ItsmAuditIndexCommand command) {
    throw const UnconfiguredItsmGatewayException('audit');
  }

  @override
  Future<ItsmCommandReceipt> synchronize(ItsmWorkItemIndexCommand command) {
    throw const UnconfiguredItsmGatewayException('work-item index');
  }

  @override
  Future<ItsmCommandReceipt> process(ItsmSlaProcessingCommand command) {
    throw const UnconfiguredItsmGatewayException('SLA');
  }

  @override
  Future<ItsmCommandReceipt> emit(ItsmNotificationEventCommand command) {
    throw const UnconfiguredItsmGatewayException('notification');
  }
}
