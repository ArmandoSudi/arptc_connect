DateTime? changeDateFromValue(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value.toUtc();
  if (value is String) return DateTime.tryParse(value)?.toUtc();
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
  }

  try {
    final result = (value as dynamic).toDate();
    return result is DateTime ? result.toUtc() : null;
  } on Object {
    return null;
  }
}

Map<String, Object?> changeMapFromValue(Object? value) {
  if (value is! Map) return const {};
  return value.map((key, item) => MapEntry(key.toString(), item));
}

List<Object?> changeListFromValue(Object? value) {
  return value is Iterable ? List<Object?>.from(value) : const [];
}

String changeString(Object? value, [String fallback = '']) {
  final result = value?.toString().trim();
  return result == null || result.isEmpty ? fallback : result;
}

String? changeNullableString(Object? value) {
  final result = changeString(value);
  return result.isEmpty ? null : result;
}

int changeInt(Object? value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(changeString(value)) ?? fallback;
}

bool changeBool(Object? value, [bool fallback = false]) {
  if (value is bool) return value;
  return switch (changeString(value).toLowerCase()) {
    'true' || '1' => true,
    'false' || '0' => false,
    _ => fallback,
  };
}

List<String> changeStringList(Object? value) {
  return List<String>.unmodifiable(
    changeListFromValue(value)
        .map(changeString)
        .where((item) => item.isNotEmpty)
        .toSet(),
  );
}

List<T> changeModelList<T>(
  Object? value,
  T Function(Map<String, Object?> map) fromMap,
) {
  return List<T>.unmodifiable(
    changeListFromValue(value)
        .map(changeMapFromValue)
        .where((map) => map.isNotEmpty)
        .map(fromMap),
  );
}

String requireChangeText(String value, String fieldName) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(
      value,
      fieldName,
      'A non-empty value is required.',
    );
  }
  return normalized;
}

DateTime requireChangeDate(Object? value, String fieldName) {
  final parsed = changeDateFromValue(value);
  if (parsed == null) {
    throw ArgumentError.value(value, fieldName, 'A valid date is required.');
  }
  return parsed;
}
