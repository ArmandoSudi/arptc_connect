# ARPTC CONNECT — IT Service Management Implementation Instructions for Codex

**Document type:** Implementation specification and execution prompt  
**Target application:** ARPTC CONNECT  
**Target stack:** Flutter, Riverpod, Firebase Authentication, Cloud Firestore, Firebase Storage, Firebase Cloud Messaging and Cloud Functions  
**Version:** 1.0  
**Date:** 31 July 2026

---

## 1. Mission

You are working inside the existing ARPTC CONNECT codebase.

Extend the current Incident Management feature into an integrated **IT Service Management (ITSM)** area aligned with ITIL practices.

The existing Incident Management capability must not be removed or rewritten from scratch. It must become the **Incidents** subfeature of the new **Support** module. Preserve its data, business rules, permissions, comments, attachments, audit history and lifecycle.

The new ITSM area must contain:

```text
IT Service Management
├── Support
│   ├── Incidents
│   ├── Service Requests
│   ├── My Requests
│   └── Knowledge Base
├── Assets & Configuration
│   ├── Assets
│   ├── Stock
│   ├── Licences
│   ├── Suppliers & Warranties
│   └── CMDB
├── Changes
│   ├── Change Requests
│   ├── Approvals / CAB
│   └── Change Calendar
├── Security & Compliance
│   ├── Security Findings
│   ├── Security Exceptions
│   ├── Asset Compliance
│   └── Access Reviews
└── Reporting & Administration
    ├── Dashboards
    ├── SLA
    ├── Service Catalogue
    ├── Workflow Configuration
    └── Audit Logs
```

The modules must share:

- The same organisation and user data.
- The same three roles.
- A shared work-item contract.
- A shared workflow engine.
- A shared approval mechanism.
- A shared SLA mechanism.
- A shared audit service.
- A shared notification service.
- A shared reporting layer.
- Reusable comments, attachments and activity timelines.

---

## 2. Non-negotiable constraints

### 2.1 Inspect before modifying

Before writing code:

1. Read every applicable `AGENTS.md` file.
2. Inspect `pubspec.yaml`, Firebase configuration and the current project structure.
3. Identify the existing:
   - Incident domain model.
   - `incidentTickets` Firestore repository.
   - Incident providers/controllers.
   - Incident screens and routes.
   - Incident comments, attachments and audit-log implementations.
   - Authentication and role providers.
   - Services-page module registry.
   - Dashboard aggregation service/helpers.
   - Firestore and Storage rules.
   - Cloud Functions.
   - Firestore indexes.
   - Unit, widget and integration tests.
4. Produce a short implementation map identifying the existing files that will be reused, moved, adapted or newly created.

Follow the architecture and naming conventions already established in the repository. Do not introduce a second competing architecture.

### 2.2 Preserve the existing Incident Management behaviour

Preserve:

- The top-level `incidentTickets` collection unless an explicit, tested migration is approved.
- Existing subcollections for:
  - Comments.
  - Attachments.
  - Audit logs.
- Existing incident identifiers and references.
- Existing uploaded files and URLs.
- Existing USER and MANAGER incident permissions.
- The existing rule that ADMIN cannot operate incidents. Move ADMIN’s organisation-wide
  read-only incident visibility into Reporting & Administration; keep the ADMIN
  self-service incident list scoped to their own records.
- Existing incident status values:
  - `open`
  - `categorized`
  - `assigned`
  - `in_progress`
  - `resolved`
  - `closed`
  - `archived`
  - `cancelled`
- Existing lifecycle-state values:
  - `active`
  - `closed`
  - `archived`
- The scheduled Cloud Function that archives closed incidents after seven days.

Scheduled archival must remain server-side. Do not implement incident archival timers in Flutter.

### 2.3 Preserve the three-role model

Use only:

```text
USER
MANAGER
ADMIN
```

Do not introduce additional top-level roles such as `ASSET_MANAGER`, `CHANGE_MANAGER`, `AUDITOR` or `SECURITY_OFFICER`.

Use assignment groups, named approvers, ownership and workflow configuration to distribute work between MANAGER users without creating new application roles.

### 2.4 Role names have specific meanings

- `USER` means a normal ARPTC employee consuming DSI services.
- `MANAGER` means a DSI operator with operational ITSM access.
- `ADMIN` means the executive/CEO overview role. It is not a technical super-administrator.

Do not interpret `ADMIN` as permission to modify every record.

### 2.5 Preserve the current platform

Preserve:

- Flutter presentation.
- Riverpod state management.
- Firebase Authentication.
- Firestore persistence.
- Firebase Storage attachments.
- Firebase Cloud Messaging notifications.
- Cloud Functions for scheduled, privileged and aggregate operations.

Do not replace Firebase or introduce another backend platform as part of this implementation.

### 2.6 Security rules are authoritative

Role restrictions must be enforced by Firestore rules, Storage rules and privileged server-side commands where required.

Hiding a screen, button or navigation item is not sufficient access control.

### 2.7 No destructive migration

- Do not delete existing incident records.
- Do not remove the current Incident dashboard until its replacement is validated.
- Do not rename collections without a backward-compatible migration.
- Do not hard-delete auditable ITSM records.
- Use status-based retirement, cancellation or archival.
- Backfill new fields safely with null/default handling.

---

## 3. Product navigation

### 3.1 ARPTC CONNECT Services page

Replace the existing standalone **Incident Management** service card with:

```text
IT SERVICE MANAGEMENT
```

Selecting it must open:

```text
/services/itsm
```

Do not create a second duplicate Incident Management card.

### 3.2 ITSM landing page

Display five responsive cards in a grid:

1. Support
2. Assets & Configuration
3. Changes
4. Security & Compliance
5. Reporting & Administration

Each card must include:

- Icon.
- Name.
- Short description.
- Optional count badge relevant to the current user.
- Accessible keyboard interaction.
- Hover, focus and pressed states.
- Responsive layout for web, tablet and mobile.

All five cards may be visible so users understand the ITSM structure, but the destination content and available actions must respect permissions.

For a feature with no permitted action, show an explanatory access state rather than loading protected data.

### 3.3 Suggested route tree

Use the project’s existing router conventions. The logical routes are:

```text
/services/itsm

/services/itsm/support
/services/itsm/support/incidents
/services/itsm/support/service-requests
/services/itsm/support/my-requests
/services/itsm/support/knowledge

/services/itsm/assets-configuration
/services/itsm/assets-configuration/assets
/services/itsm/assets-configuration/stock
/services/itsm/assets-configuration/licences
/services/itsm/assets-configuration/suppliers-warranties
/services/itsm/assets-configuration/cmdb

/services/itsm/changes
/services/itsm/changes/requests
/services/itsm/changes/approvals
/services/itsm/changes/calendar

/services/itsm/security-compliance
/services/itsm/security-compliance/findings
/services/itsm/security-compliance/exceptions
/services/itsm/security-compliance/asset-compliance
/services/itsm/security-compliance/access-reviews

/services/itsm/reporting-administration
/services/itsm/reporting-administration/dashboards
/services/itsm/reporting-administration/sla
/services/itsm/reporting-administration/service-catalogue
/services/itsm/reporting-administration/workflows
/services/itsm/reporting-administration/audit-logs
```

Deep links must apply the same permissions as navigation.

---

## 4. Role and permission requirements

### 4.1 USER

A USER can:

- Create an incident.
- View their own active, closed and archived incidents.
- Add comments and permitted attachments to their own active records.
- Browse the published DSI service catalogue.
- Submit allowed service requests.
- View all their own requests in **My Requests**.
- View the status, approval history and fulfilment progress of their own requests.
- Cancel their own request only when its workflow allows cancellation.
- Read published knowledge articles visible to employees.
- View assets currently assigned to them.
- Request an asset, asset replacement, repair, return or configuration change through the service catalogue.
- Submit a change request when the selected catalogue/workflow permits it.
- View their own change requests.
- Submit a security-exception request when permitted.
- View their own security-exception request.
- View their own access information or initiate an access-related request when permitted.

A USER cannot:

- Browse the full asset inventory.
- Directly create, edit, assign, transfer or dispose of an asset.
- Directly modify stock.
- Modify licences, suppliers, warranties or CMDB relationships.
- Assess, approve, schedule or implement a change.
- View CAB deliberations that are not explicitly published.
- Browse organisation-wide security findings.
- Mark an asset compliant.
- Perform an access review for another user.
- Access Reporting & Administration.
- Read another user’s work items.
- Edit SLA, catalogue or workflow definitions.
- Read global audit logs.

User-initiated asset, access, security or change actions must create governed requests. They must not mutate operational records directly.

### 4.2 MANAGER

A MANAGER represents a DSI operator.

A MANAGER can:

- Access all operational ITSM modules.
- View and process all incidents.
- Categorise, prioritise, assign, resolve, close and cancel incidents according to the existing workflow.
- Create requests on behalf of users.
- Process, assign, approve where allowed, fulfil, reject, cancel and close service requests.
- Manage knowledge articles.
- Manage assets, stock, licences, suppliers, warranties and CMDB records.
- Initiate and process asset lifecycle actions.
- Create, assess, approve, schedule, implement and review changes.
- Participate in CAB approval.
- Create and manage security findings and exceptions.
- Perform asset-compliance checks.
- Perform access reviews.
- View operational and management dashboards.
- Configure service-catalogue items.
- Configure SLA policies.
- Configure and publish workflow definitions.
- View audit records required for operational work.

Apply separation of duties where relevant:

- The requester of a normal or emergency change should not approve their own change.
- The requester of a security exception should not be its sole approver.
- A stock movement must identify the operator and the receiving/issuing party.

These controls must use different MANAGER users or configured approval groups. They do not require new top-level roles.

### 4.3 ADMIN

An ADMIN has:

- The same self-service permissions as a USER.
- Read-only access to Reporting & Administration for executive oversight.
- Read-only access to organisation-wide dashboard aggregates.
- Read-only access to SLA definitions and performance.
- Read-only access to service-catalogue definitions.
- Read-only access to published workflow configurations.
- Read-only access to audit logs, subject to confidentiality restrictions.

An ADMIN cannot:

- Operate incidents or requests belonging to other users.
- Assign or resolve tickets.
- Modify assets or configuration items.
- Approve or implement changes.
- Modify security findings or exceptions.
- Change SLA, catalogue or workflow configuration.
- Modify or delete audit records.

The ADMIN experience must default to concise executive dashboards rather than operational queues.

### 4.4 Permission matrix

| Feature | USER | MANAGER | ADMIN |
|---|---|---|---|
| Incidents | Create and view own | Full operational access | Own incidents only |
| Service catalogue consumption | Browse published items | Browse and submit | Browse published items |
| Service-catalogue administration | No | Create/edit/publish/retire | Read-only |
| Service requests | Create/view own | Full operational access | Create/view own |
| My Requests | Own only | Own plus operational access through queues | Own only |
| Knowledge Base | Read published | Author/review/publish/archive | Read published |
| Assets | View own assigned assets | Full operational access | View own assigned assets |
| Stock | No direct access | Full operational access | No direct access |
| Licences | No direct access | Full operational access | No direct access |
| Suppliers & warranties | No direct access | Full operational access | No direct access |
| CMDB | No direct access | Full operational access | No direct access |
| Change requests | Submit/view own | Full operational access | Submit/view own |
| CAB/approvals | No | Participate and manage | Read dashboard summaries only |
| Change calendar | Own/published changes | Full calendar | Executive read-only view |
| Security findings | No | Full operational access | Aggregate dashboard only |
| Security exceptions | Submit/view own | Full operational access | Submit/view own |
| Asset compliance | Own-device summary where safe | Full operational access | Aggregate dashboard only |
| Access reviews | Own access/request correction | Full operational access | Own access only |
| Dashboards | Personal summaries outside admin module | Full | Executive read-only |
| SLA configuration | No | Full | Read-only |
| Workflow configuration | No | Full | Read-only |
| Audit logs | Own activity timeline only | Operational access | Executive read-only |

---

## 5. Application architecture

Use a feature-first structure while preserving the current project conventions and the existing presentation, application, domain and data layers.

Suggested logical structure:

```text
lib/src/
├── core/
│   ├── auth/
│   ├── permissions/
│   ├── routing/
│   ├── shared_ui/
│   └── firebase/
├── features/
│   └── itsm/
│       ├── shared/
│       │   ├── domain/
│       │   ├── application/
│       │   ├── data/
│       │   └── presentation/
│       ├── support/
│       │   ├── incidents/
│       │   ├── service_requests/
│       │   ├── my_requests/
│       │   └── knowledge/
│       ├── assets_configuration/
│       │   ├── assets/
│       │   ├── stock/
│       │   ├── licences/
│       │   ├── suppliers_warranties/
│       │   └── cmdb/
│       ├── changes/
│       │   ├── change_requests/
│       │   ├── approvals/
│       │   └── calendar/
│       ├── security_compliance/
│       │   ├── findings/
│       │   ├── exceptions/
│       │   ├── asset_compliance/
│       │   └── access_reviews/
│       └── reporting_administration/
│           ├── dashboards/
│           ├── sla/
│           ├── service_catalogue/
│           ├── workflows/
│           └── audit_logs/
```

Do not duplicate common widgets, repositories or services inside each subfeature.

### 5.1 Layer responsibilities

#### Presentation

- Screens and responsive layouts.
- Form widgets.
- Riverpod provider consumption.
- Role-aware commands and navigation.
- Loading, empty, error and permission-denied states.
- No direct Firestore calls.
- No aggregation logic inside dashboard widgets.

#### Application

- Controllers/notifiers.
- Use cases.
- Workflow commands.
- Coordination between repositories.
- Input validation.
- Permission-aware application actions.

#### Domain

- Entities and value objects.
- Status and lifecycle rules.
- Workflow transition policies.
- SLA calculations.
- Permission policies.
- Repository interfaces.
- No Flutter or Firebase dependencies.

#### Data

- Firestore repositories.
- DTOs and converters.
- Firebase Storage.
- Cloud Function gateways.
- Pagination cursors.
- Firestore query definitions.
- Error mapping.

---

## 6. Shared ITSM foundation

### 6.1 Shared work-item contract

Incidents, service requests, change requests, security findings and security exceptions must implement a common read contract.

Suggested common fields:

```text
id
reference
type
title
description
requesterId
affectedUserId
departmentId
serviceId
locationId
assignedGroupId
assignedUserId
priority
impact
urgency
status
lifecycleState
workflowDefinitionId
workflowVersion
createdAt
createdBy
updatedAt
updatedBy
dueAt
closedAt
confidentiality
linkedAssetIds
linkedCiIds
```

Do not force all type-specific data into one large model. Use domain-specific records alongside the common fields.

### 6.2 Firestore compatibility strategy

Preserve `incidentTickets` as the source of truth for existing incidents.

Use separate domain collections for new record types, while applying the same common work-item contract:

```text
incidentTickets
serviceRequests
changeRequests
securityFindings
securityExceptions
```

Create a denormalised summary collection for cross-type screens:

```text
itsmWorkItemIndex
```

Use it for:

- My Requests.
- Cross-module search.
- User activity summaries.
- Operational queues where multiple work-item types are required.
- Reporting aggregation inputs.

The index must contain summary data only. Domain collections remain authoritative.

Maintain the index through trusted server-side logic or idempotent repository operations. Do not let clients arbitrarily forge global work-item summaries.

### 6.3 Common subresources

Reuse a consistent contract for:

```text
comments
attachments
auditLogs
tasks
approvals
```

Existing incident subcollections must remain readable. New shared services should adapt to their current paths rather than invalidate them.

### 6.4 Workflow definitions

Create versioned workflow definitions containing:

- Workflow key.
- Module.
- Work-item type.
- Version.
- Draft, published or retired state.
- States.
- Allowed transitions.
- Roles permitted per transition.
- Mandatory fields.
- Approval policy.
- SLA behaviour.
- Notifications and automation actions.

A workflow instance must retain the workflow version with which it started. Publishing a new version must not silently change active records.

Privileged transitions must be validated by Cloud Functions or another trusted server-side boundary.

### 6.5 Approval model

An approval must contain:

```text
id
workItemType
workItemId
step
approverUserId
approverGroupId
status
decision
comment
requestedAt
dueAt
decidedAt
decidedBy
```

Support:

- Sequential approvals.
- Parallel approvals.
- Approver groups.
- Approval deadline.
- Delegation.
- Rejection.
- Request for clarification.
- Separation of duties.
- Immutable decision history.

### 6.6 Notification model

Use events such as:

```text
incident.created
incident.assigned
service_request.submitted
approval.requested
approval.decided
asset.assigned
asset.warranty_expiring
licence.expiring
change.scheduled
change.failed
sla.at_risk
sla.breached
security_finding.assigned
security_exception.expiring
access_review.due
```

Support:

- In-app notifications.
- Existing FCM push notifications.
- Email when already supported by the project.
- Templates.
- Deep links.
- Retry.
- Delivery status.
- Duplicate prevention.
- Read/unread state.

### 6.7 Shared audit service

Every important command must record:

- Actor.
- Action.
- Target entity type and ID.
- Timestamp using server time.
- Previous and new values where appropriate.
- Comment/reason.
- Workflow transition.
- Correlation ID.
- Source.

Clients must not be able to edit or delete audit records.

Preserve record-level audit subcollections and create a queryable global audit index when needed for Reporting & Administration.

---

## 7. Support module

### 7.1 Incidents

Move the current Incident screens and routes under:

```text
IT Service Management → Support → Incidents
```

Do not duplicate incident logic.

Preserve the existing lifecycle and role behaviour:

- USER creates and follows their own incidents.
- MANAGER sees and operates all relevant incidents.
- ADMIN sees their own incidents through self-service and organisation-wide incident aggregates through Reporting.
- Closed incidents are archived after seven days through the existing scheduled Cloud Function.

Add shared ITSM links where missing:

- Affected service.
- Related asset.
- Related configuration item.
- Related service request.
- Related change.
- Suggested knowledge articles.

### 7.2 Service Requests

Provide:

- Request creation from a published catalogue item.
- Dynamic form fields based on the catalogue item.
- Request on behalf of another user by MANAGER.
- Manager/DSI approval steps configured by workflow.
- Assignment group.
- Fulfilment tasks.
- Status timeline.
- Comments and attachments.
- Cancellation rules.
- Rejection with mandatory reason.
- Completion confirmation.
- Linked assets, CIs, incidents and changes.
- SLA tracking.

Suggested lifecycle:

```text
draft
submitted
awaiting_approval
approved
assigned
in_fulfilment
awaiting_user
fulfilled
closed
rejected
cancelled
```

### 7.3 My Requests

Create one user-centric screen backed by `itsmWorkItemIndex`.

It must show the current user’s:

- Incidents.
- Service requests.
- Change requests.
- Security-exception requests.
- Access-related requests where applicable.

Features:

- Type filter.
- Status filter.
- Date filter.
- Search.
- Cursor pagination.
- Sort by most recently updated.
- Status and SLA indicators.
- Detail navigation.
- Empty, loading and error states.

A USER and ADMIN must never receive another user’s records from the query.

### 7.4 Knowledge Base

Provide:

- Categories.
- Search.
- Featured and recent articles.
- Related services.
- Related catalogue items.
- Related incident categories.
- Draft/review/published/retired lifecycle.
- Article versioning.
- Employee-visible and DSI-only visibility.
- Attachments.
- Author and reviewer.
- Review/expiry date.
- Helpful/not-helpful feedback.
- View and usage counts.
- Article suggestions during incident or request creation.
- Ability for a MANAGER to link a resolution to an article.

USER and ADMIN can read published employee-visible articles.

MANAGER can author, review, publish, retire and archive articles.

---

## 8. Assets & Configuration module

### 8.1 Assets

For MANAGER, implement an asset register with:

- Asset ID.
- Asset tag.
- QR/barcode.
- Category.
- Type.
- Brand.
- Model.
- Serial number.
- Description.
- Acquisition date.
- Acquisition cost where permitted.
- Supplier.
- Warranty.
- Status.
- Condition.
- Site/location.
- Department.
- Assigned user/custodian.
- Stock location.
- Security baseline.
- Attachments and photographs.
- Lifecycle history.

Suggested lifecycle:

```text
planned
ordered
received
in_stock
configured
assigned
in_maintenance
returned
retired
disposed
lost
stolen
```

For USER and ADMIN, provide a read-only **My Assets** view and catalogue actions for:

- Report fault.
- Request repair.
- Request replacement.
- Request configuration.
- Request return.

These actions create service requests. They must not directly modify the asset.

### 8.2 Stock

Provide for MANAGER:

- Stock locations.
- Asset and consumable quantities.
- Receipt.
- Reservation.
- Issue.
- Return.
- Transfer.
- Adjustment.
- Minimum-stock threshold.
- Stock movement history.
- QR/barcode scanning.
- Reconciliation.
- Low-stock notifications.

Every movement must have:

- Movement type.
- Quantity.
- Source.
- Destination.
- Actor.
- Recipient.
- Related request.
- Date.
- Supporting document.

Never update stock quantity without recording a stock movement.

### 8.3 Licences

Provide for MANAGER:

- Software product.
- Vendor.
- Licence type.
- Purchased quantity.
- Allocated quantity.
- Available quantity.
- Assigned users/devices.
- Purchase date.
- Effective and expiry dates.
- Renewal date.
- Contract.
- Cost where authorised.
- Compliance status.
- Renewal notifications.
- Licence history.

Store licence secrets/keys using a secure approach. Do not expose secrets in list screens, logs, analytics or unrestricted Firestore documents.

### 8.4 Suppliers & Warranties

Provide for MANAGER:

- Supplier register.
- Contacts.
- Contracts.
- Supplied asset categories.
- Support terms.
- SLA.
- Contract start/end.
- Warranty records.
- Warranty coverage.
- Warranty expiration.
- Linked assets.
- Claim history.
- Attachments.
- Expiry notifications.

### 8.5 CMDB

Distinguish:

- **Asset:** ownership, custody, cost and lifecycle.
- **Configuration item:** operational component whose configuration affects a service.

Provide:

- CI type catalogue.
- CI registration.
- Service/application/infrastructure CIs.
- CI owner.
- Support group.
- Criticality.
- Operational status.
- Linked asset.
- Configuration baseline.
- Relationship mapping.
- Change history.
- Related incidents, requests, changes and findings.
- Impact/dependency view.
- Data-quality status.

Relationship examples:

```text
service depends_on application
application runs_on server
server connected_to switch
user uses device
asset represented_by configuration_item
```

Start with critical services, applications, servers, network devices and end-user devices. Do not attempt automatic discovery unless an existing reliable source is available.

---

## 9. Changes module

### 9.1 Change Requests

Support:

- Standard change.
- Normal change.
- Emergency change.

Fields:

- Title.
- Description.
- Justification.
- Change type.
- Requester.
- Owner.
- Affected services.
- Affected CIs/assets.
- Impact.
- Risk.
- Urgency.
- Planned start/end.
- Expected downtime.
- Implementation plan.
- Test plan/evidence.
- Communication plan.
- Rollback plan.
- Implementation result.
- Post-implementation review.

Suggested lifecycle:

```text
draft
submitted
assessment
awaiting_approval
approved
scheduled
implementation
review
closed
rejected
cancelled
failed
rolled_back
```

USER and ADMIN can submit and view their own permitted change requests.

MANAGER can perform the operational workflow.

### 9.2 Approvals / CAB

Implement CAB as a workflow and meeting capability using MANAGER users.

Provide:

- Pending approval queue.
- Change risk and impact summary.
- Approver assignment.
- CAB meeting date.
- Agenda.
- Participants.
- Approval, rejection or clarification.
- Conditions attached to approval.
- Decision comments.
- Emergency approval.
- Meeting notes.
- Immutable decision history.

Do not create a new CAB role. CAB membership is a configured group of MANAGER users.

### 9.3 Change Calendar

Provide:

- Month, week and agenda views.
- Planned implementation window.
- Affected service.
- Change type.
- Risk.
- Status.
- Conflict indicator.
- Maintenance window.
- Filter by service, CI, change type and status.
- Detail navigation.

MANAGER sees the full operational calendar.

USER sees only their own changes and explicitly published maintenance information.

ADMIN receives a read-only executive view.

---

## 10. Security & Compliance module

### 10.1 Security Findings

For MANAGER, provide:

- Finding reference.
- Title and description.
- Source.
- Severity.
- Risk.
- Affected assets/CIs/services.
- Evidence.
- Owner.
- Remediation plan.
- Due date.
- Status.
- Validation result.
- Related incident/change.
- Comments, attachments and audit history.

Suggested lifecycle:

```text
detected
triaged
assigned
remediation
validation
closed
risk_accepted
cancelled
```

Security records must support a restricted confidentiality level.

### 10.2 Security Exceptions

Provide:

- Requirement/control being excepted.
- Business justification.
- Scope.
- Affected asset/service/user.
- Risk description.
- Compensating controls.
- Requested start/end.
- Owner.
- Approval.
- Review date.
- Expiry notification.
- Closure or renewal.

USER and ADMIN can submit and view their own exception requests.

MANAGER processes them.

The requester must not be the sole approver of their own exception.

### 10.3 Asset Compliance

Track, at minimum:

- Operating-system support.
- Patch status.
- Antivirus/EDR status.
- Encryption status.
- Backup status where applicable.
- Approved software.
- Security configuration baseline.
- Last assessment date.
- Compliance result.
- Evidence.
- Remediation request/change.

MANAGER performs assessments and remediation tracking.

USER may see only a safe status for their own assigned device, such as:

```text
compliant
action_required
assessment_pending
```

Do not expose sensitive security details to USER.

### 10.4 Access Reviews

Provide:

- Review campaign.
- Scope/system.
- User.
- Current access/role.
- Department.
- Reviewer.
- Decision.
- Justification.
- Due date.
- Evidence.
- Revocation/change task.
- Completion status.

MANAGER creates and performs reviews.

USER and ADMIN can view their own access information and request a correction/revocation where enabled.

---

## 11. Reporting & Administration module

### 11.1 Move the Incident dashboard

Move the current incident dashboard into:

```text
IT Service Management
→ Reporting & Administration
→ Dashboards
→ Incident Management
```

Requirements:

- Reuse the current dashboard calculations through services/helpers.
- Keep widgets presentation-only.
- Preserve current figures during migration.
- Remove the old dashboard route/card only after the new route is validated.
- Add redirects for old bookmarks when possible.

### 11.2 Dashboards

Provide role-aware dashboards.

#### Operational dashboard for MANAGER

- Open incidents by priority.
- Incidents awaiting assignment.
- Incident response/resolution performance.
- Open requests by type/status.
- Requests awaiting approval.
- Requests awaiting fulfilment.
- SLA at risk and breached.
- Agent/group workload.
- Assets by status/location.
- Available and low stock.
- Warranty and licence expirations.
- Planned and failed changes.
- Security findings by severity.
- Overdue remediation.
- Access reviews due.

#### Executive dashboard for ADMIN

- Total incidents and trend.
- SLA compliance.
- Average resolution time.
- Service-request fulfilment performance.
- User satisfaction where available.
- Asset inventory and lifecycle summary.
- Assets due for replacement.
- Licence/warranty exposure.
- Change success rate.
- Major security/compliance exposure.
- Monthly trend and department comparison.

ADMIN dashboards are read-only and should prioritise concise summaries with drill-down that remains read-only.

### 11.3 SLA

Provide for MANAGER:

- SLA policies.
- Target response and resolution/fulfilment times.
- Policy by work-item type.
- Priority.
- Service.
- Business hours.
- Holidays.
- Pause conditions.
- Warning threshold.
- Escalation rule.
- Versioning.
- Draft/published/retired lifecycle.

ADMIN can view policies and results but cannot modify them.

SLA timers and escalations must be calculated by trusted server-side logic, not only by the client.

### 11.4 Service Catalogue

The catalogue has two surfaces:

1. A published self-service catalogue under Support for USER, MANAGER and ADMIN.
2. Catalogue administration under Reporting & Administration for MANAGER.

Catalogue-item fields:

- Name.
- Description.
- Category.
- Icon.
- Eligibility.
- Visible roles.
- Dynamic form schema.
- Required documents.
- Workflow definition.
- Approval policy.
- Fulfilment group.
- SLA policy.
- Active dates.
- Draft/published/retired status.

Initial items should include:

- Report an IT incident.
- Request technical assistance.
- Request a computer.
- Request equipment replacement.
- Request repair.
- Request asset configuration.
- Request software installation.
- Request software licence.
- Request account/access.
- Request VPN/network access.
- Request equipment return/transfer.
- Submit a change request.
- Submit a security exception.
- Request an access correction/revocation.

### 11.5 Workflow Configuration

Allow MANAGER to:

- Create a draft workflow.
- Add/edit states.
- Configure transitions.
- Configure permitted roles.
- Configure required fields.
- Configure approvals.
- Configure SLA pause/resume behaviour.
- Configure notifications.
- Validate a workflow.
- Publish a version.
- Retire a version.

Provide guardrails:

- Cannot publish a workflow with no start state.
- Cannot publish unreachable required states.
- Cannot remove a state from an active published version.
- Cannot alter the workflow version already attached to active records.
- Cannot create a transition that bypasses mandatory approval.
- Every transition must be auditable.

ADMIN can inspect published configurations read-only.

### 11.6 Audit Logs

Provide:

- Filter by date.
- Actor.
- Module.
- Entity type.
- Entity reference.
- Action.
- Department.
- Correlation ID.
- Export where authorised.
- Read-only detail.

Audit data must be append-only.

Do not use the audit collection as the primary dashboard data source.

---

## 12. Recommended Firestore collections

Adapt names to existing project conventions, but preserve existing collections.

```text
incidentTickets                         # existing
serviceRequests
knowledgeArticles
knowledgeCategories

assets
assetModels
assetAssignments
assetLifecycleEvents
stockLocations
stockItems
stockMovements
softwareLicences
suppliers
warranties
configurationItems
ciRelationships

changeRequests
cabMeetings
changeCalendarEntries                   # optional read model

securityFindings
securityExceptions
assetComplianceAssessments
accessReviewCampaigns
accessReviewItems

serviceCatalogItems
workflowDefinitions
slaPolicies
itsmWorkItemIndex
itsmAuditEvents
itsmReportSnapshots
itsmNotifications
itsmReferenceData
```

Use subcollections for high-volume child resources where appropriate:

```text
comments
attachments
auditLogs
tasks
approvals
versions
```

### 12.1 Firestore design rules

- Use server timestamps for authoritative lifecycle events.
- Use cursor pagination.
- Avoid unbounded collection reads.
- Avoid N+1 document reads.
- Denormalise stable display fields where this reduces repeated reads.
- Preserve IDs for links and auditability.
- Use atomic batches/transactions for coupled operations.
- Use aggregate/read-model documents for dashboards.
- Document every required composite index.
- Make Cloud Functions idempotent.
- Never trust role or user ID supplied only by the client.

---

## 13. Cloud Functions responsibilities

Keep or add Cloud Functions for:

- Existing incident archival after seven days.
- Privileged workflow transitions.
- Approval decisions.
- Work-item-index maintenance.
- Global audit-index creation.
- SLA timers and escalations.
- Warranty and licence expiry notifications.
- Security-exception expiry notifications.
- Access-review reminders.
- Dashboard aggregate updates.
- Notification fan-out.
- Stock/asset operations requiring atomic consistency.

Every event-driven function must tolerate duplicate delivery.

Do not place scheduled business rules in a Flutter timer.

---

## 14. Firestore and Storage security rules

Implement and test deny-by-default rules.

At minimum:

- USER can create permitted self-service records.
- USER can read only their own work items and permitted published knowledge.
- USER cannot change protected operational fields such as assignment, approval, SLA or audit history.
- USER cannot mutate asset, stock, licence, CMDB or compliance records.
- MANAGER can access operational collections according to DSI rules.
- ADMIN has USER-level operational rights plus read-only reporting access.
- ADMIN cannot mutate operational or configuration records.
- No client can edit audit records or report snapshots.
- No client can grant itself a role.
- Attachment access must match parent-record access.
- Restricted security evidence must not be publicly readable.
- Catalogue and knowledge drafts are not visible to USER.

Write emulator tests for every important allow and deny rule.

---

## 15. Riverpod requirements

- Use repository providers for all data access.
- Use controller/notifier providers for commands.
- Use family providers for record-specific state.
- Scope queries by the authenticated UID and role.
- Invalidate user-specific providers on logout.
- Prevent stale results from one user appearing for another user.
- Represent loading, data, empty, error and permission-denied states.
- Do not subscribe to Firebase streams directly inside widget `build()` methods.
- Keep dashboard calculations outside widgets.
- Dispose subscriptions appropriately.
- Prevent duplicate commands while a mutation is in progress.

Create shared providers for:

- Current ITSM role.
- ITSM permissions.
- Published catalogue.
- Work-item summaries.
- Notifications.
- Reference data.
- Assignment groups.
- SLA display state.

---

## 16. User experience requirements

Every list must provide, where applicable:

- Search.
- Filters.
- Sort.
- Cursor pagination.
- Loading skeleton/progress.
- Empty state.
- Retryable error state.
- Permission-denied state.
- Responsive table on desktop.
- Responsive cards/list on mobile.
- Accessible labels and keyboard navigation.

Every detail page must provide:

- Summary header.
- Status.
- Owner/assignment.
- Core fields.
- Related records.
- Comments.
- Attachments.
- Activity timeline.
- Available workflow actions.
- Clear read-only state.

Do not show action buttons that the user cannot perform, but continue to enforce the same restriction in the data layer.

---

## 17. Implementation sequence

Implement incrementally. Keep the application compilable and testable after every phase.

### Phase 0 — Baseline and compatibility

- Inventory existing Incident files and behaviour.
- Add regression tests for current Incident functionality.
- Document current Firestore paths and indexes.
- Confirm existing dashboard figures.

### Phase 1 — ITSM shell and shared core

- Add the IT Service Management card.
- Add the five-module grid.
- Add routes and role guards.
- Introduce shared work-item contracts.
- Add shared workflow, approval, audit and notification interfaces.
- Do not break existing Incident routes.

### Phase 2 — Support

- Move/adapt Incidents under Support.
- Implement Service Catalogue consumption.
- Implement Service Requests.
- Implement My Requests.
- Implement Knowledge Base.
- Preserve incident archival.

### Phase 3 — Assets & Configuration

- Implement Assets and My Assets.
- Implement Stock.
- Implement Licences.
- Implement Suppliers & Warranties.
- Implement the initial CMDB.
- Link assets/CIs to incidents and requests.

### Phase 4 — Changes

- Implement Change Requests.
- Implement approval/CAB workflows.
- Implement Change Calendar.
- Link changes to services, CIs, incidents and requests.

### Phase 5 — Security & Compliance

- Implement Security Findings.
- Implement Security Exceptions.
- Implement Asset Compliance.
- Implement Access Reviews.
- Apply restricted-data security rules.

### Phase 6 — Reporting & Administration

- Move the Incident dashboard.
- Add cross-module dashboards.
- Add SLA management.
- Add catalogue administration.
- Add workflow configuration.
- Add global audit views.
- Validate old-route redirects before removing old navigation.

---

## 18. Testing requirements

### 18.1 Unit tests

Test:

- Domain entities and serialization.
- Status transitions.
- Workflow guards.
- Approval policies.
- Separation-of-duty rules.
- SLA calculations.
- Permission policies.
- Asset lifecycle.
- Stock quantity calculations.
- Licence availability.
- Change risk calculation.
- Compliance-state calculation.
- Repository error mapping.

### 18.2 Provider/controller tests

Test:

- Loading, success and failure states.
- Role-scoped queries.
- Duplicate-submission prevention.
- Logout invalidation.
- User switching.
- Pagination.
- Filters.
- Optimistic updates where used.
- Failed Cloud Function commands.

### 18.3 Widget tests

Test:

- Services-page card replacement.
- Five-module grid.
- Feature visibility by role.
- Action visibility by role.
- Forms and validation.
- Empty/loading/error/access-denied states.
- Incident dashboard at its new location.
- ADMIN read-only behaviour.

### 18.4 Router tests

Test:

- USER cannot deep-link to protected operational/admin screens.
- MANAGER can access operational screens.
- ADMIN can access Reporting & Administration read-only.
- ADMIN cannot access operational edit routes.
- Existing incident deep links remain valid or redirect safely.
- No redirect loops.

### 18.5 Firebase Emulator integration tests

Test:

- Firestore rules.
- Storage rules.
- Cloud Functions.
- Incident archival.
- Work-item index.
- Audit writing.
- Approval commands.
- SLA escalation.
- Notification events.
- Asset/stock consistency.
- Role changes.
- Cross-user data isolation.

Do not run automated tests against production Firebase.

### 18.6 Regression tests

Existing Incident tests must continue to pass.

At minimum verify:

- USER creates and views own incident.
- USER cannot view another user’s incident.
- MANAGER categorises, assigns, resolves and closes.
- ADMIN cannot operate an incident.
- Closed incident is eligible for server-side archival after seven days.
- Existing comments, attachments and audit history still load.
- Existing incident dashboard totals match after relocation.

---

## 19. Acceptance criteria

The implementation is accepted only when:

1. The standalone Incident Management card has been replaced by IT Service Management.
2. Selecting IT Service Management displays the five required module cards.
3. Incident Management is accessible under Support without data loss.
4. Existing incident lifecycle and seven-day archival still work.
5. USER, MANAGER and ADMIN permissions match this specification.
6. No additional top-level role has been introduced.
7. Service Catalogue items can initiate governed requests.
8. USER cannot directly mutate assets, CMDB, stock, changes, findings or administration.
9. MANAGER can complete operational workflows.
10. ADMIN has executive read-only Reporting & Administration access.
11. The old Incident dashboard is available under Reporting & Administration.
12. Shared comments, attachments, audit, workflow, notifications and SLA are reused.
13. Dashboard aggregation does not occur inside widgets.
14. Firestore/Storage rules protect every collection and attachment.
15. Cross-user data isolation passes emulator tests.
16. All lists use bounded/paginated Firestore queries.
17. Required Firestore indexes and Cloud Functions are documented.
18. `flutter analyze` succeeds without new errors.
19. All relevant Flutter and Firebase Emulator tests pass.
20. No production data has been destructively migrated or deleted.

---

## 20. Required Codex delivery report

At the end of each implementation phase, report:

```markdown
## Completed

- Features implemented
- Existing features reused
- Migration/adapters added

## Files changed

- Path and purpose

## Firebase changes

- Collections
- Security rules
- Storage rules
- Indexes
- Cloud Functions

## Permissions verified

- USER
- MANAGER
- ADMIN

## Tests

- Commands executed
- Passed
- Failed
- Not run and reason

## Remaining work

- Explicit backlog
- Known risks
- Manual configuration required
```

Do not claim a phase is complete if its security rules, indexes, privileged server-side behaviour or tests are missing.

---

## 21. Final implementation principle

The user-facing product has five cohesive modules, but the implementation must behave as one integrated ITSM platform:

```text
One identity and role model
One service catalogue
One work-item contract
One workflow and approval mechanism
One audit mechanism
One notification mechanism
One reporting layer
Multiple bounded ITIL capabilities
```

Extend the current Incident Management implementation safely. Replace its position in navigation, not its data or proven behaviour.
