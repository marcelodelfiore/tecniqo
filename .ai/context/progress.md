# Project Progress

## Current milestone

- **Name:** Phase 1 — Identity, Organization, Roles, and Authorization Foundation
- **Status:** Architecture defined; implementation pending approval
- **Target outcome:** Explicit, testable tenant isolation and contextual authorization on
  top of the existing authentication system

## Completed

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

- Human review and approval of ADR 0001 and the next implementation slice.

## Planned

- Implement Organization, Membership, membership roles, Founder privilege, and Pundit
  integration with focused model, policy, scope, and request coverage.
- Establish validated current-organization context and denial behavior.
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
