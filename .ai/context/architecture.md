# Architecture and Engineering Conventions

## System overview

This is a conventional Rails monolith. Controllers coordinate HTTP behavior, models
own authentication persistence rules, Active Job delivers mail asynchronously, and
server-rendered ERB plus Hotwire provides the UI. Avoid starter-specific abstraction
layers that derived applications would be forced to retain.

## Main components

| Component | Responsibility | Must not do |
|---|---|---|
| `SessionsController` | Authentication HTTP flow and session lifecycle | Store raw tokens |
| `LoginToken` | Issue, locate, revoke, and atomically consume tokens | Send mail or redirect |
| `User` | Identity and email normalization | Encode product authorization |
| `AuthMailer` | Render the sign-in link | Consume tokens |
| Shared layouts | Neutral authenticated/guest shell | Encode product domain navigation |
| `bin/bootstrap` | One-time rename and credential rotation | Run against an established app |
| `bin/new_app` | Copy the starter into a sibling application | Copy Git history or runtime data |

## Repository map

| Path | Purpose |
|---|---|
| `app/` | Rails application code |
| `config/` | Runtime, database, routes, and deployment configuration |
| `spec/` | Executable behavior and regression coverage |
| `.ai/context/` | Durable context loaded by engineering agents |
| `docs/decisions/` | Append-only architecture decisions |

## Data ownership and consistency

- PostgreSQL is the system of record.
- Token issuance locks the user while revoking and replacing active tokens.
- Token consumption locks the token row and checks expiry/use inside a transaction.
- Raw magic-link tokens exist only in the issuance call, job arguments, and email URL.
- Users own login tokens; deleting a user deletes those tokens.

## Security boundaries

- Authentication is passwordless and session-backed.
- Email links show a no-store confirmation page; a CSRF-protected POST consumes them.
- Issuance is throttled by IP and normalized email using the configured Rails cache.
- Authorization and tenant isolation are intentionally absent and must be added per product.
- Secrets belong in Rails credentials or environment variables, never source/context files.

## Error handling

- Invalid and expired credentials receive the same user-facing response.
- Do not reveal whether an email address already existed.
- Infrastructure failures should be reported, not converted into false success.

## Testing strategy

- Model specs protect persistence rules and token lifecycle.
- Request specs protect redirects, sessions, throttling, and scanner-safe confirmation.
- Mailer specs protect recipient and generated URL.
- Add system specs when a product introduces browser behavior not proven at lower levels.

## Architectural constraints

- Prefer Rails conventions and built-ins over new dependencies.
- Keep authentication changes backward-compatible unless explicitly approved.
- A derived application may diverge; this repository does not attempt downstream updates.

See `docs/decisions/` for accepted Architecture Decision Records.
