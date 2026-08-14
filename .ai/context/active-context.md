# Active Context

## Current objective

Phase 1 — Identity, Organization, Roles, and Authorization Foundation.

## Current branch

`main`

## Current state

The Rails application runs on Ruby 4.0.6 and provides tested passwordless authentication,
a global User identity, `Current.user`, PostgreSQL, RSpec, and a responsive
Tailwind/Preline/Hotwire shell.
Organization, membership roles, current-organization selection, and Pundit are not yet
implemented. ADR 0001 defines their intended boundaries.

## In progress

- Human review of the Phase 1 research and architecture decision.

## Next actions

1. Approve a focused implementation slice adding Pundit and the Organization,
   Membership, and fixed membership-role persistence foundation.
2. Define invitations/provisioning and whether unknown-email auto-registration remains valid.
3. Implement current-organization establishment and foundational policies/scopes with
   cross-tenant, unauthorized, multi-role, and Founder tests.

Do not start Customer → Site → Asset until this foundation is implemented and validated.

## Acceptance criteria for the current activity

- [x] Existing repository, authentication, product docs, scenario, UI, and tests assessed.
- [x] Pundit and CanCanCan researched and a recommendation recorded.
- [x] Identity, multi-role membership, tenancy, Founder, policy, and integrity decisions recorded.
- [x] Responsive Rails/Hotwire Native readiness recorded.
- [x] No speculative business-domain models or native applications introduced.

## Important findings and decisions

- Authentication is secure, compact, and separate from the missing authorization layer.
- Pundit 2.5.2 fits `Current.user` and explicit contextual policy/scoping requirements.
- Organization is the tenant; one global User may have multiple Memberships and roles.
- Founder remains a platform-level User capability and centralized policy exception.
- Fixed MVP role values avoid speculative editable permission infrastructure.
- The last active administrator needs transactional protection in the implementation slice.
- Root `.ai/` is operational; `docs/.ai/` and `docs/docs/decisions/` are copied artifacts.

## Risks and blockers

- User provisioning/invitations and current-organization selection behavior need a product
  decision before management UI is exposed.
- Adding Pundit is a production dependency and implementing authorization is a security
  boundary; both belong in the next explicitly approved code slice.

## Validation status

- Documentation review and repository inspection: complete.
- Ruby 4.0.6 `bundle exec rspec`: 53 examples, 0 failures.
- Ruby 4.0.6 `bin/rubocop`: 48 files, no offenses.
- Ruby 4.0.6 `bin/rails zeitwerk:check`: passed with the existing mailer-preview notice.
- Ruby 4.0.6 `bundle exec brakeman --no-pager`: no warnings. The `bin/brakeman` wrapper could not
  complete its network-backed latest-version check in the restricted environment.
- `git diff --check`: passed.

## Handoff note

Review ADR 0001. The next code task should implement only the documented Phase 1
persistence and authorization foundation, then prove tenant isolation before adding
Customer, Site, or Asset.
