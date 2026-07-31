# ITSM Phase 3 Implementation Map

## Objective

Deliver the Assets & Configuration capability as a governed operational module.
MANAGER users receive bounded operational tools; USER and ADMIN users receive
only a read-only My Assets projection and catalogue actions that create service
requests. Existing Incident and Service Request records remain authoritative
and are linked additively by stable IDs.

## Capability and access map

| Capability | USER | MANAGER | ADMIN |
| --- | --- | --- | --- |
| My Assets | Read current assignments only | Read operational inventory | Read current assignments only |
| Asset actions | Create governed catalogue request | Execute trusted lifecycle commands | Create governed catalogue request |
| Asset register | No access | Bounded operational access | No access |
| Stock | No direct access | Trusted transactional commands | No access |
| Licences | No direct access | Operational access without exposed secrets | No access |
| Suppliers, contracts and warranties | No direct access | Bounded operational access | No access |
| CMDB and relationships | No direct access | Bounded operational access | No access |
| Attachments and photographs | Own assigned-asset safe projections only | Parent-authorized operational access | Own assigned-asset safe projections only |

Route guards, repositories, callable Functions, Firestore rules and Storage
rules enforce the same matrix. Hidden controls are not treated as security.

## Authoritative Firestore paths

```text
assets/{assetId}
assets/{assetId}/attachments/{attachmentId}
assets/{assetId}/photographs/{photographId}
assetSelfServiceProjections/{projectionId}
assetModels/{modelId}
assetAssignments/{assignmentId}
assetLifecycleEvents/{eventId}

stockLocations/{locationId}
stockItems/{stockItemId}
stockMovements/{movementId}
stockSupportingDocuments/{attachmentId}

softwareLicences/{licenceId}
softwareLicences/{licenceId}/allocations/{allocationId}
softwareLicences/{licenceId}/history/{eventId}

suppliers/{supplierId}
suppliers/{supplierId}/contacts/{contactId}
supplierContracts/{contractId}
supplierContracts/{contractId}/attachments/{attachmentId}
warranties/{warrantyId}
warranties/{warrantyId}/claims/{claimId}
warranties/{warrantyId}/claims/{claimId}/history/{eventId}
warranties/{warrantyId}/attachments/{attachmentId}

configurationItems/{configurationItemId}
configurationItems/{configurationItemId}/history/{eventId}
ciRelationships/{relationshipId}

itsmAuditEvents/{eventId}
notificationEvents/{eventId}
serviceRequests/{requestId}
```

High-volume lists use stable ordering, explicit page limits, and cursor-based
pagination. Relationships denormalize safe display names while preserving the
authoritative IDs.

## Trusted command boundaries

- Asset receive, configure, assign, return, maintenance, retire, dispose,
  lost and stolen transitions validate the current lifecycle and revision.
- Stock receipt, reservation, issue, return, transfer, adjustment and
  reconciliation run in a Firestore transaction.
- Every stock quantity change writes exactly one immutable movement with the
  operator, recipient where required, source, destination, related request,
  authoritative date, quantity, server-resolved evidence metadata and
  correlation ID.
- Stock locations and items are maintained through dedicated trusted callables
  using canonical document IDs. Receipt, reservation, issue, return, transfer,
  signed adjustment and zero-safe reconciliation share one validated command
  contract.
- Licence allocation and release enforce purchased capacity and write immutable
  history. Licence keys and secrets are excluded from operational list records,
  logs, analytics and client-readable models.
- Supplier, contract, warranty and claim mutations are MANAGER-only commands.
- CI registration and directional relationship commands validate supported
  relationship types, endpoint existence and duplicate/self-link constraints.
- Every command is authenticated, role checked, idempotent, auditable and uses
  server timestamps for authoritative events.
- USER and ADMIN asset actions open a catalogue-backed Service Request and never
  mutate an asset, stock item, licence or CI directly.

## Canonical navigation

```text
/services/itsm/assets-configuration
/services/itsm/assets-configuration/assets
/services/itsm/assets-configuration/assets/my
/services/itsm/assets-configuration/assets/my/{assetId}
/services/itsm/assets-configuration/assets/register
/services/itsm/assets-configuration/assets/register/{assetId}
/services/itsm/assets-configuration/stock
/services/itsm/assets-configuration/licences
/services/itsm/assets-configuration/suppliers-warranties
/services/itsm/assets-configuration/cmdb
/services/itsm/assets-configuration/cmdb/{configurationItemId}
```

Self-service routes are available to USER, MANAGER and ADMIN. Operational list,
detail and command routes are restricted to MANAGER. Unauthorized deep links
show the shared explanatory access state without querying protected data.

## Presentation and application map

- Responsive Assets & Configuration overview with five capability cards.
- My Assets list/detail with assignment, safe asset facts, warranty summary and
  catalogue-backed actions for fault, repair, replacement, configuration and
  return requests.
- MANAGER asset register, stock, licence, supplier/warranty and CMDB screens
  with loading, data, empty, error and permission-denied states.
- MANAGER asset detail supports governed file and photograph uploads. Stock
  supports registered evidence uploads plus scanner-wedge/manual barcode and
  SKU lookup before opening the movement workflow.
- Repository providers are session scoped and invalidated across login/logout
  and role changes; widgets never subscribe to Firestore inside `build()`.
- Controller/notifier providers serialize commands and prevent duplicate
  submission.
- Shared filters and bounded page state are presentation-only and reusable.
- English and French localization covers every new user-facing string.

## Security map

- Firestore and Storage default deny all Phase 3 collections and paths not
  explicitly matched.
- USER and ADMIN can read only `assetSelfServiceProjections` currently assigned
  to their authenticated UID; they cannot list or read authoritative asset
  documents.
- MANAGER can read operational collections; protected mutations remain callable
  only where atomic consistency, audit or lifecycle validation is required.
- Stock movements, lifecycle events, licence history and global audit records
  are immutable to every client.
- Parent authorization governs asset, contract and warranty attachments.
- Governed files remain unreadable until a trusted Storage finalizer registers
  exact immutable path, owner, content-type and size metadata in Firestore.
- Secret licence material has no unrestricted Firestore or Storage path.
- No client-supplied role, actor ID or authoritative timestamp is trusted.

## Verification map

- Domain tests: serialization, asset lifecycle transitions, assignment
  consistency, stock arithmetic, licence capacity, warranty state, CI
  relationship direction and pagination cursors.
- Provider/controller tests: session switching, role changes, bounded queries,
  duplicate command prevention and mapped failures.
- Widget/router tests: responsive screens, My Assets isolation, catalogue action
  routing, MANAGER operations, ADMIN/USER denial and protected deep links.
- Functions tests: authentication, role checks, idempotency, transactions,
  immutable movement/history/audit records and invalid command rejection.
- Firestore/Storage emulator tests: cross-user asset isolation, every important
  allow/deny path, attachment inheritance and trusted-server-only writes.
- Regression verification: complete Flutter suite, Functions lint/unit suite,
  emulator suite, web build, analyzer and `git diff --check`.

No Firebase resource is deployed and no production document is migrated by
this phase.
