# ITSM Phase 2 Implementation Map

## Objective

Deliver the Support capability without replacing the existing Incident source
of truth. Phase 2 adds governed service requests, a trusted cross-type My
Requests index, and Knowledge Base workflows while preserving all Incident
IDs, statuses, comments, attachments, audit history, notifications, dashboard
calculations, and seven-day archival behavior.

## Reuse and adaptation map

| Capability | Existing implementation reused | Phase 2 adaptation |
| --- | --- | --- |
| Incidents | `incidentTickets`, existing repositories, role screens, comments, attachments, audit logs, dashboards, FCM events | Canonical Support routes, additive linked-record fields, knowledge suggestions, resolution article links |
| Identity and roles | Firebase Auth, live agent profile, `modulePermissions.ticketing` | `ItsmSession`, shared permission policy, USER/ADMIN self-service isolation, MANAGER operational access |
| Service Catalogue | Shared workflow and SLA version contracts from Phase 1 | Published, eligible catalogue reads; localized dynamic fields; document requirements; bounded pagination |
| Service Requests | Shared work-item, workflow, approval, audit, task, attachment, SLA, and command contracts | Authoritative `serviceRequests` documents, trusted draft/submit/transition commands, request-on-behalf, governed child resources |
| My Requests | Incident adapter and Phase 1 work-item repository interface | Trusted `itsmWorkItemIndex`, cross-type summaries, owner-scoped bounded queries, cursor pagination, filters, status/SLA indicators |
| Knowledge Base | Phase 1 pagination and role policies | Categories, article/version models, published library, manager lifecycle, visibility, feedback, usage, suggestions, attachments |
| Notifications | Existing `notificationEvents` and FCM delivery pipeline | Deterministic service-request, assignment, approval, status, and SLA event envelopes with canonical deep links |
| Firebase protection | Existing authentication helpers and Incident rules | Deny-by-default Support rules, callable-only protected mutations, parent-aware attachment access, immutable audit/index writes |

## Authoritative Firestore paths

```text
incidentTickets/{ticketId}
serviceCatalogItems/{catalogueItemId}
serviceRequests/{requestId}
serviceRequests/{requestId}/comments/{commentId}
serviceRequests/{requestId}/attachments/{attachmentId}
serviceRequests/{requestId}/auditLogs/{eventId}
serviceRequests/{requestId}/tasks/{taskId}
serviceRequests/{requestId}/approvals/{approvalId}
serviceRequests/{requestId}/workflowInstances/{instanceId}
knowledgeCategories/{categoryId}
knowledgeArticles/{articleId}
knowledgeArticles/{articleId}/versions/{versionId}
knowledgeArticles/{articleId}/versions/{versionId}/attachments/{attachmentId}
knowledgeArticles/{articleId}/feedback/{userId}
knowledgeArticles/{articleId}/views/{eventId}
itsmWorkItemIndex/{type}:{workItemId}
itsmAuditEvents/{eventId}
notificationEvents/{eventId}
```

The authoritative domain collections remain the source of truth.
`itsmWorkItemIndex` is a trusted summary read model only.

## Initial configuration provisioning

The fourteen required catalogue items and their pinned workflow/SLA version
documents are generated from the Dart domain definitions:

```text
tool/itsm/generate_phase2_seed.dart
tool/seeds/itsm_phase2_seed.json
tool/itsm/provision_phase2_seed.js
```

The provisioning command is dry-run by default. Applying it requires an
explicit `--apply` flag and valid administrator credentials. Existing
deterministic documents are skipped unless an operator deliberately adds
`--overwrite`; the implementation never invokes either write mode during
deployment, tests, or this phase.

## Trusted command boundaries

- Initialize a service-request draft before requester attachments are uploaded.
- Submit a validated request using a published catalogue item and pinned
  workflow/SLA versions.
- Transition, cancel, reject, confirm, assign, and decide approvals through
  callable Functions with role, state, revision, and idempotency checks.
- Maintain work-item summaries, audit events, notifications, task/approval
  synchronization, and SLA state through trusted Functions.
- Create article drafts/versions and execute review, reject, publish, retire,
  archive, feedback, and view commands through trusted Functions.
- Reject client writes to global indexes, protected workflow fields, counters,
  immutable decisions, and audit records.

## Canonical navigation

```text
/services/itsm/support/incidents
/services/itsm/support/incidents/create
/services/itsm/support/incidents/my/:ticketId
/services/itsm/support/incidents/manager/:ticketId
/services/itsm/support/service-requests
/services/itsm/support/service-requests/:requestId
/services/itsm/support/my-requests
/services/itsm/support/knowledge
/services/itsm/support/knowledge/:articleId
/services/itsm/support/knowledge/manage
/services/itsm/support/knowledge/manage/{articleId}/edit
/services/itsm/support/knowledge/manage/{articleId}/review
```

Legacy Incident routes continue to redirect to the canonical Support tree while
preserving entity IDs and query parameters.

## Verification map

- Incident compatibility, lifecycle, ownership, dashboard parity, archival,
  notifications, linked records, and knowledge-link tests.
- Catalogue serialization, eligibility, form validation, required documents,
  version pinning, and initial seed tests.
- Service-request lifecycle, access policy, cancellation, rejection,
  approvals, tasks, attachments, SLA, command, provider, and widget tests.
- Work-item index serialization, owner isolation, pagination, sorting, filters,
  and session-switch tests.
- Seed completeness tests proving each catalogue item has a deterministic
  published workflow version and SLA version.
- Knowledge visibility, lifecycle, immutable versions, suggestions, feedback,
  repository pagination, command, provider, and presentation tests.
- Functions unit tests plus Firestore and Storage emulator allow/deny tests.
- Targeted analysis, complete Flutter tests, Functions lint/tests, and
  `git diff --check` before the Phase 2 commit.

No Firebase resource is deployed and no production document is migrated by
this phase.
