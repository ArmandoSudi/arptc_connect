'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');

const indexSource = fs.readFileSync(path.join(__dirname, '..', 'index.js'), 'utf8');
const packageJson = JSON.parse(fs.readFileSync(
  path.join(__dirname, '..', 'package.json'),
  'utf8',
));

test('all Phase 6 callables are registered', () => {
  const exports = [
    'itsmCreateSlaPolicyDraft', 'itsmUpdateSlaPolicyDraft',
    'itsmValidateSlaPolicyDraft', 'itsmPublishSlaPolicyVersion',
    'itsmRetireSlaPolicyVersion', 'itsmRecalculateSla',
    'itsmCreateCatalogueItemDraft', 'itsmUpdateCatalogueItemDraft',
    'itsmValidateCatalogueItemDraft', 'itsmPublishCatalogueItemVersion',
    'itsmRetireCatalogueItemVersion', 'itsmSaveReferenceData',
    'itsmDeactivateReferenceData', 'itsmCreateWorkflowDraft',
    'itsmUpdateWorkflowDraft', 'itsmValidateWorkflowDraft',
    'itsmPublishWorkflowVersion', 'itsmRetireWorkflowVersion',
    'itsmRequestAuditExport',
  ];
  for (const exportName of exports) assert(indexSource.includes(exportName), exportName);
});

test('trusted snapshot, SLA and audit triggers are exported', () => {
  for (const exportName of [
    'itsmReportIncidentTickets', 'itsmReportServiceRequests', 'itsmReportAssets',
    'itsmReportStockItems', 'itsmReportSoftwareLicences', 'itsmReportWarranties',
    'itsmReportChangeRequests', 'itsmReportSecurityFindings',
    'itsmReportSecurityExceptions', 'itsmReportAssetCompliance',
    'itsmReportAccessReviewCampaigns', 'itsmReportAccessReviewItems',
    'itsmCompactReportSnapshots', 'itsmProcessSlaTimers',
    'itsmGenerateAuditExport',
  ]) assert(indexSource.includes(exportName), exportName);
  assert(indexSource.includes("'itsmAuditExports/{exportId}'"));
  assert(indexSource.includes("schedule: 'every 5 minutes'"));
});

test('Node 22 lint and unit scripts include Phase 6 sources and tests', () => {
  assert.equal(packageJson.engines.node, '22');
  for (const file of [
    'itsm_reporting_administration_validation.js',
    'itsm_reporting_administration_reporting.js',
    'itsm_reporting_administration_sla.js',
    'itsm_reporting_administration_audit.js',
    'itsm_reporting_administration_service.js',
    'itsm_reporting_administration_handlers.js',
  ]) assert(packageJson.scripts.lint.includes(file), file);
  assert.equal(packageJson.scripts['test:unit'], 'node --test test/*.test.js');
  assert.equal(
    packageJson.scripts['test:unit:reporting-administration'],
    'node --test test/itsm_reporting_administration_*.test.js',
  );
});
