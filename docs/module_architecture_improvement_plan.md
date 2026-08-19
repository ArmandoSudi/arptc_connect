# ERP Module Architecture Improvement Plan

## Document Status

- Status: `PLANNED`
- Scope: ARPTC Connect ERP module registration, configuration, authorization,
  navigation, and future extensibility
- Purpose: Record the current limitations and the recommended architecture so
  the module system can be improved in a later implementation cycle.

## Objective

Separate executable module implementation from runtime module configuration.
Firestore cannot create Flutter screens, routes, repositories, Cloud Functions,
or security policies dynamically. It can, however, configure modules that have
already been implemented and delivered with the application.

The target architecture must provide one reliable answer to each question:

1. Is this module implemented by the deployed application?
2. Is this module registered and enabled for use?
3. Which roles and capabilities does the module support?
4. Does the current agent have access to it?
5. Is the requested route and server operation authorized?

## Domain Distinction

The organization model and the module model solve different problems:

- `organizations` identify enterprise boundaries.
- `organizationUnits` identify where an agent belongs, such as a department,
  service, or bureau.
- `agents` identify the people using the ERP.
- `modules` identify the ERP business capabilities available to those agents.

An organization assignment answers **where the agent works**. A module access
assignment answers **which ERP functions the agent may use and what role they
have in each function**.

## Current Implementation

Module information currently comes from three overlapping sources:

1. Static module definitions in
   `lib/modules/usermanagement/domain/modules.dart`.
2. Static navigation and presentation definitions in
   `lib/modules/service/module_config.dart`.
3. Runtime module documents in the Firestore `modules` collection.

Agent access is stored in `agents/{uid}.modulePermissions`:

```json
{
  "modulePermissions": {
    "ticketing": "MANAGER",
    "usermanagement": "USER",
    "inventory": "NONE",
    "news": "REVIEWER"
  }
}
```

The Services screen normalizes these keys and displays modules whose role is
not `NONE`.

## Current Limitations

### MOD-GAP-001: Multiple sources of truth

Static registries and Firestore configuration can disagree about module names,
roles, activation, routes, and availability.

### MOD-GAP-002: Firestore records do not create executable functionality

A module document may exist without a corresponding Flutter screen, route,
repository, Cloud Function, or security policy. Creating such a document does
not create a working ERP module.

### MOD-GAP-003: Missing configuration falls back to static modules

When a Firestore configuration is missing, the Services screen can fall back to
the static definition. Deleting a module document can therefore make the module
appear enabled again instead of removing it.

### MOD-GAP-004: Available roles are not consistently enforced

The roles stored in `modules.availableRoles` are not the single authority used
by every agent editor, route guard, screen action, Cloud Function, and security
rule.

### MOD-GAP-005: Permission logic is distributed

Module key aliases and role checks are repeated across Flutter, Cloud
Functions, Firestore rules, and notification recipient resolution. These copies
can drift over time.

### MOD-GAP-006: Permissions are global

An agent currently receives one role per module. The model cannot express that
an agent manages a module only for a particular department, service, or bureau.

### MOD-GAP-007: Deletion loses configuration history

Hard deletion can remove configuration required to interpret historical
permissions, notifications, audit events, and records.

## Architecture Decision

Adopt a hybrid **code manifest plus runtime configuration** architecture.

- The code manifest is authoritative for executable and security-sensitive
  facts.
- Firestore is authoritative for runtime activation, presentation overrides,
  ordering, and controlled rollout.
- Agent access assignments determine which enabled modules an agent may use.
- Route guards and trusted backend policies enforce access independently of
  whether a module card is visible.

A module is available only when all three conditions are true:

```text
implemented in the deployed application
AND registered and active in Firestore
AND the agent has a role other than NONE
```

There must be no permissive static fallback for a missing or inactive runtime
configuration.

## Target Code Manifest

Replace the duplicate static registries with one canonical code-level manifest:

```dart
class AppModuleManifest {
  const AppModuleManifest({
    required this.key,
    required this.route,
    required this.nameKey,
    required this.descriptionKey,
    required this.availableRoles,
    required this.icon,
    required this.color,
  });

  final String key;
  final String route;
  final String nameKey;
  final String descriptionKey;
  final Set<ModuleAccessRole> availableRoles;
  final IconData icon;
  final Color color;
}
```

Example manifest:

```dart
AppModuleManifest(
  key: 'ticketing',
  route: '/services/itsm',
  nameKey: 'moduleItsmName',
  descriptionKey: 'moduleItsmDescription',
  availableRoles: {
    ModuleAccessRole.admin,
    ModuleAccessRole.manager,
    ModuleAccessRole.user,
  },
  icon: Icons.support_agent,
  color: Colors.blue,
)
```

The manifest is the compile-time authority for:

- Canonical permission key
- Canonical route
- Supported roles
- Localization keys
- Icon and default visual identity
- Route registration
- Route guard requirement
- Code-backed capabilities

## Target Firestore Module Configuration

Firestore controls only runtime configuration for code-backed modules:

### `modules/{canonicalModuleKey}`

```text
key: string                         // same as document ID
displayName: string                 // optional runtime override
description: string                 // optional runtime override
status: ACTIVE | INACTIVE | ARCHIVED
availableRoles: string[]            // subset of manifest roles
sortOrder: number
enabledOrganizationIds: string[]    // optional controlled rollout
schemaVersion: number
createdAt/createdBy: timestamp/string
updatedAt/updatedBy: timestamp/string
archivedAt/archivedBy: timestamp|string|null
```

Rules for this document:

- The document ID and `key` must match the canonical manifest key.
- `availableRoles` must be a subset of roles supported by the manifest.
- Runtime configuration must never introduce an executable route.
- Missing, inactive, or archived configuration means the module is unavailable.
- Module documents are archived, not hard deleted.

## Module Resolution

A central resolver must intersect manifests, Firestore configuration, and agent
permissions:

```dart
final visibleModules = manifests.where((manifest) {
  final configuration = configurations[manifest.key];
  final role = permissions.roleFor(manifest.key);

  return configuration?.status == ModuleStatus.active &&
      configuration!.availableRoles.contains(role) &&
      role != ModuleAccessRole.none;
});
```

This resolver must be used by:

- Services module cards
- Module-level route guards
- Dashboard navigation
- Notification deep-link authorization
- Agent permission management
- Any shared module switcher

## Module Lifecycle

Use the following lifecycle instead of hard deletion:

```text
DRAFT -> ACTIVE -> INACTIVE -> ARCHIVED
```

- `DRAFT`: Implemented or being configured but not available to agents.
- `ACTIVE`: Available to authorized agents.
- `INACTIVE`: Temporarily unavailable while configuration and history remain.
- `ARCHIVED`: Retired permanently from new use while historical references are
  retained.

The existing Delete action should become **Archive module**. Reactivation may be
allowed from `INACTIVE`, but restoring an `ARCHIVED` module should require an
explicit controlled operation.

## Agent Permission Management

The agent editor must stop iterating directly over a static module list. It
should load the intersection of:

```text
deployed module manifests
AND registered Firestore module configurations
```

For each module, allowed roles are the intersection of code and configuration:

```dart
final allowedRoles = manifest.availableRoles
    .intersection(configuration.availableRoles);
```

Examples:

```text
News: NONE, USER, MANAGER, REVIEWER
IT Service Management: NONE, USER, MANAGER, ADMIN
```

The server must validate every permission assignment. The client must not be
able to assign a role that is unsupported, inactive, archived, or unknown.

## Central Permission Policy

Introduce a single application policy interface:

```dart
abstract interface class ModuleAccessPolicy {
  bool canAccess(String moduleKey);
  bool hasRole(String moduleKey, ModuleAccessRole role);
  bool canPerform(String moduleKey, String capability);
}
```

This policy should drive presentation decisions, but backend controls remain
authoritative. Hiding a module card or action is not a security boundary.

Every module route must have a guard that verifies:

1. The module is implemented.
2. The Firestore configuration is active.
3. The agent account is active and fully onboarded.
4. The agent has a supported non-`NONE` role.
5. The requested module section or capability is allowed for that role.

## Roles and Capabilities

Roles are useful for broad assignment, but capabilities should define precise
behavior. For example:

```json
{
  "USER": [
    "incident.create",
    "incident.read_own"
  ],
  "MANAGER": [
    "incident.read_operational",
    "incident.categorize",
    "incident.assign",
    "incident.resolve"
  ],
  "ADMIN": [
    "incident.reporting.read"
  ]
}
```

Capability definitions are security-sensitive and should be version-controlled
in code. Firestore may select from or disable supported capabilities, but it
must not create arbitrary privileged capabilities.

The same policy concepts must be mirrored and tested in:

- Flutter route and UI policies
- Callable Cloud Function authorization
- Firestore and Storage security rules
- Notification audience resolution

## Canonical Module Keys

Current canonical keys are:

```text
tasks
courriers
social
news
inventory
ticketing
meetinghall
usermanagement
```

Aliases such as `itsm`, `support`, and `incident_management` may be accepted
when reading legacy data. All new writes must use the canonical key.

Automated consistency tests must ensure:

- Every manifest key is unique.
- Every manifest route exists and has a guard.
- Every Firestore configuration references a supported manifest key.
- Every configured role is supported by its manifest.
- Flutter and Cloud Functions normalize legacy aliases to the same key.
- New documents never write aliases.

## Organization-Scoped Module Access

The global `modulePermissions` map remains appropriate while an agent has only
one organization-wide role per module. If access later needs to be restricted
to a department, service, or bureau, introduce authoritative scoped grants.

### `moduleAccessGrants/{grantId}`

```text
agentId: string                    // Firebase Auth UID
moduleKey: string                  // canonical key
role: USER | MANAGER | ADMIN | REVIEWER
organizationId: string
scopeType: ORGANIZATION | DEPARTMENT | SERVICE | BUREAU
scopeUnitId: string | null
scopeKeys: string[]
status: ACTIVE | ENDED | REVOKED
startsAt: timestamp
endsAt: timestamp | null
createdAt/createdBy: timestamp/string
endedAt/endedBy: timestamp|string|null
reason: string
```

Example:

```json
{
  "agentId": "uid-123",
  "moduleKey": "ticketing",
  "role": "MANAGER",
  "organizationId": "org-arptc",
  "scopeType": "DEPARTMENT",
  "scopeUnitId": "department-it",
  "scopeKeys": [
    "org:org-arptc",
    "unit:department-it"
  ],
  "status": "ACTIVE"
}
```

This means the agent is an Incident Manager only within the IT Department and
its descendant units.

Trusted Functions should maintain a private query-optimized projection:

```json
agentAuthorizationIndex/uid-123
{
  "moduleRoleKeys": [
    "ticketing:MANAGER"
  ],
  "scopeRoleKeys": [
    "unit:department-it:ticketing:MANAGER"
  ]
}
```

The existing `modulePermissions` map can remain as a global fast-read
projection while scoped grants are introduced gradually.

## Dynamic Versus Code-Backed Modules

Two module categories should be recognized:

| Module category | Runtime creation | Implementation model |
| --- | --- | --- |
| Complex ERP module such as ITSM, Inventory, or Meeting Hall | Not supported | Flutter code, routes, repositories, Functions, rules, indexes, and tests |
| Configurable procedure such as a form and approval workflow | Supported after building a generic engine | Firestore metadata rendered by reusable code-backed screens |

A future metadata-driven workflow engine could support runtime-defined simple
procedures with:

- Form fields and validation
- Workflow states and transitions
- Approval steps
- Assignment groups
- Notifications
- SLA references
- Generic list and detail layouts

This mechanism should not be used to imitate complex modules that require
specialized domain logic or security controls.

## Administration Experience

The Module Management screen should manage only supported manifests. It should
offer **Register available module** instead of accepting arbitrary keys.

Recommended actions:

- Register an implemented module
- Edit runtime name and description overrides
- Change display order
- Select a subset of supported roles
- Activate or deactivate a module
- Configure organization rollout
- Archive a module
- View module audit history

It must not promise that creating a Firestore document creates application
functionality.

## Migration Plan

### Phase 1: Consolidate the static registry

- Introduce `AppModuleManifest`.
- Move keys, routes, localization keys, roles, and presentation defaults into
  one registry.
- Replace `Modules.all` and `ModulesConfig.allModules` consumers.
- Add uniqueness and route-coverage tests.

### Phase 2: Make runtime configuration authoritative

- Use canonical module keys as Firestore document IDs.
- Remove permissive static fallback behavior.
- Hide modules with missing, inactive, or archived configuration.
- Add stable status, ordering, schema, and audit fields.
- Replace module deletion with archival.

### Phase 3: Centralize access enforcement

- Introduce `ModuleAccessPolicy`.
- Add module-level guards to every route.
- Make navigation, dashboards, and notification deep links use the same policy.
- Add trusted backend validation for module and role assignments.
- Add allow-and-deny tests for all roles.

### Phase 4: Update agent permission management

- Load registered code-backed modules reactively from Firestore.
- Limit role choices to the manifest/configuration intersection.
- Reject unsupported assignments server-side.
- Preserve permissions for inactive or archived modules as historical data
  while treating them as inaccessible.

### Phase 5: Add controlled module registration

- Replace free-form module creation with manifest-backed registration.
- Add an idempotent reconciliation command or deployment script.
- Report missing, duplicate, unsupported, and stale module configurations.
- Record module lifecycle changes in an append-only audit collection.

### Phase 6: Add scoped grants when required

- Introduce effective-dated `moduleAccessGrants`.
- Validate organization and unit scope server-side.
- Maintain `agentAuthorizationIndex` projections transactionally.
- Add inherited department, service, and bureau authorization tests.
- Migrate one module at a time from global to scoped access.

### Phase 7: Consider a metadata-driven workflow engine

- Define the boundary for simple runtime-configurable procedures.
- Build reusable form, workflow, approval, notification, and list renderers.
- Keep complex ERP modules code-backed.
- Validate and version published definitions before allowing active instances.

## Security Requirements

- Module visibility must never be treated as authorization.
- Every protected route must enforce module access.
- Every privileged mutation must be validated by a trusted server boundary.
- Firestore and Storage rules must default to deny.
- Module configuration cannot introduce arbitrary routes or capabilities.
- Unsupported keys and roles must fail closed.
- Inactive and archived modules cannot be used even if stale permissions remain.
- ADMIN, MANAGER, REVIEWER, and USER semantics must be explicit per module.
- Module changes and permission assignments must be audited.

## Acceptance Criteria

1. One code manifest replaces the duplicate static module registries.
2. Every manifest has a unique canonical key and guarded route.
3. A missing Firestore module configuration hides the module.
4. An inactive or archived module cannot be opened through a direct URL.
5. Deleting configuration cannot reactivate a module through static fallback.
6. Module records are archived rather than hard deleted.
7. Agent permission screens use registered runtime modules.
8. Role choices are restricted to roles supported by both code and
   configuration.
9. Unsupported module keys and roles are rejected server-side.
10. Services navigation reacts immediately to module configuration and agent
    permission changes.
11. Flutter, Functions, Firestore rules, and notification logic use canonical
    keys consistently.
12. Legacy aliases are read-compatible but never written to new records.
13. Route, repository, Function, Firestore, and Storage authorization tests
    cover each module role.
14. Historical module and permission references remain interpretable after
    deactivation or archival.
15. Scoped grants, when introduced, inherit correctly through department,
    service, and bureau descendants.

## Non-Goals

- Loading arbitrary Dart code from Firestore
- Creating complex ERP functionality solely by adding a module document
- Trusting client-side role or capability claims
- Migrating every module to organization-scoped permissions immediately
- Replacing specialized modules with a generic workflow engine

## Recommended First Implementation Batch

The first future implementation should remain deliberately small:

1. Introduce `AppModuleManifest`.
2. Consolidate both static registries.
3. Make active Firestore registration mandatory.
4. Replace Delete with Archive.
5. Make the agent editor consume registered modules.
6. Add a shared route guard and consistency tests.

This batch removes the most dangerous ambiguity without requiring scoped grants
or a generic workflow engine immediately.
