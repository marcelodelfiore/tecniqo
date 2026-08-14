# Técniqo — Business & Product Analysis

## 1. Executive Summary

Técniqo is a SaaS platform for electrical maintenance service companies, initially focused on Brazil and designed to support future markets such as Paraguay.

The platform must implement the expected operational foundation—customers, sites, assets, work orders, assignments, field execution, evidence and related workflows—but these commodity capabilities are not the principal differentiation. Their strategic purpose is to give Técniqo ownership of the operational context and metadata surrounding maintenance work.

The long-term differentiation comes from structured engineering data, evidence traceability, engineering review, technical-document workflows, and eventually engineering intelligence assisted by AI.

> **Commodity operational functionality captures context. Structured engineering data and engineering intelligence create differentiated value.**

A second foundational principle is:

> **The internal domain may be sophisticated, but operating the product must remain simple, guided and fast to learn.**

Técniqo should minimize training, manual input and repeated data entry. The system should derive metadata from normal user actions whenever possible.

---

## 2. Problem Being Solved

Electrical maintenance contractors commonly coordinate work using combinations of spreadsheets, generic field-service applications, configurable forms, messaging tools, Word/Excel templates, manually assembled PDFs and ERP systems.

This fragmentation weakens the connection between:

1. the customer's request;
2. the work order;
3. what actually happened in the field;
4. measurements and findings;
5. technical evidence;
6. engineering review;
7. the report delivered to the customer;
8. eventual billing and cost analysis.

### Spreadsheet-derived systems

Many systems reproduce old spreadsheets as software: every column becomes a field and the operator must understand the company's complete business model.

Técniqo should explicitly avoid:

- giant forms;
- unnecessary required fields;
- duplicated input;
- workflows that require extensive training;
- forcing field technicians to understand administrative structures;
- making configuration a consulting project.

### Field reality

Technicians may be beside energized/industrial equipment, wearing PPE, holding tools, under time pressure, dealing with customer bureaucracy and poor connectivity.

Field UX should favor:

- tap;
- select;
- photograph;
- measure;
- speak.

Typing should be minimized.

### Engineering review

Field completion is not necessarily technical completion. Industrial maintenance documentation may require review by a supervisor or engineer before formal issuance.

Técniqo therefore distinguishes field execution from technical approval.

### Evidence and billing

Evidence should not be an unstructured photo gallery. Photos, thermograms, instrument displays and other artifacts should be associated with the findings, measurements or actions they support.

### Customer waiting and hidden cost

A technician may arrive at a site and wait hours for security procedures, shutdown authorization or equipment access. Recording only repair time hides a meaningful part of the work-order cost.

Técniqo should capture these operational events automatically.

---

## 3. Market Positioning

Existing products broadly fall into two groups.

### Generic Field Service Management

These products are often strong at:

- work-order creation;
- assignment;
- scheduling;
- GPS/routing;
- photos;
- signatures;
- basic reports.

These capabilities are market parity rather than Técniqo's primary differentiation.

### Form/Data Collection Platforms

These products often provide flexible forms and conditional fields, but flexibility can transfer configuration effort to the customer and may not create an integrated engineering workflow.

### Positioning

Técniqo follows a **minimum viable parity + standout differentiation** strategy.

Operational parity makes the platform self-sufficient. Differentiation focuses on industrial maintenance engineering:

- structured technical capture;
- evidence-backed work;
- field-to-engineering review;
- technical revisions;
- professional report generation;
- AI-assisted capture and documentation;
- long-term engineering intelligence.

---

## 4. Product Thesis

The Work Order is necessary, but the strategic asset is the structured dataset accumulated around maintenance execution.

Over time Técniqo can own structured information about:

- customers and sites;
- assets and technical characteristics;
- reported symptoms;
- service types;
- field visits;
- execution participants;
- findings;
- measurements;
- evidence;
- failure classifications;
- actions performed;
- materials;
- recommendations;
- technician observations;
- engineering corrections;
- approved conclusions;
- recurrence;
- effective work and waiting time.

This can later support operational analytics, asset history, failure analysis, anomaly detection, risk indicators, recommendations and predictive capabilities.

---

## 5. Core Product Principles

### Workflow over database
Screens represent work users perform, not tables that need values.

### Progressive complexity
Advanced concepts appear only when useful.

### Capture once, reuse everywhere
Known customer, site, asset, work-order and execution context should flow automatically.

### Defaults over configuration
Provide strong electrical-maintenance defaults. Customization is optional.

### Complexity follows responsibility
Technicians, supervisors, engineers and administrators see experiences appropriate to their responsibilities.

### Structured data beneath simple interactions
Simple UX must not imply a simplistic domain.

### AI reduces human input
Use transcription, OCR, extraction, suggestions and narrative generation to reduce effort.

### Every required field must justify itself
Potential future usefulness is not sufficient reason to burden today's operator.

### Fast onboarding is a feature
Training cost is part of product quality.

### The interface teaches the workflow
Users should normally understand the next action from the current screen.

### Users perform business actions
Prefer Start Work, Pause, Submit and Approve over generic status dropdowns.

### Users declare events; the system records them
Normal event timestamps and metadata are automatic.

### Facts and narrative are different
Structured engineering facts are authoritative; prose and documents are representations.

### No destructive approved-history changes
Corrections produce new revisions.

### Traceability
Technical statements should be traceable to supporting findings, measurements and evidence where practical.

---

## 6. Roles

### Founder
Platform-level privileged role with unrestricted access for development, support, diagnostics and early platform operation. Founder is not an ordinary organization role and should not become the basis for normal authorization logic.

### Administrator
Manages organization setup, users, customers, sites, assets, service types and basic configuration.

### Supervisor
Creates, assigns and schedules work; monitors execution; handles partial visits and schedules returns.

### Technician
Performs field execution, records operational events, findings, measurements, evidence, actions, materials and recommendations, submits work and responds to clarification.

### Engineer / Technical Reviewer
Reviews technical information, requests clarification, validates narrative, approves technical content and authorizes revisions.

Users may hold multiple organization roles.

---

## 7. Core Domain Vocabulary

### Organization
The maintenance company using Técniqo and the natural multi-tenancy boundary.

### Customer
The entity contracting maintenance work.

### Site
The physical customer location where work occurs.

### Asset
The physical object/system being maintained or inspected.

### Asset Type
Classification such as motor, electrical panel, transformer, generator, VFD, UPS or SPDA.

### Service Type
The technical type of work being performed. It may later define expected measurements, checklists, evidence, report templates and approval requirements.

### Work Order
The operational container describing requested work and its customer/site/asset/service context.

### Assignment
Records responsibility for work. Reassignment history should be preserved.

### Execution
One actual field visit or work period. A Work Order may contain multiple Executions. Return visits are MVP functionality.

### Execution Participant
A person participating in an Execution. Multiple participants must be supported.

### Execution Event
An operational event recorded from a simple user action.

MVP vocabulary:

- `arrived_at_site`
- `started_asset_work`
- `paused_asset_work`
- `resumed_asset_work`
- `finished_asset_work`
- `left_site`
- `submitted`

### Finding
A technical condition observed during an Execution.

### Measurement
A structured engineering observation containing type, value, unit and context.

### Evidence
Information supporting a technical fact; semantically richer than a generic attachment.

### Action Performed
What was actually done during an Execution.

### Material Used
Material/parts consumed during an Execution without requiring inventory management.

### Recommendation
Suggested future technical action.

### Execution Outcome
Initial vocabulary: completed, partial/return required, unable to execute.

### Engineering Review
Technical validation of submitted field information.

### Clarification Request
Structured request for additional technical information, kept inside Work Order history.

### Technical Revision
Versioned approved technical state.

### Report
Generated output derived from an approved Technical Revision, not the canonical engineering record.

---

## 8. Domain Map

```text
Organization
│
├── Users / Roles
├── Customers
│     └── Sites
│           └── Assets
├── Service Types
└── Work Orders
      ├── Assignments
      ├── Executions [1..N]
      │      ├── Participants [1..N]
      │      ├── Execution Events
      │      ├── Findings
      │      ├── Measurements
      │      ├── Evidence
      │      ├── Actions Performed
      │      ├── Materials Used
      │      └── Recommendations
      ├── Engineering Reviews
      │      └── Clarification Requests
      ├── Technical Revisions
      └── Reports
```

This is a business-domain map, not a requirement that every concept become an ActiveRecord model.

---

## 9. Work Order, Multiple Visits and Field Events

A Work Order represents the overall requested job. An Execution represents one actual field visit/work period.

```text
Work Order
   ├── Execution #1 — diagnosis / partial work
   ├── Execution #2 — return with material
   └── Execution #3 — final testing
```

Multiple return visits are explicitly MVP scope.

### Field event timeline

```text
Arrive at customer site
        ↓
Start work on asset
        ↓
Pause work ←→ Resume work
        ↓
Finish work on asset
        ↓
Leave customer site
        ↓
Submit execution
```

The user only presses buttons. Timestamps, identity and execution context are recorded automatically.

### Derived operational metadata

Técniqo can derive:

- site presence time;
- pre-work waiting time;
- effective work time;
- paused work time;
- post-work onsite time;
- interruptions;
- number of visits.

The technician never calculates these manually.

This metadata can later support true Work Order cost calculations.

---

## 10. Field UX

A technician's normal workflow should remain close to:

```text
Open assigned job

[ARRIVED AT SITE]
[START WORK]

Add:
  Photo
  Measurement
  Finding
  Work performed
  Voice description

[PAUSE WORK]
[RESUME WORK]
[FINISH WORK]

Select execution outcome

[LEAVE SITE]
[SUBMIT FOR REVIEW]
```

The internal domain can create multiple records from these actions without exposing that complexity.

---

## 11. Structured Measurements

Measurements should be first-class structured data rather than primarily free text.

Example:

```text
type: voltage
value: 381
unit: V
context: L1-L2
asset: Motor M-21
technician: João
timestamp: automatic
evidence: optional
```

The UI should infer units and expected measurement context whenever safely possible.

---

## 12. Evidence and Traceability

Evidence should be associated with the technical fact it supports.

```text
Finding: abnormal heating at terminal T2
    ↓
Evidence: thermogram.jpg
```

or:

```text
Measurement: 87.3 °C at terminal T2
    ↓
Evidence: thermogram.jpg
```

Before/after evidence is particularly valuable.

The long-term objective is evidence-backed engineering documentation where important statements can be traced to their source data.

---

## 13. Engineering Review and Clarification

Field completion and technical approval are separate.

The engineer reviews an assembled technical story containing Work Order context, all relevant visits, field timeline, findings, measurements, evidence, actions, materials, recommendations and AI-assisted narrative where applicable.

The engineer may approve, edit technical narrative, request clarification or return incomplete technical content.

Clarification should remain inside Técniqo rather than being lost in calls or messaging applications.

---

## 14. Technical Revisions and Reports

The canonical source is structured technical metadata, not the PDF.

```text
Approved Technical State
          ↓
Technical Revision N
          ↓
Report Template Version
          ↓
Rendered Report
```

Corrections create new revisions.

```text
Revision 1 → superseded
Revision 2 → current
```

The implementation should use compact versioning of technical metadata rather than blindly duplicating whole documents. The precise persistence mechanism can be decided later.

The business requirement is:

> Given a Technical Revision, Técniqo must be able to reconstruct the technical state approved for that revision.

Issued PDF artifacts may still be retained for audit/legal convenience.

---

## 15. AI Strategy

AI is broader than report generation.

### Capture
- audio transcription;
- OCR from nameplates/instruments;
- extraction of measurements and facts;
- photo-assisted capture.

### Assistance
- structured finding suggestions;
- missing-information detection;
- classification suggestions;
- evidence/measurement guidance.

### Output
- technical narrative;
- multi-visit summaries;
- report sections;
- engineering-review assistance.

The key concept is **input compression**: technicians communicate naturally and Técniqo converts that information into structured data with minimal confirmation.

Engineer corrections may form valuable labelled data:

```text
field input
→ AI draft
→ engineer revision
→ approved version
```

---

## 16. Long-Term Data Moat

Normal Técniqo operation should progressively build a structured maintenance knowledge base.

Future capabilities may include:

- asset history;
- recurring failures;
- measurement trends;
- return-visit analysis;
- customer waiting analysis;
- technician/service performance;
- effectiveness of corrective actions;
- failure/action relationships;
- risk indicators;
- anomaly detection;
- recommendations;
- predictive maintenance.

---

## 17. Internationalization

Técniqo should not embed Brazil-specific assumptions throughout the generic domain.

Brazil is the first jurisdiction/domain pack. Paraguay is a plausible future market.

Country-specific identifiers such as CNPJ/RUC and standards/templates should be modeled so they can vary by jurisdiction.

Avoid hard-coded domain columns such as `nr10_compliant`. Future concepts may include Jurisdiction, Standard, Requirement, Inspection Template and Report Template.

---

## 18. MVP Boundary

### Operational foundation
- organizations/users/roles;
- customers/sites/assets;
- asset types/service types;
- work orders;
- assignments;
- scheduling;
- multiple executions/return visits;
- execution participants;
- automatic execution events;
- findings;
- structured measurements;
- evidence;
- actions;
- simple materials;
- recommendations;
- execution outcomes;
- submission.

### Engineering differentiation
- engineering review queue;
- clarification;
- approval;
- technical revisions;
- report-generation foundation;
- evidence traceability.

### Deferred
- sophisticated route optimization;
- geofencing;
- ERP/accounting;
- inventory/purchasing;
- full CMMS/EAM hierarchy;
- arbitrary workflow designers;
- massive form builders;
- complex permission matrices;
- predictive maintenance before sufficient data exists;
- advanced AI before the structured domain foundation is reliable.

---

## 19. Scenario-Driven Product Design

Important workflows should be validated through realistic field simulations before implementation.

Scenarios serve as:

- product documentation;
- domain validation;
- UX validation;
- implementation reference;
- acceptance-test inspiration;
- demo material.

The first canonical scenario is `scenarios/001-corrective-maintenance-return-visit.md`.

---

## 20. Guiding Summary

Técniqo's intended transformation is:

```text
Simple field operation
        ↓
Rich structured metadata
        ↓
Traceable engineering information
        ↓
Engineering review
        ↓
Technical documentation
        ↓
Operational analytics
        ↓
Engineering intelligence
```

The strongest constraint is:

> **Sophistication belongs primarily inside Técniqo, not inside the user's head.**
