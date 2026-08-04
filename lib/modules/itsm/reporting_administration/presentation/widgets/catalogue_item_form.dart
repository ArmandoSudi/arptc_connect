import 'package:arptc_connect/modules/itsm/shared/domain/itsm_common.dart';
import 'package:arptc_connect/modules/itsm/support/domain/service_catalogue.dart';
import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:arptc_connect/generated/l10n.dart';
import 'package:flutter/material.dart';

import '../reporting_administration_strings.dart';
import '../../domain/catalogue_form_parameters.dart';

class CatalogueItemDraftValue {
  CatalogueItemDraftValue({
    required this.code,
    required this.nameEn,
    required this.nameFr,
    required this.descriptionEn,
    required this.descriptionFr,
    required this.categoryId,
    required this.categoryNameEn,
    required this.categoryNameFr,
    required this.iconKey,
    required this.serviceOwnerName,
    required this.serviceOwnerTeamName,
    required this.serviceOwnerUserId,
    required this.eligibilitySummaryEn,
    required this.eligibilitySummaryFr,
    required this.costModelEn,
    required this.costModelFr,
    required this.availabilityTargetEn,
    required this.availabilityTargetFr,
    required this.fulfilmentSlaEn,
    required this.fulfilmentSlaFr,
    required this.underlyingCis,
    required this.securityComplianceEn,
    required this.securityComplianceFr,
    required this.fulfilmentWorkflowEn,
    required this.fulfilmentWorkflowFr,
    required this.workflowId,
    required this.workflowVersion,
    required this.slaPolicyId,
    required this.slaPolicyVersion,
    required this.fulfilmentGroupId,
    this.approvalPolicyId = '',
    this.allEmployees = true,
    Iterable<String> departmentIds = const [],
    Iterable<String> serviceIds = const [],
    Iterable<String> locationIds = const [],
    Iterable<String> positionValues = const [],
    Iterable<ItsmRole> visibleRoles = ItsmRole.values,
    Iterable<Map<String, Object?>> formFields = const [],
    Iterable<Map<String, Object?>> requiredDocuments = const [],
    this.allowManagerRequestOnBehalf = true,
    this.workflowAllowsCancellation = true,
    this.sortOrder = 0,
  })  : departmentIds = _normalizedIds(departmentIds),
        serviceIds = _normalizedIds(serviceIds),
        locationIds = _normalizedIds(locationIds),
        positionValues = _normalizedIds(positionValues),
        visibleRoles = Set<ItsmRole>.unmodifiable(visibleRoles),
        formFields = List<Map<String, Object?>>.unmodifiable(formFields),
        requiredDocuments =
            List<Map<String, Object?>>.unmodifiable(requiredDocuments);

  factory CatalogueItemDraftValue.fromCatalogueItem(
    ServiceCatalogueItem item,
  ) {
    return CatalogueItemDraftValue(
      code: item.code,
      nameEn: item.name.en,
      nameFr: item.name.fr,
      descriptionEn: item.description.en,
      descriptionFr: item.description.fr,
      categoryId: item.categoryId,
      categoryNameEn: item.categoryName.en,
      categoryNameFr: item.categoryName.fr,
      iconKey: item.iconKey,
      serviceOwnerName: item.serviceOwner?.displayName ?? '',
      serviceOwnerTeamName: item.serviceOwner?.teamName ?? '',
      serviceOwnerUserId: item.serviceOwner?.userId ?? '',
      eligibilitySummaryEn: item.eligibilitySummary?.en ?? '',
      eligibilitySummaryFr: item.eligibilitySummary?.fr ?? '',
      costModelEn: item.costModel?.en ?? '',
      costModelFr: item.costModel?.fr ?? '',
      availabilityTargetEn: item.availabilityTarget?.en ?? '',
      availabilityTargetFr: item.availabilityTarget?.fr ?? '',
      fulfilmentSlaEn: item.fulfilmentSla?.en ?? '',
      fulfilmentSlaFr: item.fulfilmentSla?.fr ?? '',
      underlyingCis: item.underlyingCis
          .map((reference) => '${reference.id} | ${reference.name}')
          .join('\n'),
      securityComplianceEn: item.securityCompliance?.en ?? '',
      securityComplianceFr: item.securityCompliance?.fr ?? '',
      fulfilmentWorkflowEn: item.fulfilmentWorkflow?.en ?? '',
      fulfilmentWorkflowFr: item.fulfilmentWorkflow?.fr ?? '',
      workflowId: item.workflow.id,
      workflowVersion: item.workflow.version,
      slaPolicyId: item.slaPolicy.id,
      slaPolicyVersion: item.slaPolicy.version,
      fulfilmentGroupId: item.fulfilmentGroupId,
      approvalPolicyId: item.approvalPolicyId ?? '',
      allEmployees: item.eligibility.allEmployees,
      departmentIds: item.eligibility.departmentIds,
      serviceIds: item.eligibility.serviceIds,
      locationIds: item.eligibility.locationIds,
      positionValues: item.eligibility.positionValues,
      visibleRoles: item.visibleRoles,
      formFields: item.formFields
          .map((field) => field.toFirestore())
          .toList(growable: false),
      requiredDocuments: item.requiredDocuments
          .map((document) => document.toFirestore())
          .toList(growable: false),
      allowManagerRequestOnBehalf: item.allowManagerRequestOnBehalf,
      workflowAllowsCancellation: item.workflowAllowsCancellation,
      sortOrder: item.sortOrder,
    );
  }

  factory CatalogueItemDraftValue.fromDefinition(
    String itemId,
    Map<String, Object?> definition,
  ) {
    final item = ServiceCatalogueItem.fromMap(
      itemId,
      {
        ...definition,
        'version': definition['version'] ?? 1,
        'status': definition['status'] ?? ItsmPublicationState.draft.value,
        'createdAt': definition['createdAt'] ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        'createdBy': definition['createdBy'] ?? 'unknown',
        'updatedAt': definition['updatedAt'] ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        'updatedBy': definition['updatedBy'] ?? 'unknown',
      },
    );
    return CatalogueItemDraftValue.fromCatalogueItem(item);
  }

  final String code;
  final String nameEn;
  final String nameFr;
  final String descriptionEn;
  final String descriptionFr;
  final String categoryId;
  final String categoryNameEn;
  final String categoryNameFr;
  final String iconKey;
  final String serviceOwnerName;
  final String serviceOwnerTeamName;
  final String serviceOwnerUserId;
  final String eligibilitySummaryEn;
  final String eligibilitySummaryFr;
  final String costModelEn;
  final String costModelFr;
  final String availabilityTargetEn;
  final String availabilityTargetFr;
  final String fulfilmentSlaEn;
  final String fulfilmentSlaFr;
  final String underlyingCis;
  final String securityComplianceEn;
  final String securityComplianceFr;
  final String fulfilmentWorkflowEn;
  final String fulfilmentWorkflowFr;
  final String workflowId;
  final int workflowVersion;
  final String slaPolicyId;
  final int slaPolicyVersion;
  final String fulfilmentGroupId;
  final String approvalPolicyId;
  final bool allEmployees;
  final Set<String> departmentIds;
  final Set<String> serviceIds;
  final Set<String> locationIds;
  final Set<String> positionValues;
  final Set<ItsmRole> visibleRoles;
  final List<Map<String, Object?>> formFields;
  final List<Map<String, Object?>> requiredDocuments;
  final bool allowManagerRequestOnBehalf;
  final bool workflowAllowsCancellation;
  final int sortOrder;

  Map<String, Object?> toPayload() => {
        'code': code.trim().toUpperCase(),
        'name': _localized(nameEn, nameFr),
        'description': _localized(descriptionEn, descriptionFr),
        'categoryId': categoryId.trim(),
        'categoryName': _localized(categoryNameEn, categoryNameFr),
        'iconKey': iconKey.trim(),
        'eligibility': {
          'allEmployees': allEmployees,
          'userIds': const <String>[],
          'departmentIds': departmentIds.toList(growable: false),
          'serviceIds': serviceIds.toList(growable: false),
          'locationIds': locationIds.toList(growable: false),
          'positionValues': positionValues.toList(growable: false),
          'excludedUserIds': const <String>[],
        },
        'visibleRoles':
            visibleRoles.map((role) => role.value).toList(growable: false),
        'formFields': formFields,
        'requiredDocuments': requiredDocuments,
        'workflow': {
          'definitionId': workflowId.trim(),
          'version': workflowVersion,
          'versionDocumentId': 'v$workflowVersion',
        },
        'approvalPolicyId': _nullable(approvalPolicyId),
        'serviceOwner': {
          'displayName': serviceOwnerName.trim(),
          'userId': _nullable(serviceOwnerUserId),
          'teamName': _nullable(serviceOwnerTeamName),
        },
        'eligibilitySummary': _localized(
          eligibilitySummaryEn,
          eligibilitySummaryFr,
        ),
        'costModel': _localized(costModelEn, costModelFr),
        'availabilityTarget': _localized(
          availabilityTargetEn,
          availabilityTargetFr,
        ),
        'fulfilmentSla': _localized(fulfilmentSlaEn, fulfilmentSlaFr),
        'underlyingCis': _ciReferences(underlyingCis),
        'securityCompliance': _localized(
          securityComplianceEn,
          securityComplianceFr,
        ),
        'fulfilmentWorkflow': _localized(
          fulfilmentWorkflowEn,
          fulfilmentWorkflowFr,
        ),
        'fulfilmentGroupId': fulfilmentGroupId.trim(),
        'slaPolicy': {
          'definitionId': slaPolicyId.trim(),
          'version': slaPolicyVersion,
          'versionDocumentId': 'v$slaPolicyVersion',
        },
        'activeFrom': null,
        'activeUntil': null,
        'allowManagerRequestOnBehalf': allowManagerRequestOnBehalf,
        'workflowAllowsCancellation': workflowAllowsCancellation,
        'sortOrder': sortOrder,
      };

  static Set<String> _normalizedIds(Iterable<String> values) =>
      Set<String>.unmodifiable(
        values.map((value) => value.trim()).where((value) => value.isNotEmpty),
      );

  static Map<String, Object?> _localized(String en, String fr) => {
        'en': en.trim(),
        'fr': fr.trim(),
      };

  static String? _nullable(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  static List<Map<String, Object?>> _ciReferences(String input) {
    return input
        .split(RegExp(r'[\n,]+'))
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .map((entry) {
      final divider = entry.indexOf('|');
      if (divider < 1 || divider == entry.length - 1) {
        throw const FormatException(
          'Each underlying CI must use the format: ci-id | CI name.',
        );
      }
      return {
        'id': entry.substring(0, divider).trim(),
        'name': entry.substring(divider + 1).trim(),
      };
    }).toList(growable: false);
  }
}

class CatalogueItemForm extends StatefulWidget {
  const CatalogueItemForm({
    required this.onSubmit,
    super.key,
    this.initialValue,
    this.parameters = const CatalogueFormParameters.empty(),
    this.readOnly = false,
  });

  final CatalogueItemDraftValue? initialValue;
  final CatalogueFormParameters parameters;
  final bool readOnly;
  final ValueChanged<CatalogueItemDraftValue> onSubmit;

  @override
  State<CatalogueItemForm> createState() => _CatalogueItemFormState();
}

class _CatalogueItemFormState extends State<CatalogueItemForm> {
  final _key = GlobalKey<FormState>();
  late final _controllers = <String, TextEditingController>{
    for (final entry in _initialTextValues.entries)
      entry.key: TextEditingController(text: entry.value),
  };
  late bool _allEmployees = widget.initialValue?.allEmployees ?? true;
  late final Set<ItsmRole> _visibleRoles = Set<ItsmRole>.of(
    widget.initialValue?.visibleRoles ?? ItsmRole.values,
  );
  late final Set<String> _configurationItemIds = _configurationItemIdsFrom(
    widget.initialValue?.underlyingCis ?? '',
  );

  Map<String, String> get _initialTextValues {
    final value = widget.initialValue;
    return {
      'code': value?.code ?? '',
      'name': _firstAvailable(value?.nameEn, value?.nameFr),
      'description': _firstAvailable(
        value?.descriptionEn,
        value?.descriptionFr,
      ),
      'categoryId': value?.categoryId ?? '',
      'categoryName': _firstAvailable(
        value?.categoryNameEn,
        value?.categoryNameFr,
      ),
      'iconKey': value?.iconKey ?? 'support_agent',
      'serviceOwnerName': value?.serviceOwnerName ?? '',
      'serviceOwnerTeamName': value?.serviceOwnerTeamName ?? '',
      'serviceOwnerUserId': value?.serviceOwnerUserId ?? '',
      'eligibilitySummary': _firstAvailable(
        value?.eligibilitySummaryEn,
        value?.eligibilitySummaryFr,
      ),
      'departmentIds': value?.departmentIds.join(', ') ?? '',
      'serviceIds': value?.serviceIds.join(', ') ?? '',
      'locationIds': value?.locationIds.join(', ') ?? '',
      'positionValues': value?.positionValues.join(', ') ?? '',
      'costModel': _firstAvailable(value?.costModelEn, value?.costModelFr),
      'availabilityTarget': _firstAvailable(
        value?.availabilityTargetEn,
        value?.availabilityTargetFr,
      ),
      'fulfilmentSla': _firstAvailable(
        value?.fulfilmentSlaEn,
        value?.fulfilmentSlaFr,
      ),
      'underlyingCis': value?.underlyingCis ?? '',
      'securityCompliance': _firstAvailable(
        value?.securityComplianceEn,
        value?.securityComplianceFr,
      ),
      'fulfilmentWorkflow': _firstAvailable(
        value?.fulfilmentWorkflowEn,
        value?.fulfilmentWorkflowFr,
      ),
      'workflowId': value?.workflowId ?? '',
      'workflowVersion': '${value?.workflowVersion ?? 1}',
      'slaPolicyId': value?.slaPolicyId ?? '',
      'slaPolicyVersion': '${value?.slaPolicyVersion ?? 1}',
      'fulfilmentGroupId': value?.fulfilmentGroupId ?? '',
      'approvalPolicyId': value?.approvalPolicyId ?? '',
      'sortOrder': '${value?.sortOrder ?? 0}',
    };
  }

  static String _firstAvailable(String? preferred, String? fallback) {
    final preferredValue = preferred?.trim() ?? '';
    return preferredValue.isNotEmpty ? preferredValue : fallback?.trim() ?? '';
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ReportingAdministrationStrings.of(context);
    return Form(
      key: _key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FormSection(
            title: strings.value('catalogueMetadata'),
            children: [
              _text('code', strings.value('serviceCode')),
              _text('name', strings.value('name')),
              _text('description', strings.value('description'),
                  multiline: true),
              _select(
                key: 'categoryId',
                label: strings.value('categoryName'),
                options: widget.parameters.categories,
                onSelected: (option) =>
                    _controllers['categoryName']!.text = option.label,
              ),
              _text('iconKey', strings.value('iconKey')),
            ],
          ),
          _FormSection(
            title: strings.value('serviceOwnership'),
            children: [
              _text('serviceOwnerName', strings.value('serviceOwner')),
              _text('serviceOwnerTeamName', strings.value('ownerTeam')),
              _text('serviceOwnerUserId', strings.value('ownerUserId'),
                  required: false),
            ],
          ),
          _FormSection(
            title: strings.value('eligibility'),
            children: [
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _allEmployees,
                onChanged: widget.readOnly
                    ? null
                    : (value) => setState(() => _allEmployees = value),
                title: Text(strings.value('allActiveEmployees')),
              ),
              _text('eligibilitySummary', strings.value('eligibilitySummary'),
                  multiline: true),
              _text('departmentIds', strings.value('eligibleDepartmentIds'),
                  required: false),
              _text('serviceIds', strings.value('eligibleServiceIds'),
                  required: false),
              _text('locationIds', strings.value('eligibleLocationIds'),
                  required: false),
              _text('positionValues', strings.value('eligiblePositions'),
                  required: false),
              _visibleRolesField(strings),
            ],
          ),
          _FormSection(
            title: strings.value('operationalTargets'),
            children: [
              _text('costModel', strings.value('costModel')),
              _text('availabilityTarget', strings.value('availabilityTarget')),
              _text('fulfilmentSla', strings.value('fulfilmentSla')),
            ],
          ),
          _FormSection(
            title: strings.value('technicalDelivery'),
            children: [
              _configurationItemsField(strings),
              _text('securityCompliance', strings.value('securityCompliance'),
                  multiline: true),
              _text('fulfilmentWorkflow', strings.value('fulfilmentWorkflow'),
                  multiline: true),
            ],
          ),
          _FormSection(
            title: strings.value('workflowConfiguration'),
            children: [
              _select(
                key: 'workflowId',
                label: strings.value('workflowId'),
                options: widget.parameters.workflows,
                onSelected: (option) {
                  _controllers['workflowVersion']!.text =
                      '${option.version ?? 1}';
                },
              ),
              _select(
                key: 'slaPolicyId',
                label: strings.value('slaPolicyId'),
                options: widget.parameters.slaPolicies,
                onSelected: (option) {
                  _controllers['slaPolicyVersion']!.text =
                      '${option.version ?? 1}';
                },
              ),
              _select(
                key: 'fulfilmentGroupId',
                label: strings.value('fulfilmentGroupId'),
                options: widget.parameters.fulfilmentGroups,
              ),
              _select(
                key: 'approvalPolicyId',
                label: strings.value('approvalPolicyId'),
                options: widget.parameters.approvalPolicies,
                required: false,
              ),
              _text('sortOrder', strings.value('sortOrder'),
                  number: true, required: false),
            ],
          ),
          if (!widget.readOnly) ...[
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save_outlined),
                label: Text(strings.value('saveDraft')),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _visibleRolesField(ReportingAdministrationStrings strings) {
    return InputDecorator(
      decoration: InputDecoration(labelText: strings.value('visibleToRoles')),
      child: Wrap(
        spacing: 8,
        children: ItsmRole.values.map((role) {
          return FilterChip(
            label: Text(role.value),
            selected: _visibleRoles.contains(role),
            onSelected: widget.readOnly
                ? null
                : (selected) => setState(() {
                      selected
                          ? _visibleRoles.add(role)
                          : _visibleRoles.remove(role);
                    }),
          );
        }).toList(growable: false),
      ),
    );
  }

  Widget _text(
    String key,
    String label, {
    bool multiline = false,
    bool number = false,
    bool required = true,
    String? helperText,
  }) {
    final strings = ReportingAdministrationStrings.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CommonTextInput(
        label: label,
        hintText: helperText,
        controller: _controllers[key],
        readOnly: widget.readOnly,
        isMultiline: multiline,
        type: number ? CommonTextInputType.number : CommonTextInputType.text,
        validator: required
            ? (value) => value?.trim().isNotEmpty == true
                ? null
                : strings.value('requiredField')
            : null,
      ),
    );
  }

  Widget _select({
    required String key,
    required String label,
    required List<CatalogueFormOption> options,
    ValueChanged<CatalogueFormOption>? onSelected,
    bool required = true,
  }) {
    final strings = ReportingAdministrationStrings.of(context);
    final selectedId = _value(key);
    final selected =
        options.any((option) => option.id == selectedId) ? selectedId : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: selected,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          helperText: options.isEmpty
              ? strings.value('configureCatalogueParametersFirst')
              : null,
        ),
        items: [
          if (!required)
            DropdownMenuItem<String>(
              value: '',
              child: Text(strings.value('none')),
            ),
          ...options.map(
            (option) => DropdownMenuItem<String>(
              value: option.id,
              child: Text(option.label),
            ),
          ),
        ],
        onChanged: widget.readOnly || options.isEmpty
            ? null
            : (value) {
                CatalogueFormOption? option;
                for (final item in options) {
                  if (item.id == value) {
                    option = item;
                    break;
                  }
                }
                setState(() {
                  _controllers[key]!.text = value ?? '';
                  if (option != null) onSelected?.call(option);
                });
              },
        validator: required
            ? (value) => value?.trim().isNotEmpty == true
                ? null
                : strings.value('requiredField')
            : null,
      ),
    );
  }

  Widget _configurationItemsField(ReportingAdministrationStrings strings) {
    final options = widget.parameters.configurationItems;
    final selected = options
        .where((option) => _configurationItemIds.contains(option.id))
        .toList(growable: false);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FormField<Set<String>>(
        initialValue: _configurationItemIds,
        validator: (_) => _configurationItemIds.isEmpty
            ? strings.value('requiredField')
            : null,
        builder: (state) => InputDecorator(
          decoration: InputDecoration(
            labelText: strings.value('underlyingCis'),
            helperText: options.isEmpty
                ? strings.value('configureCatalogueParametersFirst')
                : strings.value('selectConfigurationItems'),
            errorText: state.errorText,
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (selected.isEmpty)
                Text(strings.value('none'))
              else
                ...selected.map((option) => Chip(label: Text(option.label))),
              OutlinedButton.icon(
                onPressed: widget.readOnly || options.isEmpty
                    ? null
                    : () => _pickConfigurationItems(options, state),
                icon: const Icon(Icons.add_link_outlined),
                label: Text(strings.value('select')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickConfigurationItems(
    List<CatalogueFormOption> options,
    FormFieldState<Set<String>> field,
  ) async {
    final selected = await showDialog<Set<String>>(
      context: context,
      builder: (context) {
        final values = Set<String>.of(_configurationItemIds);
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(ReportingAdministrationStrings.of(context)
                .value('underlyingCis')),
            content: SizedBox(
              width: 520,
              child: ListView(
                shrinkWrap: true,
                children: options
                    .map(
                      (option) => CheckboxListTile(
                        value: values.contains(option.id),
                        title: Text(option.label),
                        subtitle: Text(option.id),
                        onChanged: (checked) => setDialogState(() {
                          if (checked == true) {
                            values.add(option.id);
                          } else {
                            values.remove(option.id);
                          }
                        }),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(S.of(context).cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(values),
                child: Text(S.of(context).save),
              ),
            ],
          ),
        );
      },
    );
    if (selected == null || !mounted) return;
    setState(() {
      _configurationItemIds
        ..clear()
        ..addAll(selected);
      _controllers['underlyingCis']!.text = options
          .where((option) => _configurationItemIds.contains(option.id))
          .map((option) => '${option.id} | ${option.label}')
          .join('\n');
      field.didChange(_configurationItemIds);
    });
  }

  void _submit() {
    if (_key.currentState?.validate() != true) return;
    if (_visibleRoles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(ReportingAdministrationStrings.of(context)
                .value('visibleRolesRequired'))),
      );
      return;
    }
    if (!_allEmployees &&
        _csv('departmentIds').isEmpty &&
        _csv('serviceIds').isEmpty &&
        _csv('locationIds').isEmpty &&
        _csv('positionValues').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ReportingAdministrationStrings.of(context)
                .value('restrictedEligibilityRequired'),
          ),
        ),
      );
      return;
    }
    try {
      widget.onSubmit(CatalogueItemDraftValue(
        code: _value('code'),
        nameEn: _value('name'),
        nameFr: _value('name'),
        descriptionEn: _value('description'),
        descriptionFr: _value('description'),
        categoryId: _value('categoryId'),
        categoryNameEn: _value('categoryName'),
        categoryNameFr: _value('categoryName'),
        iconKey: _value('iconKey'),
        serviceOwnerName: _value('serviceOwnerName'),
        serviceOwnerTeamName: _value('serviceOwnerTeamName'),
        serviceOwnerUserId: _value('serviceOwnerUserId'),
        eligibilitySummaryEn: _value('eligibilitySummary'),
        eligibilitySummaryFr: _value('eligibilitySummary'),
        costModelEn: _value('costModel'),
        costModelFr: _value('costModel'),
        availabilityTargetEn: _value('availabilityTarget'),
        availabilityTargetFr: _value('availabilityTarget'),
        fulfilmentSlaEn: _value('fulfilmentSla'),
        fulfilmentSlaFr: _value('fulfilmentSla'),
        underlyingCis: _value('underlyingCis'),
        securityComplianceEn: _value('securityCompliance'),
        securityComplianceFr: _value('securityCompliance'),
        fulfilmentWorkflowEn: _value('fulfilmentWorkflow'),
        fulfilmentWorkflowFr: _value('fulfilmentWorkflow'),
        workflowId: _value('workflowId'),
        workflowVersion: _integer('workflowVersion'),
        slaPolicyId: _value('slaPolicyId'),
        slaPolicyVersion: _integer('slaPolicyVersion'),
        fulfilmentGroupId: _value('fulfilmentGroupId'),
        approvalPolicyId: _value('approvalPolicyId'),
        allEmployees: _allEmployees,
        departmentIds: _csv('departmentIds'),
        serviceIds: _csv('serviceIds'),
        locationIds: _csv('locationIds'),
        positionValues: _csv('positionValues'),
        visibleRoles: _visibleRoles,
        formFields: widget.initialValue?.formFields ?? const [],
        requiredDocuments: widget.initialValue?.requiredDocuments ?? const [],
        allowManagerRequestOnBehalf:
            widget.initialValue?.allowManagerRequestOnBehalf ?? true,
        workflowAllowsCancellation:
            widget.initialValue?.workflowAllowsCancellation ?? true,
        sortOrder: _integer('sortOrder'),
      ));
    } on FormatException catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  String _value(String key) => _controllers[key]!.text.trim();

  static Set<String> _configurationItemIdsFrom(String value) => value
      .split(RegExp(r'[\n,]+'))
      .map((entry) => entry.split('|').first.trim())
      .where((id) => id.isNotEmpty)
      .toSet();

  int _integer(String key) => int.tryParse(_value(key)) ?? 0;

  List<String> _csv(String key) => _value(key)
      .split(',')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
}

class _FormSection extends StatelessWidget {
  const _FormSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
