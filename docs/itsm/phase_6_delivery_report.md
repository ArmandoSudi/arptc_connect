# Phase 6 Delivery Report

## Completed

- Replaced the Reporting & Administration placeholder with responsive,
  role-guarded operational and executive dashboards backed only by trusted
  `itsmReportSnapshots` documents.
- Moved Incident reporting to
  `/services/itsm/reporting-administration/dashboards/incidents` and retained
  safe redirects for every legacy Incident dashboard route, including query
  parameters and fragments.
- Added reusable dashboard metrics, KPI, breakdown, trend, loading, error,
  empty, and incomplete-reconciliation presentation components.
- Added bounded SLA policy, Service Catalogue, workflow definition/version,
  and global audit repositories with cursor pagination and session-aware
  Riverpod providers.
- Added English and French Reporting & Administration localization, including
  forms, validation, audit, workflow, and dashboard labels.
- Added versioned SLA, catalogue, and workflow domain validation and adapters
  for the trusted nested `definition` document schema. Published versions are
  immutable and active instances retain pinned version document IDs.
- Added MANAGER-only trusted configuration callables for create, update,
  validate, publish, and retire operations. ADMIN has no configuration
  mutation command.
- Added server-side business-calendar SLA calculation, pause/resume handling,
  warning/breach escalation, and bounded scheduled processing.
- Added idempotent report contributions, deterministic shards, compaction,
  reconciliation watermarks, dedicated Incident snapshots, and sanitized
  ADMIN executive output for all implemented ITSM capabilities.
- Added a compatibility global audit reader, confidentiality-aware filters,
  append-only audit records, bounded requester-authorized CSV exports, and
  requester-only Storage access with expiry.
- Extended Service Request draft creation so new requests pin an exact
  immutable catalogue version; legacy parent-only records remain readable
  without allowing publication drift.
- Reused the existing `ticketing` permission key, three-role model, shared
  workflow/SLA/audit contracts, Incident data, and established notification
  and session infrastructure.

## Files Changed

- `lib/modules/itsm/reporting_administration/`: domain, application, data,
  presentation, reusable widgets, repositories, providers, and controllers.
- `lib/router.dart`: canonical Reporting & Administration route tree and old
  Incident dashboard redirect.
- `lib/modules/itsm/presentation/navigation/itsm_navigation.dart`: canonical
  dashboard/configuration/audit route constants and compatibility transforms.
- `lib/l10n/intl_en.arb`, `lib/l10n/intl_fr.arb`,
  `lib/generated/l10n.dart`: bilingual Phase 6 strings.
- `functions/src/itsm_reporting_administration_*.js`: validation, trusted
  commands, reporting projections, SLA processing, audit export, and handlers.
- `functions/index.js`: Phase 6 callable, event-trigger, and scheduled exports.
- `firestore.rules`, `storage.rules`: audience isolation, trusted-only writes,
  bounded reads, confidentiality, and export ownership.
- `firestore.indexes.json`: Phase 6 reporting, SLA, audit, and configuration
  indexes; 148 unique composite indexes in total.
- `test/modules/itsm/reporting_administration/` and
  `functions/test/itsm_reporting_administration_*`: unit, provider,
  presentation, rules, Storage, export, and callable-emulator coverage.

## Firebase Changes

- Collections added or governed:
  - `itsmReportContributions`
  - `itsmReportContributionCheckpoints`
  - `itsmReportSnapshotShards`
  - `itsmReportSnapshots`
  - `itsmAuditEvents`
  - `itsmAuditExports`
  - `slaPolicies/{policyId}/versions/{versionId}`
  - `serviceCatalogItems/{itemId}/versions/{versionId}`
  - `workflowDefinitions/{workflowId}/versions/{versionId}`
  - `itsmReferenceData`
- Firestore and Storage rules deny client writes to trusted reporting,
  configuration, audit, export, and internal projection data.
- Functions maintain report projections for Incidents, Requests, Assets,
  Stock, Licences, Warranties, Changes, Security, Compliance, and Access
  Reviews.
- Scheduled Functions compact report snapshots and process SLA timers.
- Audit export files use
  `itsm/reporting-exports/{requesterUserId}/{exportId}/{fileName}`.
- No Firebase resources were deployed and no production backfill or migration
  was run.

## Permissions Verified

- USER: cannot access Reporting & Administration, raw organisation reporting,
  global audit, configuration, report internals, or audit exports.
- MANAGER: receives operational snapshots, bounded authorized audit access,
  trusted configuration commands, and operational SLA controls. Restricted
  audit/evidence still requires explicit authorization.
- ADMIN: receives sanitized executive and Incident report snapshots and
  non-restricted audit/export access. Configuration and all operational
  mutations remain read-only/denied at UI, controller, Function, Firestore,
  and Storage boundaries.

## Tests

- `flutter analyze`: passed with no issues.
- `flutter test`: 453/453 passed.
- `flutter build web --dart-define=FIREBASE_WEB_PUSH_VAPID_KEY=...`: passed.
- `cd functions && npm run lint`: passed.
- `cd functions && npm run test:unit`: 196/196 passed.
- Phase 6 Firestore/Storage emulator suite: 13/13 passed.
- Complete cross-phase ITSM Firestore/Storage emulator suite: 75/75 passed.
- Phase 6 Auth/Firestore/Functions callable emulator suite: 1/1 passed.
- Firestore index integrity: 148/148 unique.
- `git diff --check`: passed.
- Failed required gates: none.

## Remaining Work

- Before deployment, populate `itsmReferenceData` with the active
  `assignment_group` and `approval_policy` records referenced by published
  workflows and catalogue items.
- Deploy Functions, Firestore rules/indexes, and Storage rules through the
  organisation's normal reviewed Firebase release process.
- No automatic deployment or production migration was performed, as required.
