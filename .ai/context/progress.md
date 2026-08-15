# Project Progress

## Current milestone

- **Name:** Phase 4.6 — Complete Containerized Development Infrastructure
- **Status:** Complete and validated
- **Target outcome:** One-command Rails, PostgreSQL, Garage, and Mailpit startup

## Completed

### 2026-08-15 — Add complete local Compose infrastructure

- Added PostgreSQL 17, production-image Rails/Thruster, Solid Queue, and Mailpit 1.30.7
  to the existing Garage Compose service.
- Added health-gated startup, all four Rails database URLs, automatic `db:prepare`,
  explicit idempotent demo-seed gates, SMTP routing, and correct container mail URLs.
- Added persistent database/Garage volumes and localhost-only published development ports.
- Documented one-command startup, seeded identities, logs/console, persistence, and the
  explicitly destructive volume-reset workflow.
- Container smoke validation: all services healthy; database preparation/seeding,
  Rails HTTP, Solid Queue, SMTP/Mailpit, S3 upload/download, and restart persistence passed.
- Repository validation: 242 RSpec examples, RuboCop, Zeitwerk, direct Brakeman,
  Bundler/Importmap/NPM audits, Compose parsing, entrypoint syntax, and diff checks passed.
  Canonical CI passed through Importmap Audit and stopped only at the existing locked
  Brakeman latest-version gate (8.0.5 locked; 8.0.6 latest).

### 2026-08-15 — Implement secure provider-independent Evidence storage

- Added Active Storage and provider-neutral private S3 configuration with Garage 2.3.0
  as the first Compose/Kamal backend.
- Added immutable Execution-owned Evidence with automatic authenticated Membership
  provenance, original metadata, SHA-256, allowlisted types/sizes, and tenant constraints.
- Disabled default Active Storage routes and added explicit Pundit-authorized upload and
  streamed-original endpoints.
- Documented provider migration, independent backup, the media catalog, deferred direct
  uploads/malware scanning, and future authenticity/Hotwire Native paths.
- Validation: 242 RSpec examples and RuboCop passed; direct Brakeman reported zero
  warnings; Bundler/NPM/Importmap audits passed. Garage upload/download and SHA-256 were
  verified before and after container restart. `bin/ci` passed through Importmap Audit
  and stopped only at its existing Brakeman latest-version gate (8.0.5 locked; 8.0.6 latest).

### 2026-08-15 — Implement Execution → Participants → Execution Events

- Added Work Order-local numbered Executions with independent visit scheduling and current-assignment
  participant seeding while keeping Assignment and participation separate.
- Added multiple eligible Technician participants, participant-aware historical Work Order access,
  fixed append-oriented events, automatic actor/time capture, row-locked transitions, and submission locking.
- Added derived state and timing for site presence, pre-work waiting, pause cycles, effective work,
  and post-work onsite time without status or duration columns.
- Added completed, return-required, and unable-to-execute outcomes, a natural return-visit workflow,
  and explicit handling that does not fabricate asset-work events.
- Added mobile-first field actions/timeline, supervisor visit summaries, minimal `My Work`, three-locale
  copy, canonical scenario seeds, factories, and model/policy/request/concurrency coverage.
- Recorded event/state, occurrence-time, participant, and scheduling decisions in ADR 0006.
- Validation: 230 RSpec examples, RuboCop, Zeitwerk, direct Brakeman, Bundler/NPM/Importmap audits,
  Preline verification, idempotent seed rerun, and diff checks passed. Canonical CI passed every
  step except its existing Brakeman latest-version gate (8.0.5 locked; 8.0.6 latest).
- Acceptance: responsive supervisor and Technician browser smoke testing completed successfully
  by the developer, including the seeded visit workflow.

### 2026-08-15 — Implement Service Type → Work Order → Assignment

- Added tenant-owned Service Types with case-insensitive naming and explicit activation lifecycle.
- Added Work Orders with required operational context, optional Asset, compact priorities, scheduling,
  creator metadata, and concurrency-safe `OS-YYYY-NNNNNN` tenant identifiers used in routes.
- Added first-class Assignment history with active Technician Membership eligibility, automatic actor/
  timestamps, atomic reassignment, and a database-enforced single current assignment.
- Added composite database constraints across Organization, Customer, Site, Asset, Service Type,
  Work Order, and Membership ownership.
- Added responsive Work Order/Service Type screens, contextual creation links, policy-scoped dependent
  selectors, three-locale copy, realistic seeds, factories, and model/policy/request coverage.
- Recorded Phase 3 identity, lifecycle, assignment, and selector decisions in ADR 0005.
- Validation: 207 RSpec examples, RuboCop, Zeitwerk, direct Brakeman, dependency audits,
  Preline verification, migration status, seed rerun, and diff checks passed. Canonical CI
  passed through Importmap Audit and stopped only on its existing Brakeman latest-version gate.
- Acceptance: responsive Phase 3 browser smoke testing completed successfully by the developer.

### 2026-08-15 — Implement Customer → Site → Asset operational context

- Added Customer, Site, and Asset with direct Organization ownership and composite tenant/parent
  foreign keys that reject cross-tenant nesting in PostgreSQL.
- Added concise fields, case-insensitive Customer/Site naming rules, flexible Asset identity,
  and a curated translated Asset Type vocabulary defaulting to Other.
- Added role-aware Pundit policies: Founder/Administrator/Supervisor manage, Engineer reads,
  and Technician remains denied until assignment-based scope exists.
- Added fully nested, policy-scoped Rails routes and responsive English/Portuguese/Spanish UI,
  Customer search and aggregate counts, factories, deterministic development seeds, and focused
  model/policy/request coverage.
- Recorded tenant, Asset Type, uniqueness, and lifecycle decisions in ADR 0004.
- Validation: 178 RSpec examples, RuboCop, Zeitwerk, direct Brakeman, dependency audits,
  Preline verification, migration status, seed rerun, and diff checks passed. Canonical CI
  passed through Importmap Audit and stopped only on its existing Brakeman latest-version gate.

### 2026-08-15 — Add membership administration and three-locale I18n

- Added tenant-scoped membership list/edit/update UI for active Administrators and Founder
  within a selected Organization.
- Added atomic lifecycle/role synchronization and Organization-row locking that preserves
  the last active Administrator, proven with a real concurrent PostgreSQL test.
- Added session-persisted, allowlisted `en`, `pt-BR`, and `es` locale selection, preserving
  locale through authentication resets and propagating it in emailed security links.
- Translated all reachable pages, navigation, flashes, roles, validation-facing copy, and
  authentication/invitation mail; removed unused generated session templates.
- Recorded the I18n boundary in ADR 0003.
- Validation: 154 RSpec examples passed; RuboCop, Zeitwerk, Brakeman, and diff checks passed.

### 2026-08-15 — Add authorized invitation management UI

- Added a responsive pending-invitation list and role-selection form for the selected Organization.
- Active Administrators can issue, resend, and revoke invitations; Founder can do so only
  within an explicitly selected tenant.
- Resend revokes the prior token and queues a replacement email; revoke preserves the audit row.
- Added policy-scoped loading, controller verification, email validation, and conditional
  dashboard navigation.
- Added request and policy coverage for rendered UI, multiple roles, queued delivery,
  validation failures, inactive/non-Administrators, Founder, and cross-tenant IDs.
- Validation: 129 RSpec examples passed; RuboCop, Zeitwerk, Brakeman, and diff checks passed.

### 2026-08-15 — Adopt invitation-only provisioning and implement acceptance

- Recorded invitation-only ordinary account provisioning in ADR 0002.
- Unknown emails and legacy identities without membership history no longer create Users or
  receive sign-in tokens; generic responses preserve account privacy, and Founder is exempt.
- Added digest-only, seven-day, single-use Organization invitations with revocation,
  fixed-role database constraints, and secure GET-confirm/POST-accept semantics.
- Invitation acceptance atomically creates/reuses User, creates/reactivates Membership,
  grants roles, consumes the invitation, and signs in the user.
- Added Mailpit-compatible multipart invitation delivery and focused model, mailer, request,
  database-constraint, and authentication regression coverage.
- Validation: 107 RSpec examples passed; RuboCop, Zeitwerk, Brakeman, and diff checks passed.

### 2026-08-15 — Establish validated tenant context and foundational authorization

- Added `Current.organization` with session-backed selection revalidated against active
  membership visibility on every request.
- Auto-selects one available organization, requires an explicit choice when ambiguous,
  clears stale/inactive selections, and keeps Founder tenant selection explicit.
- Added a policy-scoped organization-selection flow, Organization and Dashboard policies,
  controller verification hooks, and safe HTML denial handling.
- Added request and policy coverage for guests, non-members, inactive memberships,
  cross-tenant IDs, multiple organizations, stale selections, and Founder behavior.
- Validation: 91 RSpec examples passed; RuboCop, Zeitwerk, Brakeman, and diff checks passed.

### 2026-08-15 — Implement Phase 1 persistence and Pundit foundation

- Added Organization, Membership, and fixed MembershipRole persistence with foreign keys,
  non-null fields, unique indexes, and a PostgreSQL role-vocabulary check constraint.
- Added the non-null Founder capability to User, defaulting to false.
- Added explicit active/inactive membership state and restricted deletion of users or
  organizations that retain memberships.
- Installed Pundit 2.5.2, mapped its authorization subject to `Current.user`, and added a
  default-deny application policy and scope.
- Added focused factories and model/database/policy coverage while preserving the existing
  passwordless authentication behavior.
- Validation: 70 RSpec examples passed; RuboCop, Zeitwerk, Brakeman, Bundler Audit,
  Importmap Audit, Preline verification, migration status, and diff checks passed.
- Canonical `bin/ci` passed through Importmap Audit but stopped at its final version check
  because Brakeman 8.0.5 is locked while 8.0.6 is available; the direct scan reported no warnings.

### 2026-08-14 — Upgrade Ruby runtime

- Updated local, Docker, deployment-example, README, and technical-context pins from
  Ruby 3.4.8 to Ruby 4.0.6.
- Selected 4.0.6 instead of the initially requested 4.0.1 because the latter predates
  security fixes released in Ruby 4.0.5.
- Validation under Ruby 4.0.6: 53 RSpec examples passed; RuboCop, Zeitwerk, Brakeman,
  Bundler dependency checks, and diff checks passed.

### 2026-08-14 — Research and define the Phase 1 foundation

- Assessed authentication, sessions, Current context, schema, seeds, UI shell, RSpec,
  project tooling, product analysis, and the canonical return-visit scenario.
- Confirmed that authentication remains the existing global User + LoginToken magic-link flow.
- Selected Pundit over CanCanCan for explicit resource policies and policy scopes.
- Defined Organization tenancy, multi-organization Memberships, multiple fixed MVP roles,
  a separate Founder platform privilege, current-organization rules, and integrity targets.
- Recorded responsive Rails/Hotwire and future thin Hotwire Native shell direction.
- Added ADR 0001; no gem, migration, model, seed, route, controller, or UI behavior changed.
- Validation: 53 RSpec examples passed; RuboCop, Zeitwerk, Brakeman, and diff checks passed.

## In progress

- Phase 5 requirements inspection and task definition.

## Planned

- Define Phase 5 structured-fact, evidence-linking, authorship, lifecycle, authorization, UI,
  and test boundaries.
- Implement Phase 5 only after its task brief and plan are reviewed.

## Known defects and technical debt

| Item | Impact | Priority | Evidence | Intended action |
|---|---|---|---|---|
| Duplicate copied documentation trees | Agents may edit the wrong context/ADR path | P2 | `docs/.ai/`, `docs/docs/decisions/` | Clean up only with separate approval |
| Production infrastructure providers undecided | Deployment is incomplete | P1 | production configuration | Configure before deployment |

## Lessons worth retaining

- Authentication establishes identity; authorization applies tenant, role, resource, and
  workflow context separately.
- Tenant-safe record loading and action authorization are complementary requirements.
- Rich domain semantics should be implemented through realistic vertical slices while
  field interactions stay simple and mobile-friendly.
