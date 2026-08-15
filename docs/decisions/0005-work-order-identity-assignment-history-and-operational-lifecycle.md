# ADR-0005: Work Order Identity, Assignment History, and Operational Lifecycle

- **Status:** accepted
- **Date:** 2026-08-15
- **Decision owners:** Técniqo engineering
- **Related issue/PR:** Phase 3 — Service Type → Work Order → Assignment

## Context

Phase 3 bridges tenant-owned Customer/Site/Asset context to future field Executions. Work
Orders need human identity, scheduling, and current responsibility without collapsing the
requested job into a field visit or overwriting assignment history.

## Decision

Service Types are mutable tenant-owned records seeded per Organization from useful electrical-
maintenance defaults. They have a case-insensitively unique name, optional description, and
explicit active state. Deactivation removes a Service Type from new Work Order choices while
preserving historical references. Service Types are never shared mutable platform records.

A Work Order directly owns Organization, Customer, Site, Service Type, creator, requested work,
priority, optional Asset, and optional scheduled start. Asset is a single optional MVP context,
not a claim that all future Work Orders involve exactly one Asset. Priorities are `normal`,
`high`, and `urgent`. Phase 3 adds no one-value status or cancellation workflow; an existing
Work Order is operationally open until later Execution requirements justify explicit lifecycle
actions.

Each Organization owns a locked monotonically increasing Work Order sequence. Creation formats
the identifier as `OS-YYYY-NNNNNN`; the year records issuance time while the sequence does not
reset annually. Identifier allocation and Work Order creation share a transaction, and URLs use
the identifier rather than the database primary key. PostgreSQL enforces tenant-local sequence
and identifier uniqueness.

Assignment is append-only responsibility history. It references an eligible active Technician
Membership and the assigning User, records `assigned_at`, and has an optional `ended_at`. A
partial unique index permits one current Assignment per Work Order. Reassignment locks the Work
Order, closes the current Assignment, and creates the replacement atomically. Assigning the same
current Technician again is idempotent. Founder authorization does not make Founder assignable;
eligibility still requires active Technician membership in the Work Order Organization.

The Work Order form server-renders all policy-scoped tenant options. A small Stimulus controller
filters Site options by Customer and Asset options by Site. Without JavaScript, all tenant options
remain selectable and the server/database constraints remain authoritative.

## Consequences

- Work Order identity is stable, human-readable, concurrency-safe, and tenant-local.
- Assignment history naturally supports reassignment without confusing responsibility with
  future Execution participation.
- Direct and composite foreign keys reject cross-tenant and invalid Customer/Site/Asset context.
- Schedule changes rely on Rails timestamps for Phase 3; a broader operational audit trail remains
  deferred until concrete history requirements extend beyond Assignment.

## Revisit conditions

Revisit the optional single Asset when active Work Order workflows require multiple Assets.
Add cancellation only with an explicit reason, actor, and timestamp. Add richer scheduling,
state, or audit records only when Phase 4 behavior demonstrates the need.
