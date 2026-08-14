# Testing Runbook

## Testing objective

Tests should demonstrate observable behavior and protect important invariants, not
mirror the implementation line by line.

## Before writing a test

Determine:

- behavior being protected;
- system boundary;
- failure mode;
- suitable test level;
- existing test conventions;
- required fixtures/factories/data setup.

## Choose the narrowest useful level

- **Unit/model/component:** local rules, transformations, edge cases.
- **Request/integration:** API, authorization, persistence, component interaction.
- **Job/mail/service integration:** asynchronous or external boundary behavior.
- **System/end-to-end:** critical user workflow that cannot be proven more cheaply.

## AI prompt

```text
Inspect existing tests for this behavior and identify the project's conventions. Propose
a minimal test matrix covering the happy path, important boundary cases, authorization,
invalid input, and regression risk. Do not edit yet.
```

## Test quality checklist

- [ ] Name describes behavior.
- [ ] Setup contains only relevant data.
- [ ] Assertion verifies externally meaningful outcome.
- [ ] Test fails for the intended reason before the fix when practical.
- [ ] Time, randomness, and external services are controlled.
- [ ] Tenant/user boundaries are represented where relevant.
- [ ] The test is deterministic.
- [ ] No real secret or production endpoint is used.
- [ ] The test does not depend on execution order.

## Rails-specific checks

Consider:

- model validation and database constraint both needed?
- request authorization exercised?
- job enqueue and job behavior tested at the right levels?
- mail delivery content and recipient verified?
- Turbo/HTML/JSON response behavior covered?
- N+1 or query-volume risk for list endpoints?
- timezone and date-boundary behavior?
- transaction or idempotency behavior?

## Validation sequence

```sh
# single test
bin/rails test path/to/test.rb:LINE

# relevant directory or subsystem
bin/rails test test/models/some_area

# full suite
bin/rails test
```

Replace these with the canonical project commands in `technical-context.md`.
