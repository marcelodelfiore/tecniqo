# Project Instructions for Codex

## Purpose

Act as a careful engineering partner for this repository. Optimize for correctness,
maintainability, small reviewable changes, and preserving the project's existing
architecture.

## Boot sequence

Before meaningful work:

1. Read `.ai/context/project-brief.md`.
2. Read `.ai/context/product-context.md`.
3. Read `.ai/context/technical-context.md`.
4. Read `.ai/context/architecture.md`.
5. Read `.ai/context/active-context.md`.
6. Read `.ai/context/progress.md`.
7. Inspect the repository and relevant code before proposing edits.
8. Check `git status` and never overwrite unrelated user changes.

Do not assume a context file is accurate when the code contradicts it. Report the
difference and treat the repository as the operational source of truth.

## Working rules

- Understand before editing.
- Prefer the smallest complete change that satisfies the task.
- Follow existing naming, layering, module boundaries, and framework conventions.
- Do not introduce a new abstraction, dependency, service, or architectural pattern
  unless the task clearly requires it.
- Do not silently broaden the scope.
- Do not modify unrelated files merely to "clean them up."
- Preserve backward compatibility unless a breaking change is explicitly approved.
- Never print, store, expose, or commit secrets.
- Never weaken authentication, authorization, validation, logging, or tests simply to
  make a check pass.
- Do not run destructive commands without explicit approval.
- For database changes, inspect existing migrations and data assumptions first.
- When uncertain, state the uncertainty and gather evidence from code, tests, logs, or
  official documentation.

## Default task loop

1. Restate the goal, constraints, and acceptance criteria.
2. Inspect relevant files, tests, history, and current behavior.
3. Present a brief implementation plan before broad or risky edits.
4. Make one focused change.
5. Run the narrowest relevant validation.
6. Review the resulting diff.
7. Run broader checks when justified.
8. Summarize what changed, why, validation performed, and remaining risks.
9. Update `.ai/context/active-context.md` and `.ai/context/progress.md` after
   meaningful work.

## Planning and approval boundaries

Ask before:

- destructive data operations;
- irreversible migrations;
- deleting or renaming public interfaces;
- adding a production dependency;
- changing authentication, authorization, billing, or security-sensitive behavior;
- changing deployment or infrastructure behavior;
- rewriting a broad area outside the requested scope.

A plan is required before multi-file architectural changes. Small, obvious,
well-contained fixes may proceed after inspection.

## Validation

Use the commands recorded in `.ai/context/technical-context.md`.

Validation should normally progress from narrow to broad:

1. affected unit or component test;
2. affected integration/system test;
3. formatter/linter/static analysis;
4. full suite when appropriate.

Never claim a command passed unless it was actually run successfully. If a command
cannot be run, explain why and provide the exact command the developer should run.

## Rails defaults

When this is a Rails repository:

- prefer Rails conventions over custom architecture;
- keep controllers thin and domain behavior close to the appropriate model or
  application object already used by the project;
- avoid callbacks for non-local, surprising workflows;
- prevent N+1 queries and unnecessary object loading;
- use transactions where multiple writes must succeed atomically;
- validate authorization at the server boundary;
- add or update tests for behavior changes;
- inspect schema, migrations, routes, jobs, mailers, policies, and service objects
  relevant to the task before editing.

Project-specific conventions in `.ai/context/architecture.md` override these defaults.

## Git and generated files

- Inspect `git status` before and after work.
- Do not discard existing modifications.
- Do not commit unless explicitly requested.
- Do not edit generated files when a source file or generator should be changed instead.
- Keep diffs focused and explain any unexpectedly changed file.

## Completion format

At completion, report:

1. **Result**
2. **Files changed**
3. **Validation**
4. **Important decisions**
5. **Risks or follow-up**
6. **Suggested next concrete step**

## Repository-specific overrides

Add narrower `AGENTS.md` or `AGENTS.override.md` files inside subdirectories when a
component needs different instructions. Keep this root file stable and concise.
