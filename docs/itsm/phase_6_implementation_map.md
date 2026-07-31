# ITSM Phase 6 Implementation Map

## Objective

Deliver Reporting & Administration as the trusted, role-aware control plane for
the existing ITSM capabilities. Phase 6 relocates the Incident dashboard,
introduces cross-module operational and executive reporting, completes SLA
management, adds versioned catalogue and workflow administration, and exposes a
bounded global audit view.

This phase must preserve all production Incident identifiers and calculations,
retain `ticketing` as the canonical stored permission key, and avoid client-side
cross-module aggregation. No Firebase resource is deployed and no production
document is migrated automatically.

## Current implementation audit

### Reuse points

| Area | Existing implementation | Phase 6 reuse |
| --- | --- | --- |
| Session and role resolution | `lib/modules/itsm/shared/application/itsm_session.dart` and `itsm_providers.dart` resolve USER, MANAGER and ADMIN from the live agent profile and invalidate data on session changes | Use the same session and `ticketing` permission aliases for all Reporting & Administration providers and commands |
| Route access | `ItsmRouteAccessPolicy` already denies USER, allows MANAGER, and marks ADMIN read-only for `ItsmSection.reportingAdministration` | Retain the policy, add feature/action-specific guards, and test every deep link |
| Navigation shell | `ItsmSection.reportingAdministration` already lists Dashboards, SLA, Service Catalogue, Workflows and Audit Logs | Replace the five placeholder `ItsmFeatureAccessScreen` routes with real screens without changing the five-card shell |
| Incident calculations | `IncidentDashboardAggregator`, `IncidentDashboardStats`, `ChartPoint`, and dashboard parity tests define current manager/admin figures | Keep the pure Dart aggregator as the compatibility oracle; move production aggregate input to trusted report snapshots |
| Incident presentation | Manager/Admin Incident screens, KPI/panel layout and the pie, bar and line charts are presentation-only | Mount the Incident dashboard at the new reporting route and reuse or extract the generic layout/chart widgets without adding Firestore calls to widgets |
| Bounded Incident data | `IncidentRepository` has cursor pages and bounded first-page streams; the manager dashboard currently consumes bounded active and closed streams | Keep a separately paginated operational queue for MANAGER; do not derive organisation-wide KPIs in Flutter |
| Shared SLA domain | `BusinessCalendar`, `SlaPolicy`, `SlaState` and `SlaCalculator` implement working windows, holidays, pause/resume, warning and breach calculations | Add Firestore serialization/version metadata and mirror the calculations in tested trusted Functions |
| Existing SLA processing | `itsm_support_sla.js` evaluates bounded service-request batches, updates `itsmWorkItemIndex`, and emits deterministic notifications | Generalize it to policy-version-aware business time and supported work-item collections; retain deterministic notification semantics |
| Shared workflow domain | `WorkflowDefinition`, `WorkflowVersion`, transitions and `validateForPublication()` enforce start-state, reachability, role, audit and mandatory-approval guards | Reuse these rules in the editor and mirror them server-side before publishing immutable versions |
| Workflow execution | `itsm_command_service.js`, Support and Change Functions resolve pinned workflow versions and execute trusted, audited transitions | Administration publishes definitions consumed by these executors; it does not create a competing workflow engine |
| Catalogue model | `ServiceCatalogueItem` models localized content, icon, eligibility, visible roles, dynamic fields, required documents, workflow, approval, fulfilment, SLA and dates | Reuse the model and published Support surface; add an administration repository and immutable version lifecycle |
| Published catalogue queries | `FirestoreServiceCatalogueRepository` provides role-scoped cursor pagination and a bounded first-page stream over `serviceCatalogItems` | Keep the consumer API stable; publication materializes the selected immutable version into the parent document |
| Audit write paths | Shared, Support, Assets, Changes and Security Functions create record-level `auditLogs` and global `itsmAuditEvents` | Normalize new writes through one shared audit writer and provide a compatibility reader for existing event shapes |
| Trusted writes | `runIdempotentCommand()` records receipts in `itsmCommandReceipts`; shared configuration collections reject direct client writes | Use the same idempotent callable pattern for SLA, catalogue and workflow commands |
| Existing rules | Report snapshots, global audit, catalogue, workflow and SLA collections are client read-only; audience/configuration helpers exist | Tighten list bounds, confidentiality and version visibility while preserving deny-by-default writes |
| Existing indexes | Initial indexes exist for snapshots, two audit queries, published catalogue, workflow definitions and SLA policies | Preserve matching indexes and add the exact cursor/filter indexes below |

### Gaps that Phase 6 must close

1. All five Reporting & Administration feature routes currently render a placeholder.
2. The live Incident dashboard remains under `/services/itsm/support/incidents/dashboard`.
3. `adminAllIncidentTicketsProvider` intentionally returns an empty stream. ADMIN must not regain raw Incident access; `itsmReportSnapshots` is the required source.
4. MANAGER dashboard statistics are calculated from bounded raw pages in Flutter and cannot produce complete cross-module figures as data grows.
5. No Function creates or updates `itsmReportSnapshots`; the collection and index are security/test scaffolding only.
6. The existing SLA worker handles service requests only, uses elapsed wall time, and does not apply business hours, holidays, policy matching, versioning, response targets, pause conditions or configured escalation.
7. `SlaPolicy` has no Firestore adapter or administration repository/controller.
8. Workflow validation exists in Dart, but there is no configuration repository, editor, publishing command or server-side publication validator.
9. The catalogue has a published reader but no administration command surface, and published versions are not immutable subcollection documents.
10. Service-request initialization pins workflow and SLA versions, but catalogue submission rereads the mutable parent item instead of a pinned catalogue version.
11. Global audit event shapes are inconsistent. Dart expects `targetEntityType`, `targetEntityId`, `occurredAt`, `previousValues` and `newValues`; Functions commonly write `entityType`, `entityId`, `createdAt`, `before` and `after`. Some writers omit module, department, reference, confidentiality or correlation data.
12. Current audit indexes reference `workItemType/workItemId`, while most writers use `entityType/entityId`.
13. Audit and shared configuration list rules do not consistently require a bounded query.
14. There is no authorized audit export flow.
15. ADMIN confidentiality must be enforced in report drill-down and audit queries, not only by hidden controls.

## Target Flutter architecture

Follow the established feature architecture under a new sibling module:

```text
lib/modules/itsm/reporting_administration/
|-- domain/
|   |-- dashboard_snapshot.dart
|   |-- reporting_metrics.dart
|   |-- sla_configuration.dart
|   |-- workflow_configuration.dart
|   |-- catalogue_configuration.dart
|   |-- audit_query.dart
|   `-- reporting_administration_domain.dart
|-- application/
|   |-- reporting_administration_access_policy.dart
|   |-- reporting_administration_providers.dart
|   |-- dashboard_controller.dart
|   |-- sla_configuration_controller.dart
|   |-- workflow_configuration_controller.dart
|   |-- catalogue_configuration_controller.dart
|   |-- audit_log_controller.dart
|   `-- reporting_administration_application.dart
|-- data/
|   |-- report_snapshot_repository.dart
|   |-- firestore_report_snapshot_repository.dart
|   |-- sla_policy_repository.dart
|   |-- firestore_sla_policy_repository.dart
|   |-- workflow_definition_repository.dart
|   |-- firestore_workflow_definition_repository.dart
|   |-- catalogue_administration_repository.dart
|   |-- firestore_catalogue_administration_repository.dart
|   |-- audit_event_repository.dart
|   |-- firestore_audit_event_repository.dart
|   |-- reporting_administration_command_gateway.dart
|   |-- firebase_reporting_administration_command_gateway.dart
|   `-- reporting_administration_data.dart
`-- presentation/
    |-- screens/
    |   |-- reporting_administration_overview_screen.dart
    |   |-- itsm_dashboard_router.dart
    |   |-- manager_itsm_dashboard_screen.dart
    |   |-- admin_itsm_dashboard_screen.dart
    |   |-- incident_reporting_dashboard_screen.dart
    |   |-- sla_policies_screen.dart
    |   |-- sla_policy_detail_screen.dart
    |   |-- service_catalogue_administration_screen.dart
    |   |-- service_catalogue_administration_detail_screen.dart
    |   |-- workflow_definitions_screen.dart
    |   |-- workflow_definition_detail_screen.dart
    |   |-- workflow_editor_screen.dart
    |   |-- audit_logs_screen.dart
    |   `-- audit_log_detail_screen.dart
    `-- widgets/
        |-- reporting_dashboard_layout.dart
        |-- reporting_kpi_card.dart
        |-- reporting_chart_widgets.dart
        |-- configuration_status_badge.dart
        |-- version_history_panel.dart
        |-- sla_policy_form.dart
        |-- catalogue_item_form.dart
        |-- workflow_editor.dart
        |-- workflow_validation_panel.dart
        |-- audit_filter_bar.dart
        `-- audit_event_list.dart
```

Screens remain composition/state boundaries. Forms, charts, tables, version
history, error/loading/empty states and editor controls remain separate,
testable widgets. Add every new user-facing string to both ARB files and read it
through generated localization.

## Role and action matrix

| Capability | USER | MANAGER | ADMIN |
| --- | --- | --- | --- |
| Reporting & Administration section | Denied, including deep links | Allowed | Allowed read-only |
| Operational dashboard | Denied | Read trusted MANAGER snapshots and bounded operational drill-down | Denied |
| Executive dashboard | Denied | Denied | Read trusted ADMIN snapshots only |
| Incident reporting dashboard | Denied | Operational metrics plus paginated actionable queue | Aggregate/read-only metrics and safe snapshot highlights |
| Cross-module drill-down | Denied | Bounded operational routes allowed by each source module | Snapshot-derived read-only dimensions/highlights; never unrestricted raw records |
| SLA definitions/results | Denied | Create/edit drafts, validate, publish and retire through Functions | Read published/retired definitions and aggregate results only |
| Catalogue administration | Denied | Create/edit drafts, validate, publish and retire through Functions | Read published/retired definitions only |
| Published Support catalogue | Browse according to eligibility | Browse and submit; request on behalf when configured | Browse and submit own self-service requests |
| Workflow administration | Denied | Create/edit drafts, validate, publish and retire through Functions | Inspect published/retired definitions only |
| Global audit log | Denied | Read non-restricted plus explicitly authorized restricted events | Read non-restricted events only |
| Audit export | Denied | Export only records the MANAGER may read | Export non-restricted records only |
| Configuration writes | Denied | Trusted callable only | Denied in UI, Functions and rules |
| Snapshot/audit direct writes | Denied | Denied | Denied |

The UI uses `ItsmRouteAccessPolicy.isReadOnly` only as presentation state.
Callable Functions and Firebase rules are authoritative. ADMIN never receives a
configuration mutation gateway.

## Authoritative collections and read models

### Configuration

```text
serviceCatalogItems/{itemId}
serviceCatalogItems/{itemId}/versions/{versionId}
workflowDefinitions/{workflowDefinitionId}
workflowDefinitions/{workflowDefinitionId}/versions/{versionId}
slaPolicies/{slaPolicyId}
slaPolicies/{slaPolicyId}/versions/{versionId}
itsmReferenceData/{referenceId}
```

- Parent documents are stable identities and materialized current-published views for bounded lists and existing consumers.
- Draft and immutable published payloads live in `versions`.
- `currentPublishedVersion`, `latestVersion`, lifecycle state, audit fields and schema version live on the parent.
- A published version is never updated or deleted. Editing starts a new draft version copied from a selected version.
- `itsmReferenceData` stores reusable assignment groups, business-calendar references and holiday sets when they are not embedded in a version.
- A published SLA version contains or pins an immutable calendar snapshot so later holiday edits cannot alter historical timers.

### Reporting

```text
itsmReportSnapshots/{snapshotId}
itsmReportSnapshots/{snapshotId}/shards/{shardId}
itsmReportContributions/{sourcePathHash}
```

- `itsmReportSnapshots` is the only client-readable cross-module reporting source.
- Snapshot shards and contribution ledgers are trusted internal records denied to all clients.
- A contribution stores the last normalized value and source update fingerprint. Duplicate event delivery becomes a no-op; a changed event applies old/new deltas transactionally.
- A scheduled compactor combines bounded shards into snapshot parents. Clients never aggregate shards.

Canonical snapshot shape:

```text
schemaVersion
snapshotType                  # incident, operational, executive
audience                      # MANAGER or ADMIN
scopeType                     # global, department, service, group
scopeId
periodGranularity             # current, day, week, month
periodKey
periodStart
periodEnd
generatedAt
sourceWatermark
isComplete
confidentiality               # internal; never restricted detail
metrics                       # scalar KPIs
breakdowns                    # label/code to numeric value
trends                        # ordered label/value points
highlights                    # capped sanitized summaries
sourceCounts                  # reconciliation diagnostics
```

Required MANAGER snapshots cover:

- Incidents by priority, awaiting assignment, response/resolution performance.
- Requests by type/status, awaiting approval and fulfilment.
- SLA at-risk and breached counts.
- Workload by agent and assignment group.
- Assets by status/location, available and low stock.
- Warranty and licence expiry windows.
- Planned/failed changes.
- Findings by severity, overdue remediation and access reviews due.

Required ADMIN snapshots cover:

- Incident totals/trend, SLA compliance and average resolution time.
- Request fulfilment performance and available satisfaction results.
- Asset inventory/lifecycle/replacement, licence and warranty exposure.
- Change success rate.
- Sanitized security/compliance exposure.
- Six-month trend and department comparisons.

Snapshot highlights never contain security evidence, unrestricted audit payloads,
licence secrets, personal access details or other restricted fields.

### Audit and export

```text
{authoritativeParent}/{id}/auditLogs/{eventId}
itsmAuditEvents/{eventId}
itsmAuditExports/{exportId}
itsmCommandReceipts/{receiptId}
```

Canonical future global audit fields:

```text
eventType
action
module
entityType
entityId
entityReference
sourcePath
actor.userId
actor.displayName
actor.email
actor.role
actor.departmentId
before
after
fromState
toState
comment
correlationId
sourceCommand
sourceIdempotencyKey
confidentiality
isRestricted
authorizedManagerIds
createdAt
```

The Flutter adapter accepts existing aliases without rewriting old events. Every
new trusted writer emits the canonical shape. A manual, idempotent,
dry-run-capable backfill may normalize historical index fields only if separately
approved; Phase 6 does not run it.

`itsmAuditExports` records requester, effective filters, authorization scope,
status, row count, expiration and private Storage metadata. Export files use:

```text
itsm/reporting-exports/{requesterUserId}/{exportId}/{fileName}
```

Only the requester may read a completed, unexpired export. The server applies
the same confidentiality policy before writing each row.

### Existing authoritative reporting inputs

No source collection is replaced. Trusted projection Functions observe:

```text
incidentTickets
serviceRequests
assets
stockItems
softwareLicences
warranties
changeRequests
securityFindings
securityExceptions
assetComplianceAssessments
accessReviewCampaigns
accessReviewItems
knowledgeArticles/feedback when satisfaction data is available
```

## Server boundaries

### Reporting snapshots

Add pure aggregation/contribution helpers and v2 Firestore/scheduled handlers:

```text
functions/src/itsm_reporting_aggregation.js
functions/src/itsm_reporting_snapshots.js
functions/src/itsm_reporting_triggers.js
```

Each source trigger:

1. Normalizes `before` and `after` into a non-sensitive contribution.
2. Uses source path plus update fingerprint to detect duplicate delivery.
3. Transactionally reverses the old contribution and applies the new one to deterministic period/audience shards.
4. Stores the contribution checkpoint.
5. Never copies restricted detail into an ADMIN snapshot.

The scheduled compactor publishes complete current/week/month snapshots with
server timestamps. A bounded reconciliation helper supports emulator tests and
explicit dry-run scripts; it is not client callable and never scans an unbounded
collection in one invocation.

Incident projection logic must be fixture-tested against
`IncidentDashboardAggregator` before replacing the old provider. MANAGER keeps a
separate cursor-paginated operational queue; ADMIN receives only capped,
sanitized snapshot highlights.

### SLA management and timers

Add MANAGER-only idempotent callables:

```text
itsmCreateSlaPolicyDraft
itsmUpdateSlaPolicyDraft
itsmValidateSlaPolicyDraft
itsmPublishSlaPolicyVersion
itsmRetireSlaPolicyVersion
```

Publication validates positive response/resolution/fulfilment targets, target
ordering, work-item type, optional priority/service match, IANA time zone,
non-overlapping business windows, holidays, pause states, warning threshold and
escalation targets. The transaction creates an immutable published version,
retires the previous current version when required, updates the parent pointer,
writes record/global audit events and returns an idempotent receipt.

Generalized trusted SLA processing must:

- Pin `slaPolicyId`, `slaPolicyVersion` and version document ID on work items.
- Calculate due dates in the pinned policy's business calendar.
- Set response/resolution milestones and pause/resume state only from trusted transitions.
- Query active items whose `slaNextCheckAt` is due in bounded cursor batches.
- Emit deterministic warning, breach, met and escalation events.
- Update the authoritative item, work-item index, audit and reporting contribution through transaction-safe/idempotent steps.
- Send server-produced SLA state to Flutter; Flutter never advances a timer.

Retain the current service-request worker until generalized parity tests pass.
The generic MANAGER callable may request trusted recalculation, but cannot accept
a client-supplied due date, elapsed time or compliance result.

### Catalogue administration

Add MANAGER-only idempotent callables:

```text
itsmCreateCatalogueItemDraft
itsmUpdateCatalogueItemDraft
itsmValidateCatalogueItemDraft
itsmPublishCatalogueItemVersion
itsmRetireCatalogueItemVersion
```

Validation reuses `ServiceCatalogueItem` invariants and proves that referenced
workflow/SLA versions are published, approval and fulfilment groups exist,
active dates are ordered, localized required text exists, field/document keys
are unique, and visible roles/eligibility are safe.

Publishing creates an immutable version and materializes it into the existing
parent so the Support catalogue reader remains unchanged. New service requests
resolve the pinned catalogue version. Legacy version-1 parent-only items remain
readable through an adapter fallback; no automatic backfill is performed.

### Workflow configuration

Add MANAGER-only idempotent callables:

```text
itsmCreateWorkflowDraft
itsmUpdateWorkflowDraft
itsmValidateWorkflowDraft
itsmPublishWorkflowVersion
itsmRetireWorkflowVersion
```

Server publication mirrors `WorkflowVersion.validateForPublication()` and also
validates unique transition IDs, permitted three-role values, referenced
approval/group definitions, notification event names and SLA pause/resume
semantics. It rejects no start state, unknown states, unreachable required
states, empty permitted roles, unaudited transitions and mandatory-approval
bypasses.

Published versions are immutable. Active work items retain the pinned version.
Retirement prevents new instances but does not invalidate active instances.
Every draft, validation result, publication and retirement is globally and
locally audited.

### Audit export

Add `itsmRequestAuditExport`, accepting a bounded date range and normalized
filters. It derives the caller role from the agent document, rejects USER,
strips restricted events for ADMIN, applies explicit authorization for MANAGER,
pages on the server, writes CSV to private Storage, and records an expiring
export receipt. The command is idempotent. Export generation never runs in
Flutter.

## Route plan

Add explicit `ItsmRoutes` constants and replace the generic feature builder for
this section with a dedicated route tree:

```text
/services/itsm/reporting-administration
/services/itsm/reporting-administration/dashboards
/services/itsm/reporting-administration/dashboards/operations
/services/itsm/reporting-administration/dashboards/executive
/services/itsm/reporting-administration/dashboards/incidents
/services/itsm/reporting-administration/sla
/services/itsm/reporting-administration/sla/:policyId
/services/itsm/reporting-administration/sla/:policyId/versions/:versionId
/services/itsm/reporting-administration/service-catalogue
/services/itsm/reporting-administration/service-catalogue/:itemId
/services/itsm/reporting-administration/service-catalogue/:itemId/versions/:versionId
/services/itsm/reporting-administration/workflows
/services/itsm/reporting-administration/workflows/:workflowId
/services/itsm/reporting-administration/workflows/:workflowId/versions/:versionId
/services/itsm/reporting-administration/audit-logs
/services/itsm/reporting-administration/audit-logs/:eventId
```

Routing rules:

- `/dashboards` sends MANAGER to operations, ADMIN to executive, and denies USER.
- MANAGER cannot deep-link to executive; ADMIN cannot deep-link to operational queues or edit routes.
- ADMIN uses shared configuration detail routes read-only; draft versions are unavailable.
- Canonical Incident dashboard: `/services/itsm/reporting-administration/dashboards/incidents`.
- `/services/itsm/support/incidents/dashboard` redirects there, preserving query and fragment.
- `/service/incidents/dashboard` and `/service/ticketing/dashboard` redirect directly there.
- Existing Incident entity routes remain unchanged.
- The unrelated bottom-navigation `/dashboard` route remains unchanged.
- Remove the old Incident dashboard navigation link only after route, provider and figure-parity tests pass.

## Query and pagination plan

Every Flutter list uses `PageRequest`/`PageCursor`, fetches at most
`page.limit + 1` (maximum 101), and orders by a stable timestamp plus document
ID. First-page listeners are bounded. Widgets receive models only.

### Report snapshots

- Current dashboards watch deterministic documents by audience/type where possible.
- History queries `audience ==`, `snapshotType ==`, optional scope, then `periodStart DESC`, `__name__ DESC`, limit 101.
- ADMIN queries only ADMIN audience; MANAGER only MANAGER or explicit shared snapshots.

Required indexes:

```text
itsmReportSnapshots: audience ASC, snapshotType ASC,
  periodStart DESC, __name__ DESC
itsmReportSnapshots: audience ASC, snapshotType ASC, scopeType ASC,
  scopeId ASC, periodStart DESC, __name__ DESC
```

Keep the existing audience/period index until callers migrate.

### SLA policies

Management pages order `updatedAt DESC, __name__ DESC` and apply one bounded
server filter at a time:

```text
slaPolicies: status ASC, updatedAt DESC, __name__ DESC
slaPolicies: workItemType ASC, status ASC, updatedAt DESC, __name__ DESC
slaPolicies: serviceId ASC, status ASC, updatedAt DESC, __name__ DESC
slaPolicies: priority ASC, status ASC, updatedAt DESC, __name__ DESC
```

Version history is a bounded parent-subcollection query ordered by version
and document ID descending. Timer workers require this per SLA-enabled source:

```text
lifecycleState ASC, slaNextCheckAt ASC, __name__ ASC
```

Add it at minimum for `incidentTickets`, `changeRequests`, `securityFindings`
and `securityExceptions`; retain the existing service-request SLA index. A
collection participates only when it has a pinned policy and canonical SLA state.

### Catalogue administration

Retain the published-consumer index and add:

```text
serviceCatalogItems: status ASC, updatedAt DESC, __name__ DESC
serviceCatalogItems: categoryId ASC, status ASC, updatedAt DESC, __name__ DESC
```

Search uses bounded `searchTokens` when server token search is required.
Otherwise it filters only the loaded page and clearly indicates that scope. It
never loads the collection for local search.

### Workflow definitions

Supplement the current parent index with actual management query shapes:

```text
workflowDefinitions: status ASC, updatedAt DESC, __name__ DESC
workflowDefinitions: module ASC, status ASC, updatedAt DESC, __name__ DESC
workflowDefinitions: workItemType ASC, status ASC, updatedAt DESC, __name__ DESC
workflowDefinitions: module ASC, workItemType ASC, status ASC,
  updatedAt DESC, __name__ DESC
```

Version history remains bounded under one parent.

### Global audit

Canonical order is `createdAt DESC, __name__ DESC`. The first UI version supports
a date range plus one equality dimension. Unsupported multi-dimension
combinations go through the server export planner instead of causing an
unindexed or unbounded local scan.

Add:

```text
itsmAuditEvents: createdAt DESC, __name__ DESC
itsmAuditEvents: isRestricted ASC, createdAt DESC, __name__ DESC
itsmAuditEvents: isRestricted ASC, actor.userId ASC, createdAt DESC, __name__ DESC
itsmAuditEvents: isRestricted ASC, module ASC, createdAt DESC, __name__ DESC
itsmAuditEvents: isRestricted ASC, entityType ASC, createdAt DESC, __name__ DESC
itsmAuditEvents: isRestricted ASC, entityType ASC, entityId ASC,
  createdAt DESC, __name__ DESC
itsmAuditEvents: isRestricted ASC, entityReference ASC,
  createdAt DESC, __name__ DESC
itsmAuditEvents: isRestricted ASC, action ASC, createdAt DESC, __name__ DESC
itsmAuditEvents: isRestricted ASC, actor.departmentId ASC,
  createdAt DESC, __name__ DESC
itsmAuditEvents: isRestricted ASC, correlationId ASC,
  createdAt DESC, __name__ DESC
itsmAuditEvents: authorizedManagerIds ARRAY_CONTAINS,
  createdAt DESC, __name__ DESC
```

ADMIN queries only `isRestricted == false`. MANAGER merges two bounded pages:
non-restricted events and explicitly authorized restricted events. The
repository deduplicates and sorts those bounded pages. This makes query
constraints provable to Firestore rules.

Keep the current `workItemType/workItemId` index only for old callers; new code
uses `entityType/entityId`.

## Firestore and Storage rule plan

- Add a shared maximum-101 bounded-query helper for Phase 6 list rules.
- Report snapshots: bounded get/list only for matching audience; no client writes and no shard reads.
- Report contributions: no client read/write.
- Catalogue: MANAGER reads all parents/versions; USER/ADMIN read active published parents; ADMIN may inspect published/retired immutable versions; no client writes.
- Workflow/SLA: MANAGER reads all states; ADMIN reads published/retired parents/versions; USER reads published configuration required by self-service; no client writes.
- Global audit: USER denied; MANAGER reads non-restricted and explicitly authorized restricted events; ADMIN reads non-restricted only; all lists bounded; no writes/deletes.
- Audit exports: requester reads only their completed, unexpired metadata; no client writes.
- Export Storage: requester read only when matching metadata is completed, unexpired and UID-owned; no direct upload/update/delete.
- ADMIN mutation remains denied at route, controller, callable, Firestore and Storage layers.
- Reporting rules never permit drill-down to raw findings, compliance evidence, licence secrets or organisation-wide raw incidents.

## Presentation behavior

- Mobile uses one column; tablet/desktop uses the established responsive dashboard grid.
- Dashboards show generation time plus stale/incomplete state.
- ADMIN starts on concise executive KPIs with no action or operational queue controls.
- MANAGER gets operational metrics and separately authorized paginated queue links.
- Configuration lists show draft/published/retired badges and version history.
- ADMIN detail routes reuse read widgets but never construct forms or command controls.
- Workflow issues identify states/transitions and block publication.
- Audit filters are represented in URL query parameters for bounded bookmarks.
- Every screen handles loading, error, empty, stale, denied and retry states.

## Test plan

### Pure Dart unit tests

- Snapshot serialization, schema compatibility and sanitized highlights.
- Incident snapshot fixture parity with `IncidentDashboardAggregator` for manager/admin KPIs, trends, grouping and ordering.
- SLA policy serialization/matching, business hours, holidays, time zones, pause/resume, warning, met and breached calculations.
- SLA draft/publish/retire validation and immutable references.
- Catalogue localization, dynamic fields, required documents, eligibility and version pinning.
- Workflow guardrails plus notification/SLA configuration and immutable versions.
- Audit alias parsing, confidentiality, filter/cursor serialization and stable merge of two bounded MANAGER pages.

### Provider and controller tests

- USER denial, MANAGER operational state and ADMIN read-only state.
- Login user switching/logout invalidates all Phase 6 providers.
- Loading/success/error/empty/stale states and cursor resets after filters.
- Duplicate command prevention and idempotent receipts.
- ADMIN controllers expose no mutation gateway.
- Callable errors map to validation/conflict/access messages.

### Widget tests

- Real five-feature Reporting & Administration overview replaces placeholders.
- Responsive MANAGER/ADMIN dashboards and relocated Incident dashboard.
- Charts accept data and never query Firestore.
- ADMIN has no create/edit/publish/retire or operational actions.
- MANAGER SLA, catalogue and workflow forms validate.
- Workflow validation, version history and confirmation dialogs.
- Audit filters/detail/confidentiality/export and standard UI states.
- English and French localization for every new string.

### Router tests

- USER cannot deep-link to Reporting & Administration.
- MANAGER reaches operations/configuration/authorized audit but not executive-only routes.
- ADMIN reaches executive/read-only configuration but no operational/edit route.
- Dashboard role routing has no loop.
- All old Incident dashboard paths preserve query/fragment and redirect to the canonical route.
- Existing Incident entity links and top-level `/dashboard` remain unchanged.

### Functions and emulator tests

- Role derives only from trusted agent data.
- Configuration validation and every draft/publish/retire transition.
- Published version immutability and active-instance pinning.
- Workflow guardrails server-side and catalogue references only published workflow/SLA versions.
- Business-time SLA batching, pause/resume and deterministic escalation notifications.
- Report contribution add/change/delete deltas, duplicate delivery, compaction, watermarks and sanitized ADMIN output.
- Incident snapshot fixture parity.
- All direct client writes to configuration, snapshots, contributions and audit fail.
- Cross-role snapshot reads and unbounded queries fail.
- USER audit fails; restricted MANAGER audit requires authorization; restricted ADMIN audit fails.
- Export rows and Storage access remain requester/role scoped.
- Existing Incident, Support, Assets, Changes and Security suites stay green.

### Required phase verification

```text
flutter analyze
flutter test
flutter build web --dart-define=FIREBASE_WEB_PUSH_VAPID_KEY=...
cd functions && npm run lint
cd functions && npm run test:unit
Firebase emulator Phase 6 rules/callable/integration suites with JDK 21
git diff --check
```

Use emulator project IDs only. Phase 6 performs no Firebase deployment.

## Implementation order and compatibility gates

1. Add domain/read contracts and fixture tests for snapshots, configuration and audit compatibility.
2. Add report contribution/compaction Functions and security tests.
3. Replace ADMIN's empty dashboard source and MANAGER aggregate source with snapshots; keep the queue separately paginated.
4. Mount the Incident dashboard at the canonical reporting route and pass figure/router parity before redirecting old bookmarks.
5. Implement SLA repositories, callables, rules, screens and generalized server processing; keep the old worker until parity passes.
6. Implement catalogue administration and pinned immutable versions while preserving the Support reader.
7. Implement workflow administration over the existing shared execution engine.
8. Normalize future global audit writes and add the compatibility reader, bounded UI and export.
9. Run Phase 6, complete ITSM and Incident regression suites before removing obsolete dashboard navigation.
10. Produce `docs/itsm/phase_6_delivery_report.md` and commit Phase 6 separately.

## Acceptance mapping

| Acceptance criterion | Phase 6 evidence |
| --- | --- |
| 1. Standalone Incident card replaced | Regression test preserves the existing ITSM product card |
| 2. Five ITSM module cards | Reporting & Administration remains the fifth card |
| 3. Incidents under Support without data loss | Incident entity routes/collections remain unchanged |
| 4. Incident lifecycle and seven-day archival | Existing regression and archival tests remain mandatory |
| 5. USER/MANAGER/ADMIN permissions | Route/controller/callable/rules matrix tests |
| 6. No extra role | Shared three-role enum only |
| 7. Catalogue starts governed requests | Published-parent compatibility and pinned-version tests |
| 8. USER cannot mutate protected/admin records | Section denial and existing operational rule regressions |
| 9. MANAGER completes workflows | Published workflow/SLA/catalogue feeds existing trusted execution |
| 10. ADMIN executive read-only | ADMIN snapshots, read-only widgets, command denial and rules tests |
| 11. Incident dashboard moved | Canonical reporting route, redirects and figure parity |
| 12. Shared mechanisms reused | Existing workflow, SLA, audit, notifications and subresources remain authoritative |
| 13. No widget aggregation | Snapshot repositories/providers supply metrics; charts stay presentation-only |
| 14. Firebase protects data/files | Phase 6 rules/export tests plus all previous suites |
| 15. Cross-user isolation | Snapshot audience, audit confidentiality and export ownership tests |
| 16. Bounded/paginated lists | Maximum-101 repository/rule tests |
| 17. Indexes/Functions documented | This map, tracked indexes, Function exports and delivery report |
| 18. Analyze succeeds | Required verification gate |
| 19. Flutter/emulator tests pass | Required verification gate and regression suites |
| 20. No destructive migration | Adapters and explicit dry-run-only backfill policy; no deployment |

Phase 6 is incomplete if ADMIN receives raw organisation-wide operational data,
if Flutter aggregates unbounded source records, if published configuration can
be mutated, if a client timer advances SLA, or if any required
role/rule/index/parity test is missing.
