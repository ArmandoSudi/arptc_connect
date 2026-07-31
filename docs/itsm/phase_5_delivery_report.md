# ITSM Phase 5 Delivery Report

## Completed

- Security & Compliance is implemented under the canonical ITSM routes for
  Security Findings, Security Exceptions, Asset Compliance and Access Reviews.
- Security Findings provide MANAGER-only operational lifecycle management for
  triage, ownership, remediation, validation, risk acceptance, closure and
  cancellation. Restricted evidence requires an explicit manager grant.
- USER and ADMIN can submit and follow only their own Security Exceptions.
  MANAGER processes approval, activation, renewal and closure through trusted,
  idempotent commands with immutable approval and audit history.
- Exception approval groups resolve active MANAGER members, remove the
  requester and reject any workflow without an independent approver.
- Asset Compliance records the seven required security controls and publishes
  only `compliant`, `action_required` or `assessment_pending` to the assigned
  USER. ADMIN receives no raw assessment or own-device projection access.
- Access Review campaigns, items, decisions, correction requests and revocation
  tasks are implemented with requester isolation and trusted completion.
- Governed evidence uses one canonical Storage path and remains unreadable until
  immutable Firestore metadata is registered by the finalization Function.
- Every list and first-page stream is bounded, session scoped, indexed and
  invalidated when the authenticated user changes.

## Files changed

- `lib/modules/itsm/security_compliance`: Phase 5 domain models, policies,
  repository contracts and Firestore implementation, providers, command
  controller, role-aware screens, dialogs and reusable responsive widgets.
- `lib/router.dart` and `lib/modules/itsm/presentation/navigation`: canonical
  Security & Compliance routes, deep-link handling and role requirements.
- `lib/l10n/intl_en.arb`, `lib/l10n/intl_fr.arb`, `lib/generated/l10n.dart` and
  `tool/generate_localizations.dart`: namespaced English/French Phase 5 text and
  generated dynamic lookup support.
- `functions/src/itsm_security_compliance_*.js`: strict validation,
  transactional services, callable handlers, notifications, safe projections
  and attachment registration.
- `functions/index.js` and `functions/package.json`: callable/event exports and
  Phase 5 lint, unit, rule and callable-emulator scripts.
- `firestore.rules`, `storage.rules` and `firestore.indexes.json`: deny-by-
  default role controls, requester isolation, evidence authorization and all
  bounded query indexes.
- `test/modules/itsm/security_compliance` and
  `functions/test/itsm_security_compliance_*`: domain, data, provider, widget,
  router, Functions and emulator coverage.
- `docs/itsm/phase_5_implementation_map.md`: implementation, access and
  verification map.

## Firebase changes

- Authoritative collections: `securityFindings`, `securityExceptions`,
  `assetComplianceAssessments`, `accessReviewCampaigns` and
  `accessReviewItems`, with governed child collections for attachments,
  comments, approvals, audit history, validation/remediation records,
  correction requests and revocation tasks.
- Safe projection collection: `assetComplianceSelfService`, containing no raw
  controls, evidence or remediation details.
- Twenty-four exported callable commands cover all Phase 5 lifecycle and
  decision operations. One Storage finalization Function validates and
  registers immutable attachment metadata.
- Trusted commands maintain work-item summaries, audit events, notification
  events and safe compliance projections; clients cannot mutate those records.
- Canonical evidence path:
  `itsm/{parentCollection}/{parentId}/attachments/{attachmentId}/{fileName}`.
- The complete Firestore index manifest contains 116 unique indexes.
- No Firebase resource was deployed and no production document was migrated.

## Permissions verified

- USER: no raw finding access; submit/read own exceptions; read only their own
  safe compliance projection and own access-review records; request access
  correction or revocation.
- MANAGER: bounded operational access to findings, exceptions, raw compliance
  and access reviews; all mutations go through trusted commands; restricted
  evidence requires explicit authorization.
- ADMIN: own-exception and own-access-review self-service only; no raw findings,
  raw compliance, safe device projection, operational commands or evidence.
- Direct client writes to governed parents, approvals, audit records,
  projections and attachment metadata are denied for every role.
- Restricted evidence is parent aware, uploader bound, MIME/size checked,
  immutable and unavailable before trusted metadata registration.

## Tests

- `flutter analyze`: passed with no issues.
- `flutter test`: 431 tests passed.
- Focused Phase 5 Flutter, navigation and route suite: 87 tests passed.
- Functions lint and syntax checks: passed on Node.js 22.
- Functions unit suite: 163 tests passed.
- Phase 5 callable Auth/Firestore/Functions emulator suite: 3 tests passed.
- Focused Phase 5 Firestore and Storage emulator suite: 15 tests passed.
- Complete cross-phase ITSM Firestore and Storage emulator suite: 62 tests
  passed against `demo-arptc-connect-itsm` with JDK 21.
- `flutter build web` with the configured Web Push VAPID define: passed.
- `firestore.indexes.json` parsing and uniqueness (`116/116`) and
  `git diff --check`: passed.
- Failed: none outstanding at report finalization.
- Not run: Firebase deployment and production migration were intentionally not
  run under the approved execution rules.

## Remaining work

- Phase 6: relocate and extend Reporting & Administration dashboards using
  trusted report snapshots; implement versioned SLA processing, catalogue and
  workflow administration, and bounded global audit/export views.
- Final delivery: run the complete release gate and explicitly audit all 20
  specification acceptance criteria.
