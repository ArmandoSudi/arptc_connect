const fs = require('node:fs');
const path = require('node:path');
const { test } = require('node:test');
const assert = require('node:assert/strict');

const indexConfiguration = JSON.parse(fs.readFileSync(
  path.resolve(__dirname, '../../firestore.indexes.json'),
  'utf8',
));

const organizationCollections = new Set([
  'organizations',
  'organizationDirectory',
  'organizationUnits',
  'organizationAssignments',
  'agentDirectory',
  'agentAuthorizationIndex',
  'organizationAuditEvents',
]);

const requiredSignatures = [
  'organizations|status:ASCENDING,nameLower:ASCENDING,__name__:ASCENDING',
  'organizationDirectory|status:ASCENDING,nameLower:ASCENDING,' +
    '__name__:ASCENDING',
  'organizationUnits|organizationId:ASCENDING,nameLower:ASCENDING,' +
    '__name__:ASCENDING',
  'organizationUnits|organizationId:ASCENDING,status:ASCENDING,' +
    'nameLower:ASCENDING,__name__:ASCENDING',
  'organizationUnits|organizationId:ASCENDING,status:ASCENDING,' +
    'parentUnitId:ASCENDING,nameLower:ASCENDING,__name__:ASCENDING',
  'organizationUnits|organizationId:ASCENDING,type:ASCENDING,' +
    'nameLower:ASCENDING,__name__:ASCENDING',
  'organizationUnits|organizationId:ASCENDING,type:ASCENDING,' +
    'status:ASCENDING,nameLower:ASCENDING,__name__:ASCENDING',
  'organizationAssignments|agentId:ASCENDING,startsAt:DESCENDING,' +
    '__name__:DESCENDING',
  'organizationAssignments|organizationId:ASCENDING,agentId:ASCENDING,' +
    'startsAt:DESCENDING,__name__:DESCENDING',
  'organizationAssignments|agentId:ASCENDING,status:ASCENDING,' +
    'startsAt:DESCENDING,__name__:DESCENDING',
  'organizationAssignments|organizationId:ASCENDING,agentId:ASCENDING,' +
    'assignmentType:ASCENDING,status:ASCENDING,__name__:ASCENDING',
  'organizationAssignments|unitId:ASCENDING,startsAt:DESCENDING,' +
    '__name__:DESCENDING',
  'organizationAssignments|organizationId:ASCENDING,unitId:ASCENDING,' +
    'startsAt:DESCENDING,__name__:DESCENDING',
  'organizationAssignments|unitId:ASCENDING,status:ASCENDING,' +
    'assignmentType:ASCENDING,startsAt:DESCENDING,__name__:DESCENDING',
  'organizationAssignments|pathUnitIds:CONTAINS,status:ASCENDING,' +
    '__name__:ASCENDING',
  'organizationAssignments|assignmentType:ASCENDING,isActing:ASCENDING,' +
    'status:ASCENDING,endsAt:ASCENDING,__name__:ASCENDING',
  'agentDirectory|organizationId:ASCENDING,displayNameLower:ASCENDING,' +
    '__name__:ASCENDING',
  'agentDirectory|organizationId:ASCENDING,isActive:ASCENDING,' +
    'displayNameLower:ASCENDING,__name__:ASCENDING',
  'agentDirectory|organizationId:ASCENDING,scopeKeys:CONTAINS,' +
    'displayNameLower:ASCENDING,__name__:ASCENDING',
  'agentDirectory|organizationId:ASCENDING,scopeKeys:CONTAINS,' +
    'isActive:ASCENDING,displayNameLower:ASCENDING,__name__:ASCENDING',
  'agentDirectory|scopeKeys:CONTAINS,isActive:ASCENDING,' +
    'displayNameLower:ASCENDING,__name__:ASCENDING',
  'agentAuthorizationIndex|organizationId:ASCENDING,isActive:ASCENDING,' +
    'scopeKeys:CONTAINS,__name__:ASCENDING',
  'agentAuthorizationIndex|organizationId:ASCENDING,isActive:ASCENDING,' +
    'scopeRoleKeys:CONTAINS,__name__:ASCENDING',
  'organizationAuditEvents|organizationId:ASCENDING,createdAt:DESCENDING,' +
    '__name__:DESCENDING',
];

test('organization composite indexes exactly cover repository and authorization queries', () => {
  const organizationIndexes = indexConfiguration.indexes.filter(
    (index) => organizationCollections.has(index.collectionGroup),
  );
  const actualSignatures = organizationIndexes.map(indexSignature);

  assert.equal(
    new Set(actualSignatures).size,
    actualSignatures.length,
    'Organization indexes must not contain duplicate definitions.',
  );
  assert.deepEqual(
    new Set(actualSignatures),
    new Set(requiredSignatures),
  );
  assert.ok(
    organizationIndexes.every((index) => index.queryScope === 'COLLECTION'),
    'Organization indexes must match the top-level repository queries.',
  );
  assert.ok(
    organizationIndexes.every((index) => index.fields.length >= 3),
    'Do not configure unnecessary single-field organization indexes.',
  );
});

function indexSignature(index) {
  const fields = index.fields.map((field) => {
    const mode = field.order || field.arrayConfig;
    return `${field.fieldPath}:${mode}`;
  });
  return `${index.collectionGroup}|${fields.join(',')}`;
}
