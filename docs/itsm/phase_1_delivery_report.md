# ITSM Phase 1 Delivery Report

## Completed

- Replaced the product-facing Incident Management service card with
  **IT Service Management** while retaining `ticketing` as the stored
  permission key.
- Added the canonical `/services/itsm` shell with five responsive,
  localized sections.
- Added compatibility redirects for `/service/itsm`,
  `/service/incidents`, and `/service/ticketing`, preserving nested paths,
  query parameters, and fragments.
- Added route-level USER, MANAGER, and ADMIN guards before protected
  destination widgets build.
- Added pure-Dart work-item, workflow, approval, SLA, audit, collaboration,
  confidentiality, and bounded-pagination contracts.
- Added session-scoped Riverpod providers, incident repository adapters, and
  typed trusted-command gateways.
- Added idempotent Cloud Function boundaries for workflow transitions,
  approval decisions, audit indexing, work-item indexing, SLA processing, and
  notification events.
- Added deny-by-default Firestore and Storage rules for shared ITSM
  collections and parent-aware attachments.
- Corrected legacy Incident ADMIN behavior so raw records and files are
  owner-scoped; organisation-wide visibility is reserved for trusted report
  snapshots.

## Files

- Product shell and routing: `lib/modules/itsm/presentation`, `lib/router.dart`,
  `lib/modules/service/module_config.dart`.
- Shared domain/application/data:
  `lib/modules/itsm/shared`.
- Incident compatibility:
  `lib/modules/incident_management/presentation/controllers/incident_providers.dart`,
  Incident role routers, and the existing repository adapter.
- Backend boundaries: `functions/src/itsm_*.js` and `functions/index.js`.
- Security: `firestore.rules`, `storage.rules`, and
  `firestore.indexes.json`.
- Localization: `lib/l10n/intl_en.arb`, `lib/l10n/intl_fr.arb`, and generated
  localizations.
- Tests: `test/modules/itsm`, Incident role policy tests, and Functions
  emulator/unit tests.

## Firebase

- Added nine ITSM composite indexes.
- Added shared collection rules for work-item indexes, report snapshots,
  global audit events, catalogue items, workflow versions, SLA versions,
  service requests, changes, security records, and shared subresources.
- Added Storage rules for the canonical
  `itsm/{collection}/{workItem}/attachments/...` path.
- No Firebase resource was deployed.
- No production document or file was migrated.

## Permissions

| Capability | USER | MANAGER | ADMIN |
| --- | --- | --- | --- |
| Self-service | Own records | Allowed | Own records |
| Operational records | Denied | Allowed | Denied |
| Configuration drafts | Published read | Manage drafts | Read-only |
| Executive snapshots | Denied | Scoped operational snapshots | Read-only |
| Restricted records/evidence | Denied | Explicit authorization | Denied |
| Trusted index/audit/SLA writes | Denied | Cloud Function command only | Denied |

The existing Incident collection now follows the same boundary: USER and
ADMIN read only records they created or that affect them, MANAGER reads active
and closed operational records, and archived organisation-wide data is not
exposed as raw documents.

## Tests

- Flutter ITSM and ADMIN ownership gate: 63 tests passed.
- Complete Flutter suite: 109 tests passed.
- Functions unit suite: 23 tests passed.
- Incident Firestore emulator suite: 7 tests passed.
- ITSM Firestore and Storage emulator suite: 16 tests passed.
- Targeted Phase 1 analysis: no issues.
- Production web build with the configured VAPID key: passed.
- Whole-project analysis: 78 pre-existing legacy warnings/info remain outside
  the Phase 1 ITSM paths; no new ITSM analyzer issue is present.
- Emulator verification used JDK 21.

## Remaining

- Phase 2 must implement Support service requests, catalogue consumption,
  My Requests, Knowledge Base, trusted index maintenance, and extended
  notifications.
- The temporary legacy ADMIN raw-ticket provider is disconnected. Phase 6
  will replace the executive dashboard data source with trusted
  `itsmReportSnapshots`.
- The 78 legacy analyzer findings must be cleared before final Goal
  acceptance because the final `flutter analyze` command must pass.
