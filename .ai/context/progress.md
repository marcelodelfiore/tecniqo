# Project Progress

## Current milestone

- **Name:** Phase 1 — Identity, Organization, Roles, and Authorization Foundation
- **Status:** Persistence and tenant-context authorization implemented; membership administration pending
- **Target outcome:** Explicit, testable tenant isolation and contextual authorization on
  top of the existing authentication system

## Completed

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

- Product decision for invitation/provisioning behavior and planning membership administration.

## Planned

- Implement membership administration with last-active-Administrator protection after
  provisioning behavior is decided.
- Add resource-specific tenant policies/scopes with each future vertical slice.
- After Phase 1 passes security checks, begin the Customer → Site → Asset vertical slice.

## Known defects and technical debt

| Item | Impact | Priority | Evidence | Intended action |
|---|---|---|---|---|
| Unknown emails auto-register | May bypass intended organization invitation lifecycle | P1 | `SessionsController#create` | Decide provisioning before membership management UI |
| No tenant/authorization layer | Product records cannot yet be safely introduced | P0 | schema and controllers | Implement approved Phase 1 foundation next |
| Starter copy remains in UI | Product identity/navigation is incomplete | P2 | layouts/home/dashboard | Replace within the first relevant UI slice |
| Generator text remains in token confirmation | Duplicate/irrelevant sign-in content | P2 | `app/views/sessions/show.html.erb` | Fix in a focused authentication UI cleanup |
| Duplicate copied documentation trees | Agents may edit the wrong context/ADR path | P2 | `docs/.ai/`, `docs/docs/decisions/` | Clean up only with separate approval |
| Production infrastructure providers undecided | Deployment is incomplete | P1 | production configuration | Configure before deployment |

## Lessons worth retaining

- Authentication establishes identity; authorization applies tenant, role, resource, and
  workflow context separately.
- Tenant-safe record loading and action authorization are complementary requirements.
- Rich domain semantics should be implemented through realistic vertical slices while
  field interactions stay simple and mobile-friendly.
