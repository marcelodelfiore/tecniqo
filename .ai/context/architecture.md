# Architecture and Engineering Conventions

## System overview

Técniqo is a conventional Rails monolith. PostgreSQL is the system of record;
controllers coordinate HTTP actions; models protect local persistence invariants;
Pundit policies will own contextual authorization; and ERB + Turbo + small Stimulus
controllers provide the primary responsive UI.

Detailed product intent belongs in `docs/business-analysis.md`, and accepted tenancy
and authorization decisions are in
`docs/decisions/0001-organization-tenancy-membership-roles-and-pundit-authorization.md`.

## Identity, tenancy, and authorization

```text
User (global authenticated identity)
  ├── platform privilege: Founder (exceptional)
  └── Membership [0..N]
        ├── Organization (tenant)
        └── organization roles [1..N]
              administrator | supervisor | technician | engineer

Authentication → tenant context → membership/roles → resource policy → policy scope
```

The Organization, Membership, fixed membership-role, and Founder persistence foundation
is implemented. Current-organization selection and resource-specific policies/scopes are
not yet implemented.

- One User may belong to multiple Organizations.
- A Membership represents one User's relationship with one Organization.
- Roles describe responsibilities; policies decide actions in resource context.
- Founder is one explicit platform capability on User, outside memberships and normal RBAC.
- Every tenant-owned record carries a direct `organization_id` unless a documented
  exception makes a safely derived owner preferable.
- Policy scopes start from organization ownership and narrow further for assignments,
  participation, workflow state, or responsibility.
- Member access requires both an active membership and an allowed contextual action.
- Founder policies/scopes may bypass membership, but the bypass is centralized and tested.
- Do not use unscoped `Model.find(params[:id])` for tenant-owned controller records;
  load through `policy_scope(Model)` and still call `authorize` for the action.

## Current organization context

An explicit `Current.organization` is necessary when tenant records are introduced.
Resolve it from a server-controlled stable route/session selection and validate the
signed-in user's active membership on every request. Do not trust a submitted
organization ID, and do not silently fall back when a multi-organization choice is
ambiguous. A single-membership user may be selected automatically. Organization
switching UI is deferred, but routes and policy APIs must not assume a user has only one.

## Role representation and data integrity

For MVP, use a fixed role vocabulary in application code and a membership-role join
whose role value is constrained by PostgreSQL. Do not create editable Role records or a
permission-builder UI. Intended constraints for the implementation slice are:

- unique Membership per `(organization_id, user_id)`;
- unique role assignment per `(membership_id, role)`;
- foreign keys and non-null columns for ownership and role assignments;
- database check constraint limiting role values to the fixed vocabulary;
- explicit active/inactive membership lifecycle rather than deleting audit-relevant access.

Preventing removal of an organization's last active administrator is an MVP service
invariant. Enforce it in the membership-management transaction with row locking and
test concurrent removal; reassess a database trigger only if application enforcement
proves insufficient.

## Main components

| Component | Responsibility | Must not do |
|---|---|---|
| Authentication (`SessionsController`, `LoginToken`) | Establish global identity | Encode tenant roles or domain permissions |
| Current request context | Hold authenticated User and selected Organization | Trust an unvalidated tenant parameter |
| Membership and membership roles | Represent tenant access and responsibilities | Decide contextual resource actions |
| Pundit policies | Decide actions for a user/resource/context | Become a generic permission matrix |
| Pundit policy scopes | Enforce tenant visibility and contextual collection access | Return cross-tenant rows accidentally |
| Domain models | Own persistence and domain invariants | Depend on controllers/views |
| Rails/Hotwire UI | Render role-oriented workflows responsively | Become a JavaScript SPA or sole security boundary |

## Policy conventions

- Default policies and scopes deny access.
- Keep only small universal helpers in `ApplicationPolicy`, such as authenticated user,
  Founder, same-organization, and current-membership checks.
- Put resource-specific role, assignment, participant, and state rules in each policy.
- Controllers use `authorize record`; index/load paths use `policy_scope`.
- Views may call `policy(record)` to present allowed actions, but hidden UI never replaces
  server authorization.
- Policy specs cover permitted roles, multiple roles, non-members, wrong-organization
  records, inactive memberships, Founder, and relevant workflow state.

## UI and Hotwire Native direction

- Build mobile-first responsive HTML with accessible, touch-sized task actions.
- Evaluate major workflows in desktop/management and mobile/field contexts; mobile is
  stricter for technician work.
- Prefer stable RESTful routes, Turbo navigation, and small explicit actions that may map
  to future bridge components such as photo, voice, scan, or location.
- Avoid critical browser-only APIs, JavaScript-only route state, hover-only behavior,
  fixed wide tables, and modal-heavy workflows.
- Retain PWA scaffolding; advanced PWA/offline behavior and native shells are deferred.

## Development and testing strategy

- Implement vertical business slices against realistic scenarios, not table-by-table CRUD.
- Do not blindly translate domain vocabulary into ActiveRecord models.
- Prefer explicit Rails code and database integrity over speculative abstractions or gems.
- Use model specs for invariants, policy specs for decisions/scopes, request specs for
  authentication/authorization boundaries, and system specs only for browser behavior.
- Preserve custom authentication and its existing regression coverage.

## Repository map

| Path | Purpose |
|---|---|
| `app/` | Rails application code |
| `spec/` | RSpec behavior and regression coverage |
| `.ai/context/` | Compact durable context for engineering agents |
| `docs/` | Product analysis, scenarios, setup, and architecture decisions |
| `docs/decisions/` | Canonical append-only ADR location |

## Documentation discrepancy

`docs/docs/decisions/` duplicates `docs/decisions/` and was introduced with the copied
business-documentation bundle. It appears to be a template copy artifact. Keep it
unchanged until cleanup is separately approved; all new ADRs belong in canonical
`docs/decisions/`. Likewise, `docs/.ai/` is a copied placeholder workflow, while the
operational context remains root `.ai/` as required by `AGENTS.md`.
