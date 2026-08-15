# ADR-0004: Operational Context Tenancy, Asset Types, and Lifecycle

- **Status:** accepted
- **Date:** 2026-08-15
- **Decision owners:** Técniqo engineering
- **Related issue/PR:** Phase 2 — Customer → Site → Asset

## Context

Customer, Site, and Asset establish the tenant-owned operational context that future Work
Orders and technical records will reference. The slice needs strong tenant integrity, a
useful Asset Type default, and lifecycle behavior that will not destroy future history.

## Decision

Customer, Site, and Asset each carry a direct, non-null `organization_id`. Site also belongs
to Customer, and Asset belongs to Site. Composite foreign keys `(parent_id, organization_id)`
ensure those nested relationships cannot cross tenant boundaries even when Rails validations
are bypassed.

Asset Type is a required string with a curated application vocabulary: motor, electrical
panel, transformer, generator, VFD, UPS, SPDA, capacitor bank, and other. New Assets default
to `other`, the database constrains the value, and the UI translates display labels. It is
not an enum integer, editable taxonomy, or separate model.

Phase 2 exposes create, read, and update actions but no delete or archive action. Associations
use restrictive deletion behavior. This avoids irreversible destruction and avoids inventing
archive cascade/restoration semantics before Work Orders and technical history exist.

Customer names are case-insensitively unique within an Organization, and Site names are
case-insensitively unique within a Customer. Asset names and tags remain unconstrained because
industrial naming practices are inconsistent and duplicate tags can occur in real datasets.

## Consequences

- Tenant policy scopes remain simple and direct, at the cost of redundant ownership columns.
- Database constraints reject a Site or Asset whose direct tenant differs from its parent.
- Adding a curated Asset Type requires an application and database migration, which is an
  intentional tradeoff for strong defaults without configuration overhead.
- Lifecycle semantics must be revisited before historical records need to be retired; hard
  deletion is not part of the current product interface.

## Revisit conditions

Reconsider Asset Type storage when organizations demonstrably need custom classifications.
Define archive behavior when Work Orders introduce historical references, including ancestor
visibility and restoration semantics, before adding archive actions.
