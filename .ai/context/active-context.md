# Active Context

## Current objective

Phase 1 — Identity, Organization, Roles, and Authorization Foundation.

## Current branch

`main`

## Current state

The Rails application runs on Ruby 4.0.6 and provides tested passwordless authentication,
a global User identity, `Current.user`, PostgreSQL, RSpec, and a responsive
Tailwind/Preline/Hotwire shell.
Organization, Membership, fixed membership-role assignments, the Founder flag, Pundit
integration, default-deny policy behavior, validated current-organization selection,
foundational policies/scopes, controller verification, and safe denial handling are
implemented. Tenant-owned domain resource policies do not exist yet because those records
remain deferred. ADR 0001 defines the accepted boundaries.

## In progress

- Planning membership provisioning and administration boundaries.

## Next actions

1. Define invitations/provisioning and whether unknown-email auto-registration remains valid.
2. Implement membership administration and transactional protection for the last active
   Administrator.
3. Begin Customer → Site → Asset only after the remaining Phase 1 management invariants pass.

Do not start Customer → Site → Asset until this foundation is implemented and validated.

## Acceptance criteria for the current activity

- [x] Existing repository, authentication, product docs, scenario, UI, and tests assessed.
- [x] Pundit and CanCanCan researched and a recommendation recorded.
- [x] Identity, multi-role membership, tenancy, Founder, policy, and integrity decisions recorded.
- [x] Responsive Rails/Hotwire Native readiness recorded.
- [x] No speculative business-domain models or native applications introduced.
- [x] Pundit and the Organization/Membership/fixed-role/Founder persistence foundation implemented.
- [x] Validated current-organization selection and foundational authorization implemented.

## Important findings and decisions

- Authentication is secure, compact, and separate from the missing authorization layer.
- Pundit 2.5.2 fits `Current.user` and explicit contextual policy/scoping requirements.
- Organization is the tenant; one global User may have multiple Memberships and roles.
- Founder remains a platform-level User capability and centralized policy exception.
- Fixed MVP role values avoid speculative editable permission infrastructure.
- Membership lifecycle is an explicit non-null active state; users and organizations with
  memberships cannot be deleted through their associations.
- Current organization is revalidated through the Organization policy scope on every request;
  one option auto-selects, several require a choice, and Founder still selects a tenant.
- The last active administrator needs transactional protection in the implementation slice.
- Root `.ai/` is operational; `docs/.ai/` and `docs/docs/decisions/` are copied artifacts.

## Risks and blockers

- User provisioning/invitations need a product decision before membership management UI is exposed.
- Last-active-Administrator protection must be implemented with membership management.

## Validation status

- Ruby 4.0.6 `bundle exec rspec`: 91 examples, 0 failures.
- Ruby 4.0.6 `bin/rubocop`: 66 files, no offenses.
- Ruby 4.0.6 `bin/rails zeitwerk:check`: passed with the existing mailer-preview notice.
- Ruby 4.0.6 `bundle exec brakeman --no-pager`: no warnings.
- `bin/bundler-audit`, `bin/importmap audit`, and `npm run verify:preline`: passed.
- `bin/rails db:migrate:status`: all migrations up.
- `git diff --check`: passed.
- `bin/ci`: all steps through Importmap Audit passed; the final Brakeman wrapper stopped
  because locked Brakeman 8.0.5 is not the latest 8.0.6. The direct 8.0.5 scan has no warnings.

## Handoff note

The next task should decide provisioning and implement membership administration with
last-active-Administrator protection. Every future tenant-owned slice must use policy-scoped
loading and explicit action authorization from its first route.
