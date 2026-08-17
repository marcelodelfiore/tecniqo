# ADR 0009: Work Order engineering review, clarification, and approval boundary

- Status: Accepted
- Date: 2026-08-17

## Context

Field submission and technical approval are different responsibilities. A Work Order may
span several visits, and its engineering conclusion can depend on the chronology and facts
across all of them. Phase 6 must introduce review and clarification without mutating submitted
technician records, building generic comments, or prematurely implementing technical revisions
and reports.

## Decision

One `EngineeringReview` belongs to a Work Order. It explicitly references every submitted
Execution in its review scope through `EngineeringReviewExecution`. The review is created once
the complete current visit story is ready: at least one Execution exists, every Execution is
submitted, and the latest outcome does not require a return visit. Submission creates it
idempotently; a migration backfills existing eligible Work Orders.

The lifecycle is `pending`, `in_review`, `changes_requested`, and `approved`. An eligible Engineer
claims a pending review with the explicit Start Review action and becomes its single responsible
reviewer. Founder may explicitly claim a review as the platform exception. Administrator and
Supervisor visibility does not grant technical actions; multi-role users act as Engineers only
when their active Membership carries that responsibility.

`ClarificationRequest` is an explicit technical requirement, not a comment. It belongs to the
review and one included Execution, targets the Work Order, Execution, technical fact, or Evidence,
and names one eligible participating Technician. The default recipient is the fact recorder or
Evidence uploader when available. Its compact lifecycle is `requested`, `responded`, and
`resolved`: one Technician response and explicit reviewer resolution. Further questions use a
new clarification rather than an unbounded thread.

Clarification responses may reference existing same-Execution Evidence or append new immutable
Evidence through a dedicated authorized response route. This is the only post-submission Evidence
append path. It does not reopen submitted events, facts, participants, or Evidence originals.

Approval is an explicit action that records `approved_by` and `approved_at`. It requires the
responsible reviewer, an unchanged complete submitted Execution scope, and no unresolved
clarifications. Reviewed Executions and their structured facts are already submission-locked;
Phase 6 additionally prevents editing the approved Work Order context. Approval does not issue a
report or create a technical revision.

## Consequences

- Multi-visit technical review remains one coherent Work Order story.
- Questions, responses, Evidence, actors, and timestamps remain tenant-bound technical history.
- Reviewer response queues can derive actionable state without a generic notification platform.
- Existing submitted facts retain technician provenance and cannot be silently corrected.
- Phase 7 can snapshot the approved source set into reproducible Technical Revisions without
  redefining the human review boundary.

Phase 6 does not support reassignment of an active review, reopening an approval, multiple response
rounds inside one clarification, or a new visit after approval. These require explicit lifecycle
design rather than generic status editing. Master-data values such as Customer and Asset names are
not snapshotted; Phase 7 must capture reproducible approved metadata before report issuance.

## Future AI seam

The preserved sequence—structured technician record, future assisted draft, Engineer questions
and decisions, and approved technical state—can later provide high-quality labeled feedback.
Phase 6 introduces no model inference, training pipeline, or generated narrative.
