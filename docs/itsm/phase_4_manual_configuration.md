# Phase 4 Manual Firebase Configuration

Phase 4 does not deploy or seed production data automatically. Before users
create change requests, create the following trusted configuration documents
through an approved administrative process. The IDs match the defaults used by
the Flutter change form.

## Workflow definitions

Create one parent and one immutable published version for each change type:

```text
workflowDefinitions/change-standard
workflowDefinitions/change-standard/versions/version_1

workflowDefinitions/change-normal
workflowDefinitions/change-normal/versions/version_1

workflowDefinitions/change-emergency
workflowDefinitions/change-emergency/versions/version_1
```

Parent example:

```json
{
  "name": "Normal change workflow",
  "module": "itsm",
  "workItemType": "change_request",
  "status": "published",
  "publishedVersion": 1,
  "supportedChangeTypes": ["normal"],
  "updatedByUserId": "<authorised-manager-uid>"
}
```

Version example:

```json
{
  "version": 1,
  "status": "published",
  "supportedChangeTypes": ["normal"],
  "defaultApprovalGroupId": "cab-default",
  "approvalDeadlineHours": 72,
  "standardPreAuthorized": false,
  "states": [
    "draft",
    "submitted",
    "assessment",
    "awaiting_approval",
    "approved",
    "scheduled",
    "implementation",
    "review",
    "closed",
    "rejected",
    "cancelled",
    "failed",
    "rolled_back"
  ],
  "publishedByUserId": "<authorised-manager-uid>"
}
```

Use `supportedChangeTypes: ["standard"]` for `change-standard` and set
`standardPreAuthorized: true` only for a formally approved repeatable standard
change. Use `supportedChangeTypes: ["emergency"]` for `change-emergency` and a
shorter `approvalDeadlineHours`, for example `4`.

Published versions are immutable. Publish a new version document and update
the parent `publishedVersion` rather than editing an active version.

## CAB approval group

```text
changeApprovalGroups/cab-default
```

```json
{
  "name": "Default Change Advisory Board",
  "status": "active",
  "isActive": true,
  "memberUserIds": [
    "<manager-uid-1>",
    "<manager-uid-2>"
  ],
  "approvalDeadlineHours": 72,
  "decisionDeadlineHours": 24
}
```

Every member must be an active agent whose canonical `ticketing` permission is
`MANAGER`. Normal and emergency groups need at least one member other than the
requester so that server-enforced separation of duties can succeed.

## Maintenance windows

Maintenance windows are optional. A referenced window must contain:

```json
{
  "name": "Monthly infrastructure maintenance",
  "isActive": true,
  "startAt": "<Firestore Timestamp>",
  "endAt": "<Firestore Timestamp>",
  "serviceIds": ["<service-id>"]
}
```

The trusted schedule command rejects implementation dates outside the selected
window. Client writes to workflow definitions, CAB groups, maintenance windows,
calendar projections, audit events, and work-item indexes remain denied until
the Phase 6 administration commands are available.

## Verification

1. Confirm every workflow parent is `published` and its version document is
   also `published`.
2. Confirm the CAB group members are active `ticketing: MANAGER` agents.
3. Create one draft of each change type in the Firebase Emulator.
4. Confirm the draft pins `workflowDefinitionId`, `workflowVersion`, and
   `workflowVersionDocumentId`.
5. Do not run this checklist against production through automated tests.
