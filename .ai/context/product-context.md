# Product Context

The detailed source of product truth is [`docs/business-analysis.md`](../../docs/business-analysis.md).
The canonical workflow is
[`docs/scenarios/001-corrective-maintenance-return-visit.md`](../../docs/scenarios/001-corrective-maintenance-return-visit.md).

## Users and responsibilities

| Group | Primary responsibility | Expected experience |
|---|---|---|
| Founder | Platform support, diagnostics, and early operation | Exceptional cross-platform access |
| Administrator | Organization configuration and master data | Configuration and organizational views |
| Supervisor | Work creation, assignment, scheduling, and monitoring | Operational overview and work coordination |
| Technician | Assigned field execution and technical capture | Mobile-first `My Work` and current-job actions |
| Engineer / Technical Reviewer | Clarification, validation, approval, and revision | Technical review queue and approved work |

A person may hold multiple organization responsibilities. Founder is not one of them.

## Core workflow

The canonical corrective-maintenance scenario spans Work Order creation, assignment,
one or more field executions, event-based time capture, structured findings and
measurements, evidence, a return visit, engineering clarification, approval, a
technical revision, and report issuance.

## Core domain language

| Term | Meaning |
|---|---|
| User | A global authenticated identity |
| Organization | A maintenance company and tenant boundary |
| Membership | A user's relationship to one Organization |
| Role | An organization responsibility attached to a Membership |
| Founder | A platform-level privilege outside organization roles |
| Work Order | Overall requested job, potentially spanning multiple visits |
| Execution | One actual field visit or work period |
| Policy | Contextual answer to whether an actor may perform an action on a resource |

## Product and UX principles

- Workflow over database; users perform business actions rather than edit states.
- Progressive complexity and defaults over mandatory configuration.
- Capture context once and derive metadata from normal actions.
- Structured facts remain authoritative beneath a simple interface.
- Complexity follows responsibility; navigation may differ by role.
- Field-facing workflows use mobile usability as the stricter acceptance criterion.
- New UI is responsive, accessible, touch-friendly, and compatible with Turbo.
- Product UI and email support English, Brazilian Portuguese, and Spanish through Rails I18n.
- Rails HTML + Turbo + Stimulus remains the primary UI; do not introduce a parallel SPA.
- Técniqo will be the web core of future thin Hotwire Native iOS/Android shells with
  native navigation and selected bridge integrations.

## Product boundaries

The MVP owns operational context, field execution, structured engineering facts,
evidence traceability, review, revisions, and report foundations. Advanced AI,
offline operation, native shells, inventory, accounting, ERP, and routing are deferred.

## Accepted onboarding decisions

- Ordinary account provisioning is invitation-only; unknown emails do not auto-register.
- A sole available Organization is selected automatically; multiple options require an
  explicit choice, and Founder still selects a tenant for normal workflows.

## Open product questions

- Which future field capabilities need native bridge components or offline support?
