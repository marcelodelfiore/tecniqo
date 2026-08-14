# Project Progress

## Current milestone

- **Name:** Starter hardening
- **Status:** Complete, pending review/commit
- **Target outcome:** A secure and reproducible baseline for copied Rails applications

## Completed

### 2026-08-10 — Harden reusable starter

- Added one-time application rename and credentials-rotation bootstrap.
- Added `bin/new_app` to create and bootstrap a sibling application from one argument.
- Added PostgreSQL-backed RSpec to GitHub and canonical local CI.
- Aligned Ruby 3.4.8 and repaired RuboCop configuration.
- Hardened magic-link confirmation, atomic consumption, throttling, and persistence constraints.
- Queued authentication email delivery and corrected its route URL.
- Removed pending generated specs and added meaningful request/mailer coverage.
- Populated reusable AI context and rewrote setup/operational documentation.
- Updated dependencies to resolve all reported advisories.
- Locked Preline 4.2.0 with npm integrity metadata and added byte-for-byte vendor verification.
- Validation: `bin/ci` passed; 53 examples, 0 failures; no lint or security findings.

## In progress

- Human review and commit of the hardened baseline.

## Planned

- Validate deployment-specific SMTP, object storage, SSL, and observability in each derived app.

## Known defects and technical debt

| Item | Impact | Priority | Evidence | Intended action |
|---|---|---|---|---|
| No production mail provider default | Magic links require deployment configuration | P1 | `config/environments/production.rb` | Configure per derived application |

## Lessons worth retaining

- A starter's CI must test every guarantee because defects propagate into every copy.
- Email scanners make state-changing magic-link GET requests unsafe.
- Runtime version files are a single contract and must remain aligned.
- Run dependency audits before declaring a baseline ready for reuse.
