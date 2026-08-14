# Start-of-Workday Runbook

Use this checklist every time you resume a project after a meaningful break.

## 1. Enter the correct repository

```sh
cd /path/to/project
pwd
git rev-parse --show-toplevel
```

Confirm that the terminal is inside the expected repository before launching Codex.

## 2. Inspect repository state

```sh
git status --short --branch
git log -5 --oneline --decorate
```

Answer:

- Which branch am I on?
- Are there uncommitted changes?
- Do those changes belong to the current activity?
- Was the previous session committed, intentionally left uncommitted, or interrupted?

Do not update or switch branches until you understand local changes.

## 3. Update safely

When the working tree is clean and the team's workflow allows it:

```sh
git fetch --all --prune
git status --short --branch
```

Then use the project's approved pull/rebase procedure. Avoid blindly running commands
that could rewrite or merge work.

## 4. Restore the development environment

Use the commands in `.ai/context/technical-context.md`.

Typical Rails example:

```sh
bundle check || bundle install
bin/rails db:prepare
bin/dev
```

In another terminal, run a fast health check or targeted test.

## 5. Read project memory

Read in this order:

1. `AGENTS.md`
2. `.ai/context/project-brief.md`
3. `.ai/context/active-context.md`
4. `.ai/context/progress.md`
5. technical or architecture context needed for today's task
6. the latest relevant log or ADR

## 6. Define today's activity

Create a task brief from `.ai/templates/task-brief.md`.

The task must have:

- one outcome;
- explicit scope;
- acceptance criteria;
- constraints;
- likely validation commands;
- a stopping condition.

## 7. Start Codex from the repository root

```sh
codex
```

Useful first prompt:

```text
Read AGENTS.md and follow its boot sequence. Summarize the current project state,
current objective, relevant architecture boundaries, repository status, and the next
three concrete actions. Do not edit files yet. Identify any stale or contradictory
context.
```

## 8. Ask for inspection before implementation

```text
We are working on: [activity].

First perform a read-only inspection. Identify the relevant files, existing patterns,
tests, risks, and validation commands. Then propose the smallest complete plan. Do not
edit files yet.
```

## 9. Begin only when the task is bounded

Before allowing edits, verify:

- [ ] The expected behavior is clear.
- [ ] The non-goals are explicit.
- [ ] Relevant code and tests were inspected.
- [ ] The plan does not unnecessarily expand the scope.
- [ ] You know how the result will be validated.
