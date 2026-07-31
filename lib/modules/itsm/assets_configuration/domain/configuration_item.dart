import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'assets_configuration_serialization.dart';

enum ConfigurationItemType {
  service,
  application,
  server,
  networkDevice,
  endUserDevice,
  database,
  cloudResource,
  other;

  String get value => switch (this) {
        ConfigurationItemType.networkDevice => 'network_device',
        ConfigurationItemType.endUserDevice => 'end_user_device',
        ConfigurationItemType.cloudResource => 'cloud_resource',
        _ => name,
      };

  static ConfigurationItemType fromValue(Object? value) => values.firstWhere(
        (type) => type.value == value?.toString().toLowerCase(),
        orElse: () => ConfigurationItemType.other,
      );
}

enum CiCriticality { low, medium, high, critical }

enum CiOperationalStatus {
  planned,
  operational,
  degraded,
  unavailable,
  maintenance,
  retired;
}

enum CiDataQualityStatus { verified, incomplete, stale, disputed }

enum CiRelationshipType {
  dependsOn,
  runsOn,
  connectedTo,
  uses,
  representedBy,
  hosts,
  supports,
  memberOf;

  String get value => switch (this) {
        CiRelationshipType.dependsOn => 'depends_on',
        CiRelationshipType.runsOn => 'runs_on',
        CiRelationshipType.connectedTo => 'connected_to',
        CiRelationshipType.representedBy => 'represented_by',
        CiRelationshipType.memberOf => 'member_of',
        _ => name,
      };

  static CiRelationshipType fromValue(Object? value) => values.firstWhere(
        (type) => type.value == value?.toString().toLowerCase(),
        orElse: () => CiRelationshipType.dependsOn,
      );
}

class ConfigurationItem {
  ConfigurationItem({
    required String id,
    required String name,
    required this.type,
    required this.criticality,
    required this.operationalStatus,
    required this.dataQualityStatus,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.description = '',
    this.ownerUserId = '',
    this.ownerName = '',
    this.supportGroupId = '',
    this.supportGroupName = '',
    this.linkedAssetId = '',
    this.linkedAssetTag = '',
    this.configurationBaselineVersion = '',
    Map<String, Object?> configurationAttributes = const {},
    Iterable<String> relatedIncidentIds = const [],
    Iterable<String> relatedRequestIds = const [],
    Iterable<String> relatedChangeIds = const [],
    Iterable<String> relatedFindingIds = const [],
  })  : id = requireItsmAssetText(id, 'id'),
        name = requireItsmAssetText(name, 'name'),
        createdAt = createdAt.toUtc(),
        updatedAt = updatedAt.toUtc(),
        configurationAttributes = UnmodifiableMapView(
          Map<String, Object?>.from(configurationAttributes),
        ),
        relatedIncidentIds = immutableItsmAssetIds(relatedIncidentIds),
        relatedRequestIds = immutableItsmAssetIds(relatedRequestIds),
        relatedChangeIds = immutableItsmAssetIds(relatedChangeIds),
        relatedFindingIds = immutableItsmAssetIds(relatedFindingIds);

  final String id;
  final String name;
  final String description;
  final ConfigurationItemType type;
  final String ownerUserId;
  final String ownerName;
  final String supportGroupId;
  final String supportGroupName;
  final CiCriticality criticality;
  final CiOperationalStatus operationalStatus;
  final String linkedAssetId;
  final String linkedAssetTag;
  final String configurationBaselineVersion;
  final Map<String, Object?> configurationAttributes;
  final CiDataQualityStatus dataQualityStatus;
  final List<String> relatedIncidentIds;
  final List<String> relatedRequestIds;
  final List<String> relatedChangeIds;
  final List<String> relatedFindingIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ConfigurationItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) =>
      ConfigurationItem.fromMap(snapshot.id, snapshot.data() ?? const {});

  factory ConfigurationItem.fromMap(
    String id,
    Map<String, Object?> data,
  ) =>
      ConfigurationItem(
        id: id,
        name: itsmAssetString(data, 'name'),
        description: itsmAssetString(data, 'description'),
        type: ConfigurationItemType.fromValue(data['ciType'] ?? data['type']),
        ownerUserId: itsmAssetString(data, 'ownerUserId'),
        ownerName: itsmAssetString(data, 'ownerName'),
        supportGroupId: itsmAssetString(data, 'supportGroupId'),
        supportGroupName: itsmAssetString(data, 'supportGroupName'),
        criticality: CiCriticality.values.firstWhere(
          (value) => value.name == data['criticality']?.toString(),
          orElse: () => CiCriticality.medium,
        ),
        operationalStatus: data['operationalStatus']?.toString() == 'active'
            ? CiOperationalStatus.operational
            : CiOperationalStatus.values.firstWhere(
                (value) => value.name == data['operationalStatus']?.toString(),
                orElse: () => CiOperationalStatus.planned,
              ),
        linkedAssetId: itsmAssetString(data, 'linkedAssetId'),
        linkedAssetTag: itsmAssetString(data, 'linkedAssetTag'),
        configurationBaselineVersion: itsmAssetString(
          itsmAssetMap(data['configurationBaseline']),
          'version',
        ).isNotEmpty
            ? itsmAssetString(
                itsmAssetMap(data['configurationBaseline']),
                'version',
              )
            : itsmAssetString(data, 'configurationBaselineVersion'),
        configurationAttributes: itsmAssetMap(
          data['configurationAttributes'] ?? data['configurationBaseline'],
        ),
        dataQualityStatus: CiDataQualityStatus.values.firstWhere(
          (value) => value.name == data['dataQualityStatus']?.toString(),
          orElse: () => CiDataQualityStatus.incomplete,
        ),
        relatedIncidentIds: itsmAssetStrings(data['relatedIncidentIds']),
        relatedRequestIds: itsmAssetStrings(data['relatedRequestIds']),
        relatedChangeIds: itsmAssetStrings(data['relatedChangeIds']),
        relatedFindingIds: itsmAssetStrings(data['relatedFindingIds']),
        createdAt: itsmAssetDate(data['createdAt']) ?? DateTime.utc(1970),
        updatedAt: itsmAssetDate(data['updatedAt']) ?? DateTime.utc(1970),
      );

  Map<String, Object?> toFirestore() => {
        'name': name,
        'description': description,
        'ciType': type.value,
        'ownerUserId': ownerUserId,
        'ownerName': ownerName,
        'supportGroupId': supportGroupId,
        'supportGroupName': supportGroupName,
        'criticality': criticality.name,
        'operationalStatus': operationalStatus.name,
        'linkedAssetId': linkedAssetId,
        'linkedAssetTag': linkedAssetTag,
        'configurationBaseline': {
          ...configurationAttributes,
          'version': configurationBaselineVersion,
        },
        'dataQualityStatus': dataQualityStatus.name,
        'relatedIncidentIds': relatedIncidentIds,
        'relatedRequestIds': relatedRequestIds,
        'relatedChangeIds': relatedChangeIds,
        'relatedFindingIds': relatedFindingIds,
        'createdAt': itsmAssetTimestamp(createdAt),
        'updatedAt': itsmAssetTimestamp(updatedAt),
      };
}

class CiRelationship {
  CiRelationship({
    required String id,
    required String sourceCiId,
    required String sourceCiName,
    required String targetCiId,
    required String targetCiName,
    required this.type,
    required DateTime createdAt,
    required String createdByUserId,
    this.description = '',
  })  : id = requireItsmAssetText(id, 'id'),
        sourceCiId = requireItsmAssetText(sourceCiId, 'sourceCiId'),
        sourceCiName = sourceCiName.trim(),
        targetCiId = requireItsmAssetText(targetCiId, 'targetCiId'),
        targetCiName = targetCiName.trim(),
        createdAt = createdAt.toUtc(),
        createdByUserId = requireItsmAssetText(
          createdByUserId,
          'createdByUserId',
        ) {
    if (sourceCiId == targetCiId) {
      throw ArgumentError('A CI cannot relate to itself.');
    }
  }

  final String id;
  final String sourceCiId;
  final String sourceCiName;
  final String targetCiId;
  final String targetCiName;
  final CiRelationshipType type;
  final String description;
  final DateTime createdAt;
  final String createdByUserId;

  bool pointsFrom(String ciId) => sourceCiId == ciId.trim();
  bool pointsTo(String ciId) => targetCiId == ciId.trim();
  bool involves(String ciId) => pointsFrom(ciId) || pointsTo(ciId);

  factory CiRelationship.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) =>
      CiRelationship.fromMap(snapshot.id, snapshot.data() ?? const {});

  factory CiRelationship.fromMap(
    String id,
    Map<String, Object?> data,
  ) =>
      CiRelationship(
        id: id,
        sourceCiId: itsmAssetString(data, 'sourceEntityId').isNotEmpty
            ? itsmAssetString(data, 'sourceEntityId')
            : itsmAssetString(data, 'sourceCiId'),
        sourceCiName: itsmAssetString(data, 'sourceCiName'),
        targetCiId: itsmAssetString(data, 'targetEntityId').isNotEmpty
            ? itsmAssetString(data, 'targetEntityId')
            : itsmAssetString(data, 'targetCiId'),
        targetCiName: itsmAssetString(data, 'targetCiName'),
        type: CiRelationshipType.fromValue(
          data['relationshipType'] ?? data['type'],
        ),
        description: itsmAssetString(data, 'description'),
        createdAt: itsmAssetDate(data['createdAt']) ?? DateTime.utc(1970),
        createdByUserId: itsmAssetString(data, 'createdBy').isNotEmpty
            ? itsmAssetString(data, 'createdBy')
            : itsmAssetString(data, 'createdByUserId'),
      );

  Map<String, Object?> toFirestore() => {
        'sourceEntityType': 'configuration_item',
        'sourceEntityId': sourceCiId,
        'sourceCiName': sourceCiName,
        'targetEntityType': 'configuration_item',
        'targetEntityId': targetCiId,
        'targetCiName': targetCiName,
        'relationshipType': type.value,
        'description': description,
        'createdAt': itsmAssetTimestamp(createdAt),
        'createdBy': createdByUserId,
      };
}

class CiRelationshipGraph {
  CiRelationshipGraph(Iterable<CiRelationship> relationships)
      : relationships = List.unmodifiable(relationships);

  final List<CiRelationship> relationships;

  List<CiRelationship> outgoing(String ciId) => List.unmodifiable(
        relationships.where((relationship) => relationship.pointsFrom(ciId)),
      );

  List<CiRelationship> incoming(String ciId) => List.unmodifiable(
        relationships.where((relationship) => relationship.pointsTo(ciId)),
      );

  Set<String> directDependencies(String ciId) => outgoing(ciId)
      .where((relationship) =>
          relationship.type == CiRelationshipType.dependsOn ||
          relationship.type == CiRelationshipType.runsOn)
      .map((relationship) => relationship.targetCiId)
      .toSet();

  Set<String> directDependents(String ciId) => incoming(ciId)
      .where((relationship) =>
          relationship.type == CiRelationshipType.dependsOn ||
          relationship.type == CiRelationshipType.runsOn)
      .map((relationship) => relationship.sourceCiId)
      .toSet();
}
