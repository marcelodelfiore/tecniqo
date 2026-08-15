# ADR 0008: Explicit technical field records and Evidence references

- Status: Accepted
- Date: 2026-08-15

## Context

Phase 4 records the operational visit timeline and Phase 4.5 stores immutable,
Execution-owned original Evidence. Phase 5 must capture engineering meaning without
turning the field UI into a generic form builder or changing Evidence ownership.

## Decision

`Finding`, `Measurement`, `ActionPerformed`, `MaterialUsed`, and `Recommendation` are
explicit Execution-owned records. Organization, Execution, authenticated Technician
Membership, and `recorded_at` are assigned by the server. Records may be corrected or
removed before Execution submission; submission locks records and their Evidence links.
The stronger existing rule that accepted Evidence itself is always immutable remains.

Finding severity is technical significance (`minor`, `significant`, `critical`) and is
independent of Work Order priority. Measurement uses a PostgreSQL `numeric(18,6)` value,
stable English quantity/unit keys, and an application constant mapping backed by a
database quantity/unit check constraint. The initial electrical vocabulary is voltage,
current, frequency, resistance, insulation resistance, continuity, and temperature.
The measurement point is concise required context rather than a generic parameter tree.

`EvidenceReference` is a small polymorphic reference from one technical record to an
existing Evidence record. Evidence remains owned by its Execution and its original blob
is never copied or changed. The reference repeats Organization and Execution context; a
composite foreign key requires the selected Evidence to belong to that same context, and
model validation requires the technical record to match it. One Evidence may support
multiple facts. Removing a reference unlinks it only and cannot delete Evidence.

The fixed reference-role vocabulary is `supporting`, `before`, and `after`. Phase 5 field
forms create `supporting` references; the before/after vocabulary is retained for the
near-term action workflow without adding configurable relationship types.

## Consequences

- The field UI exposes small domain actions and derives known context automatically.
- Static vocabularies are localizable and extensible in code/migrations without reference
  tables, configurable schemas, or a scientific conversion framework.
- PostgreSQL cannot foreign-key a polymorphic target. Rails validates the referenced
  technical record context, while the composite Evidence foreign key enforces the most
  security-sensitive cross-tenant/cross-Execution boundary in the database.
- `recorded_at` preserves domain occurrence semantics for future delayed/mobile capture;
  `created_at` continues to record persistence time. Phase 5 sets both server-side.
- Engineering approval, clarification, revision, reports, templates, AI, and inventory
  remain separate future workflows.

## Revisit conditions

Revisit when delayed/offline capture needs client occurrence times, before/after role
selection becomes a field requirement, measurement normalization/conversion is needed,
or engineering revisions need non-destructive corrections to submitted facts.
