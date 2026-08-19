import 'package:arptc_connect/generated/l10n.dart';
import 'package:flutter/widgets.dart';

import '../application/assets_configuration_contracts.dart';
import '../domain/asset_parameter.dart';

class AssetsConfigurationStrings {
  AssetsConfigurationStrings._(this._l10n);

  factory AssetsConfigurationStrings.of(BuildContext context) {
    return AssetsConfigurationStrings._(S.of(context));
  }

  final S _l10n;

  String get moduleTitle => _l10n.assetConfigurationOverview;
  String get moduleSubtitle => _l10n.assetConfigurationOverviewDescription;
  String get myAssets => _l10n.myAssets;
  String get myAssetsDescription => _l10n.myAssetsDescription;
  String get assetRegister => _l10n.assetRegister;
  String get assetRegisterDescription => _l10n.assetRegisterDescription;
  String get stock => _l10n.stockManagement;
  String get stockDescription => _l10n.stockManagementDescription;
  String get licences => _l10n.softwareLicences;
  String get licencesDescription => _l10n.softwareLicencesDescription;
  String get suppliersWarranties => _l10n.itsmSuppliersWarranties;
  String get suppliersWarrantiesDescription =>
      _l10n.suppliersWarrantiesDescription;
  String get cmdb => _l10n.configurationManagementDatabase;
  String get cmdbDescription => _l10n.cmdbDescription;
  String get searchAssets => _l10n.searchAssets;
  String get noAssets => _l10n.noAssetsFound;
  String get noAssignedAssets => _l10n.noAssetsAssigned;
  String get loading => _l10n.loading;
  String get retry => _l10n.retry;
  String get permissionDenied => _l10n.permissionDenied;
  String get permissionDeniedDescription =>
      _l10n.managerOperationalAccessRequired;
  String get unavailable => _l10n.unableToLoadAssets;
  String get operational => _l10n.operationalActions;
  String get selfService => _l10n.readOnlyAccess;
  String get noData => _l10n.noDataAvailable;
  String get noDataDescription => _l10n.noDataDescription;
  String get previous => _l10n.previous;
  String get next => _l10n.next;
  String get assetDetails => '${_l10n.assetRegister} • ${_l10n.assetId}';
  String get lifecycleHistory => _l10n.lifecycleHistory;
  String get attachments => _l10n.assetPhotographs;
  String get updateLifecycle => '${_l10n.update} ${_l10n.lifecycleHistory}';
  String get editAsset => _l10n.editAsset;
  String get assignAsset => _l10n.assignAsset;
  String get returnAsset => _l10n.returnAsset;
  String get confirm => _l10n.confirm;
  String get transitionAsset => _l10n.transitionAsset;
  String get assignedUserId => _l10n.assignedUserId;
  String get assignedAssetReturnHint => _l10n.assignedAssetReturnHint;
  String get exceptionalAssetReturnHint => _l10n.exceptionalAssetReturnHint;
  String get confirmExceptionalAssetStatus =>
      _l10n.confirmExceptionalAssetStatus;
  String get exceptionalAssetStatusWarning =>
      _l10n.exceptionalAssetStatusWarning;
  String get transitionReason => _l10n.transitionReason;
  String get lifecycleOperationCompleted => _l10n.lifecycleOperationCompleted;
  String get registerAsset => '${_l10n.add} ${_l10n.assetId}';
  String get stockItems => _l10n.stockItems;
  String get stockMovements => _l10n.stockMovements;
  String get recordMovement => '${_l10n.add} ${_l10n.stockMovements}';
  String get addStockLocation => _l10n.addStockLocation;
  String get editStockLocation => _l10n.editStockLocation;
  String get addStockItem => _l10n.addStockItem;
  String get editStockItem => _l10n.editStockItem;
  String get stockLocationId => _l10n.stockLocationId;
  String get stockItemId => _l10n.stockItemId;
  String get sku => _l10n.sku;
  String get unitOfMeasure => _l10n.unitOfMeasure;
  String get isConsumable => _l10n.isConsumable;
  String get adjustmentDirection => _l10n.adjustmentDirection;
  String get increaseStock => _l10n.increaseStock;
  String get decreaseStock => _l10n.decreaseStock;
  String get reservedQuantityFulfilled => _l10n.reservedQuantityFulfilled;
  String get targetOnHand => _l10n.targetOnHand;
  String get targetReserved => _l10n.targetReserved;
  String get movementReason => _l10n.movementReason;
  String get movementRequirementsHint => _l10n.movementRequirementsHint;
  String get sourceLocationRequired => _l10n.sourceLocationRequired;
  String get destinationLocationRequired => _l10n.destinationLocationRequired;
  String get recipientRequired => _l10n.recipientRequired;
  String get evidenceRequired => _l10n.evidenceRequired;
  String get nonNegativeNumberRequired => _l10n.nonNegativeNumberRequired;
  String get reservedQuantityTooHigh => _l10n.reservedQuantityTooHigh;
  String get lowStock => _l10n.lowStock;
  String get available => _l10n.available;
  String get allocation => _l10n.licenceAssignments;
  String get addLicence => '${_l10n.add} ${_l10n.softwareLicences}';
  String get addSupplier => '${_l10n.add} ${_l10n.supplier}';
  String get addContract => '${_l10n.add} ${_l10n.contracts}';
  String get addWarranty => '${_l10n.add} ${_l10n.warranty}';
  String get addConfigurationItem => '${_l10n.add} ${_l10n.configurationItem}';
  String get registerNewAsset => _l10n.registerNewAsset;
  String get assetParameters => _l10n.assetParameters;
  String get assetParametersDescription => _l10n.assetParametersDescription;
  String get addAssetParameter => _l10n.addAssetParameter;
  String get editAssetParameter => _l10n.editAssetParameter;
  String get assetParameterSortOrder => _l10n.assetParameterSortOrder;
  String get assetParameterLocations => _l10n.assetParameterLocations;
  String get assetParameterCategories => _l10n.assetParameterCategories;
  String get assetParameterStates => _l10n.assetParameterStates;
  String get addAssetLocation => _l10n.addAssetLocation;
  String get addAssetCategory => _l10n.addAssetCategory;
  String get addAssetState => _l10n.addAssetState;
  String get noAssetLocations => _l10n.noAssetLocations;
  String get noAssetCategories => _l10n.noAssetCategories;
  String get noAssetStates => _l10n.noAssetStates;
  String get deleteAssetParameterTitle => _l10n.deleteAssetParameterTitle;
  String get deleteAssetParameterMessage => _l10n.deleteAssetParameterMessage;
  String get assetParameterDeleted => _l10n.assetParameterDeleted;
  String get assetCommandServiceUnavailable =>
      _l10n.assetCommandServiceUnavailable;
  String get productNumber => _l10n.productNumber;
  String get observation => _l10n.observation;
  String get assignmentDate => _l10n.assignmentDate;
  String get assignmentHistory => _l10n.assignmentHistory;
  String get noAssignmentHistory => _l10n.noAssignmentHistory;
  String get currentAssignment => _l10n.currentAssignment;
  String get previousAssignment => _l10n.previousAssignment;
  String get changeAssetState => _l10n.changeAssetState;
  String get updateAssetStatus => _l10n.updateAssetStatus;
  String get updateAssetStatusDescription => _l10n.updateAssetStatusDescription;
  String get assetCondition => _l10n.assetCondition;
  String get assetConditionDescription => _l10n.assetConditionDescription;
  String get assetLifecycle => _l10n.assetLifecycle;
  String get assetLifecycleDescription => _l10n.assetLifecycleDescription;
  String get noAssetConditionUpdates => _l10n.noAssetConditionUpdates;
  String get noLifecycleTransitions => _l10n.noLifecycleTransitions;
  String get decommissionUnavailable => _l10n.decommissionUnavailable;
  String get newAssignment => _l10n.newAssignment;
  String get selectAgent => _l10n.selectAgent;
  String get searchAgents => _l10n.searchAgents;
  String get noActiveAgents => _l10n.noActiveAgents;
  String get requiredField => _l10n.requiredField;
  String get allAssetCategories => _l10n.allAssetCategories;
  String get allAssetBrands => _l10n.allAssetBrands;
  String get filterByAssetCategory => _l10n.filterByAssetCategory;
  String get filterByAssetBrand => _l10n.filterByAssetBrand;
  String get searchAssetSerialOrProduct => _l10n.searchAssetSerialOrProduct;
  String get configureAssetParametersFirst =>
      _l10n.configureAssetParametersFirst;
  String get assetRegisteredSuccessfully => _l10n.assetRegisteredSuccessfully;
  String get assetParameterSaved => _l10n.assetParameterSaved;
  String get assetAssignedSuccessfully => _l10n.assetAssignedSuccessfully;
  String get assetStateUpdated => _l10n.assetStateUpdated;
  String get stateHistory => _l10n.assetStateHistory;
  String get noStateHistory => _l10n.noAssetStateHistory;
  String get stateChangeObservation => _l10n.assetStateChangeObservation;
  String get decommissionAsset => _l10n.decommissionAsset;
  String get decommissionAssetConfirmation =>
      _l10n.decommissionAssetConfirmation;
  String get decommissionObservation => _l10n.decommissionObservation;
  String get assetDecommissionedSuccessfully =>
      _l10n.assetDecommissionedSuccessfully;
  String get assetAvailability => _l10n.assetAvailability;
  String get allAssetAvailability => _l10n.allAssetAvailability;
  String get filterByAssetAvailability => _l10n.filterByAssetAvailability;
  String get selectAssetCategory => _l10n.selectAssetCategory;
  String get selectAssetLocation => _l10n.selectAssetLocation;
  String get selectAssetState => _l10n.selectAssetState;
  String get optionalInitialAssignment => _l10n.optionalInitialAssignment;
  String get optionalInitialAssignmentHint =>
      _l10n.optionalInitialAssignmentHint;
  String get selectAgentFromResults => _l10n.selectAgentFromResults;
  String get deactivateAssetParameter => _l10n.deactivateAssetParameter;
  String get assetAssignmentRequiresReturn =>
      _l10n.assetAssignmentRequiresReturn;
  String get registerNewLicence => _l10n.registerNewLicence;
  String get allocateLicence => _l10n.allocateLicence;
  String get releaseLicence => _l10n.releaseLicence;
  String get saveSupplier => _l10n.saveSupplier;
  String get saveContract => _l10n.saveContract;
  String get saveWarranty => _l10n.saveWarranty;
  String get recordWarrantyClaim => _l10n.recordWarrantyClaim;
  String get editSupplier => _l10n.editSupplier;
  String get editContract => _l10n.editContract;
  String get editWarranty => _l10n.editWarranty;
  String get manageWarranty => _l10n.manageWarranty;
  String get transitionWarrantyClaim => _l10n.transitionWarrantyClaim;
  String get claimStatus => _l10n.claimStatus;
  String get claimResolution => _l10n.claimResolution;
  String get supplierContact => _l10n.supplierContact;
  String get saveConfigurationItem => _l10n.saveConfigurationItem;
  String get editConfigurationItem => _l10n.editConfigurationItem;
  String get relatedIncidentIds => _l10n.relatedIncidentIds;
  String get relatedRequestIds => _l10n.relatedRequestIds;
  String get relatedChangeIds => _l10n.relatedChangeIds;
  String get relatedFindingIds => _l10n.relatedFindingIds;
  String get commaSeparatedIdsHint => _l10n.commaSeparatedIdsHint;
  String get allRelationships => _l10n.allRelationships;
  String get showDependencies => _l10n.showDependencies;
  String get showImpact => _l10n.showImpact;
  String get createRelationship => _l10n.createRelationship;
  String get retireRelationship => _l10n.retireRelationship;
  String get configurationOperationCompleted =>
      _l10n.configurationOperationCompleted;
  String get recordIdentifier => _l10n.recordIdentifier;
  String get assetId => _l10n.assetId;
  String get categoryId => _l10n.categoryId;
  String get department => _l10n.department;
  String get supplierId => _l10n.supplierId;
  String get contractId => _l10n.contractId;
  String get warrantyId => _l10n.warrantyId;
  String get claimId => _l10n.claimId;
  String get allocationId => _l10n.allocationId;
  String get assigneeId => _l10n.assigneeId;
  String get assigneeName => _l10n.assigneeName;
  String get assignmentType => _l10n.assignmentType;
  String get contactName => _l10n.contactName;
  String get legalName => _l10n.legalName;
  String get contractNumber => _l10n.contractNumber;
  String get warrantyNumber => _l10n.warrantyNumber;
  String get relationshipType => _l10n.relationshipType;
  String get sourceType => _l10n.sourceType;
  String get sourceId => _l10n.sourceId;
  String get targetType => _l10n.targetType;
  String get targetId => _l10n.targetId;
  String get linkedAssetId => _l10n.linkedAssetId;
  String get ownerUserId => _l10n.ownerUserId;
  String get ownerName => _l10n.ownerName;
  String get title => _l10n.title;
  String get name => _l10n.name;
  String get description => _l10n.description;
  String get email => _l10n.email;
  String get phone => _l10n.phone;
  String get address => _l10n.address;
  String get reason => _l10n.reason;
  String get save => _l10n.save;
  String get select => _l10n.select;
  String get softwareProduct => _l10n.softwareProduct;
  String get vendor => _l10n.vendor;
  String get licenceType => _l10n.licenceType;
  String get purchasedQuantity => _l10n.purchasedQuantity;
  String get effectiveDate => _l10n.effectiveDate;
  String get renewalDate => _l10n.renewalDate;
  String get acquisitionDate => _l10n.acquisitionDate;
  String get acquisitionCost => _l10n.acquisitionCost;
  String get currency => _l10n.currency;
  String get warrantyCoverage => _l10n.warrantyCoverage;
  String get supportTerms => _l10n.supportTerms;
  String get contractStart => _l10n.contractStart;
  String get contractEnd => _l10n.contractEnd;
  String get warrantyExpiration => _l10n.warrantyExpiration;
  String get ciType => _l10n.ciType;
  String get ciOwner => _l10n.ciOwner;
  String get supportGroup => _l10n.supportGroup;
  String get criticality => _l10n.criticality;
  String get operationalStatus => _l10n.operationalStatus;
  String get dataQualityStatus => _l10n.dataQualityStatus;
  String get invalidIdentifier => _l10n.invalidIdentifier;
  String get invalidDate => _l10n.invalidDate;
  String get invalidEmail => _l10n.invalidEmail;
  String get positiveWholeNumberRequired => _l10n.positiveWholeNumberRequired;
  String get isoDateHint => _l10n.isoDateHint;
  String get dependencies => _l10n.dependencyView;
  String get relationships => _l10n.relationships;
  String get relatedRecords => _l10n.relationships;
  String get reportFault => _l10n.reportAssetFault;
  String get requestRepair => _l10n.requestAssetRepair;
  String get requestReplacement => _l10n.requestAssetReplacement;
  String get requestConfiguration => _l10n.requestAssetConfiguration;
  String get requestReturn => _l10n.requestAssetReturn;
  String get requestSupport => _l10n.createServiceRequest;
  String get requestActionDescription => _l10n.assetActionCreatesRequest;
  String get noAttachments => _l10n.noDataAvailable;
  String get uploadAttachment => _l10n.uploadAssetAttachment;
  String get uploadPhotograph => _l10n.uploadAssetPhotograph;
  String get uploadSuccessful => _l10n.attachmentRegistrationSuccessful;
  String get uploading => _l10n.uploading;
  String get noLifecycle => _l10n.noDataAvailable;
  String get cancel => _l10n.cancel;
  String get delete => _l10n.delete;
  String get quantity => _l10n.quantity;
  String get positiveQuantityError => _l10n.requiredField;
  String get sourceLocation => _l10n.sourceLocation;
  String get destinationLocation => _l10n.destinationLocation;
  String get recipient => _l10n.recipient;
  String get recipientUserId => _l10n.recipientUserId;
  String get relatedRequest => _l10n.relatedRequest;
  String get supportingDocument => _l10n.supportingDocument;
  String get chooseSupportingDocument => _l10n.chooseSupportingDocument;
  String get scanBarcode => _l10n.scanStockBarcode;
  String get scanBarcodeHint => _l10n.scanStockBarcodeHint;
  String get barcodeNotFound => _l10n.barcodeNotFound;
  String get movementTypeLabel => _l10n.movementType;
  String get trackedQuantity => _l10n.quantityOnHand;
  String get suppliers => _l10n.supplierRegister;
  String get contracts => _l10n.contracts;
  String get warranties => _l10n.warranty;
  String get searchConfigurationItems =>
      '${_l10n.search} ${_l10n.configurationItems}';
  String get upstream => _l10n.dependsOn;
  String get downstream => _l10n.impactView;
  String get incidents => _l10n.itsmIncidents;
  String get requests => _l10n.itsmServiceRequests;
  String get changes => _l10n.itsmChangeRequests;
  String get findings => _l10n.itsmSecurityFindings;
  String get noRelationships => _l10n.noDataAvailable;
  String get assetTag => _l10n.assetTag;
  String get brand => _l10n.brand;
  String get model => _l10n.model;
  String get serialNumber => _l10n.serialNumber;
  String get category => _l10n.category;
  String get type => _l10n.type;
  String get location => _l10n.location;
  String get custodian => _l10n.custodian;
  String get condition => _l10n.condition;
  String get compliance => _l10n.complianceStatus;
  String get status => _l10n.status;
  String get expires => _l10n.expiryDate;
  String get linkedAssets => _l10n.relatedAsset;
  String get active => _l10n.active;
  String get pending => _l10n.pending;
  String get yes => _l10n.yes;
  String get no => _l10n.no;
  String get error => _l10n.error;

  String movementType(StockMovementType type) {
    return switch (type) {
      StockMovementType.receipt => _l10n.movementReceipt,
      StockMovementType.reservation => _l10n.movementReservation,
      StockMovementType.issue => _l10n.movementIssue,
      StockMovementType.returnToStock => _l10n.movementReturn,
      StockMovementType.transfer => _l10n.movementTransfer,
      StockMovementType.adjustment => _l10n.movementAdjustment,
      StockMovementType.reconciliation => _l10n.movementReconciliation,
    };
  }

  String lifecycleStatus(AssetLifecycleStatus status) => switch (status) {
        AssetLifecycleStatus.planned => _l10n.statusPlanned,
        AssetLifecycleStatus.ordered => _l10n.assetStatusOrdered,
        AssetLifecycleStatus.received => _l10n.assetStatusReceived,
        AssetLifecycleStatus.inStock => _l10n.assetStatusInStock,
        AssetLifecycleStatus.configured => _l10n.assetStatusConfigured,
        AssetLifecycleStatus.assigned => _l10n.assetStatusAssigned,
        AssetLifecycleStatus.inMaintenance => _l10n.statusMaintenance,
        AssetLifecycleStatus.returned => _l10n.assetStatusReturned,
        AssetLifecycleStatus.retired => _l10n.statusRetired,
        AssetLifecycleStatus.disposed => _l10n.assetStatusDisposed,
        AssetLifecycleStatus.lost => _l10n.assetStatusLost,
        AssetLifecycleStatus.stolen => _l10n.assetStatusStolen,
      };

  String assetAvailabilityName(AssetAvailability availability) =>
      switch (availability) {
        AssetAvailability.inStock => _l10n.assetStatusInStock,
        AssetAvailability.assigned => _l10n.assetStatusAssigned,
        AssetAvailability.decommissioned =>
          _l10n.assetAvailabilityDecommissioned,
        AssetAvailability.unavailable => _l10n.assetAvailabilityUnavailable,
      };

  String assetParameterType(AssetParameterType type) => switch (type) {
        AssetParameterType.category => _l10n.assetParameterCategory,
        AssetParameterType.location => _l10n.assetParameterLocation,
        AssetParameterType.state => _l10n.assetParameterState,
      };

  String complianceState(ComplianceState state) => state.name;

  String contractState(ContractState state) => switch (state) {
        ContractState.active => _l10n.active,
        ContractState.draft => _l10n.draft,
        ContractState.expired => _l10n.expiryDate,
        ContractState.terminated => _l10n.inactive,
      };

  String assignmentTypeName(String value) => switch (value) {
        'device' => _l10n.assignmentDevice,
        _ => _l10n.assignmentUser,
      };

  String ciTypeName(String value) => switch (value) {
        'application' => _l10n.ciApplication,
        'server' => _l10n.ciServer,
        'database' => _l10n.ciDatabase,
        'network_device' => _l10n.ciNetwork,
        'end_user_device' => _l10n.ciDevice,
        _ => _l10n.ciService,
      };

  String operationalStatusName(String value) => switch (value) {
        'planned' => _l10n.statusPlanned,
        'degraded' => _l10n.statusDegraded,
        'maintenance' => _l10n.statusMaintenance,
        'retired' => _l10n.statusRetired,
        _ => _l10n.active,
      };

  String dataQualityName(String value) => switch (value) {
        'verified' => _l10n.dataQualityVerified,
        'incomplete' => _l10n.dataQualityIncomplete,
        _ => _l10n.dataQualityNeedsReview,
      };

  String relationshipTypeName(String value) => switch (value) {
        'runs_on' => _l10n.runsOn,
        'connected_to' => _l10n.connectedTo,
        'uses' => _l10n.uses,
        'represented_by' => _l10n.representedBy,
        _ => _l10n.dependsOn,
      };

  String entityTypeName(String value) => switch (value) {
        'asset' => _l10n.relatedAsset,
        'service' => _l10n.services,
        'user' => _l10n.users,
        _ => _l10n.configurationItem,
      };

  String claimStatusName(String value) => switch (value) {
        'acknowledged' => _l10n.claimAcknowledged,
        'approved' => _l10n.claimApproved,
        'rejected' => _l10n.claimRejected,
        'resolved' => _l10n.claimResolved,
        'closed' => _l10n.claimClosed,
        _ => _l10n.claimSubmitted,
      };
}
