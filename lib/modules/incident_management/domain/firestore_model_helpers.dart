import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? dateTimeFromFirestore(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}

Object? dateTimeToFirestore(DateTime? value) {
  if (value == null) {
    return null;
  }
  return Timestamp.fromDate(value);
}

String stringFromFirestore(Map<String, dynamic> data, String key) {
  return data[key]?.toString().trim() ?? '';
}

List<String> stringListFromFirestore(
  Map<String, dynamic> data,
  String key,
) {
  final value = data[key];
  if (value is! Iterable) {
    return const [];
  }
  return List<String>.unmodifiable(
    value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty),
  );
}

int intFromFirestore(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool boolFromFirestore(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is bool) {
    return value;
  }
  return value?.toString().toLowerCase() == 'true';
}
