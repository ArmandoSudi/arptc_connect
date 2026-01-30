import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreFilter {
  final String field;
  final dynamic isEqualTo;
  final dynamic isGreaterThan;
  final dynamic isGreaterThanOrEqualTo;
  final dynamic isLessThan;
  final dynamic isLessThanOrEqualTo;
  final dynamic arrayContains;
  final List<dynamic>? arrayContainsAny;
  final List<dynamic>? whereIn;
  final List<dynamic>? whereNotIn;
  final bool? isNull;

  const FirestoreFilter({
    required this.field,
    this.isEqualTo,
    this.isGreaterThan,
    this.isGreaterThanOrEqualTo,
    this.isLessThan,
    this.isLessThanOrEqualTo,
    this.arrayContains,
    this.arrayContainsAny,
    this.whereIn,
    this.whereNotIn,
    this.isNull,
  });

  /// Helper factory for creating a simple equality filter
  factory FirestoreFilter.equals(String field, dynamic value) {
    return FirestoreFilter(
      field: field,
      isEqualTo: value,
    );
  }

  /// Helper factory for creating a range filter
  factory FirestoreFilter.range(String field, {
    dynamic greaterThan,
    dynamic greaterThanOrEqual,
    dynamic lessThan,
    dynamic lessThanOrEqual,
  }) {
    return FirestoreFilter(
      field: field,
      isGreaterThan: greaterThan,
      isGreaterThanOrEqualTo: greaterThanOrEqual,
      isLessThan: lessThan,
      isLessThanOrEqualTo: lessThanOrEqual,
    );
  }

  /// Helper factory for creating timestamp range filters
  factory FirestoreFilter.dateRange(String field, {
    DateTime? start,
    DateTime? end,
    bool includeStart = true,
    bool includeEnd = false,
  }) {
    return FirestoreFilter(
      field: field,
      isGreaterThanOrEqualTo: start != null ? Timestamp.fromDate(start) : null,
      isLessThan: end != null ? Timestamp.fromDate(end) : null,
    );
  }
}
