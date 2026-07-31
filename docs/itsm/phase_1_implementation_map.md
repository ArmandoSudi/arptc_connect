# ITSM Phase 1 Implementation Map

## Product Shell

| Concern | Implementation |
| --- | --- |
| Product module | `AppModule.itsm` replaces the duplicate Incident-facing card. |
| Stored permission | `ticketing` remains canonical in Firestore. |
| Permission aliases | `itsm`, `it_service_management`, `support`, incident, ticket, and existing aliases normalize to `ticketing`. |
| Canonical root | `/services/itsm` |
| Compatibility roots | `/service/itsm`, `/service/incidents`, and `/service/ticketing` redirect while preserving suffixes and query parameters. |
| Main sections | Support, Assets & Configuration, Changes, Security & Compliance, Reporting & Administration. |
| Responsive behavior | One, two, or three navigation columns for mobile, tablet, and desktop. |
| Localization | Every Phase 1 label and access state is available in English and French. |

## Permission Boundaries

| Access type | USER | MANAGER | ADMIN |
| --- | --- | --- | --- |
| Self-service routes | Allowed | Allowed | Allowed |
| Operational routes | Denied | Allowed | Denied |
| Reporting & Administration | Denied | Operational/configuration access | Read-only executive access |
| Manager-only feature deep links | Denied | Allowed | Denied |
| Missing/invalid ITSM permission | Access state, no protected child built | Access state | Access state |

Route guards execute before destination widgets build. Firestore and Storage
rules remain authoritative and mirror the same boundaries.

## Shared Domain

- `ItsmRole`, work-item type, lifecycle, priority, impact, urgency,
  confidentiality, and publication state.
- `ItsmWorkItemSummary`.
- Versioned workflow definitions, states, transitions, validation, publishing,
  and retirement.
- Approval policies, decisions, delegation, immutable decision history, and
  separation of duties.
- Business calendars, holidays, SLA policies, SLA state, and measurements.
- Immutable audit events, comments, attachments, and fulfilment tasks.
- Bounded generic page request, cursor, and result contracts.
- Permission policy for self-service, operational, and executive behavior.

The domain layer has no Flutter or Firebase dependencies.

## Shared Data And Application

- Repository interfaces expose bounded work-item summaries, reference data,
  assignment groups, published catalogue entries, notification summaries, and
  record-specific resources.
- Existing Incident repositories are adapted rather than copied.
- Riverpod providers are session- and permission-scoped, overrideable in tests,
  and invalidate across authentication changes.
- Mutations use command gateway interfaces with duplicate-submission
  prevention and mapped application failures.
- Widgets never query Firestore directly.

## Trusted Backend

- Callable command boundaries authenticate the actor and resolve the `ticketing`
  role from trusted agent data.
- Workflow transitions, approvals, global audit writes, work-item index writes,
  SLA processing, and notification event creation are server-controlled.
- Commands require idempotency/correlation identifiers and reject unknown
  command types.
- Authoritative timestamps use server time.
- Existing notification and incident archival exports remain intact.

## Security

- New shared collections are deny-by-default.
- USER and ADMIN self-service reads are requester scoped.
- MANAGER receives operational access where configured.
- ADMIN reporting access is read-only.
- Global audit, work-item index, report snapshot, and SLA state writes are
  trusted-server only.
- Attachment access inherits the parent work-item's authorization and
  confidentiality.
- Emulator tests cover representative allow and deny paths.

## Verification Map

- Domain unit tests.
- Provider/controller session and command tests.
- Module replacement, responsive shell, localization, redirect, and route-guard
  widget tests.
- Cloud Functions unit tests.
- Firestore and Storage emulator tests under JDK 21.
- Targeted analysis plus the complete Flutter test suite.
- Web build before phase completion.
