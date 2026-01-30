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
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String,
      capacity: json['capacity'] as int,
      description: json['description'] as String,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : null,
      createdBy: json['createdBy'] as String?,
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
