import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_model_helpers.dart';

class ItService {
  const ItService({
    required this.id,
    required this.name,
    required this.nameLower,
    required this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String nameLower;
  final String description;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ItService.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    return ItService(
      id: snapshot.id,
      name: stringFromFirestore(data, 'name'),
      nameLower: stringFromFirestore(data, 'nameLower'),
      description: stringFromFirestore(data, 'description'),
      isActive: data.containsKey('isActive')
          ? boolFromFirestore(data, 'isActive')
          : true,
      createdAt: dateTimeFromFirestore(data['createdAt']),
      updatedAt: dateTimeFromFirestore(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name.trim(),
      'nameLower': name.trim().toLowerCase(),
      'description': description.trim(),
      'isActive': isActive,
      'createdAt': dateTimeToFirestore(createdAt),
      'updatedAt': dateTimeToFirestore(updatedAt),
    };
  }
}
