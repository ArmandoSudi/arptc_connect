# ITSM Phase 4 Implementation Map

## Objective

Deliver governed standard, normal and emergency Change Management without
changing the stored `ticketing` permission key or weakening the Phase 1 shared
workflow, approval, audit, notification and pagination contracts.

## Access map

| Capability | USER | MANAGER | ADMIN |
| --- | --- | --- | --- |
| Change requests | Create and read own | Full operational access | Create and read own |
| Assessment and plans | No | Create and update | No |
| CAB decisions | No | Configured MANAGER groups | No |
| Calendar | Own and published maintenance | Full bounded calendar | Read-only executive/public view |
| Implementation and review | No | Execute and record | No |

Route guards, repositories, callable Functions and Firebase rules enforce this
matrix. Hidden controls are not considered authorization.

## Authoritative paths

```text
changeRequests/{changeId}
changeRequests/{changeId}/approvals/{approvalId}
changeRequests/{changeId}/cabMeetings/{meetingId}
changeRequests/{changeId}/comments/{commentId}
changeRequests/{changeId}/attachments/{attachmentId}
changeRequests/{changeId}/auditLogs/{eventId}
changeCalendarEntries/{changeId}
changeApprovalGroups/{groupId}
maintenanceWindows/{windowId}
itsmWorkItemIndex/{summaryId}
itsmAuditEvents/{eventId}
notificationEvents/{eventId}
```

`changeRequests` remains authoritative. Calendar, work-item and audit
collections are trusted projections maintained idempotently by Functions.

## Lifecycle and commands

```text
draft -> submitted -> assessment -> awaiting_approval -> approved
approved -> scheduled -> implementation -> review -> closed
awaiting_approval -> rejected
implementation -> failed | rolled_back
non-terminal states -> cancelled when policy permits
```

- Draft initialization pins the workflow definition/version.
- Standard changes may follow a pre-authorized published workflow.
- Normal and emergency changes require an approval decision by a different
  MANAGER from the requester.
- Every transition validates the current status and revision, mandatory fields,
  actor permissions, approval state and idempotency key in a transaction.
- Assessment captures affected services, CIs/assets, impact, urgency, risk,
  plans, evidence, downtime and the planned implementation window.
- CAB decisions support approve, reject and clarification, plus conditions,
  comments, emergency context and immutable history.
- Scheduling detects overlaps by bounded date-window queries and records
  maintenance-window/conflict indicators.
- Implementation, rollback/failure and post-implementation review results are
  server timestamped and audited.

## Calendar queries

- Month, week and agenda views always provide explicit start/end bounds.
- MANAGER reads the operational projection.
- USER reads own entries plus explicitly published maintenance information.
- ADMIN reads only the published/read-only executive projection.
- Filters apply service, CI, change type, status and conflict state without
  introducing unbounded collection scans.

## Verification map

- Domain: serialization, risk, lifecycle, conflict detection, CAB models and
  separation of duties.
- Application/data: session switching, role-scoped queries, bounded cursors,
  duplicate command prevention and server error mapping.
- Presentation/router: responsive request/detail/approval/calendar screens,
  role-specific controls, denied deep links and read-only ADMIN behavior.
- Functions: authentication, role checks, transition guards, immutable decision
  history, version pinning, calendar projection and notifications.
- Emulator: cross-user isolation, MANAGER operations, self-approval denial,
  client-write denial, bounded calendar visibility and append-only history.

No Firebase resource is deployed and no production document is migrated by
this phase.
