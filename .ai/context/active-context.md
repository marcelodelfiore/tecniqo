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
implemented. Invitation-only sign-in enforcement and secure invitation acceptance are also
implemented, including Administrator-authorized issue/resend/revoke UI and queued SMTP delivery.
Membership administration, transactionally locked last-active-Administrator protection,
and an internationalized `en`/`pt-BR`/`es` frontend/mail foundation are implemented.
Tenant-owned domain resource policies do not exist yet because those records remain deferred.
ADRs 0001, 0002, and 0003 define the accepted boundaries.

## In progress

- Phase 1 foundation review and browser smoke testing.

## Next actions

1. Browser smoke-test membership management and all three locale selections.
2. Review Phase 1 acceptance criteria and close remaining foundation defects.
3. Begin the Customer → Site → Asset vertical slice after Phase 1 review.

Do not start Customer → Site → Asset until this foundation is implemented and validated.

## Acceptance criteria for the current activity

- [x] Existing repository, authentication, product docs, scenario, UI, and tests assessed.
- [x] Pundit and CanCanCan researched and a recommendation recorded.
- [x] Identity, multi-role membership, tenancy, Founder, policy, and integrity decisions recorded.
- [x] Responsive Rails/Hotwire Native readiness recorded.
- [x] No speculative business-domain models or native applications introduced.
- [x] Pundit and the Organization/Membership/fixed-role/Founder persistence foundation implemented.
- [x] Validated current-organization selection and foundational authorization implemented.
- [x] Invitation-only provisioning decision and secure acceptance foundation implemented.
- [x] Administrator-authorized invitation management UI and delivery implemented.
- [x] Membership administration and concurrent last-active-Administrator protection implemented.
- [x] Existing frontend and mail localized for English, Brazilian Portuguese, and Spanish.

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
- Invitation tokens are digest-only, seven-day, single-use credentials; acceptance establishes
  identity, membership, roles, and session atomically.
- Invitation management is tenant-scoped and Administrator-only; resend rotates credentials
  and revoke preserves audit history.
- Membership changes lock the Organization and preserve at least one active Administrator,
  including concurrent demotion attempts.
- Locale is allowlisted, session-persisted, preserved across authentication resets, and
  propagated through emailed links without changing stable routes.
- The last active administrator needs transactional protection in the implementation slice.
- Root `.ai/` is operational; `docs/.ai/` and `docs/docs/decisions/` are copied artifacts.

## Risks and blockers

- Browser smoke testing should verify translations and membership management ergonomics.

## Validation status

- Ruby 4.0.6 `bundle exec rspec`: 154 examples, 0 failures.
- Ruby 4.0.6 `bin/rubocop`: 85 files, no offenses.
- Ruby 4.0.6 `bin/rails zeitwerk:check`: passed with the existing mailer-preview notice.
- Ruby 4.0.6 `bundle exec brakeman --no-pager`: no warnings.
- `bin/bundler-audit`, `bin/importmap audit`, and `npm run verify:preline`: passed.
- `bin/rails db:migrate:status`: all migrations up.
- `git diff --check`: passed.
- `bin/ci`: all steps through Importmap Audit passed; the final Brakeman wrapper stopped
  because locked Brakeman 8.0.5 is not the latest 8.0.6. The direct 8.0.5 scan has no warnings.

## Handoff note

Phase 1 identity, tenancy, onboarding, membership management, authorization foundation,
and I18n are implemented. Review and smoke-test before beginning Customer → Site → Asset;
every tenant-owned slice must use policy-scoped loading and explicit action authorization.
