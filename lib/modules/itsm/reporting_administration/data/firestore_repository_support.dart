import 'package:cloud_firestore/cloud_firestore.dart';

import '../../shared/domain/pagination.dart';

void requireForwardPage(PageRequest page) {
  if (page.direction != PageDirection.forward) {
    throw const ReportingAdministrationRepositoryException(
      'Reporting & Administration supports forward pagination only.',
    );
  }
}

void validateReadRole(Object role, bool allowed) {
  if (!allowed) {
    throw const ReportingAdministrationRepositoryException(
      'The active role cannot read this administration resource.',
    );
  }
}

Query<Map<String, dynamic>> applyDescendingCursor(
  Query<Map<String, dynamic>> query,
  PageCursor? cursor,
  String timestampField,
) {
  if (cursor == null) return query;
  final timestamp = cursor[timestampField];
  final id = cursor['id'];
  if (timestamp == null || id == null) {
    throw ReportingAdministrationRepositoryException(
      'The cursor requires $timestampField and id.',
    );
  }
  return query.startAfter([timestamp, id]);
}

PageCursor documentCursor(
  QueryDocumentSnapshot<Map<String, dynamic>> document,
  String timestampField,
) =>
    PageCursor({
      timestampField: document.data()[timestampField],
      'id': document.id,
    });

class ReportingAdministrationRepositoryException implements Exception {
  const ReportingAdministrationRepositoryException(this.message);

  final String message;

  @override
  String toString() => 'ReportingAdministrationRepositoryException($message)';
}
