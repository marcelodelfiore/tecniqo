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
is implemented. Current-organization selection, foundational policies/scopes, verification,
and denial handling are implemented. Resource-specific policies/scopes must accompany each
future tenant-owned vertical slice.

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

`Current.organization` is resolved from a server-controlled session selection and the
signed-in user's active membership is validated on every request through the Organization
policy scope. A submitted organization ID establishes context only after scoped lookup and
authorization. One available organization is selected automatically; an ambiguous choice
requires the organization-selection route. Founder may select any organization but still
selects a tenant for normal workflows. A broader organization-switching UI remains deferred.

## Invitation-only provisioning

Ordinary Users enter the system through an Organization invitation; unknown sign-in emails
do not create identities. Invitations carry a normalized email, fixed role values, expiry,
revocation/acceptance state, and only a digest of the emailed token. Acceptance creates or
reuses the global User and establishes Membership plus roles atomically. Invitation issuance
is policy-scoped to the selected Organization and allowed only to its active Administrators;
Founder may issue invitations only after explicitly selecting the tenant. Resend rotates the
token by revoking the prior invitation, while revoke preserves the invitation audit record.
Founder provisioning itself stays outside this organization workflow. See ADR 0002.

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
- Localize server-rendered UI and mail through Rails I18n dictionaries for `en`, `pt-BR`,
  and `es`. Locale is allowlisted, session-persisted, and independent of authorization.

## Membership administration

Membership management is policy-scoped to the selected Organization and limited to active
Administrators plus Founder within an explicitly selected tenant. Lifecycle and fixed-role
changes run through `Membership#update_access!`. The transaction locks the Organization row
before the Membership, serializing all Administrator demotions/deactivations and refusing a
change that would leave no active Administrator.

## Operational context

```text
Organization
  └── Customer
        └── Site
              └── Asset
```

Customer, Site, and Asset each carry direct non-null Organization ownership. Composite
foreign keys pair each nested parent ID with `organization_id`, so Site-to-Customer and
Asset-to-Site relationships cannot cross tenants at the database boundary. Controllers load
every parent and resource through policy scopes and validate the actual nested association.

Customer names are unique per Organization and Site names per Customer, both case-insensitively.
Asset names and tags are deliberately not unique. Asset Type is a curated string vocabulary
with `other` as the default and a PostgreSQL check constraint; it is not organization-configurable.
Phase 2 has no destroy/archive route, and restrictive associations preserve future historical
references until lifecycle semantics can be designed with Work Orders. ADR 0004 records these
decisions.

Founder, Administrator, and Supervisor may manage operational context. Engineer has read-only
access. Technician receives no organization-wide Customer/Site/Asset scope until Work Order
assignment supplies the contextual visibility boundary.

## Operational work management

```text
Organization
  ├── Service Type
  └── Work Order
        ├── Customer → Site → optional Asset
        └── Assignment history → Technician Membership
```

Service Types are tenant configuration with explicit activation/deactivation. Work Orders are the
requested body of work and remain distinct from future Executions. They use a concurrency-safe,
Organization-local `OS-YYYY-NNNNNN` identifier, a compact fixed priority vocabulary, and one
optional scheduled start. The optional single Asset is an MVP input simplification, not a permanent
cardinality decision.

Assignments are first-class historical records. One partial unique index permits a single current
Assignment; reassignment locks the Work Order, ends the current record, and creates another in one
transaction. Eligibility derives from an active same-Organization Membership carrying Technician
responsibility. Assignment never represents future Execution participation.

Administrator and Supervisor manage Work Orders and assignments; Engineer reads them; Technician
scope is limited to currently assigned Work Orders. Founder retains the management bypass but is
not an assignment candidate without normal Technician membership. Phase 3 has no Work Order status,
cancellation, deletion, Execution, or generic audit framework. ADR 0005 records these boundaries.

## Field execution

```text
Work Order
  └── Execution [1..N]
        ├── Execution Participant [1..N] → Technician Membership
        └── Execution Event [0..N] → actor Membership
```

Work Order is the requested overall job; Execution is one numbered field visit. Assignment records
current responsibility, while Execution Participant records who actually joined a visit. A new
Execution uses the current assigned Technician as a convenience seed, but the records never become
equivalent. Visit numbering and event transitions lock the appropriate parent row for concurrency.

Execution state is derived from immutable, append-oriented operational events rather than an
editable status. Named POST actions record server-derived actor and `occurred_at`; `created_at`
remains persistence time for future delayed/offline evolution. Pause/resume is repeatable, duration
metrics are calculated from event history, and submission locks the Phase 4 operational record.
Unable-to-execute records an outcome without inventing asset work. Return-required submissions may
create another independently scheduled Execution beneath the same Work Order.

Only active Memberships carrying Technician responsibility are participant candidates and field
actors. Administrator and Supervisor manage visits/participants, Engineer reads, and Founder has
administrative visibility without implicit field eligibility. Technician scope is current Work
Order assignment or recorded visit participation; action permission requires participation.

The execution view is phone-first with one prominent valid business action, while the Work Order
view provides supervisor-oriented visit summaries. Conventional server-authorized routes preserve
Turbo and future Hotwire Native compatibility. See ADR 0006.

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
