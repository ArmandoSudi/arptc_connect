# ITSM Phase 0 Incident Baseline

## Purpose

This document captures the Incident Management behavior that must remain compatible while it becomes the Incidents capability under ARPTC CONNECT IT Service Management. It is based on the repository state at commit `321984d` and the requirements in `ARPTC_CONNECT_ITSM_CODEX_IMPLEMENTATION_INSTRUCTIONS.md`.

## Existing implementation map

| Concern | Existing implementation | Phase 0 compatibility requirement |
| --- | --- | --- |
| Domain | `IncidentTicket`, incident enums, comments, attachments, audit logs, categories, IT services, resolution codes | Preserve Firestore field names, status/lifecycle values, legacy priority aliases, null/default parsing, IDs, and subcollection contracts. |
| Data access | `IncidentRepository` and `FirestoreIncidentRepository` | Preserve `incidentTickets` and its subcollections. Bounded live queries and cursor page APIs now protect existing consumers from unbounded reads. |
| Session and roles | Riverpod providers in `incident_providers.dart` | Keep session-aware subscriptions and the `USER`, `MANAGER`, `ADMIN` role values. Stored permission aliases currently resolve to the incident role. |
| Presentation | Role gate, user home/details, manager dashboard/queues/details/parameters/history, admin dashboard | Reuse these screens beneath ITSM routes. Do not rewrite the incident workflow or remove legacy routes before redirects are verified. |
| Dashboard | Pure `IncidentDashboardAggregator` and presentation-only chart widgets | Preserve current KPI definitions, grouping, filtering of deleted tickets, and operational queue ordering. |
| Notifications | `IncidentNotificationFactory`, `notificationEvents`, and Cloud Function dispatch | Preserve manager notification on USER submission and assignee notifications after assignment. |
| Security | Incident helpers and matches in `firestore.rules` | USER owns records by UID or email, MANAGER operates active/closed records, ADMIN is currently read-only, and deletes are denied. Rules remain authoritative. |
| Cloud Functions | Notification and user-provisioning v2 functions plus the scheduled v2 incident archival function | Preserve existing notification behavior. Archive eligible closed incidents in bounded, idempotent batches. |
| Firebase indexes | `firestore.indexes.json`, registered in `firebase.json` | Keep composite indexes aligned with bounded incident queues, pagination, and archival. |
| Tests | Notification, session switching, history filtering, and resolution-code tests | The focused regression suites added with this document lock role subscription boundaries, ownership aggregation, lifecycle/archival fields, dashboard parity, and serialization compatibility. |

## Current Firestore contract

Authoritative collection:

- `incidentTickets/{ticketId}`
- `incidentTickets/{ticketId}/comments/{commentId}`
- `incidentTickets/{ticketId}/attachments/{attachmentId}`
- `incidentTickets/{ticketId}/auditLogs/{logId}`
- `incidentCategories/{categoryId}`
- `itServices/{serviceId}`
- `incidentResolutionCodes/{resolutionCodeId}`

Stable status values:

- `open`
- `categorized`
- `assigned`
- `in_progress`
- `resolved`
- `closed`
- `archived`
- `cancelled`

Stable lifecycle values:

- `active`
- `closed`
- `archived`

Closing currently writes `status = closed`, `lifecycleState = closed`, a server `closedAt`, and `archiveEligibleAt` approximately seven days after the client UTC close time. Flutter does not archive records. The scheduled v2 function queries closed, non-deleted records whose eligibility timestamp has passed and archives them in bounded, duplicate-safe batches.

## Current role and ownership behavior

- **USER:** Creates an open/active incident for themselves; subscribes to active and closed/archived tickets by affected-user email; can read records where their UID or email matches the creator or affected user; cannot perform manager updates.
- **MANAGER:** Creates an open incident or a categorized in-progress incident for a selected affected user; subscribes to all active, all closed, and assigned-to-me operational queues; can categorize, assign, resolve, close, cancel, and add internal notes; cannot delete.
- **ADMIN:** Has a read-only organisation-wide provider and Firestore read access today; cannot create or update incidents. The ITSM specification requires the future self-service view to be owner-scoped and organisation-wide access to move to read-only Reporting & Administration snapshots.
- **NONE/unauthenticated:** Incident providers return empty data and do not subscribe to protected repositories.

Comments and audit logs are append-only from the client. USER comments must be public; MANAGER notes are internal. Attachments are append-only and inherit parent ticket visibility.

## Dashboard compatibility baseline

Manager statistics:

- Open count means active tickets with status `open`.
- Unassigned means active, no assignee, and status `categorized` or `in_progress`.
- Assigned-to-me matches the current user ID.
- Critical means active P1 or P2.
- Solved means active `resolved`.
- Operational queue excludes deleted/non-active records and sorts P1 through P4, unprioritized last, then oldest first.

Admin statistics:

- Exclude soft-deleted records.
- Count active, closed, and archived lifecycle states separately.
- Current-month service/category/department/priority groups use `createdAt`.
- Average resolution time uses `closedAt - createdAt` for closed records with both timestamps.
- Recent critical contains the latest five P1/P2 records.
- The six-month trend is calculated in memory from incident documents.

## Remaining compatibility gaps for later phases

1. ADMIN self-service reads are organisation-wide instead of owner-scoped.
2. Ticket details, comments, and audit providers rely on Firestore rules for per-record ownership after only checking that the caller has an incident role.
3. Production rules and Storage rules still need emulator regression coverage.
4. The archive eligibility timestamp is based partly on client time; trusted transition commands should derive it from server time.
5. Existing legacy routes use `/service/incidents` and `/service/ticketing`; canonical ITSM routes and redirects are not yet present.

## Regression command

```sh
flutter test test/modules/incident_management
```

Phase 0 changes Firebase Functions and index configuration locally only. Nothing is deployed.
