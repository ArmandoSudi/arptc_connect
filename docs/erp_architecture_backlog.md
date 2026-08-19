# ARPTC Connect ERP Architecture Backlog

This document tracks the organization, identity, security, notification, and
scalability gaps identified during the Firestore architecture audit. Keep each
ID stable as work is implemented and verified.

Status values: `OPEN`, `IN PROGRESS`, `BLOCKED`, `DONE`.

## Major Gaps

### GAP-001: Hierarchy integrity is not enforced

- Priority: `P0`
- Status: `DONE`
- Description: Department, service, bureau, and agent relationships are
  validated mainly in Flutter. Firestore currently permits structurally
  inconsistent references.
- Completion criteria:
  - Service department references are validated server-side.
  - Bureau service and department ancestry is validated server-side.
  - Agent placement references are validated atomically.
  - Invalid hierarchy combinations are rejected by tests and security controls.

### GAP-002: Leadership has unsynchronized sources

- Priority: `P1`
- Status: `DONE`
- Description: Leadership is represented by `headUserId` on organization units
  and by `position` on agents, without a single authoritative assignment or
  synchronization mechanism.
- Completion criteria:
  - A single authoritative leadership assignment is defined.
  - Unit head projections and agent position cannot contradict each other.
  - Acting heads and effective periods can be represented.
  - Leadership changes are audited.

### GAP-003: Organizational assignment history is missing

- Priority: `P1`
- Status: `DONE`
- Description: Changing department, service, or bureau overwrites the agent's
  current placement and loses transfer history.
- Completion criteria:
  - Effective-dated organization assignments are stored.
  - Current placement remains a derived fast-read projection.
  - Transfers record actor, reason, start date, and end date.
  - Historical ERP records retain their original organization snapshots.

### GAP-004: Agent identity has legacy document paths

- Priority: `P0`
- Status: `DONE`
- Description: Account provisioning and profile access now use
  `agents/{firebaseAuthUid}` exclusively. The retired email/generated-ID paths
  are handled only by the explicit migration command.
- Completion criteria:
  - Firebase Auth UID is the only agent document key.
  - Email and generated-ID creation paths are removed from production code.
  - Legacy migration remains explicit and idempotent.
  - Authentication, rules, and Functions resolve agents only by Auth UID.

### GAP-005: Agent data is overexposed

- Priority: `P0`
- Status: `DONE`
- Description: Any signed-in account can currently list complete agent
  documents, including fields that should not be in the public directory.
- Completion criteria:
  - Private agent profiles are protected by role and ownership.
  - A minimal `agentDirectory` projection supports dropdowns and search.
  - Matricule, permissions, and private fields are not exposed to ordinary users.
  - Inactive or unverified accounts cannot browse organization data.

### GAP-006: Notification creation is insufficiently protected

- Priority: `P0`
- Status: `DONE`
- Description: Signed-in clients can create notification events without an
  event-specific authorization policy, including company-wide targets.
- Completion criteria:
  - Notification events are created only by trusted Functions or authorized
    commands.
  - Event type, source module, actor role, and target are validated.
  - Company-wide notification creation is privileged.
  - Unauthorized broadcast attempts are covered by emulator tests.

### GAP-007: Organization-scoped notifications are unsupported

- Priority: `P1`
- Status: `DONE`
- Description: The audience model supports `ALL`, `MODULE_ROLE`, and `USERS`,
  but not inherited department, service, or bureau scopes.
- Completion criteria:
  - An `ORG_SCOPE` target is supported.
  - Department targets include agents in descendant services and bureaux.
  - Optional module-role filtering works within an organization scope.
  - Recipient resolution is idempotent, bounded, and audited.

### GAP-008: Organization queries are unbounded

- Priority: `P1`
- Status: `DONE`
- Description: Departments, services, bureaux, and agents are loaded entirely
  and searched or filtered in memory.
- Completion criteria:
  - Repository APIs use limits, stable ordering, and cursors.
  - Search is query-driven or delegated to an approved search index.
  - Required composite indexes are tracked in `firestore.indexes.json`.
  - Security rules require bounded queries where appropriate.

## Migration Priorities

### MIG-001: Protect notification event creation

- Priority: `P0`
- Status: `DONE`
- Outcome: Deny arbitrary client event creation and introduce trusted,
  event-specific notification commands.

### MIG-002: Separate private agent profiles from the directory

- Priority: `P0`
- Status: `DONE`
- Outcome: Restrict `agents` and introduce a minimal `agentDirectory` read
  projection.

### MIG-003: Enforce Firebase Auth UID-only identity

- Priority: `P0`
- Status: `DONE`
- Outcome: Remove email-keyed agent writes and reads while retaining an explicit
  legacy migration path.

### MIG-004: Replace hard organization deletion

- Priority: `P1`
- Status: `DONE`
- Outcome: Use archival or deactivation and reject removal while active children
  or assignments exist.

### MIG-005: Add transactional hierarchy commands

- Priority: `P1`
- Status: `DONE`
- Outcome: Validate references, use server timestamps, update projections
  atomically, and append audit events.

### MIG-006: Introduce organization scope and assignment history

- Priority: `P1`
- Status: `DONE`
- Outcome: Add `organizationId`, `scopeKeys`, current placement projections, and
  effective-dated assignments.

### MIG-007: Add organization-scoped notification targets

- Priority: `P1`
- Status: `DONE`
- Outcome: Resolve department, service, bureau, and optional module-role
  audiences through trusted Functions.

### MIG-008: Add bounded queries and indexes

- Priority: `P1`
- Status: `DONE`
- Outcome: Implement cursor pagination, searchable normalized fields, and the
  corresponding index definitions.

### MIG-009: Introduce a generic organization-unit model

- Priority: `P2`
- Status: `DONE`
- Outcome: When migration is ready, use `organizationUnits` as the authoritative
  extensible hierarchy and retire duplicate sources.

### MIG-010: Add integrity and authorization tests

- Priority: `P0`
- Status: `DONE`
- Outcome: Cover hierarchy mismatches, cross-scope access, transfers, acting
  heads, notification authorization, and recipient inheritance.

## Completion Evidence Matrix

| Backlog IDs | Implemented evidence | Executable evidence |
| --- | --- | --- |
| `GAP-001`, `MIG-005`, `MIG-009` | `organizations` and typed `organizationUnits` are mutated only through transactional callable commands. Parent type, organization boundary, active status, path integrity, cycle prevention, and bounded reparenting are validated server-side. Legacy hierarchy collections are denied. | `organization_domain.test.js`, `organization_service.test.js`, `organization_firestore_rules.emulator.js` |
| `GAP-002` | `HEAD` assignments are authoritative. Permanent and acting slots have separate unit projections, effective dates, immutable audit history, conflict checks, and scheduled acting-head expiry. `jobTitle` is descriptive only. | `organization_service.test.js`, `organization_maintenance.test.js` |
| `GAP-003`, `MIG-006` | Effective-dated `MEMBER` assignments preserve historical unit/path snapshots. Transfers end the old assignment, create a new primary assignment, and update current private/directory/authorization projections atomically. | `organization_service.test.js`, `organization_domain.test.js` |
| `GAP-004`, `MIG-003` | Auth UID is the only canonical agent key. New account creation writes `agents/{uid}` and explicit legacy migration is idempotent, identity-only, and preserves an already-valid v2 placement. | `agent_account_migration.test.js`, `organization_service.test.js`, authentication provider tests |
| `GAP-005`, `MIG-002` | Private `agents` profiles are owner/supervisor restricted. Safe `agentDirectory`, private `agentAuthorizationIndex`, and minimal `organizationDirectory` projections have distinct rules. Inactive and unverified principals fail closed. | `organization_firestore_rules.emulator.js`, `agent_directory_entry_test.dart`, `agent_organization_projection_test.dart` |
| `GAP-006`, `MIG-001` | Clients cannot write `notificationEvents`. The trusted command validates event policy, source record, module, MANAGER actor, canonical route, organization/scope target, and writes an idempotent receipt plus immutable organization audit. | `organization_notifications.test.js`, `organization_firestore_rules.emulator.js` |
| `GAP-007`, `MIG-007` | `ORG_SCOPE` resolves inherited organization/unit scopes from the private authorization index, optionally intersected with normalized module-role keys. Recipient pages and inbox writes are bounded and deterministic. | `organization_notifications.test.js`, `organization_firestore_indexes.test.js` |
| `GAP-008`, `MIG-008` | Organization, unit, directory, assignment, audit, migration, and maintenance APIs use limits, stable ordering, document-ID tie-breakers, and continuation cursors. Compound indexes are tracked. | `organization_query_test.dart`, `organization_accumulators_test.dart`, `organization_migration.test.js`, `organization_firestore_indexes.test.js` |
| `MIG-004` | Organization, unit, and agent removal is archival/deactivation only. Active children, agents, assignments, and leadership block archival; historical assignments and audit records remain. | `organization_service.test.js`, `organization_firestore_rules.emulator.js` |
| `MIG-010` | Domain, Functions, Flutter policy/provider/widget/router, index-manifest, and Firestore-emulator suites cover malformed hierarchy, cross-scope access, assignment history, leadership, notifications, query bounds, legacy denial, and role behavior. | `functions/test/organization_*.test.js`, `test/modules/usermanagement`, `organization_firestore_rules.emulator.js` |

## Current Implementation Batch

- `ORG-001` | `DONE` | `agents.bureau` stores the bureau name;
  `agents.bureauId` stores its Firestore ID.
- `ORG-002` | `DONE` | `agents.department` stores the department name;
  `agents.departmentId` stores its Firestore ID; legacy `agents.direction` is
  removed.
- `ORG-003` | `DONE` | `agents.service` stores the service name;
  `agents.serviceId` stores its Firestore ID.
- `ORG-004` | `DONE` | `agents/{firebaseAuthUid}` is the only
  production identity path.
- `ORG-005` | `DONE` | `organizations`, `organizationUnits`, and
  `organizationAssignments` are the authoritative hierarchy and placement
  sources.
- `ORG-006` | `DONE` | `agentDirectory`, `organizationDirectory`, and
  `agentAuthorizationIndex` separate safe discovery from private identity and
  trusted authorization.
- `ORG-007` | `DONE` | UserManagement exposes Organizations, Structure,
  Agents, and Modules with role-gated Material 3 responsive screens and live
  streams.
- `ORG-008` | `DONE` | Explicit unplaced-agent, legacy-identity, and
  architecture-audit workflows enforce the from-scratch migration sequence.

Implementation evidence:

- Agent create, update, and delete operations use trusted callable Functions.
- The server resolves names from organization IDs and validates hierarchy
  ancestry before writing an agent profile.
- Firestore denies direct parent-agent mutations from clients.
- Authentication and notification recipient resolution use Firebase Auth UIDs.
- The explicit legacy migration deletes the old agent document and records a
  separate idempotency receipt outside the `agents` collection.
- Unit, Flutter, analyzer, and Firestore emulator checks cover the invariants.
