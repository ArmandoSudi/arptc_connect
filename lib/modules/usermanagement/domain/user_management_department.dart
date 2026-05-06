import 'package:cloud_firestore/cloud_firestore.dart';

class UserManagementDepartment {
  final String id;
  final String code;
  final String name;
  final String nameLower;
  final String? headUserId;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserManagementDepartment({
    required this.id,
    required this.code,
    required this.name,
    required this.nameLower,
    this.headUserId,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory UserManagementDepartment.fromMap(Map<String, dynamic> map,
      {required String id}) {
    return UserManagementDepartment(
      id: id,
      code: (map['code'] as String?)?.trim() ?? '',
      name: (map['name'] as String?)?.trim() ?? '',
      nameLower: (map['nameLower'] as String?)?.trim() ??
          ((map['name'] as String?)?.trim().toLowerCase() ?? ''),
      headUserId: (map['headUserId'] as String?)?.trim(),
      isActive: map['isActive'] as bool? ?? true,
      createdAt: _toDateTime(map['createdAt']),
      updatedAt: _toDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    final now = Timestamp.now();

    return {
      'code': code.trim(),
      'name': name.trim(),
      'nameLower': name.trim().toLowerCase(),
      'headUserId': headUserId,
      'isActive': isActive,
      'createdAt': createdAt == null ? now : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null ? now : Timestamp.fromDate(updatedAt!),
    };
  }
}

DateTime? _toDateTime(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  return null;
}
