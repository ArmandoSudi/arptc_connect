# ITSM Phase 2 Delivery Report

## Completed

- Mounted the existing Incident capability under the canonical Support routes
  without changing the `incidentTickets` source of truth, identifiers, or
  established lifecycle values.
- Added additive Incident links for assets, configuration items, service
  requests, changes, Knowledge suggestions, and resolution articles.
- Implemented published Service Catalogue consumption with localized dynamic
  fields, eligibility, required documents, and pinned workflow/SLA versions.
- Implemented governed Service Requests, including draft initialization,
  required-document upload, submission, approval, assignment, fulfilment,
  cancellation, rejection, tasks, comments, links, audit, SLA, and requester
  completion confirmation.
- Added an idempotent, dry-run-first provisioning tool for the fourteen initial
  catalogue items and their workflow/SLA versions. No seed was applied.
- Implemented the trusted `itsmWorkItemIndex` read model and a bounded,
  filterable, cursor-paginated My Requests experience across work-item types.
- Implemented the Knowledge Base domain, repositories, manager lifecycle,
  immutable versions, visibility, review/rejection comments, publication,
  retirement, archival, feedback, usage, suggestions, and version-scoped
  attachments.
- Extended the trusted notification pipeline with deterministic Service Request
  assignment, approval, status, and SLA events using canonical role-specific
  deep links.
- Added bounded server-side SLA evaluation and deduplicated warning/breach
  notifications.
- Made live Support and Knowledge providers resubscribe when the authenticated
  user changes, preventing data leakage or stale permissions between sessions.

## Files changed

- Incident compatibility: `lib/modules/incident_management`.
- Support domain, application, data, and presentation:
  `lib/modules/itsm/support`.
- Knowledge domain, application, data, and presentation:
  `lib/modules/itsm/knowledge`.
- Trusted My Requests read model and reusable list presentation:
  `lib/modules/itsm/shared`.
- Canonical navigation: `lib/router.dart` and
  `lib/modules/itsm/presentation/navigation/itsm_navigation.dart`.
- Cloud Functions: `functions/src/itsm_support_*.js`,
  `functions/src/itsm_command_service.js`, and `functions/index.js`.
- Security and query support: `firestore.rules`, `storage.rules`, and
  `firestore.indexes.json`.
- Initial configuration tooling: `tool/itsm` and
  `tool/seeds/itsm_phase2_seed.json`.
- Localization: `lib/l10n/intl_en.arb`, `lib/l10n/intl_fr.arb`, and
  `lib/generated/l10n.dart`.
- Regression, domain, provider, widget, Functions, and emulator tests under
  `test/modules/incident_management`, `test/modules/itsm`, and
  `functions/test`.

## Firebase changes

- Added authoritative Support and Knowledge rules with self-service ownership,
  MANAGER operational access, ADMIN self-service/read-only behavior, and
  deny-by-default protected writes.
- Added canonical version-scoped Knowledge Storage paths and trusted attachment
  metadata registration.
- Added composite indexes for bounded catalogue, request, work-item index,
  Knowledge, approval, SLA, and operational queue queries.
- Added callable Functions for Service Request and Knowledge commands, trusted
  index/audit maintenance, attachment registration, notifications, and SLA
  processing.
- Added an every-five-minutes bounded Service Request SLA processor.
- No Firebase resource was deployed.
- No production document or file was migrated, deleted, or rewritten.

## Permissions verified

| Capability | USER | MANAGER | ADMIN |
| --- | --- | --- | --- |
| Incidents | Own self-service records | Active/closed operations | Own self-service records |
| Service Catalogue | Published eligible items | Published items and operational tooling | Published eligible items |
| Service Requests | Own requests and public updates | All authorized operations | Own requests, no operations |
| My Requests index | Own visible summaries | Operational summaries | Own visible summaries |
| Knowledge publications | Employee-visible published content | All lifecycle states | Employee-visible published content |
| Knowledge management | Denied | Trusted commands only | Denied |
| Restricted records/evidence | Denied | Explicit authorization only | Denied |
| Audit/index/SLA protected writes | Denied | Trusted Functions only | Denied |

## Tests

- `flutter analyze`: passed with no issues. This includes the focused ITSM
  paths and the legacy analyzer cleanup required by final acceptance.
- `flutter test`: all 209 project tests passed.
- `npm run lint` under Node 22: passed, including the SLA processor.
- `npm run test:unit` under Node 22: 46 tests passed.
- Firestore and Storage emulator ITSM suite under JDK 21 and Node 22: 26 tests
  passed.
- Production `flutter build web` with the configured VAPID key: passed.
- `git diff --check`: passed.

## Remaining work

- Phase 3 implements Assets & Configuration, including assets, stock,
  licences, suppliers/warranties, and the initial CMDB.
