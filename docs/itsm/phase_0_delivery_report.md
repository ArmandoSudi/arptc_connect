# ITSM Phase 0 Delivery Report

## Completed

- Captured the production Incident Management data, role, route, dashboard,
  notification, and security baseline.
- Preserved the authoritative `incidentTickets` collection and existing status,
  lifecycle, field, and subcollection contracts.
- Added bounded live queries and cursor-based page contracts with a default
  page size of 50 and a maximum of 100.
- Bounded comments and audit history to the newest 250 records.
- Corrected USER comment queries to request only public comments, matching the
  existing Firestore rule instead of relying on rules as filters.
- Restored a scheduled v2 archival function that processes eligible closed
  incidents in bounded, idempotent batches.
- Added incident composite indexes and registered the index file with Firebase.
- Added pure map parsers so Firestore model compatibility can be tested without
  mocking sealed Firebase SDK snapshot types.

## Files

- `ARPTC_CONNECT_ITSM_CODEX_IMPLEMENTATION_INSTRUCTIONS.md`
- `docs/itsm/phase_0_baseline.md`
- `docs/itsm/phase_0_delivery_report.md`
- `firebase.json`
- `firestore.indexes.json`
- `functions/index.js`
- `functions/package.json`
- `functions/package-lock.json`
- `functions/src/incident_archival.js`
- `functions/test/incident_archival.test.js`
- `functions/test/firestore_incident_rules.emulator.js`
- Incident repository, paging, provider, and Firestore model files under
  `lib/modules/incident_management`
- Incident regression tests under `test/modules/incident_management`

## Firebase

- Added the local `firestore.indexes.json` configuration.
- Added the local scheduled function `archiveEligibleIncidents`.
- Added `@firebase/rules-unit-testing` as a development-only dependency.
- Verified Firestore rules against the local emulator using JDK 21 and
  `firebase-tools` 15.25.1.
- No Firebase resource was deployed and no production document was read,
  migrated, or changed.

## Permissions

- USER ownership, minimal ticket creation, public comments, attachments, audit
  history, and update denial are covered by emulator tests.
- MANAGER active/closed visibility, archived denial, and operational update
  access are covered by emulator tests.
- ADMIN organisation-wide read-only baseline behavior is covered by emulator
  tests.
- Ticket deletion remains denied for every role.
- The specification's narrower ADMIN self-service behavior is intentionally a
  Phase 2 change, when organisation-wide access moves to trusted report
  snapshots.

## Tests

- `flutter analyze lib/modules/incident_management test/modules/incident_management`
  - Passed with no issues.
- `flutter test test/modules/incident_management`
  - 30 tests passed.
- `npm test`
  - 3 archival unit tests passed.
- `npm run lint`
  - Functions syntax checks passed.
- Firestore emulator suite:
  - 7 rules tests passed under JDK 21.
- `git diff --check` for implementation files
  - Passed. The unchanged supplied specification is excluded because it
    intentionally contains four Markdown hard-break trailing spaces.

## Remaining

- Add the canonical ITSM shell and compatibility redirects.
- Add shared ITSM domain, repository, provider, command, audit, workflow, SLA,
  and notification foundations.
- Move ADMIN self-service incident access to owner scope in Phase 2.
- Replace the temporary bounded ADMIN raw-ticket dashboard read with trusted
  report snapshots in Phase 6.
- Derive `archiveEligibleAt` from trusted server-side transition processing
  rather than client time.
- Add Storage and cross-feature deny-by-default rules as each ITSM feature is
  introduced.
