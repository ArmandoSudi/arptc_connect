'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');

const {
  buildAgentAuthorizationProjection,
  buildAgentDirectoryProjection,
  buildAgentOrganizationProjection,
  buildAssignmentDocument,
  buildOrganizationUnitProjection,
  normalizeCode,
  validateOrganizationInput,
} = require('../src/organization_domain');

const organization = {
  id: 'org-arptc',
  name: 'ARPTC',
  status: 'ACTIVE',
};

test('normalizes and validates organization metadata', () => {
  assert.equal(normalizeCode(' arptc connect '), 'ARPTC-CONNECT');
  assert.deepEqual(validateOrganizationInput({
    code: ' arptc ',
    name: ' ARPTC ',
    description: ' Authority ',
  }), {
    code: 'ARPTC',
    name: 'ARPTC',
    nameLower: 'arptc',
    description: 'Authority',
  });
});

test('builds a server-owned Department -> Service -> Bureau path', () => {
  const department = withId('department-it', buildOrganizationUnitProjection({
    unitId: 'department-it',
    organization,
    input: {
      organizationId: organization.id,
      type: 'DEPARTMENT',
      code: 'D-IT',
      name: 'Information Technology',
    },
    parent: null,
  }));
  const service = withId('service-operations', buildOrganizationUnitProjection({
    unitId: 'service-operations',
    organization,
    input: {
      organizationId: organization.id,
      type: 'SERVICE',
      code: 'S-OPS',
      name: 'IT Operations',
      parentUnitId: department.id,
    },
    parent: department,
  }));
  const bureau = withId('bureau-helpdesk', buildOrganizationUnitProjection({
    unitId: 'bureau-helpdesk',
    organization,
    input: {
      organizationId: organization.id,
      type: 'BUREAU',
      code: 'B-HD',
      name: 'Help Desk',
      parentUnitId: service.id,
    },
    parent: service,
  }));

  assert.deepEqual(bureau.ancestorUnitIds, [department.id, service.id]);
  assert.deepEqual(bureau.pathUnitIds, [department.id, service.id, bureau.id]);
  assert.deepEqual(bureau.pathNames, [
    'Information Technology',
    'IT Operations',
    'Help Desk',
  ]);
  assert.equal(bureau.depth, 2);
  assert.deepEqual(bureau.scopeKeys, [
    'org:org-arptc',
    'unit:department-it',
    'unit:service-operations',
    'unit:bureau-helpdesk',
  ]);
});

test('rejects invalid, skipped, and cross-organization parents', () => {
  const department = {
    id: 'department-it',
    organizationId: organization.id,
    type: 'DEPARTMENT',
    status: 'ACTIVE',
    pathUnitIds: ['department-it'],
    pathNames: ['IT'],
  };
  assert.throws(
    () => buildOrganizationUnitProjection({
      unitId: 'bureau-helpdesk',
      organization,
      input: {
        organizationId: organization.id,
        type: 'BUREAU',
        code: 'B-HD',
        name: 'Help Desk',
        parentUnitId: department.id,
      },
      parent: department,
    }),
    (error) => error.code === 'failed-precondition' &&
      error.message.includes('service'),
  );
  assert.throws(
    () => buildOrganizationUnitProjection({
      unitId: 'service-it',
      organization,
      input: {
        organizationId: organization.id,
        type: 'SERVICE',
        code: 'S-IT',
        name: 'IT',
        parentUnitId: department.id,
      },
      parent: { ...department, organizationId: 'org-other' },
    }),
    (error) => error.code === 'failed-precondition' &&
      error.message.includes('different organization'),
  );
});

test('builds an immutable assignment snapshot and agent projections', () => {
  const pathUnits = [
    activeUnit('department-it', 'DEPARTMENT', 'Information Technology', [
      'department-it',
    ]),
    activeUnit('service-operations', 'SERVICE', 'IT Operations', [
      'department-it',
      'service-operations',
    ]),
    activeUnit('bureau-helpdesk', 'BUREAU', 'Help Desk', [
      'department-it',
      'service-operations',
      'bureau-helpdesk',
    ]),
  ];
  const unit = {
    ...pathUnits.at(-1),
    ancestorUnitIds: ['department-it', 'service-operations'],
    pathNames: pathUnits.map((entry) => entry.name),
    scopeKeys: [
      'org:org-arptc',
      'unit:department-it',
      'unit:service-operations',
      'unit:bureau-helpdesk',
    ],
  };
  const startsAt = new Date('2026-08-11T00:00:00.000Z');
  const assignment = buildAssignmentDocument({
    assignmentId: 'assignment-1',
    agentId: 'uid-1',
    unit,
    startsAt,
    reason: 'Initial placement',
    actorUid: 'manager-1',
  });
  const placement = buildAgentOrganizationProjection({
    organization,
    unit,
    pathUnits,
    assignmentId: 'assignment-1',
  });
  const directory = buildAgentDirectoryProjection({
    agentId: 'uid-1',
    agent: {
      firstName: 'Aline',
      name: 'Mbuyi',
      postName: 'Kanku',
      email: 'ALINE@ARPTC.CD',
      jobTitle: 'Support analyst',
      isActive: true,
    },
    placement,
  });
  const authorization = buildAgentAuthorizationProjection({
    agent: {
      isActive: true,
      modulePermissions: {
        ticketing: 'MANAGER',
        news: 'NONE',
      },
    },
    placement,
  });

  assert.equal(assignment.status, 'ACTIVE');
  assert.equal(assignment.unitName, 'Help Desk');
  assert.equal(placement.departmentId, 'department-it');
  assert.equal(placement.serviceId, 'service-operations');
  assert.equal(placement.bureauId, 'bureau-helpdesk');
  assert.equal(directory.displayName, 'Aline Mbuyi Kanku');
  assert.equal(directory.email, 'aline@arptc.cd');
  assert.equal(directory.primaryOrganizationUnitId, 'bureau-helpdesk');
  assert.equal(directory.matricule, undefined);
  assert.equal(directory.modulePermissions, undefined);
  assert.deepEqual(authorization.moduleRoleKeys, ['ticketing:MANAGER']);
  assert.ok(authorization.scopeRoleKeys.includes(
    'unit:department-it|ticketing:MANAGER',
  ));
});

test('requires an end date for acting leadership', () => {
  const unit = {
    ...activeUnit('bureau-helpdesk', 'BUREAU', 'Help Desk', [
      'department-it',
      'service-operations',
      'bureau-helpdesk',
    ]),
    ancestorUnitIds: ['department-it', 'service-operations'],
    pathNames: ['IT', 'Operations', 'Help Desk'],
    scopeKeys: ['org:org-arptc', 'unit:bureau-helpdesk'],
  };
  assert.throws(
    () => buildAssignmentDocument({
      assignmentId: 'head-1',
      agentId: 'uid-1',
      unit,
      assignmentType: 'HEAD',
      isPrimary: false,
      isActing: true,
      startsAt: new Date(),
      reason: 'Acting appointment',
      actorUid: 'manager-1',
    }),
    (error) => error.code === 'invalid-argument' &&
      error.message.includes('end date'),
  );
});

function withId(id, data) {
  return { id, ...data };
}

function activeUnit(id, type, name, pathUnitIds) {
  return {
    id,
    organizationId: organization.id,
    type,
    name,
    status: 'ACTIVE',
    pathUnitIds,
  };
}
