import 'package:cloud_firestore/cloud_firestore.dart';

import 'knowledge_serialization.dart';

class KnowledgeCategory {
  factory KnowledgeCategory({
    required String id,
    required String nameEn,
    required String nameFr,
    String descriptionEn = '',
    String descriptionFr = '',
    bool isActive = true,
    int sortOrder = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) {
      throw ArgumentError.value(id, 'id', 'A category ID is required.');
    }
    return KnowledgeCategory._(
      id: normalizedId,
      nameEn: nameEn.trim(),
      nameFr: nameFr.trim(),
      descriptionEn: descriptionEn.trim(),
      descriptionFr: descriptionFr.trim(),
      isActive: isActive,
      sortOrder: sortOrder,
      createdAt: createdAt?.toUtc(),
      updatedAt: updatedAt?.toUtc(),
    );
  }

  const KnowledgeCategory._({
    required this.id,
    required this.nameEn,
    required this.nameFr,
    required this.descriptionEn,
    required this.descriptionFr,
    required this.isActive,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String nameEn;
  final String nameFr;
  final String descriptionEn;
  final String descriptionFr;
  final bool isActive;
  final int sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String localizedName(String languageCode) {
    return languageCode.toLowerCase().startsWith('fr') && nameFr.isNotEmpty
        ? nameFr
        : nameEn;
  }

  String localizedDescription(String languageCode) {
    return languageCode.toLowerCase().startsWith('fr') &&
            descriptionFr.isNotEmpty
        ? descriptionFr
        : descriptionEn;
  }

  factory KnowledgeCategory.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return KnowledgeCategory.fromMap(
      id: snapshot.id,
      data: snapshot.data() ?? const {},
    );
  }

  factory KnowledgeCategory.fromMap({
    required String id,
    required Map<String, dynamic> data,
  }) {
    return KnowledgeCategory(
      id: id,
      nameEn: knowledgeString(data, 'nameEn'),
      nameFr: knowledgeString(data, 'nameFr'),
      descriptionEn: knowledgeString(data, 'descriptionEn'),
      descriptionFr: knowledgeString(data, 'descriptionFr'),
      isActive: knowledgeBool(data, 'isActive', fallback: true),
      sortOrder: knowledgeInt(data, 'sortOrder'),
      createdAt: knowledgeDate(data['createdAt']),
      updatedAt: knowledgeDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'nameEn': nameEn,
        'nameFr': nameFr,
        'descriptionEn': descriptionEn,
        'descriptionFr': descriptionFr,
        'isActive': isActive,
        'sortOrder': sortOrder,
        'createdAt': knowledgeTimestamp(createdAt),
        'updatedAt': knowledgeTimestamp(updatedAt),
      };
}
