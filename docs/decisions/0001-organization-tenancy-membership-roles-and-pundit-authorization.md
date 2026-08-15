# ADR-0001: Organization Tenancy, Membership Roles, and Pundit Authorization

- **Status:** accepted
- **Date:** 2026-08-14
- **Decision owners:** Técniqo engineering
- **Related issue/PR:** Phase 1 — Identity, Tenancy, Roles & Authorization Foundation

## Context

Técniqo needs organization-isolated data and contextual permissions before introducing
maintenance-domain records. A global identity may work for more than one maintenance
company and may have several responsibilities in each. Founder needs exceptional
platform access without becoming the model for ordinary authorization. The existing
passwordless authentication system identifies a User but intentionally provides no
tenant or authorization layer.

Future decisions depend on resource ownership, assignment, execution participation,
technical state, and organization responsibility. Static role checks alone cannot
answer them.

## Decision drivers

- Make accidental cross-organization access not possible.
- Support one User in multiple Organizations and multiple roles per Membership.
- Keep Founder exceptional and auditable.
- Separate responsibilities (roles) from contextual decisions (policies).
- Preserve the existing authentication system and Rails architecture.
- Prefer explicit, testable code and database integrity over a tenancy framework or
  configurable permission system.
- Remain compatible with responsive Rails/Hotwire workflows and future thin Hotwire
  Native shells.

## Considered options

### Identity and role representation

1. **Single role enum on User** — simple, but cannot represent multiple roles or
   organization-specific responsibility. Rejected.
2. **Editable Role and Permission records** — flexible, but introduces speculative
   permission administration, joins, and naming lifecycle. Rejected for MVP.
3. **Membership plus fixed role assignments** — supports multiple organizations and
   multiple roles while keeping the approved vocabulary explicit. Selected.

### Authorization library

1. **Pundit 2.5.2** — plain Ruby resource policies, explicit `authorize`, policy scopes,
   verification hooks, Rails denial handling, direct `Current.user` support, and RSpec
   policy helpers. Selected.
2. **CanCanCan 3.6.1** — mature and capable, with `accessible_by` and automatic resource
   loading. Its centralized ability rules and loading DSL make contextual tenant and
   workflow boundaries less local and explicit for Técniqo. Rejected.
3. **Application-specific helpers only** — avoids a dependency, but would recreate
   policy lookup, scoping, controller integration, and verification inconsistently.
   Rejected.

### Tenant enforcement

1. **A multi-tenancy gem or implicit global default scope** — concise but hides query
   behavior and can create dangerous bypasses/background-job surprises. Rejected now.
2. **Explicit ownership, policy scopes, and action policies** — visible, testable, and
   Rails-native. Selected.

## Decision

### Identity and membership

- `User` remains a global authenticated identity and may have zero or more Memberships.
- A Membership belongs to one User and one Organization and represents tenant access.
- A Membership has one or more roles from the fixed MVP vocabulary:
  `administrator`, `supervisor`, `technician`, and `engineer`.
- Role values are application constants backed by role-assignment rows and a database
  check constraint. They are not editable Role records and are never a single User enum.
- Organization is the natural tenant boundary.

The intended conceptual relationship is:

```text
User
  ├── Founder platform privilege (exceptional)
  └── Membership [0..N]
        ├── Organization
        └── Roles [1..N]
```

This ADR does not claim those tables have been implemented.

### Founder

- Founder is a platform-level boolean/capability on User, separate from Membership.
- Normal policies first express member behavior. A small centralized policy helper may
  grant the explicit Founder bypass.
- Policy scopes return all otherwise eligible records for Founder; normal scopes always
  begin with organization ownership.
- Founder branches and non-Founder isolation are mandatory policy/scope tests. Business
  services must not contain scattered `founder?` conditions.

A boolean is intentionally sufficient while Founder is a single, non-configurable
platform capability. Replace it only if real platform capabilities diversify.

### Current organization and tenant scoping

- Introduce `Current.organization` when tenant records are implemented.
- Establish it from server-controlled route/session context and validate active
  Membership for the authenticated User on every request. Founder still selects an
  organization for normal tenant workflows; platform-wide support views must be explicit.
- Auto-select the only active Membership. If several exist and none is selected, require
  a choice rather than choosing silently. Organization-switching UI is deferred.
- Tenant-owned tables normally carry a non-null `organization_id`. Denormalized direct
  ownership is preferred where it makes isolation obvious and allows database constraints.
- Collection and ID loading use `policy_scope`. Mutating and member actions additionally
  use `authorize`; UI visibility is never the security boundary.

### Pundit integration and policy design

- Add Pundit in the implementation slice and map `pundit_user` to `Current.user`.
- Authenticated product controllers verify `authorize` or `policy_scope`; public and
  authentication actions use explicit skips where appropriate.
- Default `ApplicationPolicy` and its Scope deny access and reject missing users.
- `ApplicationPolicy` contains only universal primitives: Founder, selected
  organization, same-organization, and current-membership helpers.
- Resource policies own role, assignment, participation, ownership, and workflow-state
  rules. Extract a small shared module only after duplication is demonstrated.
- HTML denials use the established flash presentation and a safe redirect; non-navigation
  contexts return/raise a forbidden response as appropriate.
- Policy specs test actions; ordinary RSpec examples test scopes. Every tenant policy
  covers same-tenant permission, non-member denial, cross-tenant denial, inactive
  membership, multiple roles where relevant, and Founder behavior.

### Database integrity

The implementation must provide:

- unique `(organization_id, user_id)` Memberships;
- unique `(membership_id, role)` assignments;
- foreign keys and non-null tenant/membership/role fields;
- a check constraint for the fixed role vocabulary;
- a deliberate active/inactive membership lifecycle;
- transactional, locked protection against removing or demoting the last active
  Administrator.

The last-Administrator invariant belongs in the MVP because otherwise an Organization
can become unmanageable. Start with an application transaction and row locks; revisit a
database trigger only if multi-writer or concurrency evidence makes it necessary.

### Deferred decisions

- Invitation and provisioning UX, including whether unknown emails may auto-register.
- Exact URL/session design and UI for organization switching.
- Role-change audit history beyond timestamps and membership lifecycle.
- Database row-level security, required only if application-level isolation becomes
  insufficient for the threat model or additional data consumers.
- Fine-grained/custom permissions, only after fixed roles prove inadequate.
- Native-shell authenticated-session persistence and native bridge components.

## Consequences

### Positive

- Tenant ownership and authorization remain visible in normal Rails code.
- One identity naturally supports multiple companies and combined responsibilities.
- Contextual rules can evolve with Work Orders, Executions, participants, review, and
  revisions without turning roles into a permission DSL.
- Founder access remains deliberate rather than contaminating organization behavior.

### Negative

- Controllers must consistently use both policy scopes and action authorization.
- Direct organization ownership adds columns and integrity work to tenant-owned tables.
- A fixed role vocabulary requires a migration when an actual new responsibility is added.

### Risks and mitigations

- **Unscoped ID lookup leaks records** — load tenant resources through policy scopes and
  enforce controller verification/request specs.
- **Founder bypass becomes scattered** — expose one policy primitive and test every scope.
- **Selected tenant becomes stale or forged** — resolve server-side and validate active
  Membership each request.
- **Last Administrator race** — lock and re-check inside one transaction.
- **Role helpers turn `ApplicationPolicy` into a god object** — keep resource-specific
  decisions in resource policies and extract only demonstrated common behavior.

## Validation

The implementation is accepted when focused model, policy, scope, and request specs prove:

- multiple Organizations and roles per User;
- uniqueness and database constraints;
- denial for guests, inactive/non-members, and cross-tenant IDs;
- correct same-tenant role/context actions;
- explicit Founder behavior;
- last-Administrator protection, including concurrent attempts;
- controller authorization/scope verification and safe denial presentation;
- preservation of the existing authentication specs.

## Revisit conditions

Reconsider this decision when:

- customers require custom roles or delegated permissions;
- external data consumers bypass the Rails policy boundary;
- Founder splits into several platform capabilities;
- native shells or APIs require a richer authorization subject/context;
- measured query complexity or scale justifies another tenant-isolation mechanism.

## Research references

- [Pundit README](https://github.com/varvet/pundit) — policies, scopes, controller
  verification, denial handling, `Current.user` integration, and RSpec conventions.
- [Pundit 2.5.2 on RubyGems](https://rubygems.org/gems/pundit) — current released version
  at the decision date.
- [CanCanCan README](https://github.com/CanCanCommunity/cancancan) — abilities,
  `accessible_by`, and automatic controller resource loading.
- [CanCanCan 3.6.1 on RubyGems](https://rubygems.org/gems/cancancan) — current released
  version at the decision date.
