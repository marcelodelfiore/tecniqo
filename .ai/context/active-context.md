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
integration, and a default-deny application policy are implemented. Current-organization
selection, resource policies/scopes, controller verification, and denial handling are not
yet implemented. ADR 0001 defines their accepted boundaries.

## In progress

- Planning the current-organization and tenant-authorization slice.

## Next actions

1. Implement current-organization establishment and foundational policies/scopes with
   cross-tenant, unauthorized, multi-role, and Founder tests.
2. Define invitations/provisioning and whether unknown-email auto-registration remains valid.
3. Implement membership administration and transactional protection for the last active
   Administrator.

Do not start Customer → Site → Asset until this foundation is implemented and validated.

## Acceptance criteria for the current activity

- [x] Existing repository, authentication, product docs, scenario, UI, and tests assessed.
- [x] Pundit and CanCanCan researched and a recommendation recorded.
- [x] Identity, multi-role membership, tenancy, Founder, policy, and integrity decisions recorded.
- [x] Responsive Rails/Hotwire Native readiness recorded.
- [x] No speculative business-domain models or native applications introduced.
- [x] Pundit and the Organization/Membership/fixed-role/Founder persistence foundation implemented.

## Important findings and decisions

- Authentication is secure, compact, and separate from the missing authorization layer.
- Pundit 2.5.2 fits `Current.user` and explicit contextual policy/scoping requirements.
- Organization is the tenant; one global User may have multiple Memberships and roles.
- Founder remains a platform-level User capability and centralized policy exception.
- Fixed MVP role values avoid speculative editable permission infrastructure.
- Membership lifecycle is an explicit non-null active state; users and organizations with
  memberships cannot be deleted through their associations.
- The last active administrator needs transactional protection in the implementation slice.
- Root `.ai/` is operational; `docs/.ai/` and `docs/docs/decisions/` are copied artifacts.

## Risks and blockers

- User provisioning/invitations and current-organization selection behavior need a product
  decision before management UI is exposed.
- Current-organization establishment and resource authorization remain a security boundary;
  tenant-owned product routes must not be introduced before that slice is complete.

## Validation status

- Ruby 4.0.6 `bundle exec rspec`: 70 examples, 0 failures.
- Ruby 4.0.6 `bin/rubocop`: 60 files, no offenses.
- Ruby 4.0.6 `bin/rails zeitwerk:check`: passed with the existing mailer-preview notice.
- Ruby 4.0.6 `bundle exec brakeman --no-pager`: no warnings.
- `bin/bundler-audit`, `bin/importmap audit`, and `npm run verify:preline`: passed.
- `bin/rails db:migrate:status`: all migrations up.
- `git diff --check`: passed.
- `bin/ci`: all steps through Importmap Audit passed; the final Brakeman wrapper stopped
  because locked Brakeman 8.0.5 is not the latest 8.0.6. The direct 8.0.5 scan has no warnings.

## Handoff note

The next code task should establish validated current-organization context and prove
tenant isolation through policies, scopes, and request specs before adding Customer,
Site, or Asset.
