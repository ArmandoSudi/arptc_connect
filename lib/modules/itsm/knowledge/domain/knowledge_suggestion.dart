import 'dart:collection';

import 'knowledge_serialization.dart';

class KnowledgeSuggestionCriteria {
  KnowledgeSuggestionCriteria({
    Iterable<String> serviceIds = const [],
    Iterable<String> catalogueItemIds = const [],
    Iterable<String> incidentCategoryIds = const [],
    Iterable<String> keywords = const [],
  })  : serviceIds = _immutableIds(serviceIds),
        catalogueItemIds = _immutableIds(catalogueItemIds),
        incidentCategoryIds = _immutableIds(incidentCategoryIds),
        keywords = UnmodifiableListView(
          keywords
              .map(normalizeKnowledgeSearch)
              .where((value) => value.isNotEmpty)
              .toSet()
              .toList()
            ..sort(),
        );

  final List<String> serviceIds;
  final List<String> catalogueItemIds;
  final List<String> incidentCategoryIds;
  final List<String> keywords;

  factory KnowledgeSuggestionCriteria.fromMap(Map<String, dynamic> data) {
    return KnowledgeSuggestionCriteria(
      serviceIds: knowledgeStringList(data['serviceIds']),
      catalogueItemIds: knowledgeStringList(data['catalogueItemIds']),
      incidentCategoryIds: knowledgeStringList(data['incidentCategoryIds']),
      keywords: knowledgeStringList(data['keywords']),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'serviceIds': serviceIds,
        'catalogueItemIds': catalogueItemIds,
        'incidentCategoryIds': incidentCategoryIds,
        'keywords': keywords,
      };

  List<String> get indexKeys => List<String>.unmodifiable({
        ...serviceIds.map((id) => 'service:$id'),
        ...catalogueItemIds.map((id) => 'catalogue:$id'),
        ...incidentCategoryIds.map((id) => 'incident_category:$id'),
        ...keywords.map((keyword) => 'keyword:$keyword'),
      });

  int score(KnowledgeSuggestionContext context) {
    var score = 0;
    if (context.serviceId.isNotEmpty &&
        serviceIds.contains(context.serviceId)) {
      score += 8;
    }
    if (context.catalogueItemId.isNotEmpty &&
        catalogueItemIds.contains(context.catalogueItemId)) {
      score += 8;
    }
    if (context.incidentCategoryId.isNotEmpty &&
        incidentCategoryIds.contains(context.incidentCategoryId)) {
      score += 6;
    }
    final contextWords = normalizeKnowledgeSearch(context.text).split(' ');
    score += keywords.where(contextWords.contains).length * 2;
    return score;
  }
}

class KnowledgeSuggestionContext {
  const KnowledgeSuggestionContext({
    this.serviceId = '',
    this.catalogueItemId = '',
    this.incidentCategoryId = '',
    this.text = '',
  });

  final String serviceId;
  final String catalogueItemId;
  final String incidentCategoryId;
  final String text;

  List<String> get indexKeys {
    final keys = <String>[
      if (serviceId.trim().isNotEmpty) 'service:${serviceId.trim()}',
      if (catalogueItemId.trim().isNotEmpty)
        'catalogue:${catalogueItemId.trim()}',
      if (incidentCategoryId.trim().isNotEmpty)
        'incident_category:${incidentCategoryId.trim()}',
    ];
    final words = normalizeKnowledgeSearch(text)
        .split(' ')
        .where((word) => word.length >= 2);
    keys.addAll(words.map((word) => 'keyword:$word'));
    return List<String>.unmodifiable(keys.toSet());
  }
}

List<String> _immutableIds(Iterable<String> values) {
  final result = values
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
  return UnmodifiableListView(result);
}
