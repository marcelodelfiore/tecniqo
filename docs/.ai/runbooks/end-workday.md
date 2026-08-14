# End-of-Workday Runbook

The goal is to leave the repository safe and make tomorrow's restart inexpensive.

## 1. Stop implementation and inspect the state

```sh
git status --short --branch
git diff --stat
git diff
```

Confirm every changed file is intentional.

## 2. Run appropriate validation

Run the targeted tests first and the broader checks justified by the change. Record the
exact commands and results.

## 3. Ask for a final review

```text
Review the current uncommitted diff against the task acceptance criteria and AGENTS.md.
Do not edit. Identify correctness, security, data consistency, regression, scope, and
test problems. Cite exact files and lines.
```

Resolve confirmed high-impact findings and rerun validation.

## 4. Decide the Git stopping point

Choose explicitly:

- commit completed work;
- leave a clearly described work-in-progress state;
- revert an unsuccessful experiment carefully;
- create a patch/checkpoint according to team policy.

Never leave mystery modifications.

## 5. Update active memory

Update `.ai/context/active-context.md` with:

- current state;
- exact next action;
- unfinished files;
- decisions;
- blockers;
- last validation command and result.

Update `.ai/context/progress.md` for a meaningful completed unit.

## 6. Record durable decisions

Create an ADR when the session changed an architectural boundary, data ownership,
integration contract, significant dependency, or difficult trade-off.

## 7. Create a session log when useful

Copy `.ai/templates/session-log.md` to:

```text
.ai/logs/YYYY-MM-DD-short-topic.md
```

Do this for complex debugging, experiments, risky work, or interrupted activities.

## 8. Final handoff prompt

```text
Summarize this work session for the next developer. Include the goal, completed work,
changed files, validation and results, decisions, unresolved issues, and the single
best next action. Then verify that active-context.md accurately contains this handoff.
```

## 9. Stop local services

Stop servers, workers, tunnels, or containers that should not remain running.

## Done checklist

- [ ] Working tree state is understood.
- [ ] Validation result is recorded.
- [ ] Active context is current.
- [ ] Next action is explicit.
- [ ] No secret or temporary artifact was added.
