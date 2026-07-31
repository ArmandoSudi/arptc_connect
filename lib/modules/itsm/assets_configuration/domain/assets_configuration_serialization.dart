import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? itsmAssetDate(Object? value) {
  if (value is Timestamp) return value.toDate().toUtc();
  if (value is DateTime) return value.toUtc();
  if (value is String) return DateTime.tryParse(value)?.toUtc();
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
  }
  return null;
}

Timestamp? itsmAssetTimestamp(DateTime? value) =>
    value == null ? null : Timestamp.fromDate(value.toUtc());

String itsmAssetString(Map<Object?, Object?> data, String key) =>
    data[key]?.toString().trim() ?? '';

int itsmAssetInt(Map<Object?, Object?> data, String key) {
  final value = data[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double itsmAssetDouble(Map<Object?, Object?> data, String key) {
  final value = data[key];
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

bool itsmAssetBool(Map<Object?, Object?> data, String key) {
  final value = data[key];
  if (value is bool) return value;
  return value?.toString().toLowerCase() == 'true';
}

Map<String, Object?> itsmAssetMap(Object? value) {
  if (value is! Map) return const {};
  return value.map((key, item) => MapEntry(key.toString(), item));
}

List<String> itsmAssetStrings(Object? value) {
  if (value is! Iterable) return const [];
  return List<String>.unmodifiable(
    value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toSet(),
  );
}

String requireItsmAssetText(String value, String name) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, name, '$name is required.');
  }
  return normalized;
}

List<String> immutableItsmAssetIds(Iterable<String> values) =>
    List<String>.unmodifiable(
      values.map((value) => value.trim()).where((value) => value.isNotEmpty),
    );
