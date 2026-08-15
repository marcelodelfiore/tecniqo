# Active Context

## Current objective

Plan Phase 5 — structured technical field capture.

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
through 0004 define those accepted boundaries. Service Type management, Work Order issuance,
scheduling, optional Asset context, assignment history, role-aware visibility, responsive UI,
and dependent selectors are implemented. ADR 0005 defines the Phase 3 boundaries.

Execution visits, multiple Technician participants, append-oriented execution events, derived
state and durations, outcome/return handling, participant-aware technician scope, `My Work`, and
responsive field/supervisor UI are implemented. Visit scheduling is Execution-owned while the
existing Work Order schedule remains the initial coordination date. ADR 0006 records the Phase 4
event/state and scheduling decisions.

Phase 3 responsive browser smoke testing and acceptance review are complete.

Phase 4 responsive browser smoke testing and acceptance review are complete.

## In progress

- Phase 5 requirements inspection and task definition.

## Next actions

1. Inspect the canonical scenario's Findings, Measurements, Evidence, Actions, Materials, and Recommendations.
2. Define Phase 5 structured-fact, evidence-linking, authorship, lifecycle, and authorization boundaries.
3. Produce a bounded Phase 5 task brief and implementation plan before editing application code.

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
- [x] Tenant-owned Service Type activation/deactivation implemented.
- [x] Work Order issuance, public identifier, priority, optional Asset, and scheduling implemented.
- [x] Eligible Technician assignment and atomic reassignment history implemented.
- [x] Phase 3 policies, responsive UI, dependent selectors, seeds, and focused specs implemented.
- [x] Phase 3 responsive browser smoke testing and acceptance review completed by the developer.
- [x] Work Orders support independently scheduled, Work Order-local numbered Executions.
- [x] Assignment and multi-Technician Execution participation remain distinct.
- [x] Fixed operational events derive state and timing without manual actor/time/status input.
- [x] Pause/resume cycles, unable-to-execute, return-required, submission locking, and return visits work.
- [x] Technician access is limited to current assignment or participation; field actions require participation.
- [x] Phase 4 mobile-first field UI, supervisor visit summaries, `My Work`, translations, seeds, and tests exist.
- [x] Phase 4 responsive browser smoke testing and acceptance review completed by the developer.

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
- Work Order identifiers use a locked Organization sequence and stable `OS-YYYY-NNNNNN` URLs.
- Service Types deactivate without invalidating existing Work Orders.
- Assignment references Technician Membership and preserves one current plus historical records.
- Technician visibility is now limited to currently assigned Work Orders.
- Work Orders have no premature status/cancellation field; Asset remains optional and singular for MVP.
- Dependent selectors are a small progressive enhancement over tenant-scoped server-rendered options.
- Execution event transitions lock the Execution row; visit allocation locks the Work Order row.
- `occurred_at` is business time and `created_at` is persistence time; event chronology uses both
  occurrence time and ID as a stable tie-breaker.
- Execution state and durations are derived from immutable operational events, not editable status
  or timesheet columns.
- Only active Technician Memberships participate; Founder authorization is not field eligibility.
- Submission is terminal for Phase 4, and return visits remain under the same Work Order.
- Root `.ai/` is operational; `docs/.ai/` and `docs/docs/decisions/` are copied artifacts.

## Risks and blockers

- None currently identified; Phase 5 domain and evidence-linking rules still require planning.
- Organization-specific time zones and offline synchronization remain intentionally deferred.

## Validation status

- Ruby 4.0.6 `bundle exec rspec`: 230 examples, 0 failures.
- Ruby 4.0.6 `bin/rubocop`: 147 files, no offenses.
- Ruby 4.0.6 `bin/rails zeitwerk:check`: passed with the existing mailer-preview notice.
- Ruby 4.0.6 `bundle exec brakeman --no-pager`: no warnings.
- `bin/bundler-audit`, `bin/importmap audit`, and `npm run verify:preline`: passed.
- `npm audit --audit-level=high`: passed with no vulnerabilities.
- `bin/rails db:migrate:status`: all migrations up.
- Development seeds ran twice successfully, confirming idempotent Phase 4 demo data.
- `git diff --check`: passed.
- `bin/ci`: setup, 230 tests, style, JavaScript setup, Preline, NPM, gem, and Importmap
  audits passed; the wrapper stopped only because locked Brakeman 8.0.5 is not latest 8.0.6.
  Direct `bundle exec brakeman --no-pager` completed with no warnings.

## Handoff note

Phases 1 through 4 are complete and accepted. Phase 5 planning is next and must add technical field
facts without weakening the Phase 4 event history or collapsing Work Order, Assignment, Execution,
and participant responsibilities.
