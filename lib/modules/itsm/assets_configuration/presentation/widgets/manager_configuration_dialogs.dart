import 'dart:math' as math;

import 'package:arptc_connect/widgets/common_text_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/application/itsm_providers.dart';
import '../../../shared/data/trusted_command_gateways.dart';
import '../../application/assets_configuration_contracts.dart';
import '../../application/assets_configuration_providers.dart';
import '../assets_configuration_strings.dart';

typedef ManagerDialogAction = Future<void> Function(
  BuildContext context,
  WidgetRef ref,
);
typedef ManagerLicenceDialogAction = Future<void> Function(
  BuildContext context,
  WidgetRef ref,
  LicenceSummary licence,
);
typedef ManagerWarrantyDialogAction = Future<void> Function(
  BuildContext context,
  WidgetRef ref,
  WarrantySummary warranty,
);
typedef ManagerSupplierDialogAction = Future<void> Function(
  BuildContext context,
  WidgetRef ref,
  SupplierSummary supplier,
);
typedef ManagerContractDialogAction = Future<void> Function(
  BuildContext context,
  WidgetRef ref,
  ContractSummary contract,
);
typedef ManagerConfigurationItemDialogAction = Future<void> Function(
  BuildContext context,
  WidgetRef ref,
  ConfigurationItemSummary item,
);
typedef ManagerRelationshipDialogAction = Future<void> Function(
  BuildContext context,
  WidgetRef ref,
  ConfigurationRelationship relationship,
);

Future<void> showRegisterAssetDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final strings = AssetsConfigurationStrings.of(context);
  await _showManagerRecordDialog(
    context,
    ref,
    title: strings.registerNewAsset,
    submitLabel: strings.registerAsset,
    successMessage: strings.configurationOperationCompleted,
    recordType: 'asset',
    operation: 'register',
    recordIdKey: 'assetId',
    staticFields: const {'status': 'planned'},
    fields: [
      _requiredId('assetId', strings.assetId, strings),
      _requiredText('assetTag', strings.assetTag, strings),
      _requiredId('categoryId', strings.categoryId, strings),
      _FieldSpec(key: 'categoryName', label: strings.category),
      _requiredText('type', strings.type, strings),
      _FieldSpec(key: 'brand', label: strings.brand),
      _FieldSpec(key: 'model', label: strings.model),
      _FieldSpec(key: 'serialNumber', label: strings.serialNumber),
      _FieldSpec(key: 'condition', label: strings.condition),
      _FieldSpec(key: 'locationId', label: strings.location, identifier: true),
      _FieldSpec(
          key: 'supplierId', label: strings.supplierId, identifier: true),
      _FieldSpec(
          key: 'warrantyId', label: strings.warrantyId, identifier: true),
      _dateField('acquisitionDate', strings.acquisitionDate, strings),
      _FieldSpec(
        key: 'acquisitionCost',
        label: strings.acquisitionCost,
        type: CommonTextInputType.decimal,
        parse: _optionalNumber,
      ),
      _FieldSpec(key: 'currency', label: strings.currency),
      _FieldSpec(
        key: 'description',
        label: strings.description,
        multiline: true,
      ),
    ],
  );
}

Future<void> showEditAssetDialog(
  BuildContext context,
  WidgetRef ref,
  AssetDetail detail,
) async {
  final strings = AssetsConfigurationStrings.of(context);
  await _showAssetRecordDialog(
    context,
    ref,
    title: strings.editAsset,
    submitLabel: strings.save,
    successMessage: strings.lifecycleOperationCompleted,
    assetId: detail.summary.id,
    operation: 'update',
    fields: [
      _requiredText('assetTag', strings.assetTag, strings,
          initialValue: detail.summary.assetTag),
      _requiredText('type', strings.type, strings,
          initialValue: detail.typeName),
      _FieldSpec(
          key: 'categoryName',
          label: strings.category,
          initialValue: detail.summary.categoryName),
      _FieldSpec(
          key: 'brand',
          label: strings.brand,
          initialValue: detail.summary.brand),
      _FieldSpec(
          key: 'model',
          label: strings.model,
          initialValue: detail.summary.model),
      _FieldSpec(
        key: 'serialNumber',
        label: strings.serialNumber,
        initialValue: detail.summary.serialNumber,
      ),
      _FieldSpec(
        key: 'description',
        label: strings.description,
        multiline: true,
        initialValue: detail.description,
      ),
      _FieldSpec(
        key: 'condition',
        label: strings.condition,
        initialValue: detail.summary.condition,
      ),
      _FieldSpec(
        key: 'locationId',
        label: strings.location,
        identifier: true,
        initialValue: detail.summary.locationName,
      ),
      _FieldSpec(
        key: 'stockLocationId',
        label: strings.stockLocationId,
        identifier: true,
        initialValue: detail.stockLocationName,
      ),
      _FieldSpec(
        key: 'supplierId',
        label: strings.supplierId,
        identifier: true,
        initialValue: detail.supplierName,
      ),
      _FieldSpec(
        key: 'warrantyId',
        label: strings.warrantyId,
        identifier: true,
        initialValue: detail.warrantyName,
      ),
    ],
  );
}

Future<void> showAssignAssetDialog(
  BuildContext context,
  WidgetRef ref,
  AssetDetail detail,
) async {
  final strings = AssetsConfigurationStrings.of(context);
  await _showAssetRecordDialog(
    context,
    ref,
    title: strings.assignAsset,
    submitLabel: strings.assignAsset,
    successMessage: strings.lifecycleOperationCompleted,
    assetId: detail.summary.id,
    operation: 'assign',
    fields: [
      _requiredId('assignedUserId', strings.assignedUserId, strings),
      _FieldSpec(
        key: 'departmentId',
        label: strings.department,
        identifier: true,
      ),
      _FieldSpec(
        key: 'locationId',
        label: strings.location,
        identifier: true,
        initialValue: detail.summary.locationName,
      ),
      _FieldSpec(
        key: 'relatedRequestId',
        label: strings.relatedRequest,
        identifier: true,
      ),
      _FieldSpec(
        key: 'evidence',
        label: strings.supportingDocument,
        identifier: true,
      ),
    ],
  );
}

Future<void> showReturnAssetDialog(
  BuildContext context,
  WidgetRef ref,
  AssetDetail detail,
) async {
  final strings = AssetsConfigurationStrings.of(context);
  await _showAssetRecordDialog(
    context,
    ref,
    title: strings.returnAsset,
    submitLabel: strings.returnAsset,
    successMessage: strings.lifecycleOperationCompleted,
    assetId: detail.summary.id,
    operation: 'return',
    fields: [
      _requiredText('condition', strings.condition, strings,
          initialValue: detail.summary.condition),
      _requiredText('reason', strings.reason, strings, multiline: true),
      _FieldSpec(
        key: 'locationId',
        label: strings.location,
        identifier: true,
      ),
      _FieldSpec(
        key: 'stockLocationId',
        label: strings.stockLocationId,
        identifier: true,
      ),
      _FieldSpec(
        key: 'relatedRequestId',
        label: strings.relatedRequest,
        identifier: true,
      ),
      _FieldSpec(
        key: 'evidence',
        label: strings.supportingDocument,
        identifier: true,
      ),
    ],
  );
}

Future<void> showAssetLifecycleTransitionDialog(
  BuildContext context,
  WidgetRef ref,
  AssetDetail detail, {
  List<AssetLifecycleStatus>? validTransitions,
}) async {
  final strings = AssetsConfigurationStrings.of(context);
  final transitions =
      validTransitions ?? availableAssetLifecycleTransitions(detail);
  if (transitions.isEmpty) return;
  final selected = await showDialog<AssetLifecycleStatus>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: Text(strings.transitionAsset),
      children: [
        for (final status in transitions)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, status),
            child: Text(strings.lifecycleStatus(status)),
          ),
      ],
    ),
  );
  if (selected == null || !context.mounted) return;
  if (_isExceptionalAssetStatus(selected)) {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Theme.of(dialogContext).colorScheme.error,
        ),
        title: Text(
          '${strings.confirmExceptionalAssetStatus}: '
          '${strings.lifecycleStatus(selected)}',
        ),
        content: Text(strings.exceptionalAssetStatusWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(strings.confirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
  }
  await _showAssetRecordDialog(
    context,
    ref,
    title: '${strings.transitionAsset}: ${strings.lifecycleStatus(selected)}',
    submitLabel: strings.transitionAsset,
    successMessage: strings.lifecycleOperationCompleted,
    assetId: detail.summary.id,
    operation: 'transition',
    staticFields: {'toStatus': selected.name},
    fields: [
      _requiredText('reason', strings.transitionReason, strings,
          multiline: true),
      _FieldSpec(
        key: 'relatedRequestId',
        label: strings.relatedRequest,
        identifier: true,
      ),
      _FieldSpec(
        key: 'condition',
        label: strings.condition,
        initialValue: detail.summary.condition,
      ),
      _FieldSpec(
        key: 'locationId',
        label: strings.location,
        identifier: true,
      ),
      _FieldSpec(
        key: 'stockLocationId',
        label: strings.stockLocationId,
        identifier: true,
      ),
    ],
  );
}

List<AssetLifecycleStatus> availableAssetLifecycleTransitions(
  AssetDetail detail,
) {
  final hasAssignment = detail.summary.assignedUserName.isNotEmpty;
  final transitions = _assetLifecycleTransitions[detail.summary.status] ??
      const <AssetLifecycleStatus>[];
  return transitions.where((status) {
    if (const {
      AssetLifecycleStatus.assigned,
      AssetLifecycleStatus.returned,
      AssetLifecycleStatus.retired,
    }.contains(status)) {
      return false;
    }
    if (hasAssignment &&
        !const {
          AssetLifecycleStatus.inMaintenance,
          AssetLifecycleStatus.lost,
          AssetLifecycleStatus.stolen,
        }.contains(status)) {
      return false;
    }
    return true;
  }).toList(growable: false);
}

Future<void> showRegisterLicenceDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final strings = AssetsConfigurationStrings.of(context);
  await _showManagerRecordDialog(
    context,
    ref,
    title: strings.registerNewLicence,
    submitLabel: strings.addLicence,
    successMessage: strings.configurationOperationCompleted,
    recordType: 'licence',
    operation: 'register',
    recordIdKey: 'licenceId',
    staticFields: const {'complianceStatus': 'assessment_pending'},
    fields: [
      _requiredId('licenceId', strings.recordIdentifier, strings),
      _requiredText('softwareProduct', strings.softwareProduct, strings),
      _requiredText('vendor', strings.vendor, strings),
      _requiredText('licenceType', strings.licenceType, strings),
      _positiveIntegerField(
        'purchasedQuantity',
        strings.purchasedQuantity,
        strings,
      ),
      _dateField('effectiveDate', strings.effectiveDate, strings),
      _dateField('expiryDate', strings.expires, strings),
      _dateField('renewalDate', strings.renewalDate, strings),
      _FieldSpec(
          key: 'contractId', label: strings.contractId, identifier: true),
      _FieldSpec(
        key: 'cost',
        label: strings.acquisitionCost,
        type: CommonTextInputType.decimal,
        parse: _optionalNumber,
      ),
      _FieldSpec(key: 'currency', label: strings.currency),
    ],
  );
}

Future<void> showSaveStockLocationDialog(
  BuildContext context,
  WidgetRef ref, {
  bool editing = false,
}) async {
  final strings = AssetsConfigurationStrings.of(context);
  await _showManagerRecordDialog(
    context,
    ref,
    title: editing ? strings.editStockLocation : strings.addStockLocation,
    submitLabel: strings.save,
    successMessage: strings.configurationOperationCompleted,
    recordType: 'stock_location',
    operation: 'save',
    recordIdKey: 'locationId',
    staticFields: const {'isActive': true},
    fields: [
      _requiredId('locationId', strings.stockLocationId, strings),
      _requiredText('name', strings.name, strings),
      _FieldSpec(
          key: 'description', label: strings.description, multiline: true),
      _FieldSpec(key: 'siteId', label: strings.location, identifier: true),
    ],
  );
}

Future<void> showSaveStockItemDialog(
  BuildContext context,
  WidgetRef ref, {
  StockItemSummary? item,
}) async {
  final strings = AssetsConfigurationStrings.of(context);
  await _showManagerRecordDialog(
    context,
    ref,
    title: item == null ? strings.addStockItem : strings.editStockItem,
    submitLabel: strings.save,
    successMessage: strings.configurationOperationCompleted,
    recordType: 'stock_item',
    operation: 'save',
    recordIdKey: 'stockItemId',
    fields: [
      _requiredId(
        'stockItemId',
        strings.stockItemId,
        strings,
        initialValue: item?.id ?? '',
      ),
      _requiredText('name', strings.name, strings,
          initialValue: item?.name ?? ''),
      _requiredText('sku', strings.sku, strings, initialValue: item?.sku ?? ''),
      _requiredText('unitOfMeasure', strings.unitOfMeasure, strings,
          initialValue: 'unit'),
      _FieldSpec(
        key: 'minimumQuantity',
        label: strings.lowStock,
        type: CommonTextInputType.decimal,
        initialValue: item?.minimumQuantity.toString() ?? '0',
        parse: _optionalNumber,
        validator: (value) {
          final number = num.tryParse(value);
          return number == null || number < 0
              ? strings.nonNegativeNumberRequired
              : null;
        },
      ),
      _FieldSpec(
        key: 'defaultLocationId',
        label: strings.stockLocationId,
        identifier: true,
        initialValue: item?.locationName ?? '',
      ),
      _FieldSpec(
          key: 'description', label: strings.description, multiline: true),
    ],
    choices: [
      _ChoiceSpec(
        key: 'isConsumable',
        label: strings.isConsumable,
        initialValue: (item?.isConsumable ?? false).toString(),
        values: const ['false', 'true'],
        labelFor: (value) => value == 'true' ? strings.yes : strings.no,
        parse: (value) => value == 'true',
      ),
    ],
  );
}

Future<void> showLicenceActionDialog(
  BuildContext context,
  WidgetRef ref,
  LicenceSummary licence,
) async {
  final strings = AssetsConfigurationStrings.of(context);
  final action = await showDialog<_LicenceAction>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(licence.productName),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${strings.available}: ${licence.availableQuantity}',
            style: Theme.of(dialogContext).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ListTile(
            enabled: licence.availableQuantity > 0,
            leading: const Icon(Icons.person_add_alt_1_outlined),
            title: Text(strings.allocateLicence),
            onTap: () => Navigator.pop(dialogContext, _LicenceAction.allocate),
          ),
          ListTile(
            leading: const Icon(Icons.person_remove_outlined),
            title: Text(strings.releaseLicence),
            onTap: () => Navigator.pop(dialogContext, _LicenceAction.release),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(strings.cancel),
        ),
      ],
    ),
  );
  if (!context.mounted || action == null) return;
  if (action == _LicenceAction.allocate) {
    await _showManagerRecordDialog(
      context,
      ref,
      title: strings.allocateLicence,
      submitLabel: strings.allocateLicence,
      successMessage: strings.configurationOperationCompleted,
      recordType: 'licence',
      operation: 'allocate',
      recordIdKey: 'licenceId',
      staticFields: {'licenceId': licence.id},
      fields: [
        _requiredId('assigneeId', strings.assigneeId, strings),
        _requiredText('assigneeName', strings.assigneeName, strings),
        _positiveIntegerField('quantity', strings.quantity, strings),
        _FieldSpec(
          key: 'relatedRequestId',
          label: strings.relatedRequest,
          identifier: true,
        ),
        _FieldSpec(
          key: 'notes',
          label: strings.description,
          multiline: true,
        ),
      ],
      choices: [
        _ChoiceSpec(
          key: 'assignmentType',
          label: strings.assignmentType,
          initialValue: 'user',
          values: const ['user', 'device'],
          labelFor: strings.assignmentTypeName,
        ),
      ],
    );
    return;
  }
  await _showManagerRecordDialog(
    context,
    ref,
    title: strings.releaseLicence,
    submitLabel: strings.releaseLicence,
    successMessage: strings.configurationOperationCompleted,
    recordType: 'licence',
    operation: 'release',
    recordIdKey: 'licenceId',
    staticFields: {'licenceId': licence.id},
    fields: [
      _requiredId('allocationId', strings.allocationId, strings),
      _requiredText('reason', strings.reason, strings, multiline: true),
      _FieldSpec(
        key: 'relatedRequestId',
        label: strings.relatedRequest,
        identifier: true,
      ),
    ],
  );
}

Future<void> showAddSupplierDialog(BuildContext context, WidgetRef ref,
    {SupplierSummary? supplier}) async {
  final strings = AssetsConfigurationStrings.of(context);
  await _showManagerRecordDialog(
    context,
    ref,
    title: supplier == null ? strings.addSupplier : strings.editSupplier,
    submitLabel: strings.saveSupplier,
    successMessage: strings.configurationOperationCompleted,
    recordType: 'supplier',
    operation: 'save',
    recordIdKey: 'id',
    staticFields: const {'isActive': true},
    fields: [
      _requiredId('id', strings.recordIdentifier, strings,
          initialValue: supplier?.id ?? ''),
      _requiredText('name', strings.name, strings,
          initialValue: supplier?.name ?? ''),
      _FieldSpec(key: 'legalName', label: strings.legalName),
      _FieldSpec(key: 'supplierCode', label: strings.assetTag),
      _FieldSpec(
        key: 'contactName',
        label: strings.contactName,
        initialValue: supplier?.contactName ?? '',
      ),
      _FieldSpec(
        key: 'contactEmail',
        label: strings.email,
        type: CommonTextInputType.email,
        validator: (value) => _optionalEmailValidator(value, strings),
        initialValue: supplier?.email ?? '',
      ),
      _FieldSpec(
        key: 'contactPhone',
        label: strings.phone,
        type: CommonTextInputType.phone,
        initialValue: supplier?.phone ?? '',
      ),
      _FieldSpec(key: 'address', label: strings.address, multiline: true),
      _FieldSpec(
        key: 'supportTerms',
        label: strings.supportTerms,
        multiline: true,
        initialValue: supplier?.supportTerms ?? '',
      ),
      _FieldSpec(
        key: 'description',
        label: strings.description,
        multiline: true,
      ),
    ],
  );
}

Future<void> showAddContractDialog(BuildContext context, WidgetRef ref,
    {ContractSummary? contract}) async {
  final strings = AssetsConfigurationStrings.of(context);
  await _showManagerRecordDialog(
    context,
    ref,
    title: contract == null ? strings.addContract : strings.editContract,
    submitLabel: strings.saveContract,
    successMessage: strings.configurationOperationCompleted,
    recordType: 'contract',
    operation: 'save',
    recordIdKey: 'id',
    staticFields: const {'isActive': true, 'status': 'active'},
    fields: [
      _requiredId('id', strings.recordIdentifier, strings,
          initialValue: contract?.id ?? ''),
      _requiredText('name', strings.name, strings,
          initialValue: contract?.title ?? ''),
      _requiredText('contractNumber', strings.contractNumber, strings,
          initialValue: contract?.number ?? ''),
      _requiredId('supplierId', strings.supplierId, strings,
          initialValue: _identifierInitial(contract?.supplierName)),
      _requiredDateField('startDate', strings.contractStart, strings,
          initialValue: _dateInitial(contract?.startsAt)),
      _requiredDateField('endDate', strings.contractEnd, strings,
          initialValue: _dateInitial(contract?.endsAt)),
      _dateField('renewalNoticeDate', strings.renewalDate, strings),
      _FieldSpec(
        key: 'supportTerms',
        label: strings.supportTerms,
        multiline: true,
      ),
      _FieldSpec(
        key: 'description',
        label: strings.description,
        multiline: true,
      ),
    ],
  );
}

Future<void> showAddWarrantyDialog(BuildContext context, WidgetRef ref,
    {WarrantySummary? warranty}) async {
  final strings = AssetsConfigurationStrings.of(context);
  await _showManagerRecordDialog(
    context,
    ref,
    title: warranty == null ? strings.addWarranty : strings.editWarranty,
    submitLabel: strings.saveWarranty,
    successMessage: strings.configurationOperationCompleted,
    recordType: 'warranty',
    operation: 'save',
    recordIdKey: 'id',
    staticFields: const {'isActive': true, 'status': 'active'},
    fields: [
      _requiredId('id', strings.recordIdentifier, strings,
          initialValue: warranty?.id ?? ''),
      _requiredText('name', strings.name, strings,
          initialValue: warranty?.name ?? ''),
      _requiredText('warrantyNumber', strings.warrantyNumber, strings),
      _requiredId('supplierId', strings.supplierId, strings,
          initialValue: _identifierInitial(warranty?.supplierName)),
      _FieldSpec(
          key: 'contractId', label: strings.contractId, identifier: true),
      _requiredText(
        'coverage',
        strings.warrantyCoverage,
        strings,
        multiline: true,
        initialValue: warranty?.coverage ?? '',
      ),
      _requiredDateField('startDate', strings.contractStart, strings),
      _requiredDateField(
        'expirationDate',
        strings.warrantyExpiration,
        strings,
        initialValue: _dateInitial(warranty?.expiresAt),
      ),
      _FieldSpec(
        key: 'description',
        label: strings.description,
        multiline: true,
      ),
    ],
  );
}

Future<void> showWarrantyClaimDialog(
  BuildContext context,
  WidgetRef ref,
  WarrantySummary warranty,
) async {
  final strings = AssetsConfigurationStrings.of(context);
  await _showManagerRecordDialog(
    context,
    ref,
    title: '${strings.recordWarrantyClaim}: ${warranty.name}',
    submitLabel: strings.recordWarrantyClaim,
    successMessage: strings.configurationOperationCompleted,
    recordType: 'warranty.claim',
    operation: 'record',
    recordIdKey: 'claimId',
    staticFields: {'warrantyId': warranty.id},
    fields: [
      _requiredId('claimId', strings.claimId, strings),
      _requiredId('assetId', strings.assetId, strings),
      _requiredText('title', strings.title, strings),
      _requiredText(
        'description',
        strings.description,
        strings,
        multiline: true,
      ),
      _FieldSpec(
        key: 'relatedRequestId',
        label: strings.relatedRequest,
        identifier: true,
      ),
    ],
  );
}

Future<void> showWarrantyClaimTransitionDialog(
  BuildContext context,
  WidgetRef ref,
  WarrantySummary warranty,
) async {
  final strings = AssetsConfigurationStrings.of(context);
  await _showManagerRecordDialog(
    context,
    ref,
    title: '${strings.transitionWarrantyClaim}: ${warranty.name}',
    submitLabel: strings.transitionWarrantyClaim,
    successMessage: strings.configurationOperationCompleted,
    recordType: 'warranty.claim',
    operation: 'transition',
    recordIdKey: 'claimId',
    staticFields: {'warrantyId': warranty.id},
    fields: [
      _requiredId('claimId', strings.claimId, strings),
      _requiredText(
        'reason',
        strings.claimResolution,
        strings,
        multiline: true,
      ),
      _FieldSpec(
        key: 'evidence',
        label: strings.supportingDocument,
        identifier: true,
      ),
    ],
    choices: [
      _ChoiceSpec(
        key: 'toStatus',
        label: strings.claimStatus,
        initialValue: 'acknowledged',
        values: const [
          'acknowledged',
          'approved',
          'rejected',
          'resolved',
          'closed',
        ],
        labelFor: strings.claimStatusName,
      ),
    ],
  );
}

Future<void> showAddConfigurationItemDialog(BuildContext context, WidgetRef ref,
    {ConfigurationItemSummary? item}) async {
  final strings = AssetsConfigurationStrings.of(context);
  await _showManagerRecordDialog(
    context,
    ref,
    title: item == null
        ? strings.addConfigurationItem
        : strings.editConfigurationItem,
    submitLabel: strings.saveConfigurationItem,
    successMessage: strings.configurationOperationCompleted,
    recordType: 'cmdb.ci',
    operation: 'save',
    recordIdKey: 'ciId',
    fields: [
      _requiredId('ciId', strings.recordIdentifier, strings,
          initialValue: item?.id ?? ''),
      _requiredText('name', strings.name, strings,
          initialValue: item?.name ?? ''),
      _FieldSpec(
          key: 'ownerUserId', label: strings.ownerUserId, identifier: true),
      _FieldSpec(
          key: 'ownerName',
          label: strings.ownerName,
          initialValue: item?.ownerName ?? ''),
      _FieldSpec(
        key: 'supportGroupId',
        label: strings.supportGroup,
        identifier: true,
      ),
      _FieldSpec(
          key: 'criticality',
          label: strings.criticality,
          initialValue: item?.criticality ?? ''),
      _FieldSpec(
        key: 'linkedAssetId',
        label: strings.linkedAssetId,
        identifier: true,
      ),
      _FieldSpec(
        key: 'description',
        label: strings.description,
        multiline: true,
      ),
      for (final related in [
        ('relatedIncidentIds', strings.relatedIncidentIds),
        ('relatedRequestIds', strings.relatedRequestIds),
        ('relatedChangeIds', strings.relatedChangeIds),
        ('relatedFindingIds', strings.relatedFindingIds),
      ])
        _FieldSpec(
          key: related.$1,
          label: related.$2,
          hintText: strings.commaSeparatedIdsHint,
          parse: _commaSeparatedIds,
        ),
    ],
    choices: [
      _ChoiceSpec(
        key: 'ciType',
        label: strings.ciType,
        initialValue: _ciTypeValue(item?.typeName),
        values: const [
          'service',
          'application',
          'server',
          'database',
          'network_device',
          'end_user_device',
        ],
        labelFor: strings.ciTypeName,
      ),
      _ChoiceSpec(
        key: 'operationalStatus',
        label: strings.operationalStatus,
        initialValue: _operationalStatusValue(item?.operationalStatus),
        values: const [
          'planned',
          'active',
          'degraded',
          'maintenance',
          'retired'
        ],
        labelFor: strings.operationalStatusName,
      ),
      _ChoiceSpec(
        key: 'dataQualityStatus',
        label: strings.dataQualityStatus,
        initialValue: _dataQualityValue(item?.dataQuality),
        values: const ['verified', 'needs_review', 'incomplete'],
        labelFor: strings.dataQualityName,
      ),
    ],
  );
}

Future<void> showCreateRelationshipDialog(
  BuildContext context,
  WidgetRef ref,
  ConfigurationItemSummary item,
) async {
  final strings = AssetsConfigurationStrings.of(context);
  await _showManagerRecordDialog(
    context,
    ref,
    title: '${strings.createRelationship}: ${item.name}',
    submitLabel: strings.createRelationship,
    successMessage: strings.configurationOperationCompleted,
    recordType: 'cmdb.relationship',
    operation: 'create',
    recordIdKey: 'relationshipId',
    staticFields: {
      'sourceEntityType': 'configuration_item',
      'sourceEntityId': item.id,
    },
    fields: [
      _requiredId('relationshipId', strings.recordIdentifier, strings),
      _requiredId('targetEntityId', strings.targetId, strings),
      _FieldSpec(
        key: 'description',
        label: strings.description,
        multiline: true,
      ),
    ],
    choices: [
      _ChoiceSpec(
        key: 'relationshipType',
        label: strings.relationshipType,
        initialValue: 'depends_on',
        values: const [
          'depends_on',
          'runs_on',
          'connected_to',
          'uses',
          'represented_by',
        ],
        labelFor: strings.relationshipTypeName,
      ),
      _ChoiceSpec(
        key: 'targetEntityType',
        label: strings.targetType,
        initialValue: 'configuration_item',
        values: const ['configuration_item', 'asset', 'service', 'user'],
        labelFor: strings.entityTypeName,
      ),
    ],
  );
}

Future<void> showRetireRelationshipDialog(
  BuildContext context,
  WidgetRef ref,
  ConfigurationRelationship relationship,
) async {
  final strings = AssetsConfigurationStrings.of(context);
  await _showManagerRecordDialog(
    context,
    ref,
    title: strings.retireRelationship,
    submitLabel: strings.retireRelationship,
    successMessage: strings.configurationOperationCompleted,
    recordType: 'cmdb.relationship',
    operation: 'retire',
    recordIdKey: 'relationshipId',
    staticFields: {'relationshipId': relationship.id},
    fields: [
      _requiredText('reason', strings.reason, strings, multiline: true),
    ],
    destructive: true,
  );
}

Future<void> _showManagerRecordDialog(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  required String submitLabel,
  required String successMessage,
  required String recordType,
  required String operation,
  required String recordIdKey,
  required List<_FieldSpec> fields,
  Map<String, Object?> staticFields = const {},
  List<_ChoiceSpec> choices = const [],
  bool destructive = false,
}) async {
  final succeeded = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _ManagerRecordDialog(
      title: title,
      submitLabel: submitLabel,
      fields: fields,
      choices: choices,
      destructive: destructive,
      onSubmit: (visibleFields) async {
        final payload = <String, Object?>{
          ...staticFields,
          ...visibleFields,
        };
        final recordId = payload[recordIdKey]?.toString().trim() ?? '';
        await _dispatchManagerCommand(
          ref,
          recordType: recordType,
          operation: operation,
          recordId: recordId,
          fields: payload,
        );
      },
    ),
  );
  if (succeeded == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(successMessage)),
    );
  }
}

Future<void> _showAssetRecordDialog(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  required String submitLabel,
  required String successMessage,
  required String assetId,
  required String operation,
  required List<_FieldSpec> fields,
  Map<String, Object?> staticFields = const {},
}) async {
  final succeeded = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _ManagerRecordDialog(
      title: title,
      submitLabel: submitLabel,
      fields: fields,
      choices: const [],
      destructive: operation == 'return',
      onSubmit: (visibleFields) async {
        final session = await ref.read(itsmSessionProvider.future);
        if (session == null) {
          throw const AssetsConfigurationAccessDenied(
            'An authenticated ITSM session is required.',
          );
        }
        final controller =
            await ref.read(assetsConfigurationCommandControllerProvider.future);
        final nonce = DateTime.now().toUtc().microsecondsSinceEpoch;
        await controller.operateAsset(
          AssetOperationalCommand(
            context: ItsmCommandContext(
              idempotencyKey: 'asset-$operation-$assetId-$nonce',
              correlationId: 'asset-$assetId-$nonce',
              actorUserId: session.userId,
              actorRole: session.role,
              actorDisplayName: session.displayName,
            ),
            assetId: assetId,
            operation: operation,
            fields: {...staticFields, ...visibleFields},
          ),
        );
      },
    ),
  );
  if (succeeded == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(successMessage)),
    );
  }
}

Future<void> _dispatchManagerCommand(
  WidgetRef ref, {
  required String recordType,
  required String operation,
  required String recordId,
  required Map<String, Object?> fields,
}) async {
  final session = await ref.read(itsmSessionProvider.future);
  if (session == null) {
    throw const AssetsConfigurationAccessDenied(
      'An authenticated ITSM session is required.',
    );
  }
  final controller =
      await ref.read(assetsConfigurationCommandControllerProvider.future);
  final nonce = DateTime.now().toUtc().microsecondsSinceEpoch;
  final normalizedOperation = operation.replaceAll('.', '-');
  await controller.manageConfiguration(
    ManagerConfigurationCommand(
      context: ItsmCommandContext(
        idempotencyKey: 'assets-ui-$normalizedOperation-$nonce',
        correlationId: 'assets-ui-$recordType-$nonce',
        actorUserId: session.userId,
        actorRole: session.role,
        actorDisplayName: session.displayName,
      ),
      recordType: recordType,
      operation: operation,
      recordId: recordId,
      fields: fields,
    ),
  );
}

class _ManagerRecordDialog extends StatefulWidget {
  const _ManagerRecordDialog({
    required this.title,
    required this.submitLabel,
    required this.fields,
    required this.choices,
    required this.onSubmit,
    required this.destructive,
  });

  final String title;
  final String submitLabel;
  final List<_FieldSpec> fields;
  final List<_ChoiceSpec> choices;
  final Future<void> Function(Map<String, Object?> fields) onSubmit;
  final bool destructive;

  @override
  State<_ManagerRecordDialog> createState() => _ManagerRecordDialogState();
}

class _ManagerRecordDialogState extends State<_ManagerRecordDialog> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers;
  late final Map<String, String> _choices;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final field in widget.fields)
        field.key: TextEditingController(text: field.initialValue),
    };
    _choices = {
      for (final choice in widget.choices) choice.key: choice.initialValue,
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final values = <String, Object?>{
      for (final choice in widget.choices)
        choice.key: choice.parse(_choices[choice.key]!),
    };
    for (final field in widget.fields) {
      final raw = _controllers[field.key]!.text.trim();
      final value = field.parse(raw);
      if (value != null && (value is! String || value.isNotEmpty)) {
        values[field.key] = value;
      }
    }
    try {
      await widget.onSubmit(values);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = _errorMessage(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AssetsConfigurationStrings.of(context);
    final availableWidth = MediaQuery.sizeOf(context).width - 72;
    final width = math.max(280.0, math.min(680.0, availableWidth));
    final submitColor = widget.destructive
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
    return PopScope(
      canPop: !_submitting,
      child: AlertDialog(
        title: Text(widget.title),
        content: SizedBox(
          width: width,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final choice in widget.choices) ...[
                    DropdownButtonFormField<String>(
                      value: _choices[choice.key],
                      decoration: InputDecoration(labelText: choice.label),
                      items: [
                        for (final value in choice.values)
                          DropdownMenuItem(
                            value: value,
                            child: Text(choice.labelFor(value)),
                          ),
                      ],
                      onChanged: _submitting
                          ? null
                          : (value) => setState(() {
                                _choices[choice.key] =
                                    value ?? choice.initialValue;
                              }),
                    ),
                    const SizedBox(height: 16),
                  ],
                  for (final field in widget.fields) ...[
                    CommonTextInput(
                      label: field.label,
                      controller: _controllers[field.key],
                      type: field.type,
                      isMultiline: field.multiline,
                      hintText: field.hintText,
                      enabled: !_submitting,
                      validator: (value) {
                        final normalized = value?.trim() ?? '';
                        if (field.required && normalized.isEmpty) {
                          return strings.positiveQuantityError;
                        }
                        if (normalized.isEmpty) return null;
                        if (field.identifier && !_isIdentifier(normalized)) {
                          return strings.invalidIdentifier;
                        }
                        return field.validator?.call(normalized);
                      },
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _submitting ? null : () => Navigator.pop(context, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: submitColor),
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.submitLabel),
          ),
        ],
      ),
    );
  }
}

class _FieldSpec {
  const _FieldSpec({
    required this.key,
    required this.label,
    this.required = false,
    this.identifier = false,
    this.multiline = false,
    this.type = CommonTextInputType.text,
    this.hintText,
    this.initialValue = '',
    this.validator,
    this.parse = _identity,
  });

  final String key;
  final String label;
  final bool required;
  final bool identifier;
  final bool multiline;
  final CommonTextInputType type;
  final String? hintText;
  final String initialValue;
  final String? Function(String value)? validator;
  final Object? Function(String value) parse;
}

class _ChoiceSpec {
  const _ChoiceSpec({
    required this.key,
    required this.label,
    required this.initialValue,
    required this.values,
    required this.labelFor,
    this.parse = _identity,
  });

  final String key;
  final String label;
  final String initialValue;
  final List<String> values;
  final String Function(String value) labelFor;
  final Object? Function(String value) parse;
}

enum _LicenceAction { allocate, release }

_FieldSpec _requiredText(
  String key,
  String label,
  AssetsConfigurationStrings strings, {
  bool multiline = false,
  String initialValue = '',
}) {
  return _FieldSpec(
    key: key,
    label: label,
    required: true,
    multiline: multiline,
    initialValue: initialValue,
  );
}

const _assetLifecycleTransitions =
    <AssetLifecycleStatus, List<AssetLifecycleStatus>>{
  AssetLifecycleStatus.planned: [
    AssetLifecycleStatus.ordered,
  ],
  AssetLifecycleStatus.ordered: [
    AssetLifecycleStatus.received,
  ],
  AssetLifecycleStatus.received: [
    AssetLifecycleStatus.inStock,
    AssetLifecycleStatus.configured,
    AssetLifecycleStatus.inMaintenance,
  ],
  AssetLifecycleStatus.inStock: [
    AssetLifecycleStatus.configured,
    AssetLifecycleStatus.assigned,
    AssetLifecycleStatus.inMaintenance,
  ],
  AssetLifecycleStatus.configured: [
    AssetLifecycleStatus.assigned,
    AssetLifecycleStatus.inStock,
    AssetLifecycleStatus.inMaintenance,
  ],
  AssetLifecycleStatus.assigned: [
    AssetLifecycleStatus.inMaintenance,
    AssetLifecycleStatus.returned,
    AssetLifecycleStatus.lost,
    AssetLifecycleStatus.stolen,
  ],
  AssetLifecycleStatus.inMaintenance: [
    AssetLifecycleStatus.configured,
    AssetLifecycleStatus.assigned,
    AssetLifecycleStatus.returned,
  ],
  AssetLifecycleStatus.returned: [
    AssetLifecycleStatus.inStock,
    AssetLifecycleStatus.configured,
    AssetLifecycleStatus.inMaintenance,
  ],
  AssetLifecycleStatus.retired: [AssetLifecycleStatus.disposed],
  AssetLifecycleStatus.disposed: [],
  AssetLifecycleStatus.lost: [
    AssetLifecycleStatus.returned,
  ],
  AssetLifecycleStatus.stolen: [
    AssetLifecycleStatus.returned,
  ],
};

bool _isExceptionalAssetStatus(AssetLifecycleStatus status) =>
    status == AssetLifecycleStatus.lost ||
    status == AssetLifecycleStatus.stolen;

_FieldSpec _requiredId(
  String key,
  String label,
  AssetsConfigurationStrings strings, {
  String initialValue = '',
}) {
  return _FieldSpec(
    key: key,
    label: label,
    required: true,
    identifier: true,
    initialValue: initialValue,
  );
}

_FieldSpec _dateField(
  String key,
  String label,
  AssetsConfigurationStrings strings,
) {
  return _FieldSpec(
    key: key,
    label: label,
    type: CommonTextInputType.dateTime,
    hintText: strings.isoDateHint,
    validator: (value) => _isIsoDate(value) ? null : strings.invalidDate,
  );
}

_FieldSpec _requiredDateField(
  String key,
  String label,
  AssetsConfigurationStrings strings, {
  String initialValue = '',
}) {
  final optional = _dateField(key, label, strings);
  return _FieldSpec(
    key: optional.key,
    label: optional.label,
    required: true,
    type: optional.type,
    hintText: optional.hintText,
    initialValue: initialValue,
    validator: optional.validator,
  );
}

String _dateInitial(DateTime? value) {
  if (value == null) return '';
  final date = value.toLocal();
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String _identifierInitial(String? value) {
  final normalized = value?.trim() ?? '';
  return _isIdentifier(normalized) ? normalized : '';
}

Object? _commaSeparatedIds(String value) {
  final values = value
      .split(',')
      .map((entry) => entry.trim())
      .where((entry) => entry.isNotEmpty)
      .toList(growable: false);
  return values.isEmpty ? null : values;
}

String _ciTypeValue(String? value) {
  const values = {
    'service',
    'application',
    'server',
    'database',
    'network_device',
    'end_user_device',
  };
  return values.contains(value) ? value! : 'service';
}

String _operationalStatusValue(String? value) {
  const values = {'planned', 'active', 'degraded', 'maintenance', 'retired'};
  return values.contains(value) ? value! : 'active';
}

String _dataQualityValue(String? value) {
  const values = {'verified', 'needs_review', 'incomplete'};
  return values.contains(value) ? value! : 'needs_review';
}

_FieldSpec _positiveIntegerField(
  String key,
  String label,
  AssetsConfigurationStrings strings,
) {
  return _FieldSpec(
    key: key,
    label: label,
    required: true,
    type: CommonTextInputType.number,
    validator: (value) {
      final parsed = int.tryParse(value);
      return parsed != null && parsed > 0
          ? null
          : strings.positiveWholeNumberRequired;
    },
    parse: (value) => int.tryParse(value),
  );
}

Object? _identity(String value) => value;

Object? _optionalNumber(String value) {
  if (value.isEmpty) return null;
  return num.tryParse(value.replaceAll(',', '.'));
}

String? _optionalEmailValidator(
  String value,
  AssetsConfigurationStrings strings,
) {
  final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  return valid ? null : strings.invalidEmail;
}

bool _isIdentifier(String value) {
  return RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$').hasMatch(value);
}

bool _isIsoDate(String value) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return false;
  final parsed = DateTime.tryParse(value);
  return parsed != null && parsed.toIso8601String().startsWith(value);
}

String _errorMessage(Object error) {
  if (error is AssetsConfigurationAccessDenied) return error.message;
  return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
}
