import '../../shared/data/itsm_work_item_repository.dart';
import '../../shared/domain/pagination.dart';
import '../domain/support_domain.dart';

class ServiceCatalogueQuery {
  const ServiceCatalogueQuery({
    this.searchTerm = '',
    this.categoryId,
    this.effectiveAt,
  });

  final String searchTerm;
  final String? categoryId;
  final DateTime? effectiveAt;

  bool matches(ServiceCatalogueItem item, String languageCode) {
    final normalizedCategory = categoryId?.trim() ?? '';
    if (normalizedCategory.isNotEmpty &&
        item.categoryId != normalizedCategory) {
      return false;
    }
    final search = searchTerm.trim().toLowerCase();
    if (search.isEmpty) return true;
    return item.code.toLowerCase().contains(search) ||
        item.name.resolve(languageCode).toLowerCase().contains(search) ||
        item.description.resolve(languageCode).toLowerCase().contains(search) ||
        item.categoryName.resolve(languageCode).toLowerCase().contains(search);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ServiceCatalogueQuery &&
            searchTerm.trim() == other.searchTerm.trim() &&
            categoryId?.trim() == other.categoryId?.trim() &&
            effectiveAt == other.effectiveAt;
  }

  @override
  int get hashCode => Object.hash(
        searchTerm.trim(),
        categoryId?.trim(),
        effectiveAt,
      );
}

abstract interface class ServiceCatalogueRepository {
  Future<PageResult<ServiceCatalogueItem>> fetchPublishedPage({
    required ItsmQueryPrincipal principal,
    required CataloguePrincipal cataloguePrincipal,
    required ServiceCatalogueQuery query,
    required PageRequest page,
    required String languageCode,
  });

  Stream<List<ServiceCatalogueItem>> watchPublishedFirstPage({
    required ItsmQueryPrincipal principal,
    required CataloguePrincipal cataloguePrincipal,
    required ServiceCatalogueQuery query,
    required int limit,
    required String languageCode,
  });

  Future<ServiceCatalogueItem?> getPublishedById({
    required ItsmQueryPrincipal principal,
    required CataloguePrincipal cataloguePrincipal,
    required String id,
    required DateTime at,
  });
}

class ServiceCatalogueRepositoryException implements Exception {
  const ServiceCatalogueRepositoryException(this.message);

  final String message;

  @override
  String toString() => 'ServiceCatalogueRepositoryException($message)';
}
