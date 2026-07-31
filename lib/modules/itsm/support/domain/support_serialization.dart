DateTime? supportDateFromValue(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
  }

  // Keeps domain parsing independent from cloud_firestore while accepting a
  // Timestamp-like value supplied by a Firestore document map.
  try {
    final result = (value as dynamic).toDate();
    return result is DateTime ? result : null;
  } on Object {
    return null;
  }
}

Map<String, Object?> supportMapFromValue(Object? value) {
  if (value is Map<String, Object?>) {
    return Map<String, Object?>.from(value);
  }
  if (value is Map) {
    return value.map(
      (key, item) => MapEntry(key.toString(), item),
    );
  }
  return const {};
}

List<Object?> supportListFromValue(Object? value) {
  return value is Iterable<Object?> ? List<Object?>.from(value) : const [];
}

String supportString(Object? value, [String fallback = '']) {
  return value?.toString().trim() ?? fallback;
}

String? supportNullableString(Object? value) {
  final result = supportString(value);
  return result.isEmpty ? null : result;
}

int supportInt(Object? value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(supportString(value)) ?? fallback;
}

double? supportNullableDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(supportString(value));
}

bool supportBool(Object? value, [bool fallback = false]) {
  if (value is bool) return value;
  return switch (supportString(value).toLowerCase()) {
    'true' || '1' => true,
    'false' || '0' => false,
    _ => fallback,
  };
}

List<String> supportStringList(Object? value) {
  return supportListFromValue(value)
      .map(supportString)
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

void supportRequire(String value, String fieldName) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(
      value,
      fieldName,
      'A non-empty value is required.',
    );
  }
}
