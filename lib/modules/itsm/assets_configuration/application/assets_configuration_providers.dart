import 'dart:async';

import 'package:arptc_connect/core/firebase_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/application/itsm_providers.dart';
import '../../shared/application/itsm_session.dart';
import '../../shared/domain/pagination.dart';
import '../data/firestore_assets_configuration_port.dart';
import '../data/firebase_assets_attachment_gateway.dart';
import 'assets_attachment.dart';
import 'assets_configuration_access_policy.dart';
import 'assets_configuration_command_controller.dart';
import 'assets_configuration_contracts.dart';

final firestoreAssetsConfigurationPortProvider =
    Provider<FirestoreAssetsConfigurationPort>(
  (ref) => FirestoreAssetsConfigurationPort(),
);

final assetsConfigurationReadPortProvider =
    Provider<AssetsConfigurationReadPort>(
  (ref) => ref.watch(firestoreAssetsConfigurationPortProvider),
);

final assetsConfigurationCommandPortProvider =
    Provider<AssetsConfigurationCommandPort>(
  (ref) => ref.watch(firestoreAssetsConfigurationPortProvider),
);

final assetsAttachmentGatewayProvider = Provider<AssetsAttachmentGateway>(
  (ref) => FirebaseAssetsAttachmentGateway(
    storage: ref.watch(firebaseStorageProvider),
    firestore: ref.watch(fireStoreProvider),
  ),
);

final assetsConfigurationAccessPolicyProvider =
    Provider<AssetsConfigurationAccessPolicy>(
  (ref) => const AssetsConfigurationAccessPolicy(),
);

final assetsConfigurationAccessProvider =
    Provider.autoDispose<AsyncValue<AssetsConfigurationAccess>>((ref) {
  final policy = ref.watch(assetsConfigurationAccessPolicyProvider);
  return ref.watch(itsmSessionProvider).whenData((session) {
    if (session == null) return const AssetsConfigurationAccess.denied();
    return AssetsConfigurationAccess(
      canReadMyAssets: policy.canReadMyAssets(session),
      canOperate: policy.canOperate(session),
    );
  });
});

class AssetsConfigurationAccess {
  const AssetsConfigurationAccess({
    required this.canReadMyAssets,
    required this.canOperate,
  });

  const AssetsConfigurationAccess.denied()
      : canReadMyAssets = false,
        canOperate = false;

  final bool canReadMyAssets;
  final bool canOperate;
}

final myAssetsProvider =
    StreamProvider.autoDispose.family<List<AssetSummary>, int>((ref, limit) {
  _validateLimit(limit);
  final port = ref.watch(assetsConfigurationReadPortProvider);
  final policy = ref.read(assetsConfigurationAccessPolicyProvider);
  return _sessionStream(ref, (session) {
    policy.authorizeMyAssets(session);
    return port.watchMyAssets(
      principal: AssetConfigurationPrincipal.fromSession(session),
      limit: limit,
    );
  });
});

final assetRegisterProvider = StreamProvider.autoDispose
    .family<List<AssetSummary>, AssetRegisterRequest>((ref, request) {
  _validateLimit(request.limit);
  final port = ref.watch(assetsConfigurationReadPortProvider);
  final policy = ref.read(assetsConfigurationAccessPolicyProvider);
  return _sessionStream(ref, (session) {
    policy.authorizeOperational(session);
    return port.watchAssetRegister(
      principal: AssetConfigurationPrincipal.fromSession(session),
      query: request.query,
      limit: request.limit,
    );
  });
});

class AssetRegisterRequest {
  const AssetRegisterRequest({
    this.query = const AssetListQuery(),
    this.limit = PageRequest.defaultLimit,
  });

  final AssetListQuery query;
  final int limit;

  @override
  bool operator ==(Object other) =>
      other is AssetRegisterRequest &&
      other.query == query &&
      other.limit == limit;

  @override
  int get hashCode => Object.hash(query, limit);
}

final assetPageProvider = FutureProvider.autoDispose
    .family<PageResult<AssetSummary>, AssetPageRequest>((ref, request) async {
  final port = ref.watch(assetsConfigurationReadPortProvider);
  final session = await _requireSession(ref);
  ref
      .read(assetsConfigurationAccessPolicyProvider)
      .authorizeOperational(session);
  return port.fetchAssetPage(
    principal: AssetConfigurationPrincipal.fromSession(session),
    request: request,
  );
});

final assetDetailProvider = StreamProvider.autoDispose
    .family<AssetDetail?, AssetIdentity>((ref, identity) {
  final port = ref.watch(assetsConfigurationReadPortProvider);
  final policy = ref.read(assetsConfigurationAccessPolicyProvider);
  return _sessionStream(ref, (session) {
    if (identity.selfService) {
      policy.authorizeMyAssets(session);
    } else {
      policy.authorizeOperational(session);
    }
    final principal = AssetConfigurationPrincipal.fromSession(session);
    return identity.selfService
        ? port.watchMyAssetDetail(principal: principal, assetId: identity.id)
        : port.watchAssetDetail(principal: principal, assetId: identity.id);
  });
});

class AssetIdentity {
  AssetIdentity({required String id, required this.selfService})
      : id = id.trim() {
    if (this.id.isEmpty) throw ArgumentError.value(id, 'id');
  }

  final String id;
  final bool selfService;

  @override
  bool operator ==(Object other) =>
      other is AssetIdentity &&
      other.id == id &&
      other.selfService == selfService;

  @override
  int get hashCode => Object.hash(id, selfService);
}

final stockItemsProvider = StreamProvider.autoDispose
    .family<List<StockItemSummary>, int>((ref, limit) {
  return _managerListStream(
    ref,
    limit,
    (port, principal) => port.watchStockItems(
      principal: principal,
      limit: limit,
    ),
  );
});

final stockMovementsProvider = StreamProvider.autoDispose
    .family<List<StockMovementSummary>, int>((ref, limit) {
  return _managerListStream(
    ref,
    limit,
    (port, principal) => port.watchStockMovements(
      principal: principal,
      limit: limit,
    ),
  );
});

final licencesProvider =
    StreamProvider.autoDispose.family<List<LicenceSummary>, int>((ref, limit) {
  return _managerListStream(
    ref,
    limit,
    (port, principal) => port.watchLicences(
      principal: principal,
      limit: limit,
    ),
  );
});

final suppliersProvider =
    StreamProvider.autoDispose.family<List<SupplierSummary>, int>((ref, limit) {
  return _managerListStream(
    ref,
    limit,
    (port, principal) => port.watchSuppliers(
      principal: principal,
      limit: limit,
    ),
  );
});

final contractsProvider =
    StreamProvider.autoDispose.family<List<ContractSummary>, int>((ref, limit) {
  return _managerListStream(
    ref,
    limit,
    (port, principal) => port.watchContracts(
      principal: principal,
      limit: limit,
    ),
  );
});

final warrantiesProvider =
    StreamProvider.autoDispose.family<List<WarrantySummary>, int>((ref, limit) {
  return _managerListStream(
    ref,
    limit,
    (port, principal) => port.watchWarranties(
      principal: principal,
      limit: limit,
    ),
  );
});

final configurationItemsProvider = StreamProvider.autoDispose
    .family<List<ConfigurationItemSummary>, int>((ref, limit) {
  return _managerListStream(
    ref,
    limit,
    (port, principal) => port.watchConfigurationItems(
      principal: principal,
      limit: limit,
    ),
  );
});

final configurationDependencyProvider = StreamProvider.autoDispose
    .family<ConfigurationDependencyView?, String>((ref, itemId) {
  final normalizedId = itemId.trim();
  if (normalizedId.isEmpty) {
    return Stream.error(ArgumentError.value(itemId, 'itemId'));
  }
  final port = ref.watch(assetsConfigurationReadPortProvider);
  final policy = ref.read(assetsConfigurationAccessPolicyProvider);
  return _sessionStream(ref, (session) {
    policy.authorizeOperational(session);
    return port.watchDependencyView(
      principal: AssetConfigurationPrincipal.fromSession(session),
      configurationItemId: normalizedId,
    );
  });
});

final assetsConfigurationCommandControllerProvider =
    FutureProvider.autoDispose<AssetsConfigurationCommandController>(
        (ref) async {
  final session = await _requireSession(ref);
  return AssetsConfigurationCommandController(
    session: session,
    accessPolicy: ref.read(assetsConfigurationAccessPolicyProvider),
    commandPort: ref.read(assetsConfigurationCommandPortProvider),
    executor: ref.read(itsmCommandExecutorProvider),
  );
});

Stream<T> _sessionStream<T>(
  Ref ref,
  Stream<T> Function(ItsmSession session) build,
) {
  return ref.watch(itsmSessionProvider).when(
        loading: _pendingStream,
        error: (error, stackTrace) => Stream.error(error, stackTrace),
        data: (session) => session == null
            ? Stream.error(const ItsmSessionRequiredException())
            : build(session),
      );
}

Stream<List<T>> _managerListStream<T>(
  Ref ref,
  int limit,
  Stream<List<T>> Function(
    AssetsConfigurationReadPort port,
    AssetConfigurationPrincipal principal,
  ) build,
) {
  _validateLimit(limit);
  final port = ref.watch(assetsConfigurationReadPortProvider);
  final policy = ref.read(assetsConfigurationAccessPolicyProvider);
  return _sessionStream(ref, (session) {
    policy.authorizeOperational(session);
    return build(port, AssetConfigurationPrincipal.fromSession(session));
  });
}

Future<ItsmSession> _requireSession(Ref ref) async {
  final session = await ref.watch(itsmSessionProvider.future);
  if (session == null) throw const ItsmSessionRequiredException();
  return session;
}

Stream<T> _pendingStream<T>() => Stream<T>.multi((_) {});

void _validateLimit(int limit) {
  if (limit < 1 || limit > PageRequest.maximumLimit) {
    throw RangeError.range(limit, 1, PageRequest.maximumLimit, 'limit');
  }
}
