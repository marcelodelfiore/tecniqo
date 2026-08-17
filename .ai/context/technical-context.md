# Technical Context

## Stack

- **Language/runtime:** Ruby 4.0.6
- **Framework:** Rails 8.1.3.1
- **Database:** PostgreSQL
- **Background jobs/cache/cable:** Solid Queue, Solid Cache, Solid Cable
- **Frontend:** server-rendered ERB, Turbo 2, Stimulus, Importmaps, Tailwind CSS 4, Preline 4.2
- **Infrastructure:** Docker and Kamal baseline; PWA scaffolding retained
- **Evidence storage:** Active Storage with private provider-neutral S3 configuration;
  Garage 2.3.0 is the initial Compose/Kamal backend
- **Tests:** RSpec 3.13 / RSpec Rails 8 with Factory Bot
- **Observability:** Rails logging; provider undecided

## Internationalization

- Supported locales are `en`, `pt-BR`, and `es`; English is the default and fallback.
- A dedicated allowlisted locale action stores the browser preference in the Rails session.
- Authentication session resets preserve locale, and emailed security links carry the locale.
- Requests and mailers use `I18n.with_locale` so locale state does not leak.
- All new user-facing UI, flash, role, validation-facing, and email copy must be added to all
  three locale dictionaries. ADR 0003 records the boundary.

## Existing authentication

Authentication is custom, passwordless, and must be preserved:

- `User` is a global email identity and normalizes email addresses.
- `LoginToken` stores only a SHA-256 digest, expires after 15 minutes, and is single-use.
- issuing a token locks the user and revokes other active tokens;
- the emailed GET renders a no-store confirmation; a CSRF-protected POST consumes it;
- the Rails session stores `user_id`, and `ApplicationController` assigns `Current.user`;
- issuance is rate-limited by IP and normalized email and delivery uses Active Job.

Ordinary provisioning is invitation-only. Unknown emails and legacy Users without
membership history receive the generic sign-in response but no token or email; Founder is
the explicit exception. Invitation tokens also store only a SHA-256 digest, expire after
seven days, and use a no-store GET confirmation plus CSRF-protected POST acceptance. The
POST atomically creates/reuses the User, activates Membership, grants invited roles, and
establishes the session. Active current-organization Administrators can issue, resend, and
revoke invitations through the Rails UI; Founder has the same capability only inside an
explicitly selected Organization. Delivery uses Active Job and the configured SMTP server.
ADR 0002 records the provisioning decision.

## Authorization foundation

- Pundit 2.5.2 is installed.
- Include `Pundit::Authorization` and define `pundit_user` as `Current.user`.
- Use resource policies for actions and policy scopes for collections/record loading.
- Use `verify_authorized` / `verify_policy_scoped` in authenticated product controllers,
  with explicit skips for public/authentication endpoints.
- Rescue authorization denial into the existing flash/redirect UI for HTML while
  preserving an explicit forbidden response where a redirect is inappropriate.
- Keep policy specs under `spec/policies`; use Pundit's RSpec support for actions and
  ordinary examples for scopes and cross-tenant isolation.

The default `ApplicationPolicy` and scope deny every action/record and reject missing
users. `Current.organization` is established from a server-side session selection that is
revalidated through `OrganizationPolicy::Scope` on every request; a sole available
organization is selected automatically. The dashboard and organization-selection flow
use Pundit verification and safe HTML denial handling. Resource-specific policies/scopes
remain mandatory as tenant-owned domain records are introduced. CanCanCan 3.6.1 was
evaluated but not selected; its
centralized ability DSL and automatic loading offer less clarity for contextual,
tenant-sensitive rules than explicit policies and scopes.

## Phase 2 operational context

- `Customer` belongs to Organization and owns Sites; `Site` directly belongs to Organization
  and Customer; `Asset` directly belongs to Organization and Site.
- Composite tenant/parent foreign keys enforce nested ownership in PostgreSQL.
- Customer routes are top-level; Site and Asset routes remain fully nested so server-rendered
  pages and future Hotwire Native shells retain explicit operational context.
- Customer/Site/Asset controllers use policy-scoped parent and record loading plus explicit
  Pundit authorization. Administrator and Supervisor manage, Engineer reads, and Technician
  remains excluded until assignment-based scoping exists.
- Asset Type uses the fixed translated `Asset::TYPES` vocabulary with `other` as its default.
- Product UI remains server-rendered, Turbo-compatible, responsive cards and compact forms;
  Phase 2 adds no Stimulus behavior because normal navigation and submission are sufficient.

## Phase 3 operational work management

- `ServiceType` is Organization-owned, case-insensitively unique, and explicitly active/inactive;
  inactive records remain valid history but are excluded from new Work Orders.
- `WorkOrder` directly belongs to Organization, Customer, Site, Service Type, creator, and an
  optional Asset. Composite foreign keys enforce tenant and Customer/Site/Asset consistency.
- Work Order identifiers use a locked per-Organization sequence formatted as
  `OS-YYYY-NNNNNN`; public routes resolve this identifier rather than exposing database IDs.
- Priorities are `normal`, `high`, and `urgent`; scheduling is one optional `scheduled_start`.
  Phase 3 deliberately adds no status or cancellation workflow.
- `Assignment` preserves responsibility history using Technician Membership, assigning User,
  `assigned_at`, and `ended_at`. Reassignment is atomic and a partial unique index permits one
  current Assignment per Work Order.
- Work Order forms server-render policy-scoped options and use one small Stimulus controller to
  filter Site by Customer and Asset by Site. Server/model/database validation remains authoritative.
- Administrator and Supervisor manage Work Orders; Engineer reads; Technician reads only current
  assignments. Founder manages but is assignable only with an eligible Technician Membership.
- ADR 0005 records identifier, lifecycle, assignment-history, and dependent-selector decisions.

## Phase 4 field execution

- `Execution` is a Work Order visit with a concurrency-safe Work Order-local visit number and its
  own optional schedule. Visit 1 defaults from the existing Work Order schedule.
- `ExecutionParticipant` references an eligible active Technician Membership. Assignment seeds the
  first participant but remains a separate responsibility-history concept.
- Fixed `ExecutionEvent` actions store server-derived actor Membership and `occurred_at`; Rails
  `created_at` separately records persistence. Events are ordered by occurrence plus ID.
- Execution state and operational durations derive from append-oriented event history. Row locks
  serialize transitions and reject duplicate/concurrent actions.
- Outcomes are `completed`, `return_required`, and `unable_to_execute`; return/unable reasons use a
  small fixed vocabulary. Submission is terminal for Phase 4.
- Technician access is limited to current Work Order assignment or Execution participation; field
  actions require actual participation. `My Work` provides the minimal technician entry point.
- Rails persists timestamps in its configured UTC convention and renders them through the active
  Rails time zone. Organization-specific zones remain deferred.
- ADR 0006 records event/state, occurrence timestamp, participant, and visit-scheduling decisions.

## Phase 5 structured technical record

- `Finding`, `Measurement`, `ActionPerformed`, `MaterialUsed`, and `Recommendation` belong
  directly to Execution and Organization with composite tenant foreign keys.
- Authenticated participating Technician Membership and `recorded_at` are server-derived.
- Measurements persist `numeric(18,6)` values and stable quantity/unit keys; the curated
  `Measurement::QUANTITY_UNITS` map and a PostgreSQL check reject incompatible pairs.
- `EvidenceReference` reuses immutable Execution-owned Evidence. A composite foreign key
  enforces Evidence, Execution, and Organization consistency; unlink never deletes Evidence.
- Participating Technicians create/edit/remove before submission. Founder, Administrator,
  Supervisor, and Engineer read according to Execution scope without acquiring authorship.
- The Execution page provides focused mobile-first capture and grouped responsive technical
  presentation. ADR 0008 records vocabulary, lifecycle, and linking decisions.

## Phase 6 engineering review

- `EngineeringReview` belongs to a Work Order and explicitly includes its ready submitted
  Executions; one review is allowed per Work Order.
- Reviews are created automatically after the final current visit is submitted, with a deployment
  backfill for already-ready Work Orders. States are pending, in review, changes requested, and
  approved; transitions are explicit locked actions.
- One Engineer claims responsibility. Founder must explicitly perform the same action;
  Administrator and Supervisor visibility never implies technical approval authority.
- `ClarificationRequest` targets useful Work Order/Execution/fact/Evidence context, defaults to the
  original Technician author where possible, records one response, and requires explicit reviewer
  resolution. Unresolved requests block approval.
- Clarification responses may link existing Evidence or append a new immutable original to the same
  submitted Execution through a dedicated recipient-authorized endpoint.
- Approval records actor/time, retains submission immutability, and locks Work Order edits. It is
  neither report issuance nor a reproducible metadata revision; ADR 0009 defines that Phase 7 seam.

## Local environment

The complete containerized environment requires only Docker:

```sh
docker compose up --build
```

It provides Rails at `localhost:3000`, Mailpit at `localhost:8026`, internal PostgreSQL,
and Garage on localhost ports 3900/3903. Rails runs its production artifact, prepares all
Solid databases, seeds demo identities through the explicit `LOAD_DEMO_DATA` gate, and
runs Solid Queue in Puma. Details and reset warnings are in
`docs/containerized-development.md`.

Garage is optional for normal tests. Copy `.env.example`, set its secrets, run
`docker compose up -d garage`, and select `ACTIVE_STORAGE_SERVICE=evidence_s3` to test
the S3 path. The persistence smoke test is in `docs/evidence-storage.md`.

Prerequisites are Ruby 4.0.6, PostgreSQL, and an SMTP catcher such as Mailpit on `127.0.0.1:1025`.
Node.js 24 is required for Preline maintenance and the complete CI pipeline.

```sh
bundle install
bin/setup
bin/dev
```

## Validation commands

```sh
bundle exec rspec spec/path/to/relevant_spec.rb # targeted tests
bundle exec rspec                                # full suite
bin/rubocop                                     # Ruby lint
bin/brakeman --no-pager                         # application security scan
bin/bundler-audit                               # gem vulnerability scan
bin/importmap audit                             # JavaScript vulnerability scan
npm run verify:preline                          # verify vendored Preline
bin/rails zeitwerk:check                        # autoloading
bin/rails db:migrate:status                     # migrations
bin/ci                                          # canonical pipeline
```

## Environment variables and secrets

| Variable | Purpose | Required locally? |
|---|---|---|
| `APPLICATION_NAME` | Override visible product name | No |
| `APP_HOST` | Host in production email URLs | No |
| `APP_PROTOCOL` / `APP_PORT` | Email-link scheme and optional port | No |
| `SMTP_ADDRESS` / `SMTP_PORT` | SMTP endpoint | No |
| `MAILER_FROM` | Email sender | No |
| `FORCE_SSL` | Enable HTTPS enforcement | No |
| `RAILS_MASTER_KEY` | Decrypt production credentials | No |
| `DATABASE_URL` | Override PostgreSQL connection | No |
| `RAILS_LOG_LEVEL` | Log verbosity | No |
| `SEED_DATABASE` / `LOAD_DEMO_DATA` | Explicit local Compose demo seeding gates | No |

Never record secret values in source or context.

## Compatibility and known setup constraints

- Modern browsers are enforced by `ApplicationController`.
- New navigation uses conventional stable Rails routes and progressive enhancement so
  future Hotwire Native shells can intercept selected routes or actions.
- Browser session authentication is current; native-shell session persistence must be
  designed before native clients ship, without redesigning authentication now.
- Tests require a reachable PostgreSQL server; network-backed audit updates may fail in
  restricted environments.
