# Product Context

## Users and stakeholders

| Group | Need | Important behavior |
|---|---|---|
| Application developer | Start a new Rails product quickly | Copies, bootstraps, verifies, then changes the domain |
| Derived-app user | Secure and understandable sign-in | Receives and confirms a short-lived email link |

## Core workflows

### Create a derived application

1. Run `bin/new_app` with the new technical and display names.
2. Let it create a sibling copy and invoke `bin/bootstrap` there.
3. Run setup and validation.
4. Replace starter screens and context with product-specific behavior.

### Sign in

1. Submit an email address.
2. Receive a single-use link without account-existence disclosure.
3. Open a confirmation page and explicitly continue.
4. Enter the authenticated dashboard.

## Domain language

| Term | Meaning |
|---|---|
| Starter | This source repository before copying |
| Derived application | An independent product created from a copy |
| Bootstrap | One-time rename and credential-rotation operation |
| New-app command | Outer command that copies the starter and invokes bootstrap |
| Magic link | A short-lived bearer credential delivered by email |

## Business rules

- Submitting an unknown email creates a user by default.
- A new magic link revokes previous active links for that user.
- Links expire after 15 minutes and are consumed once.
- Derived applications are independent; fixes do not propagate automatically.

## Product boundaries

The starter owns initial authentication, application shell, setup, and quality gates.
It does not define authorization, tenancy, billing, domain behavior, or a production
vendor configuration.

## UX principles

- Give the same issuance response whether an account existed or was created.
- Require explicit confirmation before consuming emailed credentials.
- Keep starter UI neutral and easy to replace.

## Open product questions

- Each derived application must decide whether automatic registration is acceptable.
- Each derived application must choose production mail, storage, and observability providers.
