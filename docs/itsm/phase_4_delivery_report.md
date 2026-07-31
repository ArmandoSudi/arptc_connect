# ITSM Phase 4 Delivery Report

## Completed

- Standard, normal and emergency Change Management is implemented under the
  canonical ITSM routes while retaining `ticketing` as the stored permission
  key.
- USER and ADMIN receive requester-scoped self-service change creation,
  cancellation, detail and collaboration access. MANAGER receives the
  operational assessment, approval, CAB, scheduling, implementation, review
  and closure workspace.
- Change requests pin immutable published workflow versions and use trusted,
  authenticated and idempotent callable commands for every governed write.
- Assessment records impact, urgency, calculated risk, affected services,
  assets/CIs, implementation/test/communication/rollback plans, evidence,
  downtime and implementation windows.
- Normal and emergency approvals enforce separation of duties. CAB decisions,
  clarification, conditions, emergency context, meetings, participants,
  agenda, notes and deadlines preserve immutable history.
- The responsive Change Calendar supports month, week and agenda views with
  bounded date windows, role-scoped visibility, conflicts, maintenance windows
  and one indexed filter dimension at a time.
- Change comments, attachments and requester-visible activity use bounded live
  streams. Internal and CAB records never enter a requester read model.
- Calendar, work-item, audit and notification projections are maintained by
  trusted Functions rather than client writes.

## Files changed

- `lib/modules/itsm/changes`: Phase 4 domain, repository, application,
  controller, screen, dialog and reusable presentation layers.
- `lib/router.dart`, `lib/modules/itsm/presentation/navigation`: canonical
  Change Management routes and ITSM navigation entries.
- `lib/l10n/intl_en.arb`, `lib/l10n/intl_fr.arb`: bilingual Change Management
  vocabulary and generated localization accessors.
- `functions/src/itsm_changes_*.js`: validation, transactional service,
  callable handlers and notification projections.
- `firestore.rules`, `storage.rules`: requester, operational, collaboration,
  calendar, configuration and immutable evidence controls.
- `firestore.indexes.json`: bounded change-list, CAB and calendar indexes.
- `test/modules/itsm/changes`, `functions/test/itsm_changes_*`: domain,
  provider, data, presentation, Functions and emulator regression coverage.
- `docs/itsm/phase_4_implementation_map.md` and
  `docs/itsm/phase_4_manual_configuration.md`: implementation and manual
  workflow/CAB provisioning guidance.

## Firebase changes

- Authoritative collection: `changeRequests`, including `approvals`,
  `cabMeetings`, `comments`, `attachments` and `auditLogs` subcollections.
- Trusted configuration/projection collections: `changeApprovalGroups`,
  `maintenanceWindows`, `changeCalendarEntries`, `workflowDefinitions`,
  `itsmWorkItemIndex`, `itsmAuditEvents` and `notificationEvents`.
- Thirteen exported callable commands cover draft initialization/save,
  submission, cancellation, assessment, approval request/decision, CAB meeting,
  scheduling, implementation start/result, post-implementation review and
  closure.
- Firestore and Storage rules deny direct governed mutations, inherit parent
  access for evidence, preserve ADMIN self-service scope and keep internal/CAB
  data MANAGER-only.
- Composite indexes support every bounded Phase 4 query. The complete manifest
  contains 99 unique indexes, including 8 for `changeRequests` and 18 for
  `changeCalendarEntries`.
- Cross-service Storage rule tests must run with the CLI and test environment on
  the same project, for example `--project demo-arptc-connect-itsm`; otherwise
  Storage resolves Firestore parents in a different emulator namespace.
- No Firebase resource was deployed and no production document was migrated.

## Permissions verified

- USER: create, edit, submit, cancel and read own changes; read own/public
  calendar entries and requester-visible collaboration only.
- MANAGER: bounded operational access, assessment, assignment, approval/CAB,
  scheduling, implementation, review, closure and internal evidence access.
- ADMIN: USER-equivalent own-change self-service and read-only published
  calendar visibility; no organisation-wide raw change access and no
  operational command access.
- Normal and emergency requesters cannot approve their own change, including
  through CAB group membership.

## Tests

- `flutter analyze`: passed with no issues.
- `flutter test`: 402 tests passed.
- Focused Change Management Flutter and route suite: 56 tests passed.
- Functions lint and syntax checks: passed on Node.js 22.
- Functions unit suite: 125 tests passed.
- Focused Change Management Firestore and Storage emulator suite: 10 tests
  passed with JDK 21 against `demo-arptc-connect-itsm`.
- Complete ITSM Firestore and Storage emulator suite: 47 tests passed.
- Exported Auth/Firestore/Functions callable emulator suite: 2 tests passed,
  including workflow pinning/idempotent replay and ADMIN operational denial.
- `flutter build web` with the configured Web Push VAPID define: passed.
- English/French ARB and `firestore.indexes.json` JSON parsing, index uniqueness,
  and `git diff --check`: passed.
- Failed: none outstanding at report finalization.
- Not run: Firebase deployment and production migration were intentionally not
  run under the approved execution rules.

## Remaining work

- Phase 5: complete Security & Compliance repositories, providers, screens,
  trusted commands, rules, indexes and emulator verification on top of the
  delivered pure-Dart domain foundation.
- Phase 6: Reporting & Administration, SLA/configuration administration and
  append-only audit/reporting views.
- Final delivery: run the complete release gate and explicitly audit all 20
  specification acceptance criteria.
