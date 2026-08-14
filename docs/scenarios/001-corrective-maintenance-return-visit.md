# Técniqo Scenario 001 — Corrective Maintenance with Return Visit

## Purpose

Canonical end-to-end product scenario validating multiple visits, customer waiting, pause/resume, structured technical capture, engineering clarification, approval and non-destructive revision.

## Actors

- Supervisor — coordinates the Work Order.
- João — field technician.
- Maria — engineer / technical reviewer.
- Indústria ABC — customer.
- Betim Plant — site.
- Motor M-21 — asset.

---

## 1. Work Order Creation

The customer reports that Motor M-21 on packaging line 2 trips its protection after operating for a few minutes.

The supervisor creates:

```text
Customer: Indústria ABC
Site: Betim Plant
Asset: Motor M-21
Service Type: Corrective Electrical Maintenance
Requested Work: Motor protection trips after a few minutes of operation.
Priority: High
Technician: João
Scheduled: Aug 18, 08:00
```

Técniqo creates a human-readable identifier such as `OS-2026-001842` and records creation metadata automatically.

## 2. Technician Receives the Job

João sees the assigned Work Order directly in `My Work`. He does not search through administrative menus.

The job shows its context and:

```text
[ARRIVED AT SITE]
```

## 3. Arrival

João arrives at 07:58 and presses the button.

Técniqo records:

```text
event_type: arrived_at_site
timestamp: automatic
user: João
execution: Visit 1
```

No manual timestamp entry exists in the normal workflow.

## 4. Customer Waiting

Security procedures and production constraints prevent immediate access to the motor.

At 09:47 production releases the equipment. João presses:

```text
[START WORK]
```

Técniqo can now derive 1h49 of pre-work onsite waiting without a timesheet.

## 5. Asset Work

The execution workspace offers:

```text
[Voice description]
[Photo]
[Measurement]
[Finding]
[Work performed]

[PAUSE WORK]
```

## 6. Asset Identification

João photographs the motor nameplate.

Future OCR/AI may propose:

```text
Manufacturer: WEG
Rated power: 30 kW
Rated voltage: 380 V
Rated current: 58.7 A
Rated speed: 1770 rpm
```

João confirms rather than transcribing everything.

## 7. Measurements

João records:

```text
Voltage:
L1-L2: 381 V
L2-L3: 379 V
L3-L1: 380 V

Current:
L1: 61.8 A
L2: 62.1 A
L3: 61.6 A
```

These remain structured measurements.

## 8. Finding and Evidence

João observes oxidation and signs of heating around terminal T2.

He records a short voice description and photographs the condition.

AI may later propose a structured finding:

```text
Oxidation and evidence of abnormal heating at motor terminal T2,
including thermal effects on the adjacent conductor.
```

The photograph is linked as Evidence for that Finding.

## 9. Pause and Resume

At 10:31 production requests the equipment back.

João presses:

```text
[PAUSE WORK]
```

The pause is recorded immediately. He optionally selects `Customer request` as the reason.

At 11:16 he presses:

```text
[RESUME WORK]
```

## 10. Additional Diagnosis

João identifies excessive contact wear on the contactor.

He records a Finding and photographic Evidence.

He performs:

```text
Action:
Terminal T2 cleaned and connection retorqued.
```

He recommends:

```text
Replace contactor before returning equipment to continuous operation.
```

The required contactor is unavailable.

## 11. First Visit Completion

At 12:02 João presses:

```text
[FINISH WORK]
```

Outcome:

```text
Another visit required
Reason: Material required
Note: Contactor WEG CWM65 required.
```

At 12:17:

```text
[LEAVE SITE]
```

Técniqo has:

```text
Arrival:       07:58
Work start:    09:47
Pause:         10:31
Resume:        11:16
Work finish:   12:02
Departure:     12:17
```

Derived approximately:

```text
Site presence:      4h19
Pre-work waiting:   1h49
Paused time:        0h45
Effective work:     1h30
Post-work onsite:   0h15
```

## 12. Return Visit

The supervisor sees the return requirement and obtains the contactor.

Selecting:

```text
[SCHEDULE RETURN VISIT]
```

creates Execution / Visit 2 under the same Work Order.

It does not create a duplicate Work Order.

## 13. Second Visit

João records:

```text
13:04 ARRIVED AT SITE
13:22 START WORK
```

He replaces the contactor:

```text
Action:
Contactor CWM65 replaced.
```

He captures before/after evidence and final currents:

```text
L1: 56.4 A
L2: 56.1 A
L3: 56.3 A
```

Operational testing succeeds.

At 14:41 he finishes work with outcome `Completed`.

At 14:52 he leaves and then submits the execution.

## 14. Complete Work Order Story

```text
OS-2026-001842
│
├── Visit 1
│     ├── customer waiting
│     ├── diagnosis
│     ├── measurements
│     ├── findings
│     ├── evidence
│     ├── interruption
│     ├── partial corrective action
│     └── material requirement
│
└── Visit 2
      ├── replacement
      ├── before/after evidence
      ├── final measurements
      └── successful operational test
```

## 15. Engineering Review

Maria receives the Work Order in the Technical Review queue.

Técniqo assembles the chronological technical story across both visits, including events, findings, measurements, evidence, actions and recommendations.

AI may generate a technical narrative, but the structured facts remain authoritative.

## 16. Clarification

Maria notices there is no clear photograph of the removed contactor identification.

She requests:

> Do you have a photo showing the identification of the removed contactor?

João receives the Clarification Request inside Técniqo, attaches the photograph and responds.

The conversation becomes part of the technical history.

## 17. Approval

Maria approves the technical content.

Técniqo establishes:

```text
Technical Revision 1
approved_by: Maria
approved_at: automatic
```

## 18. Report Issuance

Técniqo renders the customer-facing report from:

```text
Technical Revision 1
+
Report Template Version
```

The report is an output artifact rather than the canonical source of technical truth.

## 19. Later Correction

Maria later notices a narrative reference to `CWM50` instead of `CWM65`.

Revision 1 is not modified.

Corrected metadata is approved as:

```text
Technical Revision 2
```

and the report is regenerated:

```text
Report Revision 1 → superseded
Report Revision 2 → current
```

Revision 1 remains reconstructible.

---

## What the Scenario Validates

- Multiple executions/return visits are fundamental.
- Customer waiting time is operationally and commercially meaningful.
- Pause/resume events matter.
- Simple button actions can produce rich metadata.
- Measurements/findings/evidence remain structured facts.
- Engineering review is separate from field completion.
- Clarification belongs inside the Work Order.
- Approved technical history is non-destructive.
- Executions must support multiple participants.
- Reports are generated from approved metadata.

## Acceptance Principle

The field technician should be able to complete this scenario without understanding Técniqo's internal domain model.

```text
Few natural field actions
        ↓
Structured operational + engineering metadata
        ↓
Engineering review
        ↓
Traceable technical documentation
```
