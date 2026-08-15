# ADR-0006: Execution Events, Derived State, and Visit Scheduling

- **Status:** accepted
- **Date:** 2026-08-15
- **Decision owners:** Técniqo engineering
- **Related issue/PR:** Phase 4 — Field Execution, Participants & Execution Events

## Context

Phase 4 introduces actual field visits beneath a Work Order. It must preserve multiple visits,
actual participants, automatic operational timestamps, pause/resume cycles, unable-to-execute
reality, return scheduling, mobile retries, and future delayed/offline capture without creating
independent status and duration sources of truth.

## Decision

An `Execution` is one numbered visit under a Work Order. Visit numbers are allocated while the
Work Order row is locked and are unique within that Work Order. The existing Work Order schedule
remains its original coordination date for backward compatibility; each Execution owns its visit
schedule, Visit 1 defaults from the Work Order, and later visits are scheduled independently.

`ExecutionParticipant` records active same-Organization Memberships carrying Technician
responsibility. The current Assignment seeds a new visit's first participant, but Assignment and
participation remain independent records. Founder privilege never creates operational eligibility.

Explicit server endpoints append fixed-vocabulary `ExecutionEvent` records. Actor Membership,
Execution, Organization, and time are server-derived. `occurred_at` records business occurrence;
`created_at` records persistence. Events order by `occurred_at` with ID as a stable tie-breaker and
are immutable through normal application behavior.

Execution state is derived from its ordered event history. There is no editable status column.
Transitions run while the Execution row is locked, which rejects double taps and concurrent
duplicates. Pause/resume may repeat. An unable-to-execute outcome after arrival permits departure
without fabricating asset-work events. Outcome, reason, recording actor, and recording time live on
the Execution; normal finishing records outcome and `finished_asset_work` atomically. Submission is
terminal for Phase 4.

Site presence, pre-work waiting, effective work, paused time, and post-work onsite time are derived
from events rather than persisted. A return visit may be created under the same Work Order only
after a submitted `return_required` visit.

## Consequences

- Operational chronology remains auditable and supports future delayed persistence without
  implementing offline synchronization now.
- State and durations cannot drift from an independently editable status or timesheet.
- Work Order schedule and Visit 1 schedule temporarily overlap by design; new multi-visit behavior
  uses Execution scheduling, and a later product decision may retire Work Order scheduling.
- Corrections to submitted operational history require a future explicit audit mechanism rather
  than CRUD editing.

## Revisit conditions

Revisit this decision when offline synchronization is implemented, operational corrections need a
formal workflow, organizations need non-Technician field participants, or dispatch requirements
need scheduling beyond one timestamp per visit.
