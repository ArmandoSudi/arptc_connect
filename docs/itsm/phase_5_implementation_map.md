# ITSM Phase 5 Implementation Map

## Objective

Deliver the Security & Compliance domain foundation for security findings,
security exceptions, asset compliance and access reviews. Phase 5 reuses the
shared ITSM confidentiality, approval and three-role contracts. It does not
introduce a new top-level role or grant ADMIN operational access.

## Access map

| Capability | USER | MANAGER | ADMIN |
| --- | --- | --- | --- |
| Security findings | No raw access | Full operational access, subject to restricted-data authorization | Aggregate reporting only |
| Security exceptions | Submit and read own | Process and approve, with separation of duties | Submit and read own |
| Asset compliance | Safe own-device status only | Assess and track remediation | Aggregate reporting only |
| Access reviews | Own access and correction/revocation requests | Create and perform reviews | Own access and correction/revocation requests |
| Restricted evidence | No | Explicitly authorized operational access | No raw access |

Hidden controls are not authorization. Application policies, trusted commands,
Firestore rules and Storage rules must enforce the same matrix when the
remaining Phase 5 layers are implemented.

## Authoritative paths

```text
securityFindings/{findingId}
securityFindings/{findingId}/comments/{commentId}
securityFindings/{findingId}/attachments/{attachmentId}
securityFindings/{findingId}/auditLogs/{eventId}
securityExceptions/{exceptionId}
securityExceptions/{exceptionId}/approvals/{approvalId}
securityExceptions/{exceptionId}/comments/{commentId}
securityExceptions/{exceptionId}/attachments/{attachmentId}
securityExceptions/{exceptionId}/auditLogs/{eventId}
assetComplianceAssessments/{assessmentId}
assetComplianceSelfService/{projectionId}
accessReviewCampaigns/{campaignId}
accessReviewItems/{itemId}
accessReviewItems/{itemId}/revocationTasks/{taskId}
itsmWorkItemIndex/{summaryId}
itsmAuditEvents/{eventId}
notificationEvents/{eventId}
```

Authoritative operational records retain sensitive details. Self-service asset
compliance uses a separate safe projection because Firestore cannot hide fields
inside an otherwise readable document.

## Domain rules

- Findings support `detected`, `triaged`, `assigned`, `remediation`,
  `validation`, `closed`, `risk_accepted` and `cancelled` states.
- Restricted finding evidence is readable only by explicitly authorized
  MANAGER users. USER and ADMIN never receive raw finding evidence.
- Exception requests validate their requested period, compensating controls,
  review date, approval state, closure and renewal.
- A requester cannot be the sole approver of their own security exception.
- Exception renewal extends the current end date and requires a justification,
  review date and a new approval cycle.
- Asset compliance calculates a detailed operational result from individual
  checks, while the self-service projection exposes only `compliant`,
  `action_required` or `assessment_pending`.
- Access-review decisions are made by MANAGER reviewers, capture justification
  and evidence, and require an immutable revocation/change task for decisions
  that remove or modify access.
- USER and ADMIN correction/revocation actions create governed requests; they
  never mutate review items or source-system access directly.

## Planned server boundaries

Trusted Cloud Functions will own workflow transitions, approvals, expiry and
review reminders, self-service projection writes, revocation-task creation,
audit/index writes and notification events. Event-driven handlers must be
idempotent and all scheduled processing must use server time.

## Verification map

- Domain: immutable serialization, finding transitions, confidentiality,
  exception dates/expiry/renewal, self-approval separation, compliance-state
  calculation, safe projection shape, campaign lifecycle, decisions and
  revocation tasks.
- Application/data: role-scoped bounded queries, session switching, duplicate
  command prevention and trusted Function error mapping.
- Presentation/router: role-specific actions, self-service-only ADMIN views,
  restricted-data denial and responsive state handling.
- Emulator: cross-user isolation, restricted Firestore/Storage evidence,
  append-only approvals/audit, trusted projection writes and self-approval
  denial.

This domain-foundation slice changes no Firebase resource, deploys nothing and
migrates no production data.
