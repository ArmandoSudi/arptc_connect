# ITSM Phase 3 Delivery Report

## Completed

- Assets & Configuration capability implemented with bounded operational and
  self-service read models.
- Existing ITSM identity, `ticketing` permission, catalogue, Service Request,
  audit, notification, command, pagination and attachment mechanisms reused.
- My Assets exposes only current assignments and routes every employee action
  through a governed catalogue request.
- Safe `assetSelfServiceProjections` keep employee reads separate from the
  authoritative MANAGER-only asset register.
- Asset lifecycle, stock, licence, supplier, contract, warranty, claim and CMDB
  operations use trusted, authenticated and idempotent command boundaries.
- MANAGER workspaces include asset photograph/file uploads, stock evidence
  uploads, barcode/SKU scanner-wedge lookup, stock location/item maintenance,
  licence allocation, warranty claims and directional CMDB relationships.
- Directional CI relationships and linked Incident/Service Request IDs are
  additive and preserve existing records.
- Parent-aware Storage finalization registers immutable attachment metadata for
  asset photographs, asset files and stock evidence before those files become
  readable through the corresponding Firestore policy.

## Files changed

- `lib/modules/itsm/assets_configuration`: Phase 3 domain, repository,
  application, controller, screen and reusable widget layers.
- `lib/router.dart`: canonical self-service and MANAGER operational routes.
- `lib/l10n/intl_en.arb`, `lib/l10n/intl_fr.arb`: bilingual Phase 3 vocabulary.
- `functions/src/itsm_assets_*.js`: validation, transactional commands,
  callable handlers and expiry processing.
- `firestore.rules`, `storage.rules`: deny-by-default Phase 3 access controls.
- `firestore.indexes.json`: bounded asset, stock, licence, warranty and CMDB
  query indexes.
- `test/modules/itsm/assets_configuration`, `functions/test/itsm_assets_*`:
  domain, provider, widget, Functions and emulator regression coverage.

## Firebase changes

- Collections: `assets`, `assetModels`, `assetAssignments`,
  `assetLifecycleEvents`, `assetSelfServiceProjections`, `stockLocations`,
  `stockItems`, `stockMovements`, `stockSupportingDocuments`,
  `softwareLicences`, `suppliers`,
  `supplierContracts`, `warranties`, `configurationItems`, and
  `ciRelationships`, including their governed attachment, allocation, history,
  contact and claim subcollections.
- Firestore rules restrict self-service reads to current assignees, operational
  reads to MANAGER, and consistency-sensitive writes to trusted Functions.
- Storage rules inherit asset assignment/manager access and keep operational
  contract/warranty evidence MANAGER-only.
- Composite indexes support every bounded list and directional relationship
  query introduced in this phase.
- Cloud Functions provide lifecycle, assignment, stock, licence, supplier,
  contract, warranty/claim, CMDB and expiry-notification operations.
- Stock callables resolve agent, recipient, location, licence, CI and supporting
  evidence facts from authoritative documents. Client-supplied display names,
  roles, evidence metadata and timestamps are never trusted.
- No Firebase resource was deployed and no production document was migrated.

## Permissions verified

- USER: read-only current My Assets and catalogue-generated actions; no direct
  asset, stock, licence, supplier/warranty or CMDB mutation.
- MANAGER: bounded operational reads and trusted command execution across all
  Phase 3 capabilities.
- ADMIN: USER-equivalent current My Assets and catalogue actions; no operational
  inventory access or mutation.

## Tests

- `flutter analyze`: passed with no issues.
- `flutter test`: 298 tests passed.
- Focused Assets & Configuration Flutter suite: 89 tests passed.
- Functions lint and syntax checks: passed on the supported Node.js 22 runtime.
- Functions unit suite: 91 tests passed.
- Phase 3 Firestore, Storage and transactional integration emulator suite: 19
  tests passed with JDK 21 against the demo project.
- Exported callable Auth/Firestore/Functions/Storage emulator suite: 2 tests
  passed, including canonical stock master-data persistence.
- Complete ITSM Firestore and Storage rules emulator suite: 37 tests passed.
- `flutter build web` with the configured Web Push VAPID define: passed.
- `git diff --check` and `firestore.indexes.json` JSON parsing: passed.
- Failed: none outstanding at report finalization.
- Dependency review: the non-breaking audit update is applied. Eight moderate
  transitive advisories remain because the suggested fix requires a breaking
  Firebase Admin major upgrade; this is recorded for a dedicated compatibility
  upgrade rather than forced into Phase 3.
- Not run: Firebase deployment and production migration were intentionally not
  run under the approved execution rules.

## Remaining work

- Phase 4: Changes, CAB approvals and Change Calendar.
- Phase 5: Security & Compliance.
- Phase 6: Reporting & Administration and final 20-criterion audit.
- Deployment: provision callable, trigger, scheduled Function, rule and index
  resources only after separate review and deployment approval.
