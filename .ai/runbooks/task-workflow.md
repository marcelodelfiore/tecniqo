# Focused Task Workflow

## Phase 1 — Frame

Write the task in the format:

```text
Goal:
Current behavior:
Desired behavior:
Scope:
Non-goals:
Constraints:
Acceptance criteria:
Validation:
```

Do not start with "implement feature X" when the behavior and boundaries are still
unclear.

## Phase 2 — Inspect

Ask Codex to work read-only first:

```text
Read AGENTS.md and relevant context. Inspect the implementation and tests related to
this task. Explain the current behavior, identify the likely change points and existing
patterns, and list risks. Do not edit files.
```

Inspect at least:

- entry points;
- domain/data model;
- authorization and validation boundaries;
- existing tests;
- adjacent implementations;
- schema/migrations when data changes;
- logs or error output when debugging.

## Phase 3 — Plan

For a non-trivial task, require a concise plan containing:

1. files likely to change;
2. behavior changed in each file;
3. tests to add or modify;
4. migration/deployment concerns;
5. rollback or compatibility concerns.

Reject a plan that introduces unrelated refactors.

## Phase 4 — Implement

Use this prompt pattern:

```text
Implement the smallest complete version of the approved plan.

Constraints:
- preserve [specific behavior/interface];
- use the existing [pattern/reference path];
- do not change [out-of-scope area];
- add or update tests for the behavior;
- do not commit.

After editing, run [targeted commands], inspect the diff, and report any deviation from
the plan.
```

## Phase 5 — Validate

Run the narrowest relevant checks first. When a check fails:

1. preserve the output;
2. determine whether it is caused by the change;
3. fix the cause, not the assertion symptom;
4. rerun the failed check;
5. expand validation after targeted checks pass.

## Phase 6 — Review the diff

```sh
git status --short
git diff --stat
git diff
```

Ask Codex:

```text
Review the current diff as a skeptical senior engineer. Look for correctness defects,
missing edge cases, security or authorization mistakes, data consistency problems,
unnecessary complexity, regressions, and missing tests. Do not edit yet. Rank findings
by severity and cite files and lines.
```

Then address confirmed findings with a bounded follow-up.

## Phase 7 — Consolidate

Update:

- `.ai/context/active-context.md`;
- `.ai/context/progress.md`;
- an ADR when an important durable decision was made;
- a session or experiment log when the path taken teaches something reusable.

## Definition of done

A task is done only when:

- [ ] Acceptance criteria are satisfied.
- [ ] Relevant tests pass.
- [ ] Lint/static/security checks appropriate to the change pass.
- [ ] The diff contains no unrelated edits.
- [ ] New behavior is documented where needed.
- [ ] Important decisions and remaining risks are recorded.
- [ ] The next action is explicit.
