import '../../shared/domain/pagination.dart';
import '../domain/assets_configuration_domain.dart';

class AssetQuery {
  const AssetQuery({
    this.status,
    this.categoryId = '',
    this.locationId = '',
    this.searchToken = '',
  });

  final AssetStatus? status;
  final String categoryId;
  final String locationId;
  final String searchToken;
}

abstract interface class AssetRepository {
  Future<PageResult<Asset>> fetchAssetsPage({
    required AssetQuery query,
    required PageRequest page,
  });

  Stream<Asset?> watchAsset(String assetId);

  Future<PageResult<AssetAssignment>> fetchAssignmentsPage({
    required String assetId,
    required PageRequest page,
  });

  Future<PageResult<AssetLifecycleEvent>> fetchLifecyclePage({
    required String assetId,
    required PageRequest page,
  });
}

abstract interface class MyAssetsRepository {
  Future<PageResult<AssetAssignment>> fetchMyAssetsPage({
    required String currentUserId,
    required PageRequest page,
  });

  Stream<List<AssetAssignment>> watchMyCurrentAssets({
    required String currentUserId,
    int limit = PageRequest.defaultLimit,
  });
}
