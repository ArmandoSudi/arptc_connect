# UserManagement Organization Test Coverage

The focused Flutter suite now exercises the organization architecture without
starting Firebase or editing production code. The previous repository compile
and router-harness blockers no longer apply.

## Proven coverage

1. **Domain queries and pagination**
   - Organization, unit, agent-directory, assignment, and audit query identity
     includes every field that changes the result set.
   - Search and unit-type normalization is stable for Riverpod family keys.
   - Page sizes are bounded to `1..100`.
   - Name/document-ID and timestamp/document-ID cursors preserve deterministic
     continuation state.

2. **Page and timeline accumulation**
   - First-page cursor seeding, short-page termination, append, reset, and
     continuation behavior are covered.
   - Live first-page refreshes merge with older pages without duplicate IDs.
   - Audit timelines retain the timestamp plus document-ID tie-breaker.

3. **Audit parsing**
   - Firestore timestamps, ISO dates, malformed values, immutable before/after
     evidence, subject fallback, architecture issue counts, repaired IDs, and
     repair eligibility are covered.

4. **Role user stories and command policy**
   - `MANAGER` is the only mutating role.
   - `ADMIN` can inspect private profiles and audit history read-only.
   - `USER` can access only the safe agent directory.
   - `NONE` and malformed permission data fail closed.
   - Canonical and compatibility permission keys are covered.
   - Command-controller tests prove read-only roles cannot execute organization
     commands and cover submitting, success, failure, and feedback reset states.

5. **Role-based presentation and responsive destinations**
   - Access-gate loading, safe-directory access, and private deep-link denial are
     covered.
   - `MANAGER` receives four compact destinations and a four-item desktop rail,
     with mutation controls.
   - Compact `USER` presentation exposes only Agents and hides mutations.
   - Wide `USER` presentation omits redundant one-item navigation and renders
     the safe directory without violating Material rail constraints.
   - Desktop `ADMIN` presentation retains four read destinations, displays the
     read-only banner, and hides mutation controls.
   - Public organization dialogs cover validation for creation, hierarchy,
     safe unit moves, archival reason, acting-head expiry, and agent credentials.

6. **Live presentation updates**
   - Organization, hierarchy, and safe agent-directory screens rebuild from
     provider stream emissions without a manual refresh.
   - Responsive filter tests cover constrained desktop columns and prevent
     dropdown overflow regressions.

6. **Actual application GoRouter behavior**
   - The real `goRouterProvider` is exercised with an authenticated session.
   - Root routing sends `USER` to Agents and `MANAGER`/`ADMIN` to Organizations.
   - `NONE` is denied, and `USER` cannot render organization, audit, structure,
     private agent, or module screens through direct deep links.
   - Legacy department/service/bureau routes and malformed unit/add-agent paths
     converge to their safe canonical routes.
   - A mounted private route immediately fails closed when a `MANAGER` policy is
     revoked to `USER`.

## Complementary suite boundaries

These are not open production defects. They identify evidence that intentionally
lives outside this Firebase-free Flutter suite.

1. **Safe directory outbound projection**
   Flutter proves safe parsing. Exact server-written keys and omission of
   matricule/module permissions are covered by `organization_service.test.js`;
   client visibility is covered by `organization_firestore_rules.emulator.js`.

2. **Firestore query and security behavior**
   Query identity, limits, cursors, and accumulators are covered here. Actual
   rule allow/deny behavior and cross-user isolation are covered by the
   organization Firestore emulator suite, and compound query definitions are
   covered by `organization_firestore_indexes.test.js`.

3. **Mutation boundaries and privileged side effects**
   Dialog validation, role-hidden controls, route guards, and command-controller
   state are covered here. Transactional create/edit/archive/move/transfer/head/
   deactivate behavior, Auth UID provisioning, audit append-only behavior,
   repair idempotency, and notification delivery are covered by Functions unit
   tests and Firestore emulator tests. No Firebase deployment or production-data
   mutation is part of the verification plan.
