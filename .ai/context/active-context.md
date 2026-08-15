# Active Context

## Current objective

Phase 2 — Customer → Site → Asset operational-context vertical slice.

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
Customer, Site, and Asset persistence, composite tenant integrity, policies, nested routes,
responsive translated UI, factories, seeds, and focused tests are implemented. ADRs 0001
through 0004 define the accepted boundaries.

## In progress

- Phase 2 responsive browser smoke testing and acceptance review.

## Next actions

1. Browser smoke-test the Customer → Site → Asset workflow at desktop and phone widths.
2. Review Phase 2 acceptance criteria and commit the slice after approval.
3. Plan Service Type → Work Order → Assignment without implementing it automatically.

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
- [x] Customer, Site, and Asset persistence and database tenant integrity implemented.
- [x] Role-aware policies and policy-scoped nested loading implemented.
- [x] Responsive translated Customer → Site → Asset workflow implemented.
- [x] Phase 2 factories, realistic development seeds, and focused specs implemented.

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
- Direct Organization ownership plus composite parent foreign keys protects nested domain data.
- Asset Type is curated with Other as the default; Asset name and tag remain flexible.
- Phase 2 deliberately exposes no delete/archive action pending historical lifecycle semantics.
- Engineer is read-only; Technician has no broad operational scope before assignments exist.
- Root `.ai/` is operational; `docs/.ai/` and `docs/docs/decisions/` are copied artifacts.

## Risks and blockers

- Browser smoke testing should verify Phase 2 ergonomics at desktop and phone widths.

## Validation status

- Ruby 4.0.6 `bundle exec rspec`: 178 examples, 0 failures.
- Ruby 4.0.6 `bin/rubocop`: 105 files, no offenses.
- Ruby 4.0.6 `bin/rails zeitwerk:check`: passed with the existing mailer-preview notice.
- Ruby 4.0.6 `bundle exec brakeman --no-pager`: no warnings.
- `bin/bundler-audit`, `bin/importmap audit`, and `npm run verify:preline`: passed.
- `npm audit --audit-level=high`: passed with no vulnerabilities.
- `bin/rails db:migrate:status`: all migrations up.
- Development seeds ran twice successfully, confirming idempotent Phase 2 demo data.
- `git diff --check`: passed.
- `bin/ci`: tests, style, JavaScript setup, Preline, NPM, gem, and Importmap audits passed;
  the final wrapper stopped only because Brakeman 8.0.5 is not the latest 8.0.6. The direct
  locked-version scan completed with no warnings.

## Handoff note

Phase 1 is complete and browser-smoke-tested. Phase 2 implements the first tenant-owned domain
slice using direct ownership, policy-scoped nested loading, and explicit action authorization.
