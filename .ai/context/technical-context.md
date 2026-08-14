# Technical Context

## Stack

- **Language/runtime:** Ruby 3.4.8
- **Framework:** Rails 8.1
- **Database:** PostgreSQL
- **Background jobs/cache/cable:** Solid Queue, Solid Cache, Solid Cable
- **Frontend:** Turbo, Stimulus, Importmaps, Tailwind CSS, Preline
- **Infrastructure:** Docker and Kamal baseline
- **Tests:** RSpec with Factory Bot
- **Observability:** Structured Rails logs only; provider intentionally undecided

## Local environment

Prerequisites are Ruby 3.4.8, PostgreSQL, and an SMTP catcher on `127.0.0.1:1025`.
Node.js 24 is required only for Preline maintenance and the complete CI pipeline.

```sh
bundle install
bin/setup
bin/dev
```

## Validation commands

```sh
bundle exec rspec                         # full suite
bundle exec rspec spec/models/file_spec.rb # targeted suite
bin/rubocop                              # lint
bin/brakeman --no-pager                  # application security scan
bin/bundler-audit                        # gem vulnerability scan
bin/importmap audit                      # JavaScript vulnerability scan
npm run verify:preline                   # prove vendor file matches npm lockfile
bin/rails zeitwerk:check                 # autoloading
bin/rails db:migrate:status              # migrations
bin/ci                                   # canonical local pipeline
```

## Environment variables and secrets

| Variable | Purpose | Required locally? |
|---|---|---|
| `APPLICATION_NAME` | Override visible product name | No |
| `APP_HOST` | Host in production email URLs | No |
| `MAILER_FROM` | Email sender | No |
| `FORCE_SSL` | Enable proxy SSL assumptions and HTTPS enforcement | No |
| `RAILS_MASTER_KEY` | Decrypt production credentials | No |
| `DATABASE_URL` | Override PostgreSQL connection | No |
| `RAILS_LOG_LEVEL` | Log verbosity | No |

Never store secret values in this file.

## External integrations

| Integration | Purpose | Local substitute |
|---|---|---|
| SMTP provider | Magic-link delivery | SMTP catcher on port 1025 |
| PostgreSQL | System of record | Local PostgreSQL |

## Compatibility constraints

- Modern browsers as enforced by `ApplicationController`.
- `.ruby-version`, `.tool-versions`, and Docker must remain aligned.

## Known setup problems

- Tests require a reachable PostgreSQL server.
- Network-backed audit database updates may fail in restricted environments.
