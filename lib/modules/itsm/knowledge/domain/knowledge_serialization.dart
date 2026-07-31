import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? knowledgeDate(Object? value) {
  if (value is Timestamp) return value.toDate().toUtc();
  if (value is DateTime) return value.toUtc();
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
  }
  if (value is String) return DateTime.tryParse(value)?.toUtc();
  return null;
}

Timestamp? knowledgeTimestamp(DateTime? value) {
  return value == null ? null : Timestamp.fromDate(value.toUtc());
}

String knowledgeString(Map<String, dynamic> data, String key) {
  return data[key]?.toString().trim() ?? '';
}

int knowledgeInt(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool knowledgeBool(
  Map<String, dynamic> data,
  String key, {
  bool fallback = false,
}) {
  final value = data[key];
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == 'true') return true;
  if (normalized == 'false') return false;
  return fallback;
}

List<String> knowledgeStringList(Object? value) {
  if (value is! Iterable) return const [];
  return List<String>.unmodifiable(
    value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty),
  );
}

Map<String, dynamic> knowledgeMap(Object? value) {
  if (value is Map<String, dynamic>) return Map<String, dynamic>.from(value);
  if (value is Map) {
    return value.map(
      (key, item) => MapEntry(key.toString(), item),
    );
  }
  return const {};
}

String normalizeKnowledgeSearch(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

Set<String> buildKnowledgeSearchTokens(Iterable<String> values) {
  final tokens = <String>{};
  for (final value in values) {
    final normalized = normalizeKnowledgeSearch(value);
    if (normalized.isEmpty) continue;
    tokens.add(normalized);
    for (final word in normalized.split(' ')) {
      if (word.length < 2) continue;
      for (var length = 2; length <= word.length; length++) {
        tokens.add(word.substring(0, length));
      }
    }
  }
  return Set<String>.unmodifiable(tokens);
}
