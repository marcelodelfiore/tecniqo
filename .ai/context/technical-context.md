# Technical Context

## Stack

- **Language/runtime:** Ruby 4.0.6
- **Framework:** Rails 8.1.3.1
- **Database:** PostgreSQL
- **Background jobs/cache/cable:** Solid Queue, Solid Cache, Solid Cable
- **Frontend:** server-rendered ERB, Turbo 2, Stimulus, Importmaps, Tailwind CSS 4, Preline 4.2
- **Infrastructure:** Docker and Kamal baseline; PWA scaffolding retained
- **Tests:** RSpec 3.13 / RSpec Rails 8 with Factory Bot
- **Observability:** Rails logging; provider undecided

## Existing authentication

Authentication is custom, passwordless, and must be preserved:

- `User` is a global email identity and normalizes email addresses.
- `LoginToken` stores only a SHA-256 digest, expires after 15 minutes, and is single-use.
- issuing a token locks the user and revokes other active tokens;
- the emailed GET renders a no-store confirmation; a CSRF-protected POST consumes it;
- the Rails session stores `user_id`, and `ApplicationController` assigns `Current.user`;
- issuance is rate-limited by IP and normalized email and delivery uses Active Job.

The current sign-in flow creates an unknown `User` automatically. Revisit that product
rule before organization invitations are exposed; do not silently change it.

## Authorization direction

- Adopt Pundit 2.5.x when the Phase 1 persistence foundation is implemented.
- Include `Pundit::Authorization` and define `pundit_user` as `Current.user`.
- Use resource policies for actions and policy scopes for collections/record loading.
- Use `verify_authorized` / `verify_policy_scoped` in authenticated product controllers,
  with explicit skips for public/authentication endpoints.
- Rescue authorization denial into the existing flash/redirect UI for HTML while
  preserving an explicit forbidden response where a redirect is inappropriate.
- Keep policy specs under `spec/policies`; use Pundit's RSpec support for actions and
  ordinary examples for scopes and cross-tenant isolation.

Pundit is not installed yet. CanCanCan 3.6.1 was evaluated but not selected; its
centralized ability DSL and automatic loading offer less clarity for contextual,
tenant-sensitive rules than explicit policies and scopes.

## Local environment

Prerequisites are Ruby 4.0.6, PostgreSQL, and an SMTP catcher on `127.0.0.1:1025`.
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
| `MAILER_FROM` | Email sender | No |
| `FORCE_SSL` | Enable HTTPS enforcement | No |
| `RAILS_MASTER_KEY` | Decrypt production credentials | No |
| `DATABASE_URL` | Override PostgreSQL connection | No |
| `RAILS_LOG_LEVEL` | Log verbosity | No |

Never record secret values in source or context.

## Compatibility and known setup constraints

- Modern browsers are enforced by `ApplicationController`.
- New navigation uses conventional stable Rails routes and progressive enhancement so
  future Hotwire Native shells can intercept selected routes or actions.
- Browser session authentication is current; native-shell session persistence must be
  designed before native clients ship, without redesigning authentication now.
- Tests require a reachable PostgreSQL server; network-backed audit updates may fail in
  restricted environments.
