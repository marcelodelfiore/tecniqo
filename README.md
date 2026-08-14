# Técniqo — Personal Rails Starter

An opinionated, production-oriented Rails baseline for applications that share the
same starting architecture. It is designed to be copied, renamed, and then allowed
to evolve independently—not consumed as a framework or kept synchronized upstream.

## Included defaults

- Rails 8.1 and Ruby 3.4.8
- PostgreSQL
- passwordless email authentication with single-use, 15-minute magic links
- scanner-safe confirmation before a link is consumed
- IP and normalized-email request throttling
- Solid Queue, Solid Cache, and Solid Cable
- Tailwind CSS, Turbo, Stimulus, Importmaps, and Preline
- reusable authenticated and guest layouts
- RSpec, RuboCop, Brakeman, Bundler Audit, and Importmap Audit
- Docker, Kamal, GitHub Actions, and AI-agent project context

Passwordless authentication and the chosen frontend/deployment stack are deliberate
personal defaults, not universal Rails requirements. Replace them when a product's
requirements differ.

## Prerequisites

- Ruby 3.4.8
- PostgreSQL
- a local SMTP catcher listening on `127.0.0.1:1025` (Mailpit is recommended)
- Node.js 24 only for updating or verifying vendored Preline; it is not needed at runtime

## Create an application from this starter

Enter this repository and run:

```sh
bin/new_app my_product "My Product"
cd ../my-product
bin/setup
bin/dev
```

`bin/new_app` creates a sibling directory under this repository's parent, copies the
starter without Git history or runtime data, and invokes `bin/bootstrap` in the copy.
Bootstrap updates the Rails module, database names, Docker/Kamal identifiers, PWA
metadata, and visible starter name. It also generates fresh Rails credentials.
The generated copy no longer contains the template marker, so its bootstrap command
cannot be run a second time accidentally.

The first argument becomes the folder and technical identifier. It accepts snake case,
kebab case, or CamelCase. The optional second argument controls the display name.

The application name shown by layouts can later be overridden with
`APPLICATION_NAME` without renaming code.

## Authentication behavior

1. A visitor submits an email address.
2. The normalized email is found or registered.
3. Previous active links are revoked and a new token digest is stored.
4. The email is enqueued through Active Job.
5. Opening the link displays a non-cacheable confirmation page.
6. A CSRF-protected POST atomically consumes the token and creates the session.

Issuance is limited to 10 requests per IP in three minutes and three requests per
normalized email in 15 minutes. Production rate limiting uses Solid Cache.

## Configuration

| Variable | Purpose | Production |
|---|---|---|
| `APPLICATION_NAME` | Visible product name | Optional after bootstrap |
| `APP_HOST` | Host used in emailed links | Required |
| `MAILER_FROM` | Sender mailbox | Required |
| `FORCE_SSL` | Trust SSL termination and enforce HTTPS when `true` | Required |
| `RAILS_MASTER_KEY` | Decrypt Rails credentials | Required |
| `DATABASE_URL` | Primary PostgreSQL connection | Deployment-dependent |
| `RAILS_LOG_LEVEL` | Rails log verbosity | Optional |

Configure the production mail delivery provider in
`config/environments/production.rb` before deployment.

## Validation

```sh
bundle exec rspec
bin/rubocop
bin/brakeman --no-pager
bin/bundler-audit
bin/importmap audit
bin/rails zeitwerk:check
```

`bin/ci` runs the canonical local checks. GitHub Actions runs tests against PostgreSQL
and performs lint and security scans.

### Updating Preline

Preline is served locally through Importmap, but its exact npm version and integrity
metadata are committed in `package.json` and `package-lock.json`.

```sh
npm install --save-exact preline@VERSION
npm run vendor:preline
npm run verify:preline
npm audit --audit-level=high
bin/importmap audit
```

Commit the package files, `config/importmap.rb`, and `vendor/javascript/preline.js`
together. Dependabot monitors the npm version, and CI rejects a vendored file that
does not exactly match the locked package.

## Before building product features

1. Confirm no `Tecniqo`/`tecniqo` identifiers remain after creation.
2. Replace the home page and dashboard with product entry points.
3. Customize navigation, branding, icons, and email copy.
4. Configure SMTP, `APP_HOST`, SSL termination, host authorization, and storage.
5. Review whether automatic user registration fits the product.
6. Decide whether authorization, multitenancy, uploads, payments, or an API are needed.
7. Complete the product-specific files in `.ai/context/` as requirements emerge.

## Intentionally excluded

- authorization framework
- multitenancy
- payments
- product notifications
- API conventions
- product-specific observability provider

Add these only after the derived application's requirements establish their shape.
