'use strict';

const ORGANIZATION_SCHEMA_VERSION = 2;
const ORGANIZATION_STATUSES = Object.freeze(['ACTIVE', 'INACTIVE', 'ARCHIVED']);
const ORGANIZATION_UNIT_TYPES = Object.freeze([
  'DEPARTMENT',
  'SERVICE',
  'BUREAU',
  'CUSTOM',
]);
const ASSIGNMENT_TYPES = Object.freeze(['MEMBER', 'HEAD']);
const ASSIGNMENT_STATUSES = Object.freeze(['ACTIVE', 'ENDED', 'CANCELLED']);

const DEFAULT_PARENT_TYPES = Object.freeze({
  DEPARTMENT: null,
  SERVICE: 'DEPARTMENT',
  BUREAU: 'SERVICE',
});

class OrganizationDomainError extends Error {
  constructor(code, message) {
    super(message);
    this.name = 'OrganizationDomainError';
    this.code = code;
  }
}

function normalizeString(value) {
  return value === null || value === undefined ? '' : String(value).trim();
}

function normalizeCode(value) {
  return normalizeString(value)
    .toUpperCase()
    .replace(/[^A-Z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

function normalizeStatus(value, fallback = 'ACTIVE') {
  const status = normalizeString(value || fallback).toUpperCase();
  if (!ORGANIZATION_STATUSES.includes(status)) {
    throw new OrganizationDomainError(
      'invalid-argument',
      `Unsupported organization status: ${status || '(empty)'}.`,
    );
  }
  return status;
}

function normalizeUnitType(value) {
  const type = normalizeString(value).toUpperCase();
  if (!ORGANIZATION_UNIT_TYPES.includes(type)) {
    throw new OrganizationDomainError(
      'invalid-argument',
      `Unsupported organization unit type: ${type || '(empty)'}.`,
    );
  }
  return type;
}

function validateOrganizationInput(data) {
  const code = normalizeCode(data && data.code);
  const name = normalizeString(data && data.name);
  const description = normalizeString(data && data.description);
  if (!code) {
    throw new OrganizationDomainError(
      'invalid-argument',
      'Organization code is required.',
    );
  }
  if (!name) {
    throw new OrganizationDomainError(
      'invalid-argument',
      'Organization name is required.',
    );
  }
  if (code.length > 40 || name.length > 160 || description.length > 1000) {
    throw new OrganizationDomainError(
      'invalid-argument',
      'Organization fields exceed their supported length.',
    );
  }
  return { code, name, nameLower: name.toLowerCase(), description };
}

function validateUnitInput(data) {
  const organizationId = normalizeString(data && data.organizationId);
  const type = normalizeUnitType(data && data.type);
  const code = normalizeCode(data && data.code);
  const name = normalizeString(data && data.name);
  const description = normalizeString(data && data.description);
  const parentUnitId = normalizeString(data && data.parentUnitId) || null;
  if (!organizationId) {
    throw new OrganizationDomainError(
      'invalid-argument',
      'Select an organization.',
    );
  }
  if (!code || !name) {
    throw new OrganizationDomainError(
      'invalid-argument',
      'Unit code and name are required.',
    );
  }
  if (code.length > 40 || name.length > 160 || description.length > 1000) {
    throw new OrganizationDomainError(
      'invalid-argument',
      'Organization unit fields exceed their supported length.',
    );
  }
  return {
    organizationId,
    type,
    code,
    name,
    nameLower: name.toLowerCase(),
    description,
    parentUnitId,
  };
}

function assertOrganizationActive(organization) {
  if (!organization) {
    throw new OrganizationDomainError('not-found', 'Organization not found.');
  }
  if (normalizeStatus(organization.status) !== 'ACTIVE') {
    throw new OrganizationDomainError(
      'failed-precondition',
      'The selected organization is not active.',
    );
  }
}

function assertValidParent({ organization, unit, parent }) {
  assertOrganizationActive(organization);
  const expectedParentType = DEFAULT_PARENT_TYPES[unit.type];
  if (unit.type === 'CUSTOM') {
    if (!parent) {
      throw new OrganizationDomainError(
        'failed-precondition',
        'A custom unit requires a parent.',
      );
    }
  } else if (expectedParentType === null && parent) {
    throw new OrganizationDomainError(
      'failed-precondition',
      'A department must be a root organization unit.',
    );
  } else if (expectedParentType && !parent) {
    throw new OrganizationDomainError(
      'failed-precondition',
      `A ${unit.type.toLowerCase()} requires a ${expectedParentType.toLowerCase()} parent.`,
    );
  }

  if (!parent) return;
  if (normalizeString(parent.organizationId) !== unit.organizationId) {
    throw new OrganizationDomainError(
      'failed-precondition',
      'The parent unit belongs to a different organization.',
    );
  }
  if (normalizeStatus(parent.status) !== 'ACTIVE') {
    throw new OrganizationDomainError(
      'failed-precondition',
      'The parent organization unit is not active.',
    );
  }
  const parentType = normalizeUnitType(parent.type);
  if (expectedParentType && parentType !== expectedParentType) {
    throw new OrganizationDomainError(
      'failed-precondition',
      `A ${unit.type.toLowerCase()} must belong to a ${expectedParentType.toLowerCase()}.`,
    );
  }
}

function buildOrganizationUnitProjection({ unitId, organization, input, parent }) {
  const unit = validateUnitInput(input);
  const id = normalizeString(unitId);
  if (!id) {
    throw new OrganizationDomainError(
      'invalid-argument',
      'Organization unit ID is required.',
    );
  }
  if (normalizeString(organization.id) !== unit.organizationId) {
    throw new OrganizationDomainError(
      'failed-precondition',
      'The organization reference is inconsistent.',
    );
  }
  assertValidParent({ organization, unit, parent });

  const parentPathIds = parent ? normalizedStringArray(parent.pathUnitIds) : [];
  const parentPathNames = parent ? normalizedStringArray(parent.pathNames) : [];
  if (parent && parentPathIds[parentPathIds.length - 1] !== normalizeString(parent.id)) {
    throw new OrganizationDomainError(
      'failed-precondition',
      'The parent unit has an invalid authoritative path.',
    );
  }
  const pathUnitIds = [...parentPathIds, id];
  const pathNames = [...parentPathNames, unit.name];
  return {
    ...unit,
    parentUnitType: parent ? normalizeUnitType(parent.type) : null,
    ancestorUnitIds: parentPathIds,
    pathUnitIds,
    pathNames,
    depth: parentPathIds.length,
    scopeKeys: [
      `org:${unit.organizationId}`,
      ...pathUnitIds.map((pathId) => `unit:${pathId}`),
    ],
    status: 'ACTIVE',
    headUserId: null,
    headAssignmentId: null,
    schemaVersion: ORGANIZATION_SCHEMA_VERSION,
  };
}

function validateUnitPath({ organizationId, unit, pathUnits }) {
  const normalizedOrganizationId = normalizeString(organizationId);
  const unitId = normalizeString(unit && unit.id);
  const expectedPath = normalizedStringArray(unit && unit.pathUnitIds);
  if (!unitId || expectedPath.length === 0 || expectedPath.at(-1) !== unitId) {
    throw new OrganizationDomainError(
      'failed-precondition',
      'The selected unit has an invalid path.',
    );
  }
  if (pathUnits.length !== expectedPath.length) {
    throw new OrganizationDomainError(
      'failed-precondition',
      'The selected unit path is incomplete.',
    );
  }
  pathUnits.forEach((pathUnit, index) => {
    if (
      normalizeString(pathUnit.id) !== expectedPath[index] ||
      normalizeString(pathUnit.organizationId) !== normalizedOrganizationId ||
      normalizeStatus(pathUnit.status) !== 'ACTIVE'
    ) {
      throw new OrganizationDomainError(
        'failed-precondition',
        'The selected unit path is inconsistent or inactive.',
      );
    }
  });
}

function buildTypedPlacement(pathUnits) {
  const projection = {
    departmentId: '',
    department: '',
    serviceId: '',
    service: '',
    bureauId: '',
    bureau: '',
  };
  for (const unit of pathUnits) {
    const type = normalizeUnitType(unit.type);
    const key = type.toLowerCase();
    if (Object.hasOwn(projection, `${key}Id`)) {
      projection[`${key}Id`] = normalizeString(unit.id);
      projection[key] = normalizeString(unit.name);
    }
  }
  return projection;
}

function buildAgentOrganizationProjection({
  organization,
  unit,
  pathUnits,
  assignmentId,
}) {
  assertOrganizationActive(organization);
  validateUnitPath({
    organizationId: organization.id,
    unit,
    pathUnits,
  });
  const id = normalizeString(assignmentId);
  if (!id) {
    throw new OrganizationDomainError(
      'invalid-argument',
      'Primary assignment ID is required.',
    );
  }
  return {
    organizationSchemaVersion: ORGANIZATION_SCHEMA_VERSION,
    organizationId: normalizeString(organization.id),
    organizationName: normalizeString(organization.name),
    primaryOrganizationUnitId: normalizeString(unit.id),
    primaryOrganizationUnitName: normalizeString(unit.name),
    primaryOrganizationUnitType: normalizeUnitType(unit.type),
    primaryAssignmentId: id,
    organizationAncestorUnitIds: normalizedStringArray(unit.ancestorUnitIds),
    organizationPathUnitIds: normalizedStringArray(unit.pathUnitIds),
    organizationPathNames: normalizedStringArray(unit.pathNames),
    scopeKeys: normalizedStringArray(unit.scopeKeys),
    ...buildTypedPlacement(pathUnits),
  };
}

function buildAssignmentDocument({
  assignmentId,
  agentId,
  unit,
  assignmentType = 'MEMBER',
  isPrimary = true,
  isActing = false,
  startsAt,
  endsAt = null,
  reason,
  actorUid,
}) {
  const normalizedAssignmentType = normalizeString(assignmentType).toUpperCase();
  if (!ASSIGNMENT_TYPES.includes(normalizedAssignmentType)) {
    throw new OrganizationDomainError(
      'invalid-argument',
      'Unsupported organization assignment type.',
    );
  }
  const normalizedAgentId = normalizeString(agentId);
  const normalizedReason = normalizeString(reason);
  if (!normalizeString(assignmentId) || !normalizedAgentId || !startsAt) {
    throw new OrganizationDomainError(
      'invalid-argument',
      'Assignment, agent, and start date are required.',
    );
  }
  if (!normalizedReason) {
    throw new OrganizationDomainError(
      'invalid-argument',
      'An assignment reason is required.',
    );
  }
  if (normalizedAssignmentType === 'HEAD' && isActing && !endsAt) {
    throw new OrganizationDomainError(
      'invalid-argument',
      'An acting head assignment requires an end date.',
    );
  }
  if (
    normalizedAssignmentType === 'HEAD' &&
    isActing &&
    timestampMilliseconds(endsAt) <= timestampMilliseconds(startsAt)
  ) {
    throw new OrganizationDomainError(
      'invalid-argument',
      'An acting head assignment must end after it starts.',
    );
  }
  return {
    organizationId: normalizeString(unit.organizationId),
    agentId: normalizedAgentId,
    unitId: normalizeString(unit.id),
    unitType: normalizeUnitType(unit.type),
    unitName: normalizeString(unit.name),
    ancestorUnitIds: normalizedStringArray(unit.ancestorUnitIds),
    pathUnitIds: normalizedStringArray(unit.pathUnitIds),
    pathNames: normalizedStringArray(unit.pathNames),
    scopeKeys: normalizedStringArray(unit.scopeKeys),
    assignmentType: normalizedAssignmentType,
    isPrimary: isPrimary === true,
    isActing: isActing === true,
    status: 'ACTIVE',
    startsAt,
    endsAt,
    reason: normalizedReason,
    createdBy: normalizeString(actorUid),
    updatedBy: normalizeString(actorUid),
  };
}

function buildAgentDirectoryProjection({ agentId, agent, placement }) {
  const firstName = normalizeString(agent.firstName);
  const name = normalizeString(agent.name);
  const postName = normalizeString(agent.postName);
  const displayName = [firstName, name, postName].filter(Boolean).join(' ');
  if (!normalizeString(agentId) || !displayName || !normalizeString(agent.email)) {
    throw new OrganizationDomainError(
      'failed-precondition',
      'The private agent profile is incomplete.',
    );
  }
  return {
    displayName,
    displayNameLower: displayName.toLowerCase(),
    firstName,
    name,
    postName,
    email: normalizeString(agent.email).toLowerCase(),
    profilePictureUrl: normalizeString(agent.profilePictureUrl) || null,
    jobTitle: normalizeString(agent.jobTitle || agent.position),
    organizationId: placement.organizationId,
    organizationName: placement.organizationName,
    primaryOrganizationUnitId: placement.primaryOrganizationUnitId,
    primaryOrganizationUnitName: placement.primaryOrganizationUnitName,
    primaryOrganizationUnitType: placement.primaryOrganizationUnitType,
    departmentId: placement.departmentId || '',
    serviceId: placement.serviceId || '',
    bureauId: placement.bureauId || '',
    organizationPathNames: placement.organizationPathNames,
    scopeKeys: placement.scopeKeys,
    isActive: agent.isActive === true,
  };
}

function buildAgentAuthorizationProjection({ agent, placement }) {
  const permissions = agent.modulePermissions &&
    typeof agent.modulePermissions === 'object' &&
    !Array.isArray(agent.modulePermissions)
    ? agent.modulePermissions
    : {};
  const moduleRoleKeys = Object.entries(permissions)
    .map(([moduleKey, role]) => {
      const normalizedModuleKey = normalizeString(moduleKey).toLowerCase();
      const normalizedRole = normalizeString(role).toUpperCase();
      return normalizedModuleKey && normalizedRole && normalizedRole !== 'NONE'
        ? `${normalizedModuleKey}:${normalizedRole}`
        : '';
    })
    .filter(Boolean);
  const scopeRoleKeys = placement.scopeKeys.flatMap((scopeKey) =>
    moduleRoleKeys.map((roleKey) => `${scopeKey}|${roleKey}`));
  return {
    organizationId: placement.organizationId,
    primaryUnitId: placement.primaryOrganizationUnitId,
    scopeKeys: placement.scopeKeys,
    moduleRoleKeys,
    scopeRoleKeys,
    isActive: agent.isActive === true,
    schemaVersion: ORGANIZATION_SCHEMA_VERSION,
  };
}

function normalizedStringArray(value) {
  if (!Array.isArray(value)) return [];
  return value.map(normalizeString).filter(Boolean);
}

function timestampMilliseconds(value) {
  const date = value && typeof value.toDate === 'function'
    ? value.toDate()
    : value instanceof Date
      ? value
      : new Date(value);
  const milliseconds = date.getTime();
  if (Number.isNaN(milliseconds)) {
    throw new OrganizationDomainError(
      'invalid-argument',
      'Enter a valid assignment date.',
    );
  }
  return milliseconds;
}

module.exports = {
  ASSIGNMENT_STATUSES,
  ASSIGNMENT_TYPES,
  ORGANIZATION_SCHEMA_VERSION,
  ORGANIZATION_STATUSES,
  ORGANIZATION_UNIT_TYPES,
  OrganizationDomainError,
  assertOrganizationActive,
  assertValidParent,
  buildAgentDirectoryProjection,
  buildAgentAuthorizationProjection,
  buildAgentOrganizationProjection,
  buildAssignmentDocument,
  buildOrganizationUnitProjection,
  buildTypedPlacement,
  normalizeCode,
  normalizeStatus,
  normalizeString,
  normalizeUnitType,
  normalizedStringArray,
  validateOrganizationInput,
  validateUnitInput,
  validateUnitPath,
};
