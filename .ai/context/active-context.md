# Active Context

## Current objective

Maintain Base App 1 as a secure, reproducible source for independently copied Rails applications.

## Current branch

`main`

## Current state

The starter has a scanner-safe and rate-limited magic-link flow, atomic token
consumption, asynchronous delivery, database constraints, a tested sibling-app
creation command and one-time bootstrap, aligned Ruby tooling, PostgreSQL-backed
GitHub tests, and populated AI context.

## In progress

- Review and commit the starter-hardening changes.

## Next actions

1. Configure and exercise a real production SMTP provider in a derived application.
2. Add product-specific authorization and observability only when requirements exist.
3. Periodically run `bin/ci` and update the locked dependencies.

## Acceptance criteria for the current activity

- [x] `bin/new_app` copy/rename workflow rotates credentials and passes a smoke test.
- [x] Authentication resists link scanners, replay, concurrent consumption, and basic abuse.
- [x] Tests, lint, dependency audits, importmap audit, and Brakeman pass.
- [x] AI context describes the repository without placeholders.

## Important findings

- GitHub CI previously omitted RSpec.
- The prior mailer generated `/session?token=...`, not the routed magic-link URL.
- The old lockfile contained known vulnerabilities; patched versions are now locked.
- Preline 4.2.0 is locked through npm, vendored locally, and verified byte-for-byte in CI.

## Decisions made

- Derived applications are independent copies rather than downstream-synchronized templates.
- Magic-link GET requests validate and confirm; POST requests consume and authenticate.
- Rails' cache-backed rate limiter protects issuance by both IP and normalized email.
- `bin/new_app` copies into the parent folder; `bin/bootstrap` performs the destructive rename only in that fresh copy.

## Risks and blockers

- Production SMTP/storage/host values remain deployment-specific by design.
- Preline updates must commit `package.json`, `package-lock.json`, the importmap pin, and the vendor file together.

## Validation status

- Last command: `bin/ci`
- Result: passed (53 RSpec examples, lint, npm/importmap/gem audits, and Brakeman)
- Additional: bootstrap smoke test and `bin/rails zeitwerk:check` passed

## Handoff note

Review the working-tree diff, then commit it as the hardened starter baseline. No commit
has been created by the agent.
