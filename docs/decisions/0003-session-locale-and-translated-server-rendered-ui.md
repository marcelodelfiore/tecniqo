# ADR-0003: Session Locale and Translated Server-Rendered UI

- **Status:** accepted
- **Date:** 2026-08-15
- **Decision owners:** Técniqo engineering
- **Related issue/PR:** Phase 1 — Internationalized product foundation

## Context

Técniqo currently serves English and Brazilian Portuguese users and expects Spanish soon.
Its Rails-rendered pages, flashes, validation-facing copy, navigation, and emails need one
consistent localization boundary before business-domain workflows multiply the string surface.

## Decision drivers

- Keep Rails HTML, Turbo, and mailers as the primary interface.
- Preserve a user's language across authentication session resets.
- Open emailed security links in the language in which they were sent.
- Reject arbitrary locale input and avoid locale-dependent authorization behavior.
- Make Spanish a first-class supported locale now rather than a later retrofit.

## Considered options

### Locale-prefixed URLs

- Advantages: explicit, shareable language in every route.
- Disadvantages: changes every stable route and future Hotwire Native interception path.

### User database preference

- Advantages: follows authenticated users across devices.
- Disadvantages: does not cover guests or invitation recipients and requires identity writes.

### Allowlisted session locale with email-link propagation

- Advantages: covers guests and authenticated users without route restructuring or schema changes.
- Disadvantages: preference is browser-specific rather than account-global.

## Decision

Support `en`, `pt-BR`, and `es` through Rails I18n. Store the allowlisted locale in the
session, preserve it when authentication resets the session, and include it in magic-link
and invitation URLs. The locale selector posts to a dedicated endpoint; emailed links may
also request one of the same allowlisted values. English is the default and fallback.

All reachable server-rendered UI, controller flashes, roles, navigation, and authentication/
invitation mail are translated. Future slices add their copy to all three dictionaries.

## Rationale

This keeps stable routes intact, works before authentication, and matches the existing
server-rendered architecture while providing a low-friction path to account-level preferences later.

## Consequences

### Positive

- Guests, invitation recipients, and members share one localization mechanism.
- Locale cannot change tenant visibility or authorization decisions.
- New languages require dictionaries and allowlist expansion, not route duplication.

### Negative

- Language preference does not yet follow a user to another browser.
- Translation completeness requires review with every UI slice.

### Risks and mitigations

- **Unsupported locale input** — accept only configured `available_locales`.
- **Locale leakage between requests/jobs** — use `I18n.with_locale` and explicit mailer params.
- **Missing translations** — fall back to English and cover representative pages/mailers in tests.

## Validation

Request specs cover locale persistence, invalid locale rejection, HTML language attributes,
and session resets. Mailer specs cover localized subjects/body copy and locale-bearing links.

## Revisit conditions

Reconsider this decision when cross-device preference persistence, locale-specific public
URLs, or organization-enforced language becomes a product requirement.
