import 'package:cloud_firestore/cloud_firestore.dart';

import '../../shared/domain/pagination.dart';
import '../domain/assets_configuration_domain.dart';
import 'firestore_page_support.dart';
import 'supplier_warranty_repository.dart';

const warrantiesCollectionPath = 'warranties';
const warrantyClaimsCollectionName = 'claims';
const warrantyClaimSortField = 'updatedAt';

String warrantyClaimsPath(String warrantyId) => '$warrantiesCollectionPath/'
    '${requireRepositoryId(warrantyId, 'warrantyId')}/'
    '$warrantyClaimsCollectionName';

class FirestoreSupplierWarrantyRepository
    implements SupplierWarrantyRepository {
  FirestoreSupplierWarrantyRepository(FirebaseFirestore firestore)
      : _suppliers = firestore.collection('suppliers'),
        _contracts = firestore.collection('supplierContracts'),
        _warranties = firestore.collection(warrantiesCollectionPath);

  final CollectionReference<Map<String, dynamic>> _suppliers;
  final CollectionReference<Map<String, dynamic>> _contracts;
  final CollectionReference<Map<String, dynamic>> _warranties;

  @override
  Future<PageResult<Supplier>> fetchSuppliersPage({
    required PageRequest page,
    bool activeOnly = true,
  }) {
    Query<Map<String, dynamic>> query = _suppliers;
    if (activeOnly) query = query.where('isActive', isEqualTo: true);
    return fetchFirestorePage(
      query: query,
      page: page,
      sortField: 'updatedAt',
      parse: Supplier.fromFirestore,
    );
  }

  @override
  Stream<Supplier?> watchSupplier(String supplierId) {
    final id = requireRepositoryId(supplierId, 'supplierId');
    return _suppliers.doc(id).snapshots().map(
          (snapshot) =>
              snapshot.exists ? Supplier.fromFirestore(snapshot) : null,
        );
  }

  @override
  Future<PageResult<SupplierContract>> fetchContractsPage({
    required PageRequest page,
    String supplierId = '',
    ContractStatus? status,
  }) {
    Query<Map<String, dynamic>> query = _contracts;
    if (supplierId.trim().isNotEmpty) {
      query = query.where('supplierId', isEqualTo: supplierId.trim());
    }
    if (status != null) query = query.where('status', isEqualTo: status.name);
    return fetchFirestorePage(
      query: query,
      page: page,
      sortField: 'updatedAt',
      parse: SupplierContract.fromFirestore,
    );
  }

  @override
  Future<PageResult<Warranty>> fetchWarrantiesPage({
    required PageRequest page,
    String supplierId = '',
    DateTime? expiringBefore,
  }) {
    Query<Map<String, dynamic>> query = _warranties;
    if (supplierId.trim().isNotEmpty) {
      query = query.where('supplierId', isEqualTo: supplierId.trim());
    }
    if (expiringBefore != null) {
      query = query.where(
        'expirationDate',
        isLessThanOrEqualTo: Timestamp.fromDate(expiringBefore.toUtc()),
      );
    }
    return fetchFirestorePage(
      query: query,
      page: page,
      sortField: 'expirationDate',
      parse: Warranty.fromFirestore,
    );
  }

  @override
  Future<PageResult<WarrantyClaim>> fetchClaimsPage({
    required String warrantyId,
    required PageRequest page,
  }) {
    final id = requireRepositoryId(warrantyId, 'warrantyId');
    return fetchFirestorePage(
      query: _warranties.doc(id).collection(warrantyClaimsCollectionName),
      page: page,
      sortField: warrantyClaimSortField,
      parse: WarrantyClaim.fromFirestore,
    );
  }
}
