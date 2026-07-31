import 'package:cloud_firestore/cloud_firestore.dart';

import '../../shared/domain/pagination.dart';
import '../domain/assets_configuration_domain.dart';
import 'firestore_page_support.dart';
import 'licence_repository.dart';

const softwareLicencesCollectionPath = 'softwareLicences';
const softwareLicenceAllocationsCollectionName = 'allocations';
const softwareLicenceAllocationSortField = 'allocatedAt';

String softwareLicenceAllocationsPath(String licenceId) =>
    '$softwareLicencesCollectionPath/'
    '${requireRepositoryId(licenceId, 'licenceId')}/'
    '$softwareLicenceAllocationsCollectionName';

class FirestoreLicenceRepository implements LicenceRepository {
  FirestoreLicenceRepository(FirebaseFirestore firestore)
      : _licences = firestore.collection(softwareLicencesCollectionPath);

  final CollectionReference<Map<String, dynamic>> _licences;

  @override
  Future<PageResult<SoftwareLicence>> fetchLicencesPage({
    required LicenceQuery query,
    required PageRequest page,
  }) {
    Query<Map<String, dynamic>> firestoreQuery = _licences;
    if (query.complianceStatus != null) {
      firestoreQuery = firestoreQuery.where(
        'complianceStatus',
        isEqualTo: query.complianceStatus!.value,
      );
    }
    if (query.expiringBefore != null) {
      firestoreQuery = firestoreQuery.where(
        'expiryDate',
        isLessThanOrEqualTo: Timestamp.fromDate(query.expiringBefore!.toUtc()),
      );
    }
    if (query.vendor.trim().isNotEmpty) {
      firestoreQuery =
          firestoreQuery.where('vendor', isEqualTo: query.vendor.trim());
    }
    return fetchFirestorePage(
      query: firestoreQuery,
      page: page,
      sortField: 'updatedAt',
      parse: SoftwareLicence.fromFirestore,
    );
  }

  @override
  Stream<SoftwareLicence?> watchLicence(String licenceId) {
    final id = requireRepositoryId(licenceId, 'licenceId');
    return _licences.doc(id).snapshots().map(
          (snapshot) =>
              snapshot.exists ? SoftwareLicence.fromFirestore(snapshot) : null,
        );
  }

  @override
  Future<PageResult<SoftwareLicenceAssignment>> fetchAssignmentsPage({
    required String licenceId,
    required PageRequest page,
  }) {
    final id = requireRepositoryId(licenceId, 'licenceId');
    return fetchFirestorePage(
      query: _licences
          .doc(id)
          .collection(softwareLicenceAllocationsCollectionName),
      page: page,
      sortField: softwareLicenceAllocationSortField,
      parse: SoftwareLicenceAssignment.fromFirestore,
    );
  }

  @override
  Future<PageResult<LicenceHistoryEvent>> fetchHistoryPage({
    required String licenceId,
    required PageRequest page,
  }) {
    final id = requireRepositoryId(licenceId, 'licenceId');
    return fetchFirestorePage(
      query: _licences.doc(id).collection('history'),
      page: page,
      sortField: 'occurredAt',
      parse: LicenceHistoryEvent.fromFirestore,
    );
  }
}
