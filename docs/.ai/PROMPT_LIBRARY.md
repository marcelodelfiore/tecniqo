# Codex Prompt Library

These prompts complement `AGENTS.md`; they do not replace clear task requirements.

## Resume the project

```text
Read AGENTS.md and execute its boot sequence. Summarize the product, architecture,
current objective, current repository state, and next three actions. Flag stale or
contradictory context. Do not edit files.
```

## Explore an unfamiliar area

```text
Read-only task. Trace how [behavior] works from entry point to persistence/output.
Identify relevant files, important abstractions, tests, authorization boundaries,
failure paths, and existing conventions. Do not edit.
```

## Prepare an implementation plan

```text
Goal: [goal]

Acceptance criteria:
- [criterion]

Constraints:
- [constraint]

Inspect the code first. Return the smallest complete implementation plan, files likely
to change, tests, risks, migration/deployment concerns, and validation commands. Do not
edit yet.
```

## Implement a bounded change

```text
Implement the approved plan only. Preserve [interface/invariant]. Follow the pattern in
[path]. Do not refactor unrelated code and do not commit. Add or update tests. Run the
targeted validation, inspect the diff, and report deviations from the plan.
```

## Analyze a failure

```text
Analyze this failure without editing:

[error and reproduction]

Trace the execution path, rank root-cause hypotheses by evidence, and propose the
smallest diagnostic checks. Distinguish facts from assumptions.
```

## Review a diff

```text
Review the current diff as a skeptical senior engineer. Do not edit. Find actionable
correctness, security, authorization, data consistency, concurrency, compatibility,
performance, scope, and test issues. Rank by severity and cite files and lines.
```

## Add tests

```text
Inspect existing tests and propose a minimal behavior-focused test matrix for [change].
Include happy path, important boundaries, invalid input, authorization, and regression
coverage. Follow current project conventions. Do not edit yet.
```

## Update project memory

```text
Review the work completed in this session. Update active-context.md with current state,
next actions, decisions, blockers, and validation. Update progress.md only with durable
progress or lessons. Remove stale information and avoid duplicating stable docs.
```

## End-of-session handoff

```text
Produce a handoff containing the goal, completed work, changed files, validation and
results, decisions, unresolved risks, and the single best next action. Verify it
against git status and the actual diff.
```
