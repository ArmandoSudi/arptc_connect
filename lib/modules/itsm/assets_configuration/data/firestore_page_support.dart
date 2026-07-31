import 'package:cloud_firestore/cloud_firestore.dart';

import '../../shared/domain/pagination.dart';
import '../domain/assets_configuration_serialization.dart';

class FirestorePageCursorCodec {
  const FirestorePageCursorCodec({required this.sortField});

  final String sortField;

  PageCursor encode({required DateTime sortAt, required String documentId}) =>
      PageCursor({
        sortField: sortAt.toUtc().toIso8601String(),
        'documentId': documentId.trim(),
      });

  List<Object> decode(PageCursor cursor) {
    final sortAt = itsmAssetDate(cursor[sortField]);
    final documentId = cursor['documentId']?.toString().trim() ?? '';
    if (sortAt == null || documentId.isEmpty) {
      throw AssetsConfigurationPaginationException(
        'Cursor requires $sortField and documentId.',
      );
    }
    return [Timestamp.fromDate(sortAt), documentId];
  }
}

class AssetsConfigurationPaginationException implements Exception {
  const AssetsConfigurationPaginationException(this.message);

  final String message;

  @override
  String toString() => 'AssetsConfigurationPaginationException($message)';
}

Future<PageResult<T>> fetchFirestorePage<T>({
  required Query<Map<String, dynamic>> query,
  required PageRequest page,
  required String sortField,
  required T Function(QueryDocumentSnapshot<Map<String, dynamic>>) parse,
}) async {
  if (page.direction != PageDirection.forward) {
    throw const AssetsConfigurationPaginationException(
      'Firestore repositories support forward cursor pagination only.',
    );
  }
  final codec = FirestorePageCursorCodec(sortField: sortField);
  var ordered = query
      .orderBy(sortField, descending: true)
      .orderBy(FieldPath.documentId, descending: true);
  if (page.cursor != null) {
    ordered = ordered.startAfter(codec.decode(page.cursor!));
  }
  final snapshot = await ordered.limit(page.limit + 1).get();
  final hasMore = snapshot.docs.length > page.limit;
  final documents = snapshot.docs.take(page.limit).toList(growable: false);
  PageCursor? nextCursor;
  if (hasMore && documents.isNotEmpty) {
    final last = documents.last;
    final sortAt = itsmAssetDate(last.data()[sortField]);
    if (sortAt == null) {
      throw AssetsConfigurationPaginationException(
        'Document ${last.id} has no $sortField cursor value.',
      );
    }
    nextCursor = codec.encode(sortAt: sortAt, documentId: last.id);
  }
  return PageResult(
    items: documents.map(parse),
    hasMore: hasMore,
    nextCursor: nextCursor,
  );
}

String requireRepositoryId(String value, String name) =>
    requireItsmAssetText(value, name);

void requireRepositoryLimit(int limit) {
  if (limit < 1 || limit > PageRequest.maximumLimit) {
    throw RangeError.range(limit, 1, PageRequest.maximumLimit, 'limit');
  }
}
