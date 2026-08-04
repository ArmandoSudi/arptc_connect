import '../../shared/domain/itsm_common.dart';
import 'localized_value.dart';
import 'support_serialization.dart';

enum CatalogueFieldType {
  shortText('short_text'),
  longText('long_text'),
  integer('integer'),
  decimal('decimal'),
  email('email'),
  phone('phone'),
  boolean('boolean'),
  date('date'),
  dateTime('date_time'),
  singleSelect('single_select'),
  multiSelect('multi_select'),
  user('user'),
  asset('asset'),
  attachment('attachment');

  const CatalogueFieldType(this.value);

  final String value;

  static CatalogueFieldType fromValue(Object? value) {
    final normalized = supportString(value)
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
    return values.firstWhere(
      (type) => type.value == normalized,
      orElse: () => CatalogueFieldType.shortText,
    );
  }
}

class CatalogueFieldOption {
  CatalogueFieldOption({
    required this.value,
    required this.label,
  }) {
    supportRequire(value, 'value');
  }

  factory CatalogueFieldOption.fromMap(Map<String, Object?> map) {
    return CatalogueFieldOption(
      value: supportString(map['value']),
      label: LocalizedValue.fromValue(map['label']),
    );
  }

  final String value;
  final LocalizedValue label;

  Map<String, Object?> toFirestore() => {
        'value': value.trim(),
        'label': label.toFirestore(),
      };
}

class CatalogueFieldDependency {
  CatalogueFieldDependency({
    required this.fieldKey,
    required this.acceptedValues,
  }) {
    supportRequire(fieldKey, 'fieldKey');
    if (acceptedValues.isEmpty) {
      throw ArgumentError('A field dependency requires an accepted value.');
    }
  }

  factory CatalogueFieldDependency.fromMap(Map<String, Object?> map) {
    return CatalogueFieldDependency(
      fieldKey: supportString(map['fieldKey']),
      acceptedValues: supportStringList(map['acceptedValues']).toSet(),
    );
  }

  final String fieldKey;
  final Set<String> acceptedValues;

  Map<String, Object?> toFirestore() => {
        'fieldKey': fieldKey.trim(),
        'acceptedValues': acceptedValues.toList(growable: false),
      };
}

class CatalogueFieldSchema {
  CatalogueFieldSchema({
    required this.key,
    required this.type,
    required this.label,
    this.helpText,
    this.required = false,
    this.sensitive = false,
    this.defaultValue,
    this.minimumLength,
    this.maximumLength,
    this.minimumValue,
    this.maximumValue,
    this.validationPattern,
    this.dependency,
    Iterable<CatalogueFieldOption> options = const [],
  }) : options = List<CatalogueFieldOption>.unmodifiable(options) {
    supportRequire(key, 'key');
    if (minimumLength != null && minimumLength! < 0) {
      throw RangeError.value(minimumLength!, 'minimumLength');
    }
    if (maximumLength != null && maximumLength! < 1) {
      throw RangeError.value(maximumLength!, 'maximumLength');
    }
    if (minimumLength != null &&
        maximumLength != null &&
        minimumLength! > maximumLength!) {
      throw ArgumentError('minimumLength cannot exceed maximumLength.');
    }
    if (minimumValue != null &&
        maximumValue != null &&
        minimumValue! > maximumValue!) {
      throw ArgumentError('minimumValue cannot exceed maximumValue.');
    }
    final needsOptions = type == CatalogueFieldType.singleSelect ||
        type == CatalogueFieldType.multiSelect;
    if (needsOptions && this.options.isEmpty) {
      throw ArgumentError('Select fields require at least one option.');
    }
    final optionValues = this.options.map((option) => option.value).toSet();
    if (optionValues.length != this.options.length) {
      throw ArgumentError('Field option values must be unique.');
    }
  }

  factory CatalogueFieldSchema.fromMap(Map<String, Object?> map) {
    return CatalogueFieldSchema(
      key: supportString(map['key']),
      type: CatalogueFieldType.fromValue(map['type']),
      label: LocalizedValue.fromValue(map['label']),
      helpText: supportMapFromValue(map['helpText']).isEmpty &&
              supportString(map['helpText']).isEmpty
          ? null
          : LocalizedValue.fromValue(map['helpText']),
      required: supportBool(map['required']),
      sensitive: supportBool(map['sensitive']),
      defaultValue: map['defaultValue'],
      minimumLength: map['minimumLength'] == null
          ? null
          : supportInt(map['minimumLength']),
      maximumLength: map['maximumLength'] == null
          ? null
          : supportInt(map['maximumLength']),
      minimumValue: supportNullableDouble(map['minimumValue']),
      maximumValue: supportNullableDouble(map['maximumValue']),
      validationPattern: supportNullableString(map['validationPattern']),
      dependency: supportMapFromValue(map['dependency']).isEmpty
          ? null
          : CatalogueFieldDependency.fromMap(
              supportMapFromValue(map['dependency']),
            ),
      options: supportListFromValue(map['options'])
          .map(supportMapFromValue)
          .where((option) => option.isNotEmpty)
          .map(CatalogueFieldOption.fromMap),
    );
  }

  final String key;
  final CatalogueFieldType type;
  final LocalizedValue label;
  final LocalizedValue? helpText;
  final bool required;
  final bool sensitive;
  final Object? defaultValue;
  final int? minimumLength;
  final int? maximumLength;
  final double? minimumValue;
  final double? maximumValue;
  final String? validationPattern;
  final CatalogueFieldDependency? dependency;
  final List<CatalogueFieldOption> options;

  Map<String, Object?> toFirestore() => {
        'key': key.trim(),
        'type': type.value,
        'label': label.toFirestore(),
        if (helpText != null) 'helpText': helpText!.toFirestore(),
        'required': required,
        'sensitive': sensitive,
        if (defaultValue != null) 'defaultValue': defaultValue,
        if (minimumLength != null) 'minimumLength': minimumLength,
        if (maximumLength != null) 'maximumLength': maximumLength,
        if (minimumValue != null) 'minimumValue': minimumValue,
        if (maximumValue != null) 'maximumValue': maximumValue,
        if (validationPattern != null)
          'validationPattern': validationPattern!.trim(),
        if (dependency != null) 'dependency': dependency!.toFirestore(),
        'options': options
            .map((option) => option.toFirestore())
            .toList(growable: false),
      };
}

class CatalogueRequiredDocument {
  CatalogueRequiredDocument({
    required this.key,
    required this.label,
    this.description,
    this.required = true,
    this.maximumFiles = 1,
    Iterable<String> allowedContentTypes = const [],
  }) : allowedContentTypes = Set<String>.unmodifiable(
          allowedContentTypes
              .map((type) => type.trim().toLowerCase())
              .where((type) => type.isNotEmpty),
        ) {
    supportRequire(key, 'key');
    if (maximumFiles < 1 || maximumFiles > 20) {
      throw RangeError.range(maximumFiles, 1, 20, 'maximumFiles');
    }
  }

  factory CatalogueRequiredDocument.fromMap(Map<String, Object?> map) {
    return CatalogueRequiredDocument(
      key: supportString(map['key']),
      label: LocalizedValue.fromValue(map['label']),
      description: supportString(map['description']).isEmpty
          ? null
          : LocalizedValue.fromValue(map['description']),
      required: supportBool(map['required'], true),
      maximumFiles: supportInt(map['maximumFiles'], 1),
      allowedContentTypes: supportStringList(map['allowedContentTypes']),
    );
  }

  final String key;
  final LocalizedValue label;
  final LocalizedValue? description;
  final bool required;
  final int maximumFiles;
  final Set<String> allowedContentTypes;

  Map<String, Object?> toFirestore() => {
        'key': key.trim(),
        'label': label.toFirestore(),
        if (description != null) 'description': description!.toFirestore(),
        'required': required,
        'maximumFiles': maximumFiles,
        'allowedContentTypes': allowedContentTypes.toList(growable: false),
      };
}

class CatalogueEligibility {
  CatalogueEligibility({
    this.allEmployees = true,
    Iterable<String> userIds = const [],
    Iterable<String> departmentIds = const [],
    Iterable<String> serviceIds = const [],
    Iterable<String> locationIds = const [],
    Iterable<String> positionValues = const [],
    Iterable<String> excludedUserIds = const [],
  })  : userIds = _normalizedSet(userIds),
        departmentIds = _normalizedSet(departmentIds),
        serviceIds = _normalizedSet(serviceIds),
        locationIds = _normalizedSet(locationIds),
        positionValues = _normalizedSet(positionValues),
        excludedUserIds = _normalizedSet(excludedUserIds) {
    if (!allEmployees &&
        this.userIds.isEmpty &&
        this.departmentIds.isEmpty &&
        this.serviceIds.isEmpty &&
        this.locationIds.isEmpty &&
        this.positionValues.isEmpty) {
      throw ArgumentError(
        'Restricted eligibility needs a user, department, service, location, '
        'or organisation position.',
      );
    }
  }

  factory CatalogueEligibility.fromMap(Map<String, Object?> map) {
    return CatalogueEligibility(
      allEmployees: supportBool(map['allEmployees'], true),
      userIds: supportStringList(map['userIds']),
      departmentIds: supportStringList(map['departmentIds']),
      serviceIds: supportStringList(map['serviceIds']),
      locationIds: supportStringList(map['locationIds']),
      positionValues: supportStringList(map['positionValues']),
      excludedUserIds: supportStringList(map['excludedUserIds']),
    );
  }

  final bool allEmployees;
  final Set<String> userIds;
  final Set<String> departmentIds;
  final Set<String> serviceIds;
  final Set<String> locationIds;
  final Set<String> positionValues;
  final Set<String> excludedUserIds;

  bool allows(CataloguePrincipal principal) {
    if (excludedUserIds.contains(principal.userId)) return false;
    if (allEmployees) return true;
    return userIds.contains(principal.userId) ||
        (principal.departmentId != null &&
            departmentIds.contains(principal.departmentId)) ||
        (principal.serviceId != null &&
            serviceIds.contains(principal.serviceId)) ||
        (principal.locationId != null &&
            locationIds.contains(principal.locationId)) ||
        (principal.positionValue != null &&
            positionValues.contains(principal.positionValue));
  }

  Map<String, Object?> toFirestore() => {
        'allEmployees': allEmployees,
        'userIds': userIds.toList(growable: false),
        'departmentIds': departmentIds.toList(growable: false),
        'serviceIds': serviceIds.toList(growable: false),
        'locationIds': locationIds.toList(growable: false),
        'positionValues': positionValues.toList(growable: false),
        'excludedUserIds': excludedUserIds.toList(growable: false),
      };
}

class CataloguePrincipal {
  CataloguePrincipal({
    required this.userId,
    required this.role,
    this.departmentId,
    this.serviceId,
    this.locationId,
    this.positionValue,
  }) {
    supportRequire(userId, 'userId');
  }

  final String userId;
  final ItsmRole role;
  final String? departmentId;
  final String? serviceId;
  final String? locationId;
  final String? positionValue;
}

/// Identifies the accountable business or technical owner of a catalogue
/// service. The optional user ID can later be used for escalations while the
/// display name remains useful when the owner is an external team.
class CatalogueServiceOwner {
  CatalogueServiceOwner({
    required this.displayName,
    this.userId,
    this.teamName,
  }) {
    supportRequire(displayName, 'displayName');
  }

  factory CatalogueServiceOwner.fromMap(Map<String, Object?> map) {
    return CatalogueServiceOwner(
      displayName: supportString(map['displayName'] ?? map['name']),
      userId: supportNullableString(map['userId']),
      teamName: supportNullableString(map['teamName']),
    );
  }

  final String displayName;
  final String? userId;
  final String? teamName;

  Map<String, Object?> toFirestore() => {
        'displayName': displayName.trim(),
        if (userId != null) 'userId': userId!.trim(),
        if (teamName != null) 'teamName': teamName!.trim(),
      };
}

/// A CMDB reference deliberately keeps only an identifier and a display name.
/// Self-service users are not given the linked CI records themselves.
class CatalogueConfigurationItemReference {
  CatalogueConfigurationItemReference({
    required this.id,
    required this.name,
  }) {
    supportRequire(id, 'id');
    supportRequire(name, 'name');
  }

  factory CatalogueConfigurationItemReference.fromMap(
    Map<String, Object?> map,
  ) {
    return CatalogueConfigurationItemReference(
      id: supportString(map['id']),
      name: supportString(map['name']),
    );
  }

  final String id;
  final String name;

  Map<String, Object?> toFirestore() => {
        'id': id.trim(),
        'name': name.trim(),
      };
}

class VersionedConfigurationReference {
  VersionedConfigurationReference({
    required this.id,
    required this.version,
  }) {
    supportRequire(id, 'id');
    if (version < 1) throw RangeError.value(version, 'version');
  }

  factory VersionedConfigurationReference.fromMap(
    Map<String, Object?> map,
  ) {
    return VersionedConfigurationReference(
      id: supportString(map['id']),
      version: supportInt(map['version']),
    );
  }

  final String id;
  final int version;

  Map<String, Object?> toFirestore() => {
        'id': id.trim(),
        'version': version,
      };
}

class ServiceCatalogueItem {
  ServiceCatalogueItem({
    required this.id,
    required this.code,
    required this.version,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.categoryName,
    required this.iconKey,
    required this.eligibility,
    required Iterable<ItsmRole> visibleRoles,
    required this.workflow,
    required this.fulfilmentGroupId,
    required this.slaPolicy,
    required this.status,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    this.approvalPolicyId,
    this.serviceOwner,
    this.eligibilitySummary,
    this.costModel,
    this.availabilityTarget,
    this.fulfilmentSla,
    this.securityCompliance,
    this.fulfilmentWorkflow,
    this.activeFrom,
    this.activeUntil,
    this.allowManagerRequestOnBehalf = true,
    this.workflowAllowsCancellation = true,
    this.sortOrder = 0,
    Iterable<CatalogueConfigurationItemReference> underlyingCis = const [],
    Iterable<CatalogueFieldSchema> formFields = const [],
    Iterable<CatalogueRequiredDocument> requiredDocuments = const [],
  })  : visibleRoles = Set<ItsmRole>.unmodifiable(visibleRoles),
        underlyingCis = List<CatalogueConfigurationItemReference>.unmodifiable(
          underlyingCis,
        ),
        formFields = List<CatalogueFieldSchema>.unmodifiable(formFields),
        requiredDocuments =
            List<CatalogueRequiredDocument>.unmodifiable(requiredDocuments) {
    for (final value in {
      'id': id,
      'code': code,
      'categoryId': categoryId,
      'iconKey': iconKey,
      'fulfilmentGroupId': fulfilmentGroupId,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
    }.entries) {
      supportRequire(value.value, value.key);
    }
    if (version < 1) throw RangeError.value(version, 'version');
    if (this.visibleRoles.isEmpty) {
      throw ArgumentError('A catalogue item needs at least one visible role.');
    }
    if (activeFrom != null &&
        activeUntil != null &&
        activeFrom!.isAfter(activeUntil!)) {
      throw ArgumentError('activeFrom cannot be after activeUntil.');
    }
    _requireUniqueKeys(
      this.formFields.map((field) => field.key),
      'Dynamic form field',
    );
    _requireUniqueKeys(
      this.requiredDocuments.map((document) => document.key),
      'Required document',
    );
  }

  factory ServiceCatalogueItem.fromMap(
    String id,
    Map<String, Object?> map,
  ) {
    final workflowMap = supportMapFromValue(map['workflow']);
    final slaMap = supportMapFromValue(map['slaPolicy']);
    final serviceOwnerMap = supportMapFromValue(map['serviceOwner']);
    return ServiceCatalogueItem(
      id: id,
      code: supportString(map['code']),
      version: supportInt(map['version'], 1),
      name: LocalizedValue.fromValue(map['name']),
      description: LocalizedValue.fromValue(map['description']),
      categoryId: supportString(map['categoryId']),
      categoryName: LocalizedValue.fromValue(map['categoryName']),
      iconKey: supportString(map['iconKey'], 'support_agent'),
      eligibility:
          CatalogueEligibility.fromMap(supportMapFromValue(map['eligibility'])),
      visibleRoles: supportStringList(map['visibleRoles'])
          .map(ItsmRole.tryParse)
          .whereType<ItsmRole>(),
      workflow: VersionedConfigurationReference.fromMap(workflowMap),
      approvalPolicyId: supportNullableString(map['approvalPolicyId']),
      serviceOwner: serviceOwnerMap.isEmpty
          ? null
          : CatalogueServiceOwner.fromMap(serviceOwnerMap),
      eligibilitySummary: _localizedNullable(map['eligibilitySummary']),
      costModel: _localizedNullable(map['costModel']),
      availabilityTarget: _localizedNullable(map['availabilityTarget']),
      fulfilmentSla: _localizedNullable(map['fulfilmentSla']),
      underlyingCis: supportListFromValue(map['underlyingCis'])
          .map(supportMapFromValue)
          .where((reference) => reference.isNotEmpty)
          .map(CatalogueConfigurationItemReference.fromMap),
      securityCompliance: _localizedNullable(map['securityCompliance']),
      fulfilmentWorkflow: _localizedNullable(map['fulfilmentWorkflow']),
      fulfilmentGroupId: supportString(map['fulfilmentGroupId']),
      slaPolicy: VersionedConfigurationReference.fromMap(slaMap),
      status: _publicationState(map['status']),
      activeFrom: supportDateFromValue(map['activeFrom']),
      activeUntil: supportDateFromValue(map['activeUntil']),
      allowManagerRequestOnBehalf:
          supportBool(map['allowManagerRequestOnBehalf'], true),
      workflowAllowsCancellation:
          supportBool(map['workflowAllowsCancellation'], true),
      sortOrder: supportInt(map['sortOrder']),
      formFields: supportListFromValue(map['formFields'])
          .map(supportMapFromValue)
          .where((field) => field.isNotEmpty)
          .map(CatalogueFieldSchema.fromMap),
      requiredDocuments: supportListFromValue(map['requiredDocuments'])
          .map(supportMapFromValue)
          .where((document) => document.isNotEmpty)
          .map(CatalogueRequiredDocument.fromMap),
      createdAt: supportDateFromValue(map['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      createdBy: supportString(map['createdBy'], 'unknown'),
      updatedAt: supportDateFromValue(map['updatedAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      updatedBy: supportString(map['updatedBy'], 'unknown'),
    );
  }

  final String id;
  final String code;
  final int version;
  final LocalizedValue name;
  final LocalizedValue description;
  final String categoryId;
  final LocalizedValue categoryName;
  final String iconKey;
  final CatalogueEligibility eligibility;
  final Set<ItsmRole> visibleRoles;
  final List<CatalogueFieldSchema> formFields;
  final List<CatalogueRequiredDocument> requiredDocuments;
  final VersionedConfigurationReference workflow;
  final String? approvalPolicyId;
  final CatalogueServiceOwner? serviceOwner;
  final LocalizedValue? eligibilitySummary;
  final LocalizedValue? costModel;
  final LocalizedValue? availabilityTarget;
  final LocalizedValue? fulfilmentSla;
  final List<CatalogueConfigurationItemReference> underlyingCis;
  final LocalizedValue? securityCompliance;
  final LocalizedValue? fulfilmentWorkflow;
  final String fulfilmentGroupId;
  final VersionedConfigurationReference slaPolicy;
  final DateTime? activeFrom;
  final DateTime? activeUntil;
  final ItsmPublicationState status;
  final bool allowManagerRequestOnBehalf;
  final bool workflowAllowsCancellation;
  final int sortOrder;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;

  bool isAvailableTo(
    CataloguePrincipal principal, {
    required DateTime at,
  }) {
    if (status != ItsmPublicationState.published ||
        !visibleRoles.contains(principal.role) ||
        !eligibility.allows(principal)) {
      return false;
    }
    if (activeFrom != null && at.isBefore(activeFrom!)) return false;
    if (activeUntil != null && at.isAfter(activeUntil!)) return false;
    return true;
  }

  Map<String, Object?> toFirestore() => {
        'code': code.trim(),
        'version': version,
        'name': name.toFirestore(),
        'description': description.toFirestore(),
        'categoryId': categoryId.trim(),
        'categoryName': categoryName.toFirestore(),
        'iconKey': iconKey.trim(),
        'eligibility': eligibility.toFirestore(),
        'visibleRoles':
            visibleRoles.map((role) => role.value).toList(growable: false),
        'formFields': formFields
            .map((field) => field.toFirestore())
            .toList(growable: false),
        'requiredDocuments': requiredDocuments
            .map((document) => document.toFirestore())
            .toList(growable: false),
        'workflow': workflow.toFirestore(),
        if (approvalPolicyId != null)
          'approvalPolicyId': approvalPolicyId!.trim(),
        if (serviceOwner != null) 'serviceOwner': serviceOwner!.toFirestore(),
        if (eligibilitySummary != null)
          'eligibilitySummary': eligibilitySummary!.toFirestore(),
        if (costModel != null) 'costModel': costModel!.toFirestore(),
        if (availabilityTarget != null)
          'availabilityTarget': availabilityTarget!.toFirestore(),
        if (fulfilmentSla != null)
          'fulfilmentSla': fulfilmentSla!.toFirestore(),
        'underlyingCis': underlyingCis
            .map((reference) => reference.toFirestore())
            .toList(growable: false),
        if (securityCompliance != null)
          'securityCompliance': securityCompliance!.toFirestore(),
        if (fulfilmentWorkflow != null)
          'fulfilmentWorkflow': fulfilmentWorkflow!.toFirestore(),
        'fulfilmentGroupId': fulfilmentGroupId.trim(),
        'slaPolicy': slaPolicy.toFirestore(),
        if (activeFrom != null) 'activeFrom': activeFrom,
        if (activeUntil != null) 'activeUntil': activeUntil,
        'status': status.value,
        'allowManagerRequestOnBehalf': allowManagerRequestOnBehalf,
        'workflowAllowsCancellation': workflowAllowsCancellation,
        'sortOrder': sortOrder,
        'createdAt': createdAt,
        'createdBy': createdBy.trim(),
        'updatedAt': updatedAt,
        'updatedBy': updatedBy.trim(),
      };
}

Set<String> _normalizedSet(Iterable<String> values) {
  return Set<String>.unmodifiable(
    values.map((value) => value.trim()).where((value) => value.isNotEmpty),
  );
}

void _requireUniqueKeys(Iterable<String> keys, String subject) {
  final normalized = keys.map((key) => key.trim()).toList(growable: false);
  if (normalized.toSet().length != normalized.length) {
    throw ArgumentError('$subject keys must be unique.');
  }
}

ItsmPublicationState _publicationState(Object? value) {
  final normalized = supportString(value).toLowerCase();
  return ItsmPublicationState.values.firstWhere(
    (state) => state.value == normalized,
    orElse: () => ItsmPublicationState.draft,
  );
}

LocalizedValue? _localizedNullable(Object? value) {
  final map = supportMapFromValue(value);
  if (map.isEmpty && supportString(value).isEmpty) return null;
  return LocalizedValue.fromValue(value);
}
