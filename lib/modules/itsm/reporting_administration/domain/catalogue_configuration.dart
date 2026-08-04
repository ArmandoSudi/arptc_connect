import 'dart:collection';

import '../../shared/domain/itsm_common.dart';
import 'configuration_common.dart';

class CatalogueItemConfiguration {
  CatalogueItemConfiguration({
    required this.id,
    required this.code,
    required this.name,
    required this.categoryId,
    required this.status,
    required this.latestVersion,
    required this.updatedAt,
    this.currentPublishedVersion,
    this.currentDraftVersion,
    this.currentDraftVersionDocumentId,
    this.currentPublishedVersionDocumentId,
    this.revision = 0,
  });

  final String id;
  final String code;
  final Map<String, String> name;
  final String categoryId;
  final ItsmPublicationState status;
  final int latestVersion;
  final int? currentPublishedVersion;
  final int? currentDraftVersion;
  final String? currentDraftVersionDocumentId;
  final String? currentPublishedVersionDocumentId;
  final int revision;
  final DateTime updatedAt;

  String label(String languageCode) =>
      name[languageCode] ?? name['en'] ?? name['fr'] ?? code;

  factory CatalogueItemConfiguration.fromMap(
          String id, Map<String, Object?> map) =>
      CatalogueItemConfiguration(
        id: id,
        code: configurationString(map['code'], id),
        name: _localized(map['name']),
        categoryId: configurationString(map['categoryId']),
        status: publicationState(map['status']),
        latestVersion:
            configurationInt(map['latestVersion'] ?? map['version'], 1),
        currentPublishedVersion: map['currentPublishedVersion'] == null
            ? null
            : configurationInt(map['currentPublishedVersion']),
        currentDraftVersion: map['currentDraftVersion'] == null
            ? null
            : configurationInt(map['currentDraftVersion']),
        currentDraftVersionDocumentId: _nullable(
          map['currentDraftVersionDocumentId'],
        ),
        currentPublishedVersionDocumentId: _nullable(
          map['currentPublishedVersionDocumentId'],
        ),
        revision: configurationInt(map['revision']),
        updatedAt: configurationDate(map['updatedAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );
}

class CatalogueItemVersionConfiguration {
  CatalogueItemVersionConfiguration({
    required this.itemId,
    required this.versionId,
    required this.version,
    required this.state,
    required Map<String, String> name,
    required Map<String, String> description,
    required this.categoryId,
    required this.workflowId,
    required this.workflowVersion,
    required this.slaPolicyId,
    required this.slaPolicyVersion,
    required Iterable<ItsmRole> visibleRoles,
    required Iterable<String> fieldKeys,
    required Iterable<String> requiredDocumentKeys,
    required this.createdAt,
    required this.createdBy,
    this.fulfilmentGroupId,
    this.activeFrom,
    this.activeUntil,
    this.publishedAt,
    this.revision = 0,
    Map<String, Object?> definition = const {},
  })  : name = UnmodifiableMapView(Map<String, String>.from(name)),
        description =
            UnmodifiableMapView(Map<String, String>.from(description)),
        visibleRoles = Set<ItsmRole>.unmodifiable(visibleRoles),
        fieldKeys = List<String>.unmodifiable(fieldKeys),
        requiredDocumentKeys = List<String>.unmodifiable(requiredDocumentKeys),
        definition = UnmodifiableMapView(Map<String, Object?>.from(definition));

  final String itemId;
  final String versionId;
  final int version;
  final ItsmPublicationState state;
  final Map<String, String> name;
  final Map<String, String> description;
  final String categoryId;
  final String workflowId;
  final int workflowVersion;
  final String slaPolicyId;
  final int slaPolicyVersion;
  final String? fulfilmentGroupId;
  final Set<ItsmRole> visibleRoles;
  final List<String> fieldKeys;
  final List<String> requiredDocumentKeys;
  final DateTime? activeFrom;
  final DateTime? activeUntil;
  final DateTime createdAt;
  final String createdBy;
  final DateTime? publishedAt;
  final int revision;
  final Map<String, Object?> definition;

  bool get isImmutable => state != ItsmPublicationState.draft;

  ConfigurationValidationResult validateForPublication({
    bool workflowVersionPublished = true,
    bool slaVersionPublished = true,
    bool fulfilmentGroupExists = true,
  }) {
    final issues = <ConfigurationValidationIssue>[];
    for (final language in const ['en', 'fr']) {
      if ((name[language] ?? '').trim().isEmpty) {
        issues.add(ConfigurationValidationIssue(
            'name_$language', 'A $language name is required.',
            field: 'name.$language'));
      }
      if ((description[language] ?? '').trim().isEmpty) {
        issues.add(ConfigurationValidationIssue(
            'description_$language', 'A $language description is required.',
            field: 'description.$language'));
      }
    }
    if (visibleRoles.isEmpty) {
      issues.add(const ConfigurationValidationIssue(
          'visible_roles', 'At least one visible role is required.'));
    }
    if (fieldKeys.toSet().length != fieldKeys.length) {
      issues.add(const ConfigurationValidationIssue(
          'duplicate_fields', 'Dynamic field keys must be unique.'));
    }
    if (requiredDocumentKeys.toSet().length != requiredDocumentKeys.length) {
      issues.add(const ConfigurationValidationIssue(
          'duplicate_documents', 'Required document keys must be unique.'));
    }
    if (!workflowVersionPublished ||
        workflowId.isEmpty ||
        workflowVersion < 1) {
      issues.add(const ConfigurationValidationIssue(
          'workflow_reference', 'A published workflow version is required.'));
    }
    if (!slaVersionPublished || slaPolicyId.isEmpty || slaPolicyVersion < 1) {
      issues.add(const ConfigurationValidationIssue(
          'sla_reference', 'A published SLA version is required.'));
    }
    if (fulfilmentGroupId != null && !fulfilmentGroupExists) {
      issues.add(const ConfigurationValidationIssue(
          'fulfilment_group', 'The fulfilment group does not exist.'));
    }
    if (activeFrom != null &&
        activeUntil != null &&
        activeFrom!.isAfter(activeUntil!)) {
      issues.add(const ConfigurationValidationIssue(
          'active_dates', 'Active start cannot follow active end.'));
    }
    return ConfigurationValidationResult(issues);
  }

  factory CatalogueItemVersionConfiguration.fromMap(
    String itemId,
    String versionId,
    Map<String, Object?> map,
  ) {
    final nestedDefinition = configurationMap(map['definition']);
    final definition = nestedDefinition.isEmpty ? map : nestedDefinition;
    final workflow = configurationMap(definition['workflow']);
    final sla = configurationMap(definition['slaPolicy']);
    return CatalogueItemVersionConfiguration(
      itemId: itemId,
      versionId: versionId,
      version: configurationInt(map['version'], 1),
      state: publicationState(map['status'] ?? map['state']),
      name: _localized(definition['name']),
      description: _localized(definition['description']),
      categoryId: configurationString(definition['categoryId']),
      workflowId: configurationString(
        workflow['definitionId'] ?? workflow['id'] ?? definition['workflowId'],
      ),
      workflowVersion: configurationInt(
          workflow['version'] ?? definition['workflowVersion']),
      slaPolicyId: configurationString(
        sla['definitionId'] ?? sla['id'] ?? definition['slaPolicyId'],
      ),
      slaPolicyVersion:
          configurationInt(sla['version'] ?? definition['slaPolicyVersion']),
      fulfilmentGroupId: _nullable(definition['fulfilmentGroupId']),
      visibleRoles: configurationList(definition['visibleRoles'])
          .map(ItsmRole.tryParse)
          .whereType<ItsmRole>(),
      fieldKeys: configurationList(definition['formFields'])
          .map(configurationMap)
          .map((field) => configurationString(field['key']))
          .where((key) => key.isNotEmpty),
      requiredDocumentKeys: configurationList(definition['requiredDocuments'])
          .map(configurationMap)
          .map((document) => configurationString(document['key']))
          .where((key) => key.isNotEmpty),
      activeFrom: configurationDate(definition['activeFrom']),
      activeUntil: configurationDate(definition['activeUntil']),
      createdAt: configurationDate(map['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      createdBy: configurationString(map['createdBy'], 'unknown'),
      publishedAt: configurationDate(map['publishedAt']),
      revision: configurationInt(map['revision']),
      definition: Map<String, Object?>.from(definition),
    );
  }
}

Map<String, String> _localized(Object? value) => {
      for (final entry in configurationMap(value).entries)
        entry.key: configurationString(entry.value),
    };
String? _nullable(Object? value) {
  final result = configurationString(value);
  return result.isEmpty ? null : result;
}
