import '../../shared/domain/pagination.dart';
import '../domain/assets_configuration_domain.dart';

abstract interface class SupplierWarrantyRepository {
  Future<PageResult<Supplier>> fetchSuppliersPage({
    required PageRequest page,
    bool activeOnly = true,
  });

  Stream<Supplier?> watchSupplier(String supplierId);

  Future<PageResult<SupplierContract>> fetchContractsPage({
    required PageRequest page,
    String supplierId = '',
    ContractStatus? status,
  });

  Future<PageResult<Warranty>> fetchWarrantiesPage({
    required PageRequest page,
    String supplierId = '',
    DateTime? expiringBefore,
  });

  Future<PageResult<WarrantyClaim>> fetchClaimsPage({
    required String warrantyId,
    required PageRequest page,
  });
}
