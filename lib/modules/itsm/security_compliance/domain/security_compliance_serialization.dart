DateTime? securityComplianceDate(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value.toUtc();
  if (value is String) return DateTime.tryParse(value)?.toUtc();
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
  }

  try {
    final converted = (value as dynamic).toDate();
    return converted is DateTime ? converted.toUtc() : null;
  } on Object {
    return null;
  }
}

Map<String, Object?> securityComplianceMap(Object? value) {
  if (value is! Map) return const {};
  return value.map((key, item) => MapEntry(key.toString(), item));
}

List<Object?> securityComplianceList(Object? value) =>
    value is Iterable ? List<Object?>.from(value) : const [];

String securityComplianceString(Object? value, [String fallback = '']) {
  final result = value?.toString().trim();
  return result == null || result.isEmpty ? fallback : result;
}

String? securityComplianceNullableString(Object? value) {
  final result = securityComplianceString(value);
  return result.isEmpty ? null : result;
}

int securityComplianceInt(Object? value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(securityComplianceString(value)) ?? fallback;
}

bool securityComplianceBool(Object? value, [bool fallback = false]) {
  if (value is bool) return value;
  return switch (securityComplianceString(value).toLowerCase()) {
    'true' || '1' => true,
    'false' || '0' => false,
    _ => fallback,
  };
}

List<String> securityComplianceStrings(Object? value) =>
    List<String>.unmodifiable(
      securityComplianceList(value)
          .map(securityComplianceString)
          .where((item) => item.isNotEmpty)
          .toSet(),
    );

List<T> securityComplianceModels<T>(
  Object? value,
  T Function(Map<String, Object?> map) fromMap,
) =>
    List<T>.unmodifiable(
      securityComplianceList(value)
          .map(securityComplianceMap)
          .where((map) => map.isNotEmpty)
          .map(fromMap),
    );

String requireSecurityComplianceText(String value, String fieldName) {
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

DateTime requireSecurityComplianceDate(Object? value, String fieldName) {
  final parsed = securityComplianceDate(value);
  if (parsed == null) {
    throw ArgumentError.value(value, fieldName, 'A valid date is required.');
  }
  return parsed;
}

List<String> immutableSecurityComplianceStrings(Iterable<String> values) =>
    List<String>.unmodifiable(
      values
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toSet(),
    );

Map<String, Object?> immutableSecurityComplianceMap(
  Map<String, Object?> value,
) =>
    Map<String, Object?>.unmodifiable(Map<String, Object?>.from(value));

String enumStorageValue(Enum value) => value.name.replaceAllMapped(
      RegExp('[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    );

T enumFromStorageValue<T extends Enum>(
  Iterable<T> values,
  Object? value,
  T fallback,
) {
  final normalized = securityComplianceString(value)
      .toLowerCase()
      .replaceAll('-', '_')
      .replaceAll(' ', '_');
  return values.firstWhere(
    (item) => enumStorageValue(item) == normalized,
    orElse: () => fallback,
  );
}
