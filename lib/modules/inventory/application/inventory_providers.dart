import 'package:arptc_connect/core/firebase_providers.dart';
import 'package:arptc_connect/modules/authentication/application/authorized_session.dart';
import 'package:arptc_connect/modules/authentication/providers/authorized_session_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firebase_inventory_command_gateway.dart';
import '../data/firestore_inventory_repository.dart';
import '../domain/inventory_domain.dart';
import 'inventory_contracts.dart';
import 'inventory_request_draft_controller.dart';
import 'inventory_session.dart';

final inventoryRepositoryProvider = Provider<InventoryReadRepository>((ref) {
  return FirestoreInventoryRepository(ref.watch(fireStoreProvider));
});

final inventoryCommandGatewayProvider =
    Provider<InventoryCommandGateway>((ref) {
  return FirebaseInventoryCommandGateway(ref.watch(firebaseFunctionsProvider));
});

final inventoryCommandIdFactoryProvider = Provider<String Function()>((ref) {
  final firestore = ref.watch(fireStoreProvider);
  return () => firestore.collection('inventoryCommandReceipts').doc().id;
});

final inventorySessionProvider = Provider<AsyncValue<InventorySession>>((ref) {
  final state = ref.watch(authorizedSessionProvider);
  final session = state.session;
  if (session != null) {
    return AsyncData(InventorySession.fromAuthorizedSession(session));
  }
  if (state.status == AuthenticationStatus.initializing ||
      state.status == AuthenticationStatus.profileLoading) {
    return const AsyncLoading();
  }
  return AsyncError(
    const InventorySessionRequired(),
    StackTrace.current,
  );
});

final currentInventoryRoleProvider = Provider<InventoryRole>((ref) {
  return ref.watch(inventorySessionProvider).valueOrNull?.role ??
      InventoryRole.none;
});

final inventoryAccessPolicyProvider = Provider<InventoryAccessPolicy>((ref) {
  return InventoryAccessPolicy(ref.watch(currentInventoryRoleProvider));
});

final inventoryCatalogueProvider = StreamProvider.autoDispose
    .family<List<InventoryCatalogueItem>, InventoryCatalogueQuery>(
        (ref, query) {
  if (!_hasInventorySession(ref)) return Stream.value(const []);
  return ref.watch(inventoryRepositoryProvider).watchCatalogue(query);
});

final inventoryItemsProvider = StreamProvider.autoDispose
    .family<List<InventoryItem>, InventoryItemQuery>((ref, query) {
  if (!ref.watch(inventoryAccessPolicyProvider).canReadExactStock) {
    return Stream.value(const []);
  }
  return ref.watch(inventoryRepositoryProvider).watchItems(query);
});

final inventoryItemProvider =
    StreamProvider.autoDispose.family<InventoryItem?, String>((ref, itemId) {
  if (!ref.watch(inventoryAccessPolicyProvider).canReadExactStock) {
    return Stream.value(null);
  }
  return ref.watch(inventoryRepositoryProvider).watchItem(itemId);
});

final inventoryWarehousesProvider = StreamProvider.autoDispose
    .family<List<InventoryWarehouse>, bool>((ref, activeOnly) {
  if (!ref.watch(inventoryAccessPolicyProvider).canReadExactStock) {
    return Stream.value(const []);
  }
  return ref
      .watch(inventoryRepositoryProvider)
      .watchWarehouses(activeOnly: activeOnly);
});

final inventoryLocationsProvider = StreamProvider.autoDispose
    .family<List<InventoryLocation>, String>((ref, warehouseId) {
  if (!ref.watch(inventoryAccessPolicyProvider).canReadExactStock) {
    return Stream.value(const []);
  }
  return ref
      .watch(inventoryRepositoryProvider)
      .watchLocations(warehouseId: warehouseId);
});

final inventoryParametersProvider = StreamProvider.autoDispose
    .family<List<InventoryParameter>, InventoryParameterType>((ref, type) {
  if (!ref.watch(inventoryAccessPolicyProvider).canReadExactStock) {
    return Stream.value(const []);
  }
  return ref.watch(inventoryRepositoryProvider).watchParameters(type);
});

final inventoryBalancesProvider = StreamProvider.autoDispose
    .family<List<InventoryBalance>, String>((ref, itemId) {
  if (!ref.watch(inventoryAccessPolicyProvider).canReadExactStock) {
    return Stream.value(const []);
  }
  return ref.watch(inventoryRepositoryProvider).watchBalances(itemId: itemId);
});

final inventoryMovementsProvider = StreamProvider.autoDispose
    .family<List<InventoryStockMovement>, InventoryMovementQuery>((ref, query) {
  if (!ref.watch(inventoryAccessPolicyProvider).canReadExactStock) {
    return Stream.value(const []);
  }
  return ref.watch(inventoryRepositoryProvider).watchMovements(
        itemId: query.itemId,
        requestId: query.requestId,
        limit: query.limit,
      );
});

final inventoryMovementsPageProvider = FutureProvider.autoDispose.family<
    InventoryPageResult<InventoryStockMovement>, InventoryMovementPageKey>(
  (ref, key) {
    if (!ref.watch(inventoryAccessPolicyProvider).canReadExactStock) {
      return Future.value(const InventoryPageResult(
        items: <InventoryStockMovement>[],
        hasMore: false,
      ));
    }
    return ref.watch(inventoryRepositoryProvider).fetchMovementsPage(
          query: key.query,
          page: key.page,
        );
  },
);

final materialRequestsProvider = StreamProvider.autoDispose
    .family<List<MaterialRequest>, InventoryRequestQuery>((ref, query) {
  final session = ref.watch(inventorySessionProvider).valueOrNull;
  if (session == null || session.role == InventoryRole.none) {
    return Stream.value(const []);
  }
  return ref.watch(inventoryRepositoryProvider).watchRequests(session, query);
});

final materialRequestsPageProvider = FutureProvider.autoDispose
    .family<InventoryPageResult<MaterialRequest>, InventoryRequestPageKey>(
  (ref, key) {
    final session = ref.watch(inventorySessionProvider).valueOrNull;
    if (session == null || session.role == InventoryRole.none) {
      return Future.value(const InventoryPageResult(
        items: <MaterialRequest>[],
        hasMore: false,
      ));
    }
    return ref.watch(inventoryRepositoryProvider).fetchRequestsPage(
          session,
          key.query,
          key.page,
        );
  },
);

final inventoryItemsPageProvider = FutureProvider.autoDispose
    .family<InventoryPageResult<InventoryItem>, InventoryItemPageKey>(
        (ref, key) {
  if (!ref.watch(inventoryAccessPolicyProvider).canReadExactStock) {
    return Future.value(const InventoryPageResult(
      items: <InventoryItem>[],
      hasMore: false,
    ));
  }
  return ref.watch(inventoryRepositoryProvider).fetchItemsPage(
        key.query,
        key.page,
      );
});

final materialRequestProvider = StreamProvider.autoDispose
    .family<MaterialRequest?, String>((ref, requestId) {
  if (!_hasInventorySession(ref)) return Stream.value(null);
  return ref.watch(inventoryRepositoryProvider).watchRequest(requestId);
});

final materialRequestLinesProvider = StreamProvider.autoDispose
    .family<List<MaterialRequestLine>, String>((ref, requestId) {
  if (!_hasInventorySession(ref)) return Stream.value(const []);
  return ref.watch(inventoryRepositoryProvider).watchRequestLines(requestId);
});

final materialRequestAllocationsProvider = StreamProvider.autoDispose
    .family<List<MaterialRequestAllocation>, String>((ref, requestId) {
  if (!_hasInventorySession(ref)) return Stream.value(const []);
  return ref
      .watch(inventoryRepositoryProvider)
      .watchRequestAllocations(requestId);
});

final inventoryAlertsProvider =
    StreamProvider.autoDispose.family<List<InventoryAlert>, int>((ref, limit) {
  if (!ref.watch(inventoryAccessPolicyProvider).canReadExactStock) {
    return Stream.value(const []);
  }
  return ref.watch(inventoryRepositoryProvider).watchActiveAlerts(limit: limit);
});

final inventoryAuditProvider = StreamProvider.autoDispose
    .family<List<InventoryAuditEvent>, int>((ref, limit) {
  if (!ref.watch(inventoryAccessPolicyProvider).canReadAudit) {
    return Stream.value(const []);
  }
  return ref.watch(inventoryRepositoryProvider).watchAudit(limit: limit);
});

final inventoryDashboardProvider =
    StreamProvider.autoDispose<InventoryDashboardStats>((ref) {
  final role = ref.watch(currentInventoryRoleProvider);
  if (role != InventoryRole.manager && role != InventoryRole.admin) {
    return Stream.value(InventoryDashboardStats.empty);
  }
  return ref.watch(inventoryRepositoryProvider).watchDashboard(role);
});

final inventoryRequestDraftProvider = StateNotifierProvider.autoDispose
    .family<InventoryRequestDraftController, InventoryRequestDraft, String>(
        (ref, sessionKey) {
  ref.watch(currentAuthorizedSessionKeyProvider);
  return InventoryRequestDraftController();
});

final inventoryCommandControllerProvider = StateNotifierProvider.autoDispose<
    InventoryCommandController, AsyncValue<InventoryCommandResult?>>((ref) {
  final sessionKey = ref.watch(currentAuthorizedSessionKeyProvider);
  return InventoryCommandController(
    gateway: ref.watch(inventoryCommandGatewayProvider),
    isAuthorized: sessionKey != null &&
        ref.watch(currentInventoryRoleProvider) != InventoryRole.none,
  );
});

class InventoryCommandController
    extends StateNotifier<AsyncValue<InventoryCommandResult?>> {
  InventoryCommandController({
    required InventoryCommandGateway gateway,
    required bool isAuthorized,
  })  : _gateway = gateway,
        _isAuthorized = isAuthorized,
        super(const AsyncData(null));

  final InventoryCommandGateway _gateway;
  final bool _isAuthorized;

  Future<InventoryCommandResult> execute({
    required String functionName,
    required String commandId,
    required Map<String, Object?> payload,
  }) async {
    if (!_isAuthorized) throw const InventorySessionRequired();
    if (state.isLoading) throw const InventoryCommandInProgress();
    state = const AsyncLoading();
    try {
      final result = await _gateway.execute(
        InventoryCommand(
          functionName: functionName,
          commandId: commandId,
          payload: payload,
        ),
      );
      if (mounted) state = AsyncData(result);
      return result;
    } catch (error, stackTrace) {
      if (mounted) state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  void clear() {
    if (mounted && !state.isLoading) state = const AsyncData(null);
  }
}

class InventoryItemPageKey {
  const InventoryItemPageKey(this.query, this.page);
  final InventoryItemQuery query;
  final InventoryPageRequest page;

  @override
  bool operator ==(Object other) =>
      other is InventoryItemPageKey &&
      other.query == query &&
      other.page == page;

  @override
  int get hashCode => Object.hash(query, page);
}

class InventoryMovementPageKey {
  const InventoryMovementPageKey(this.query, this.page);
  final InventoryMovementQuery query;
  final InventoryPageRequest page;

  @override
  bool operator ==(Object other) =>
      other is InventoryMovementPageKey &&
      other.query == query &&
      other.page == page;

  @override
  int get hashCode => Object.hash(query, page);
}

class InventoryRequestPageKey {
  const InventoryRequestPageKey(this.query, this.page);
  final InventoryRequestQuery query;
  final InventoryPageRequest page;

  @override
  bool operator ==(Object other) =>
      other is InventoryRequestPageKey &&
      other.query == query &&
      other.page == page;

  @override
  int get hashCode => Object.hash(query, page);
}

class InventoryCommandInProgress implements Exception {
  const InventoryCommandInProgress();

  @override
  String toString() => 'An Inventory action is already in progress.';
}

bool _hasInventorySession(Ref ref) {
  final session = ref.watch(inventorySessionProvider).valueOrNull;
  return session != null && session.role != InventoryRole.none;
}
