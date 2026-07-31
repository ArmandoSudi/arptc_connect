import '../../shared/domain/itsm_common.dart';

ItsmPublicationState publicationState(Object? value) {
  final normalized = value?.toString().trim().toLowerCase();
  return ItsmPublicationState.values.firstWhere(
    (state) => state.value == normalized,
    orElse: () => ItsmPublicationState.draft,
  );
}

class ConfigurationValidationIssue {
  const ConfigurationValidationIssue(this.code, this.message, {this.field});

  final String code;
  final String message;
  final String? field;
}

class ConfigurationValidationResult {
  ConfigurationValidationResult(Iterable<ConfigurationValidationIssue> issues)
      : issues = List<ConfigurationValidationIssue>.unmodifiable(issues);

  final List<ConfigurationValidationIssue> issues;
  bool get isValid => issues.isEmpty;
}

class ConfigurationVersionSummary {
  const ConfigurationVersionSummary({
    required this.id,
    required this.version,
    required this.state,
    required this.createdAt,
    required this.createdBy,
    this.publishedAt,
  });

  final String id;
  final int version;
  final ItsmPublicationState state;
  final DateTime createdAt;
  final String createdBy;
  final DateTime? publishedAt;

  bool get isImmutable => state != ItsmPublicationState.draft;
}

DateTime? configurationDate(Object? value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  try {
    final converted = (value as dynamic).toDate();
    return converted is DateTime ? converted : null;
  } on Object {
    return null;
  }
}

Map<String, Object?> configurationMap(Object? value) => value is Map
    ? value.map((key, item) => MapEntry(key.toString(), item))
    : const {};

List<Object?> configurationList(Object? value) =>
    value is Iterable ? value.toList(growable: false) : const [];

String configurationString(Object? value, [String fallback = '']) {
  final normalized = value?.toString().trim() ?? '';
  return normalized.isEmpty ? fallback : normalized;
}

int configurationInt(Object? value, [int fallback = 0]) => value is num
    ? value.toInt()
    : int.tryParse(configurationString(value)) ?? fallback;

double configurationDouble(Object? value, [double fallback = 0]) => value is num
    ? value.toDouble()
    : double.tryParse(configurationString(value)) ?? fallback;

bool configurationBool(Object? value, [bool fallback = false]) {
  if (value is bool) return value;
  return switch (configurationString(value).toLowerCase()) {
    'true' || '1' => true,
    'false' || '0' => false,
    _ => fallback,
  };
}
