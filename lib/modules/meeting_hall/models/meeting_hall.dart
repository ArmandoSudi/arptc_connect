import 'package:cloud_firestore/cloud_firestore.dart';

class MeetingHall {
  final String id;
  final String name;
  final String location;
  final int capacity;
  final String description;
  final DateTime? createdAt;
  final String? createdBy;

  MeetingHall({
    required this.id,
    required this.name,
    required this.location,
    required this.capacity,
    required this.description,
    this.createdAt,
    this.createdBy,
  });

  factory MeetingHall.fromJson(Map<String, dynamic> json) {
    return MeetingHall(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      capacity: _intFromJson(json['capacity']),
      description: json['description']?.toString() ?? '',
      createdAt:
          json['createdAt'] != null ? _dateFromJson(json['createdAt']) : null,
      createdBy: json['createdBy']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'location': location,
      'capacity': capacity,
      'description': description,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'createdBy': createdBy,
    };
  }

  MeetingHall copyWith({
    String? id,
    String? name,
    String? location,
    int? capacity,
    String? description,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return MeetingHall(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      capacity: capacity ?? this.capacity,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}

int _intFromJson(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _dateFromJson(dynamic value) {
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
