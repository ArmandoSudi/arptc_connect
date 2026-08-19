import 'package:cloud_firestore/cloud_firestore.dart';

enum OrganizationStatus {
  active('ACTIVE'),
  inactive('INACTIVE'),
  archived('ARCHIVED');

  const OrganizationStatus(this.value);

  final String value;

  static OrganizationStatus parse(Object? value) {
    final normalized = value?.toString().trim().toUpperCase();
    return OrganizationStatus.values.firstWhere(
      (status) => status.value == normalized,
      orElse: () => OrganizationStatus.active,
    );
  }
}

class Organization {
  const Organization({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.status,
    this.schemaVersion = 2,
    this.createdAt,
    this.createdBy = '',
    this.updatedAt,
    this.updatedBy = '',
    this.archivedAt,
    this.archivedBy,
  });

  final String id;
  final String code;
  final String name;
  final String description;
  final OrganizationStatus status;
  final int schemaVersion;
  final DateTime? createdAt;
  final String createdBy;
  final DateTime? updatedAt;
  final String updatedBy;
  final DateTime? archivedAt;
  final String? archivedBy;

  String get nameLower => name.trim().toLowerCase();
  bool get isActive => status == OrganizationStatus.active;

  factory Organization.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    return Organization(
      id: id,
      code: (map['code'] ?? '').toString().trim(),
      name: (map['name'] ?? '').toString().trim(),
      description: (map['description'] ?? '').toString().trim(),
      status: OrganizationStatus.parse(map['status']),
      schemaVersion: _integer(map['schemaVersion'], fallback: 2),
      createdAt: _dateTime(map['createdAt']),
      createdBy: (map['createdBy'] ?? '').toString().trim(),
      updatedAt: _dateTime(map['updatedAt']),
      updatedBy: (map['updatedBy'] ?? '').toString().trim(),
      archivedAt: _dateTime(map['archivedAt']),
      archivedBy: _nullableString(map['archivedBy']),
    );
  }

  Map<String, dynamic> toCommandPayload() => {
        'organizationId': id,
        'code': code.trim(),
        'name': name.trim(),
        'description': description.trim(),
      };
}

DateTime? organizationDateTime(Object? value) => _dateTime(value);

DateTime? _dateTime(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

String? _nullableString(Object? value) {
  final normalized = value?.toString().trim() ?? '';
  return normalized.isEmpty ? null : normalized;
}

int _integer(Object? value, {required int fallback}) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
