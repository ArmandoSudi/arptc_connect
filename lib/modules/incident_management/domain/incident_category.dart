import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_model_helpers.dart';

class IncidentCategory {
  const IncidentCategory({
    required this.id,
    required this.name,
    required this.nameLower,
    required this.subcategories,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String nameLower;
  final List<String> subcategories;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory IncidentCategory.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    final rawSubcategories =
        data['subcategories'] as List<dynamic>? ?? const [];
    return IncidentCategory(
      id: snapshot.id,
      name: stringFromFirestore(data, 'name'),
      nameLower: stringFromFirestore(data, 'nameLower'),
      subcategories: rawSubcategories
          .map((subcategory) => subcategory.toString().trim())
          .where((subcategory) => subcategory.isNotEmpty)
          .toList(),
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
      'subcategories': subcategories
          .map((subcategory) => subcategory.trim())
          .where((subcategory) => subcategory.isNotEmpty)
          .toList(),
      'isActive': isActive,
      'createdAt': dateTimeToFirestore(createdAt),
      'updatedAt': dateTimeToFirestore(updatedAt),
    };
  }
}
