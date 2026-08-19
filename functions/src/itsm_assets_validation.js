'use strict';

const {
  ITSM_ROLES,
  ItsmCommandError,
  normalizeString,
} = require('./itsm_permissions');

const ITSM_ASSETS_COMMANDS = Object.freeze({
  registerAsset: 'asset.register',
  updateAsset: 'asset.update',
  changeAssetState: 'asset.state.change',
  transitionAsset: 'asset.lifecycle.transition',
  assignAsset: 'asset.assign',
  returnAsset: 'asset.return',
  decommissionAsset: 'asset.decommission',
  saveAssetParameter: 'asset.parameter.save',
  saveStockLocation: 'stock.location.save',
  saveStockItem: 'stock.item.save',
  receiveStock: 'stock.receive',
  reserveStock: 'stock.reserve',
  issueStock: 'stock.issue',
  returnStock: 'stock.return',
  transferStock: 'stock.transfer',
  adjustStock: 'stock.adjust',
  reconcileStock: 'stock.reconcile',
  registerLicence: 'licence.register',
  allocateLicence: 'licence.allocate',
  releaseLicence: 'licence.release',
  saveSupplier: 'supplier.save',
  saveContract: 'contract.save',
  saveWarranty: 'warranty.save',
  recordWarrantyClaim: 'warranty.claim.record',
  transitionWarrantyClaim: 'warranty.claim.transition',
  saveConfigurationItem: 'cmdb.ci.save',
  createCiRelationship: 'cmdb.relationship.create',
  retireCiRelationship: 'cmdb.relationship.retire',
});

const MANAGER_ONLY = Object.freeze([ITSM_ROLES.manager]);
const ASSETS_COMMAND_ALLOWED_ROLES = Object.freeze(
  Object.fromEntries(
    Object.values(ITSM_ASSETS_COMMANDS).map((command) => [command, MANAGER_ONLY]),
  ),
);

const ASSET_LIFECYCLE_STATES = Object.freeze([
  'planned',
  'ordered',
  'received',
  'in_stock',
  'configured',
  'assigned',
  'in_maintenance',
  'returned',
  'retired',
  'disposed',
  'lost',
  'stolen',
]);
const STOCK_MOVEMENT_TYPES = Object.freeze([
  'receipt',
  'reservation',
  'issue',
  'return',
  'transfer',
  'adjustment',
  'reconciliation',
]);
const LICENCE_ASSIGNMENT_TYPES = Object.freeze(['user', 'device']);
const CLAIM_STATUSES = Object.freeze([
  'submitted',
  'acknowledged',
  'approved',
  'rejected',
  'resolved',
  'closed',
]);
const CI_OPERATIONAL_STATUSES = Object.freeze([
  'planned',
  'active',
  'degraded',
  'maintenance',
  'retired',
]);
const CI_DATA_QUALITY_STATUSES = Object.freeze([
  'verified',
  'needs_review',
  'incomplete',
]);
const CI_RELATIONSHIP_TYPES = Object.freeze([
  'depends_on',
  'runs_on',
  'connected_to',
  'uses',
  'represented_by',
]);

const ENVELOPE_FIELDS = new Set(['command', 'idempotencyKey', 'payload']);
const COMMON_RECORD_FIELDS = [
  'id',
  'expectedRevision',
  'name',
  'description',
  'isActive',
];
const PAYLOAD_FIELDS = Object.freeze({
  [ITSM_ASSETS_COMMANDS.registerAsset]: new Set([
    'assetId', 'assetTag', 'barcode', 'categoryId', 'categoryName', 'type',
    'brand', 'model', 'serialNumber', 'description', 'acquisitionDate',
    'acquisitionCost', 'currency', 'supplierId', 'warrantyId', 'status',
    'condition', 'siteId', 'locationId', 'locationName', 'stateId',
    'stateName', 'departmentId', 'stockLocationId', 'productNumber',
    'observation',
    'securityBaselineId', 'attachmentIds', 'photoAttachmentIds',
    'assignedUserId', 'assignedAt',
  ]),
  [ITSM_ASSETS_COMMANDS.updateAsset]: new Set([
    'assetId', 'expectedRevision', 'assetTag', 'barcode', 'categoryId',
    'categoryName', 'type', 'brand', 'model', 'serialNumber', 'description',
    'acquisitionDate', 'acquisitionCost', 'currency', 'supplierId',
    'warrantyId', 'condition', 'siteId', 'locationId', 'locationName',
    'stateId', 'stateName', 'departmentId', 'productNumber', 'observation',
    'stockLocationId', 'securityBaselineId', 'attachmentIds',
    'photoAttachmentIds',
  ]),
  [ITSM_ASSETS_COMMANDS.transitionAsset]: new Set([
    'assetId', 'expectedRevision', 'toStatus', 'reason', 'relatedRequestId',
    'locationId', 'stockLocationId', 'condition', 'evidence',
  ]),
  [ITSM_ASSETS_COMMANDS.changeAssetState]: new Set([
    'assetId', 'expectedRevision', 'stateId', 'stateName', 'observation',
  ]),
  [ITSM_ASSETS_COMMANDS.assignAsset]: new Set([
    'assetId', 'expectedRevision', 'assignedUserId', 'assignedUserName',
    'assignedUserEmail', 'departmentId', 'locationId', 'relatedRequestId',
    'assignedAt', 'evidence',
  ]),
  [ITSM_ASSETS_COMMANDS.returnAsset]: new Set([
    'assetId', 'expectedRevision', 'condition', 'locationId',
    'stockLocationId', 'reason', 'relatedRequestId', 'evidence',
  ]),
  [ITSM_ASSETS_COMMANDS.decommissionAsset]: new Set([
    'assetId', 'expectedRevision', 'observation',
  ]),
  [ITSM_ASSETS_COMMANDS.saveAssetParameter]: new Set([
    'id', 'expectedRevision', 'type', 'name', 'isActive', 'sortOrder',
  ]),
  [ITSM_ASSETS_COMMANDS.saveStockLocation]: new Set([
    'id', 'expectedRevision', 'name', 'description', 'siteId', 'siteName',
    'barcode', 'isActive',
  ]),
  [ITSM_ASSETS_COMMANDS.saveStockItem]: new Set([
    'id', 'expectedRevision', 'sku', 'name', 'description', 'kind', 'barcode',
    'assetCategoryId', 'unitOfMeasure', 'minimumQuantity', 'isActive',
  ]),
  [ITSM_ASSETS_COMMANDS.receiveStock]: stockFields([
    'destinationLocationId', 'recipientUserId', 'recipientName',
  ]),
  [ITSM_ASSETS_COMMANDS.reserveStock]: stockFields([
    'sourceLocationId', 'recipientUserId', 'recipientName',
  ]),
  [ITSM_ASSETS_COMMANDS.issueStock]: stockFields([
    'sourceLocationId', 'recipientUserId', 'recipientName',
    'reservedQuantity',
  ]),
  [ITSM_ASSETS_COMMANDS.returnStock]: stockFields([
    'destinationLocationId', 'recipientUserId', 'recipientName',
  ]),
  [ITSM_ASSETS_COMMANDS.transferStock]: stockFields([
    'sourceLocationId', 'destinationLocationId', 'recipientUserId',
    'recipientName',
  ]),
  [ITSM_ASSETS_COMMANDS.adjustStock]: stockFields([
    'sourceLocationId', 'adjustmentDelta',
  ]),
  [ITSM_ASSETS_COMMANDS.reconcileStock]: new Set([
    'stockItemId', 'sourceLocationId', 'targetOnHand', 'targetReserved',
    'reason', 'relatedRequestId', 'supportingDocument', 'evidence',
    'correlationId',
  ]),
  [ITSM_ASSETS_COMMANDS.registerLicence]: new Set([
    'licenceId', 'softwareProduct', 'vendor', 'licenceType',
    'purchasedQuantity', 'purchaseDate', 'effectiveDate', 'expiryDate',
    'renewalDate', 'contractId', 'cost', 'currency', 'complianceStatus',
  ]),
  [ITSM_ASSETS_COMMANDS.allocateLicence]: new Set([
    'licenceId', 'assignmentType', 'assigneeId', 'assigneeName',
    'quantity', 'relatedRequestId', 'notes',
  ]),
  [ITSM_ASSETS_COMMANDS.releaseLicence]: new Set([
    'licenceId', 'allocationId', 'reason', 'relatedRequestId',
  ]),
  [ITSM_ASSETS_COMMANDS.saveSupplier]: new Set([
    ...COMMON_RECORD_FIELDS, 'supplierCode', 'legalName', 'contactName',
    'contactEmail', 'contactPhone', 'address', 'assetCategoryIds',
    'supportTerms', 'slaSummary', 'attachmentIds',
  ]),
  [ITSM_ASSETS_COMMANDS.saveContract]: new Set([
    ...COMMON_RECORD_FIELDS, 'contractNumber', 'supplierId', 'startDate',
    'endDate', 'supportTerms', 'slaSummary', 'assetIds', 'attachmentIds',
    'renewalNoticeDate', 'status',
  ]),
  [ITSM_ASSETS_COMMANDS.saveWarranty]: new Set([
    ...COMMON_RECORD_FIELDS, 'warrantyNumber', 'supplierId', 'contractId',
    'coverage', 'startDate', 'expirationDate', 'assetIds', 'attachmentIds',
    'status',
  ]),
  [ITSM_ASSETS_COMMANDS.recordWarrantyClaim]: new Set([
    'warrantyId', 'claimId', 'assetId', 'title', 'description',
    'supportingDocument', 'evidence', 'relatedRequestId',
  ]),
  [ITSM_ASSETS_COMMANDS.transitionWarrantyClaim]: new Set([
    'warrantyId', 'claimId', 'expectedRevision', 'toStatus', 'reason',
    'evidence',
  ]),
  [ITSM_ASSETS_COMMANDS.saveConfigurationItem]: new Set([
    'ciId', 'expectedRevision', 'name', 'description', 'ciType', 'ownerUserId',
    'ownerName', 'supportGroupId', 'criticality', 'operationalStatus',
    'linkedAssetId', 'configurationBaseline', 'dataQualityStatus',
    'relatedIncidentIds', 'relatedRequestIds', 'relatedChangeIds',
    'relatedFindingIds',
  ]),
  [ITSM_ASSETS_COMMANDS.createCiRelationship]: new Set([
    'relationshipId', 'relationshipType', 'sourceEntityType',
    'sourceEntityId', 'targetEntityType', 'targetEntityId', 'description',
  ]),
  [ITSM_ASSETS_COMMANDS.retireCiRelationship]: new Set([
    'relationshipId', 'reason',
  ]),
});

function stockFields(extra) {
  return new Set([
    'stockItemId', 'quantity', 'reason', 'relatedRequestId',
    'supportingDocument', 'evidence', 'correlationId', ...extra,
  ]);
}

function validateAssetsCommand(input, expectedCommand) {
  if (!isPlainObject(input)) throw invalid('The assets command must be an object.');
  rejectUnknownFields(input, ENVELOPE_FIELDS, 'assets command');
  const command = normalizeString(input.command);
  if (!Object.values(ITSM_ASSETS_COMMANDS).includes(command)) {
    throw invalid(`Unknown assets command: ${command || '(empty)'}.`);
  }
  if (expectedCommand && command !== expectedCommand) {
    throw invalid(`The ${expectedCommand} endpoint cannot execute ${command}.`);
  }
  const idempotencyKey = normalizeString(input.idempotencyKey);
  if (!/^[A-Za-z0-9][A-Za-z0-9._:-]{7,127}$/.test(idempotencyKey)) {
    throw invalid('idempotencyKey must contain 8-128 safe characters.');
  }
  const payload = input.payload === undefined ? {} : input.payload;
  if (!isPlainObject(payload)) throw invalid('payload must be an object.');
  rejectUnknownFields(payload, PAYLOAD_FIELDS[command], `${command} payload`);
  return deepFreeze({
    command,
    idempotencyKey,
    payload: validatePayload(command, payload),
  });
}

function validatePayload(command, payload) {
  switch (command) {
    case ITSM_ASSETS_COMMANDS.registerAsset:
      return validateAsset(payload, false);
    case ITSM_ASSETS_COMMANDS.updateAsset:
      return validateAsset(payload, true);
    case ITSM_ASSETS_COMMANDS.changeAssetState:
      return {
        assetId: requireIdentifier(payload.assetId, 'assetId'),
        expectedRevision: requireNonNegativeInteger(
          payload.expectedRevision,
          'expectedRevision',
        ),
        stateId: requireIdentifier(payload.stateId, 'stateId'),
        stateName: requireText(payload.stateName, 'stateName', 240),
        observation: requireText(payload.observation, 'observation', 4000),
      };
    case ITSM_ASSETS_COMMANDS.transitionAsset:
      return {
        assetId: requireIdentifier(payload.assetId, 'assetId'),
        expectedRevision: requireNonNegativeInteger(
          payload.expectedRevision,
          'expectedRevision',
        ),
        toStatus: requireEnum(payload.toStatus, 'toStatus', ASSET_LIFECYCLE_STATES),
        reason: requireText(payload.reason, 'reason', 2000),
        relatedRequestId: optionalIdentifier(payload.relatedRequestId, 'relatedRequestId'),
        locationId: optionalIdentifier(payload.locationId, 'locationId'),
        stockLocationId: optionalIdentifier(payload.stockLocationId, 'stockLocationId'),
        condition: optionalText(payload.condition, 200),
        evidence: validateEvidence(payload.evidence),
      };
    case ITSM_ASSETS_COMMANDS.assignAsset:
      return {
        assetId: requireIdentifier(payload.assetId, 'assetId'),
        expectedRevision: requireNonNegativeInteger(payload.expectedRevision, 'expectedRevision'),
        assignedUserId: requireIdentifier(payload.assignedUserId, 'assignedUserId'),
        assignedUserName: optionalText(payload.assignedUserName, 240),
        assignedUserEmail: optionalEmail(payload.assignedUserEmail),
        departmentId: optionalIdentifier(payload.departmentId, 'departmentId'),
        locationId: optionalIdentifier(payload.locationId, 'locationId'),
        relatedRequestId: optionalIdentifier(payload.relatedRequestId, 'relatedRequestId'),
        assignedAt: optionalDateString(payload.assignedAt, 'assignedAt'),
        evidence: validateEvidence(payload.evidence),
      };
    case ITSM_ASSETS_COMMANDS.returnAsset:
      return {
        assetId: requireIdentifier(payload.assetId, 'assetId'),
        expectedRevision: requireNonNegativeInteger(payload.expectedRevision, 'expectedRevision'),
        condition: requireText(payload.condition, 'condition', 200),
        locationId: optionalIdentifier(payload.locationId, 'locationId'),
        stockLocationId: optionalIdentifier(payload.stockLocationId, 'stockLocationId'),
        reason: requireText(payload.reason, 'reason', 2000),
        relatedRequestId: optionalIdentifier(payload.relatedRequestId, 'relatedRequestId'),
        evidence: validateEvidence(payload.evidence),
      };
    case ITSM_ASSETS_COMMANDS.decommissionAsset:
      return {
        assetId: requireIdentifier(payload.assetId, 'assetId'),
        expectedRevision: requireNonNegativeInteger(
          payload.expectedRevision,
          'expectedRevision',
        ),
        observation: requireText(payload.observation, 'observation', 4000),
      };
    case ITSM_ASSETS_COMMANDS.saveAssetParameter:
      return validateAssetParameter(payload);
    case ITSM_ASSETS_COMMANDS.saveStockLocation:
      return validateStockLocation(payload);
    case ITSM_ASSETS_COMMANDS.saveStockItem:
      return validateStockItem(payload);
    case ITSM_ASSETS_COMMANDS.receiveStock:
    case ITSM_ASSETS_COMMANDS.reserveStock:
    case ITSM_ASSETS_COMMANDS.issueStock:
    case ITSM_ASSETS_COMMANDS.returnStock:
    case ITSM_ASSETS_COMMANDS.transferStock:
    case ITSM_ASSETS_COMMANDS.adjustStock:
      return validateStockMovement(command, payload);
    case ITSM_ASSETS_COMMANDS.reconcileStock:
      return validateReconciliation(payload);
    case ITSM_ASSETS_COMMANDS.registerLicence:
      return validateLicence(payload);
    case ITSM_ASSETS_COMMANDS.allocateLicence:
      return {
        licenceId: requireIdentifier(payload.licenceId, 'licenceId'),
        assignmentType: requireEnum(
          payload.assignmentType,
          'assignmentType',
          LICENCE_ASSIGNMENT_TYPES,
        ),
        assigneeId: requireIdentifier(payload.assigneeId, 'assigneeId'),
        assigneeName: requireText(payload.assigneeName, 'assigneeName', 240),
        quantity: requirePositiveInteger(payload.quantity, 'quantity'),
        relatedRequestId: optionalIdentifier(payload.relatedRequestId, 'relatedRequestId'),
        notes: optionalText(payload.notes, 2000),
      };
    case ITSM_ASSETS_COMMANDS.releaseLicence:
      return {
        licenceId: requireIdentifier(payload.licenceId, 'licenceId'),
        allocationId: requireIdentifier(payload.allocationId, 'allocationId'),
        reason: requireText(payload.reason, 'reason', 2000),
        relatedRequestId: optionalIdentifier(payload.relatedRequestId, 'relatedRequestId'),
      };
    case ITSM_ASSETS_COMMANDS.saveSupplier:
      return validateSupplier(payload);
    case ITSM_ASSETS_COMMANDS.saveContract:
      return validateContract(payload);
    case ITSM_ASSETS_COMMANDS.saveWarranty:
      return validateWarranty(payload);
    case ITSM_ASSETS_COMMANDS.recordWarrantyClaim:
      return validateClaim(payload);
    case ITSM_ASSETS_COMMANDS.transitionWarrantyClaim:
      return {
        warrantyId: requireIdentifier(payload.warrantyId, 'warrantyId'),
        claimId: requireIdentifier(payload.claimId, 'claimId'),
        expectedRevision: requireNonNegativeInteger(payload.expectedRevision, 'expectedRevision'),
        toStatus: requireEnum(payload.toStatus, 'toStatus', CLAIM_STATUSES),
        reason: requireText(payload.reason, 'reason', 2000),
        evidence: validateEvidence(payload.evidence),
      };
    case ITSM_ASSETS_COMMANDS.saveConfigurationItem:
      return validateConfigurationItem(payload);
    case ITSM_ASSETS_COMMANDS.createCiRelationship:
      return validateRelationship(payload);
    case ITSM_ASSETS_COMMANDS.retireCiRelationship:
      return {
        relationshipId: requireIdentifier(payload.relationshipId, 'relationshipId'),
        reason: requireText(payload.reason, 'reason', 2000),
      };
    default:
      throw invalid(`Unknown assets command: ${command}.`);
  }
}

function validateStockLocation(payload) {
  return {
    id: requireIdentifier(payload.id, 'id'),
    expectedRevision: optionalRevision(payload.expectedRevision),
    name: requireText(payload.name, 'name', 240),
    description: optionalText(payload.description, 2000),
    siteId: requireIdentifier(payload.siteId, 'siteId'),
    siteName: requireText(payload.siteName, 'siteName', 240),
    barcode: optionalText(payload.barcode, 200),
    isActive: optionalBoolean(payload.isActive, true, 'isActive'),
  };
}

function validateStockItem(payload) {
  const rawKind = normalizeString(payload.kind);
  if (!['serializedAsset', 'consumable'].includes(rawKind)) {
    throw invalid('kind must be one of: serializedAsset, consumable.');
  }
  return {
    id: requireIdentifier(payload.id, 'id'),
    expectedRevision: optionalRevision(payload.expectedRevision),
    sku: requireText(payload.sku, 'sku', 120),
    name: requireText(payload.name, 'name', 240),
    description: optionalText(payload.description, 2000),
    kind: rawKind,
    barcode: optionalText(payload.barcode, 200),
    assetCategoryId: optionalIdentifier(payload.assetCategoryId, 'assetCategoryId'),
    unitOfMeasure: requireText(payload.unitOfMeasure || 'unit', 'unitOfMeasure', 80),
    minimumQuantity: requireNonNegativeInteger(
      payload.minimumQuantity,
      'minimumQuantity',
    ),
    isActive: optionalBoolean(payload.isActive, true, 'isActive'),
  };
}

function validateAsset(payload, isUpdate) {
  const result = {
    assetId: requireIdentifier(payload.assetId, 'assetId'),
    expectedRevision: isUpdate
      ? requireNonNegativeInteger(payload.expectedRevision, 'expectedRevision')
      : 0,
    assetTag: isUpdate
      ? optionalText(payload.assetTag, 120)
      : requireText(payload.assetTag, 'assetTag', 120),
    barcode: optionalText(payload.barcode, 200),
    categoryId: isUpdate
      ? optionalIdentifier(payload.categoryId, 'categoryId')
      : requireIdentifier(payload.categoryId, 'categoryId'),
    categoryName: optionalText(payload.categoryName, 240),
    type: isUpdate
      ? optionalText(payload.type, 120)
      : requireText(payload.type, 'type', 120),
    brand: isUpdate
      ? optionalText(payload.brand, 120)
      : requireText(payload.brand, 'brand', 120),
    model: isUpdate
      ? optionalText(payload.model, 120)
      : requireText(payload.model, 'model', 120),
    serialNumber: isUpdate
      ? optionalText(payload.serialNumber, 200)
      : requireText(payload.serialNumber, 'serialNumber', 200),
    productNumber: optionalText(payload.productNumber, 200),
    description: optionalText(payload.description, 4000),
    observation: optionalText(payload.observation, 4000),
    acquisitionDate: isUpdate
      ? optionalDateString(payload.acquisitionDate, 'acquisitionDate')
      : requireDateString(payload.acquisitionDate, 'acquisitionDate'),
    acquisitionCost: optionalNonNegativeNumber(payload.acquisitionCost, 'acquisitionCost'),
    currency: optionalCurrency(payload.currency),
    supplierId: optionalIdentifier(payload.supplierId, 'supplierId'),
    warrantyId: optionalIdentifier(payload.warrantyId, 'warrantyId'),
    condition: optionalText(payload.condition, 200),
    siteId: optionalIdentifier(payload.siteId, 'siteId'),
    locationId: optionalIdentifier(payload.locationId, 'locationId'),
    locationName: optionalText(payload.locationName, 240),
    stateId: isUpdate
      ? optionalIdentifier(payload.stateId, 'stateId')
      : requireIdentifier(payload.stateId, 'stateId'),
    stateName: isUpdate
      ? optionalText(payload.stateName, 240)
      : requireText(payload.stateName, 'stateName', 240),
    departmentId: optionalIdentifier(payload.departmentId, 'departmentId'),
    stockLocationId: optionalIdentifier(payload.stockLocationId, 'stockLocationId'),
    securityBaselineId: optionalIdentifier(payload.securityBaselineId, 'securityBaselineId'),
    attachmentIds: validateIdentifierList(payload.attachmentIds, 'attachmentIds', 50),
    photoAttachmentIds: validateIdentifierList(
      payload.photoAttachmentIds,
      'photoAttachmentIds',
      50,
    ),
  };
  if (!isUpdate) {
    result.assignedUserId = optionalIdentifier(payload.assignedUserId, 'assignedUserId');
    result.assignedAt = optionalDateString(payload.assignedAt, 'assignedAt');
    if (result.assignedAt && !result.assignedUserId) {
      throw invalid('assignedAt requires assignedUserId.');
    }
    result.status = result.assignedUserId ? 'assigned' : 'in_stock';
  }
  return result;
}

function validateAssetParameter(payload) {
  return {
    id: optionalIdentifier(payload.id, 'id'),
    expectedRevision: optionalRevision(payload.expectedRevision),
    type: requireEnum(payload.type, 'type', ['category', 'location', 'state']),
    name: requireText(payload.name, 'name', 240),
    isActive: optionalBoolean(payload.isActive, true, 'isActive'),
    sortOrder: requireNonNegativeInteger(payload.sortOrder ?? 0, 'sortOrder'),
  };
}

function validateStockMovement(command, payload) {
  const result = {
    stockItemId: requireIdentifier(payload.stockItemId, 'stockItemId'),
    quantity: command === ITSM_ASSETS_COMMANDS.adjustStock
      ? Math.abs(requireNonZeroInteger(payload.adjustmentDelta, 'adjustmentDelta'))
      : requirePositiveInteger(payload.quantity, 'quantity'),
    sourceLocationId: optionalIdentifier(payload.sourceLocationId, 'sourceLocationId'),
    destinationLocationId: optionalIdentifier(
      payload.destinationLocationId,
      'destinationLocationId',
    ),
    recipientUserId: optionalIdentifier(payload.recipientUserId, 'recipientUserId'),
    recipientName: optionalText(payload.recipientName, 240),
    reason: requireText(payload.reason, 'reason', 2000),
    relatedRequestId: optionalIdentifier(payload.relatedRequestId, 'relatedRequestId'),
    supportingDocument: validateSupportingDocument(payload.supportingDocument),
    evidence: validateEvidence(payload.evidence),
    correlationId: optionalIdentifier(payload.correlationId, 'correlationId'),
    reservedQuantity: optionalNonNegativeInteger(payload.reservedQuantity, 'reservedQuantity'),
    adjustmentDelta: command === ITSM_ASSETS_COMMANDS.adjustStock
      ? requireNonZeroInteger(payload.adjustmentDelta, 'adjustmentDelta')
      : null,
  };
  requireStockLocations(command, result);
  if ([
    ITSM_ASSETS_COMMANDS.reserveStock,
    ITSM_ASSETS_COMMANDS.issueStock,
    ITSM_ASSETS_COMMANDS.returnStock,
  ].includes(command) && !result.recipientUserId) {
    throw invalid('recipientUserId is required for this stock movement.');
  }
  if (result.reservedQuantity > result.quantity) {
    throw invalid('reservedQuantity cannot exceed quantity.');
  }
  if ([ITSM_ASSETS_COMMANDS.adjustStock].includes(command) &&
      !result.supportingDocument) {
    throw invalid('A supportingDocument is required for stock adjustment.');
  }
  return result;
}

function validateReconciliation(payload) {
  const supportingDocument = validateSupportingDocument(payload.supportingDocument);
  if (!supportingDocument) {
    throw invalid('A supportingDocument is required for stock reconciliation.');
  }
  return {
    stockItemId: requireIdentifier(payload.stockItemId, 'stockItemId'),
    sourceLocationId: requireIdentifier(payload.sourceLocationId, 'sourceLocationId'),
    targetOnHand: requireNonNegativeInteger(payload.targetOnHand, 'targetOnHand'),
    targetReserved: requireNonNegativeInteger(payload.targetReserved, 'targetReserved'),
    reason: requireText(payload.reason, 'reason', 2000),
    relatedRequestId: optionalIdentifier(payload.relatedRequestId, 'relatedRequestId'),
    supportingDocument,
    evidence: validateEvidence(payload.evidence),
    correlationId: optionalIdentifier(payload.correlationId, 'correlationId'),
  };
}

function requireStockLocations(command, payload) {
  const sourceRequired = [
    ITSM_ASSETS_COMMANDS.reserveStock,
    ITSM_ASSETS_COMMANDS.issueStock,
    ITSM_ASSETS_COMMANDS.transferStock,
    ITSM_ASSETS_COMMANDS.adjustStock,
  ].includes(command);
  const destinationRequired = [
    ITSM_ASSETS_COMMANDS.receiveStock,
    ITSM_ASSETS_COMMANDS.returnStock,
    ITSM_ASSETS_COMMANDS.transferStock,
  ].includes(command);
  if (sourceRequired && !payload.sourceLocationId) {
    throw invalid('sourceLocationId is required for this stock movement.');
  }
  if (destinationRequired && !payload.destinationLocationId) {
    throw invalid('destinationLocationId is required for this stock movement.');
  }
  if (command === ITSM_ASSETS_COMMANDS.transferStock &&
      payload.sourceLocationId === payload.destinationLocationId) {
    throw invalid('Stock transfer source and destination must be different.');
  }
}

function validateLicence(payload) {
  return {
    licenceId: requireIdentifier(payload.licenceId, 'licenceId'),
    softwareProduct: requireText(payload.softwareProduct, 'softwareProduct', 240),
    vendor: requireText(payload.vendor, 'vendor', 240),
    licenceType: requireText(payload.licenceType, 'licenceType', 120),
    purchasedQuantity: requirePositiveInteger(payload.purchasedQuantity, 'purchasedQuantity'),
    purchaseDate: requireDateString(payload.purchaseDate, 'purchaseDate'),
    effectiveDate: requireDateString(payload.effectiveDate, 'effectiveDate'),
    expiryDate: optionalDateString(payload.expiryDate, 'expiryDate'),
    renewalDate: optionalDateString(payload.renewalDate, 'renewalDate'),
    contractId: optionalIdentifier(payload.contractId, 'contractId'),
    cost: optionalNonNegativeNumber(payload.cost, 'cost'),
    currency: optionalCurrency(payload.currency),
    complianceStatus: optionalText(payload.complianceStatus, 120),
  };
}

function validateSupplier(payload) {
  return {
    id: requireIdentifier(payload.id, 'id'),
    expectedRevision: optionalRevision(payload.expectedRevision),
    name: requireText(payload.name || payload.legalName, 'name', 240),
    legalName: optionalText(payload.legalName, 240),
    supplierCode: optionalText(payload.supplierCode, 120),
    description: optionalText(payload.description, 4000),
    contactName: optionalText(payload.contactName, 240),
    contactEmail: optionalEmail(payload.contactEmail),
    contactPhone: optionalText(payload.contactPhone, 80),
    address: optionalText(payload.address, 1000),
    assetCategoryIds: validateIdentifierList(payload.assetCategoryIds, 'assetCategoryIds', 100),
    supportTerms: optionalText(payload.supportTerms, 8000),
    slaSummary: optionalText(payload.slaSummary, 4000),
    attachmentIds: validateIdentifierList(payload.attachmentIds, 'attachmentIds', 50),
    isActive: payload.isActive !== false,
  };
}

function validateContract(payload) {
  return {
    id: requireIdentifier(payload.id, 'id'),
    expectedRevision: optionalRevision(payload.expectedRevision),
    name: requireText(payload.name, 'name', 240),
    description: optionalText(payload.description, 4000),
    contractNumber: requireText(payload.contractNumber, 'contractNumber', 160),
    supplierId: requireIdentifier(payload.supplierId, 'supplierId'),
    startDate: requireDateString(payload.startDate, 'startDate'),
    endDate: requireDateString(payload.endDate, 'endDate'),
    supportTerms: optionalText(payload.supportTerms, 8000),
    slaSummary: optionalText(payload.slaSummary, 4000),
    assetIds: validateIdentifierList(payload.assetIds, 'assetIds', 500),
    attachmentIds: validateIdentifierList(payload.attachmentIds, 'attachmentIds', 50),
    renewalNoticeDate: optionalDateString(payload.renewalNoticeDate, 'renewalNoticeDate'),
    status: optionalText(payload.status, 120),
    isActive: payload.isActive !== false,
  };
}

function validateWarranty(payload) {
  return {
    id: requireIdentifier(payload.id, 'id'),
    expectedRevision: optionalRevision(payload.expectedRevision),
    name: requireText(payload.name, 'name', 240),
    description: optionalText(payload.description, 4000),
    warrantyNumber: requireText(payload.warrantyNumber, 'warrantyNumber', 160),
    supplierId: requireIdentifier(payload.supplierId, 'supplierId'),
    contractId: optionalIdentifier(payload.contractId, 'contractId'),
    coverage: requireText(payload.coverage, 'coverage', 8000),
    startDate: requireDateString(payload.startDate, 'startDate'),
    expirationDate: requireDateString(payload.expirationDate, 'expirationDate'),
    assetIds: validateIdentifierList(payload.assetIds, 'assetIds', 500),
    attachmentIds: validateIdentifierList(payload.attachmentIds, 'attachmentIds', 50),
    status: optionalText(payload.status, 120),
    isActive: payload.isActive !== false,
  };
}

function validateClaim(payload) {
  return {
    warrantyId: requireIdentifier(payload.warrantyId, 'warrantyId'),
    claimId: requireIdentifier(payload.claimId, 'claimId'),
    assetId: requireIdentifier(payload.assetId, 'assetId'),
    title: requireText(payload.title, 'title', 240),
    description: requireText(payload.description, 'description', 8000),
    supportingDocument: validateSupportingDocument(payload.supportingDocument),
    evidence: validateEvidence(payload.evidence),
    relatedRequestId: optionalIdentifier(payload.relatedRequestId, 'relatedRequestId'),
  };
}

function validateConfigurationItem(payload) {
  return {
    ciId: requireIdentifier(payload.ciId, 'ciId'),
    expectedRevision: optionalRevision(payload.expectedRevision),
    name: requireText(payload.name, 'name', 240),
    description: optionalText(payload.description, 4000),
    ciType: requireText(payload.ciType, 'ciType', 120).toLowerCase(),
    ownerUserId: optionalIdentifier(payload.ownerUserId, 'ownerUserId'),
    ownerName: optionalText(payload.ownerName, 240),
    supportGroupId: optionalIdentifier(payload.supportGroupId, 'supportGroupId'),
    criticality: optionalText(payload.criticality, 120),
    operationalStatus: requireEnum(
      payload.operationalStatus || 'active',
      'operationalStatus',
      CI_OPERATIONAL_STATUSES,
    ),
    linkedAssetId: optionalIdentifier(payload.linkedAssetId, 'linkedAssetId'),
    configurationBaseline: validateSafeMap(payload.configurationBaseline, 'configurationBaseline'),
    dataQualityStatus: requireEnum(
      payload.dataQualityStatus || 'needs_review',
      'dataQualityStatus',
      CI_DATA_QUALITY_STATUSES,
    ),
    relatedIncidentIds: validateIdentifierList(payload.relatedIncidentIds, 'relatedIncidentIds', 200),
    relatedRequestIds: validateIdentifierList(payload.relatedRequestIds, 'relatedRequestIds', 200),
    relatedChangeIds: validateIdentifierList(payload.relatedChangeIds, 'relatedChangeIds', 200),
    relatedFindingIds: validateIdentifierList(payload.relatedFindingIds, 'relatedFindingIds', 200),
  };
}

function validateRelationship(payload) {
  return {
    relationshipId: requireIdentifier(payload.relationshipId, 'relationshipId'),
    relationshipType: requireEnum(
      payload.relationshipType,
      'relationshipType',
      CI_RELATIONSHIP_TYPES,
    ),
    sourceEntityType: requireEnum(
      payload.sourceEntityType,
      'sourceEntityType',
      ['configuration_item', 'asset', 'service', 'user'],
    ),
    sourceEntityId: requireIdentifier(payload.sourceEntityId, 'sourceEntityId'),
    targetEntityType: requireEnum(
      payload.targetEntityType,
      'targetEntityType',
      ['configuration_item', 'asset', 'service', 'user'],
    ),
    targetEntityId: requireIdentifier(payload.targetEntityId, 'targetEntityId'),
    description: optionalText(payload.description, 2000),
  };
}

function validateSupportingDocument(value) {
  if (value === undefined || value === null) return null;
  if (!isPlainObject(value)) throw invalid('supportingDocument must be an object.');
  rejectUnknownFields(
    value,
    new Set(['attachmentId', 'storagePath', 'fileName', 'contentType', 'sizeBytes', 'checksum']),
    'supportingDocument',
  );
  return {
    attachmentId: requireIdentifier(value.attachmentId, 'supportingDocument.attachmentId'),
    storagePath: requireStoragePath(value.storagePath),
    fileName: requireText(value.fileName, 'supportingDocument.fileName', 240),
    contentType: requireText(value.contentType, 'supportingDocument.contentType', 160),
    sizeBytes: requireNonNegativeInteger(value.sizeBytes, 'supportingDocument.sizeBytes'),
    checksum: optionalText(value.checksum, 256),
  };
}

function validateEvidence(value) {
  if (value === undefined || value === null) return [];
  if (!Array.isArray(value) || value.length > 20) {
    throw invalid('evidence must contain at most 20 metadata entries.');
  }
  return value.map((entry, index) => {
    if (!isPlainObject(entry)) throw invalid(`evidence[${index}] must be an object.`);
    rejectUnknownFields(
      entry,
      new Set(['attachmentId', 'storagePath', 'fileName', 'contentType', 'sizeBytes', 'checksum']),
      `evidence[${index}]`,
    );
    return {
      attachmentId: requireIdentifier(entry.attachmentId, `evidence[${index}].attachmentId`),
      storagePath: requireStoragePath(entry.storagePath),
      fileName: requireText(entry.fileName, `evidence[${index}].fileName`, 240),
      contentType: requireText(entry.contentType, `evidence[${index}].contentType`, 160),
      sizeBytes: requireNonNegativeInteger(entry.sizeBytes, `evidence[${index}].sizeBytes`),
      checksum: optionalText(entry.checksum, 256),
    };
  });
}

function validateSafeMap(value, field) {
  if (value === undefined || value === null) return {};
  if (!isPlainObject(value) || Object.keys(value).length > 100) {
    throw invalid(`${field} must be an object with at most 100 fields.`);
  }
  const blocked = /secret|password|credential|token|private.?key|licen[cs]e.?key/i;
  const output = {};
  for (const [key, entry] of Object.entries(value)) {
    if (blocked.test(key)) throw invalid(`${field} cannot contain secret fields.`);
    const safeKey = requireIdentifier(key, `${field} key`);
    if (!['string', 'number', 'boolean'].includes(typeof entry) && entry !== null) {
      throw invalid(`${field}.${safeKey} has an unsupported value type.`);
    }
    if (typeof entry === 'string' && entry.length > 2000) {
      throw invalid(`${field}.${safeKey} is too long.`);
    }
    output[safeKey] = typeof entry === 'string' ? entry.trim() : entry;
  }
  return output;
}

function validateIdentifierList(value, field, maximum) {
  if (value === undefined || value === null) return [];
  if (!Array.isArray(value) || value.length > maximum) {
    throw invalid(`${field} must contain at most ${maximum} identifiers.`);
  }
  return [...new Set(value.map((entry) => requireIdentifier(entry, field)))];
}

function requireIdentifier(value, field) {
  const identifier = normalizeString(value);
  if (!/^[A-Za-z0-9][A-Za-z0-9._:-]{0,199}$/.test(identifier)) {
    throw invalid(`${field} must be a safe identifier.`);
  }
  return identifier;
}

function optionalIdentifier(value, field) {
  const normalized = normalizeString(value);
  return normalized ? requireIdentifier(normalized, field) : '';
}

function requireText(value, field, maximum) {
  const text = normalizeString(value);
  if (!text || text.length > maximum) {
    throw invalid(`${field} must contain 1-${maximum} characters.`);
  }
  return text;
}

function optionalText(value, maximum) {
  const text = normalizeString(value);
  if (text.length > maximum) throw invalid(`Text cannot exceed ${maximum} characters.`);
  return text;
}

function requireEnum(value, field, allowed) {
  const normalized = normalizeString(value).toLowerCase();
  if (!allowed.includes(normalized)) {
    throw invalid(`${field} must be one of: ${allowed.join(', ')}.`);
  }
  return normalized;
}

function requirePositiveInteger(value, field) {
  const number = Number(value);
  if (!Number.isSafeInteger(number) || number < 1) {
    throw invalid(`${field} must be a positive integer.`);
  }
  return number;
}

function requireNonNegativeInteger(value, field) {
  const number = Number(value);
  if (!Number.isSafeInteger(number) || number < 0) {
    throw invalid(`${field} must be a non-negative integer.`);
  }
  return number;
}

function optionalNonNegativeInteger(value, field) {
  if (value === undefined || value === null || value === '') return 0;
  return requireNonNegativeInteger(value, field);
}

function requireNonZeroInteger(value, field) {
  const number = Number(value);
  if (!Number.isSafeInteger(number) || number === 0) {
    throw invalid(`${field} must be a non-zero integer.`);
  }
  return number;
}

function optionalRevision(value) {
  if (value === undefined || value === null || value === '') return null;
  return requireNonNegativeInteger(value, 'expectedRevision');
}

function optionalBoolean(value, fallback, field) {
  if (value === undefined || value === null) return fallback;
  if (typeof value !== 'boolean') throw invalid(`${field} must be a boolean.`);
  return value;
}

function optionalNonNegativeNumber(value, field) {
  if (value === undefined || value === null || value === '') return null;
  const number = Number(value);
  if (!Number.isFinite(number) || number < 0) {
    throw invalid(`${field} must be a non-negative number.`);
  }
  return number;
}

function optionalCurrency(value) {
  const currency = normalizeString(value).toUpperCase();
  if (currency && !/^[A-Z]{3}$/.test(currency)) {
    throw invalid('currency must be a three-letter ISO code.');
  }
  return currency;
}

function optionalEmail(value) {
  const email = normalizeString(value).toLowerCase();
  if (email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    throw invalid('email must be valid.');
  }
  return email;
}

function requireDateString(value, field) {
  const date = optionalDateString(value, field);
  if (!date) throw invalid(`${field} is required.`);
  return date;
}

function optionalDateString(value, field) {
  const text = normalizeString(value);
  if (!text) return '';
  const date = new Date(text);
  if (Number.isNaN(date.getTime())) throw invalid(`${field} must be a valid date.`);
  return date.toISOString();
}

function requireStoragePath(value) {
  const path = normalizeString(value);
  if (!/^itsm\/[A-Za-z0-9._/-]{1,900}$/.test(path) || path.includes('..')) {
    throw invalid('storagePath must be a safe ITSM Storage path.');
  }
  return path;
}

function rejectUnknownFields(value, allowed, label) {
  const unknown = Object.keys(value).filter((field) => !allowed.has(field));
  if (unknown.length > 0) {
    throw invalid(`${label} contains unsupported fields: ${unknown.join(', ')}.`);
  }
}

function isPlainObject(value) {
  return Boolean(value && typeof value === 'object' && !Array.isArray(value) &&
    Object.getPrototypeOf(value) === Object.prototype);
}

function deepFreeze(value) {
  if (!value || typeof value !== 'object' || Object.isFrozen(value)) return value;
  Object.freeze(value);
  Object.values(value).forEach(deepFreeze);
  return value;
}

function invalid(message) {
  return new ItsmCommandError('invalid-argument', message);
}

module.exports = {
  ASSET_LIFECYCLE_STATES,
  ASSETS_COMMAND_ALLOWED_ROLES,
  CI_RELATIONSHIP_TYPES,
  CLAIM_STATUSES,
  ITSM_ASSETS_COMMANDS,
  LICENCE_ASSIGNMENT_TYPES,
  STOCK_MOVEMENT_TYPES,
  validateAssetsCommand,
};
