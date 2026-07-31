import '../../shared/data/itsm_work_item_repository.dart';
import '../../shared/domain/itsm_common.dart';
import '../../shared/domain/pagination.dart';
import '../domain/catalogue_configuration.dart';

class CatalogueAdministrationQuery {
  const CatalogueAdministrationQuery({this.status, this.categoryId});

  final ItsmPublicationState? status;
  final String? categoryId;
}

abstract interface class CatalogueAdministrationRepository {
  Future<PageResult<CatalogueItemConfiguration>> fetchItems({
    required ItsmQueryPrincipal principal,
    required CatalogueAdministrationQuery query,
    required PageRequest page,
  });

  Stream<CatalogueItemConfiguration?> watchItem({
    required ItsmQueryPrincipal principal,
    required String itemId,
  });

  Future<PageResult<CatalogueItemVersionConfiguration>> fetchVersions({
    required ItsmQueryPrincipal principal,
    required String itemId,
    required PageRequest page,
  });
}
