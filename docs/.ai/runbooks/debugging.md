# Debugging Runbook

## Principle

Debug from evidence, not from repeated speculative edits.

## 1. Capture the failure

Record:

- exact command or user action;
- complete error message and stack trace;
- environment;
- expected behavior;
- actual behavior;
- whether it is reproducible;
- last known working state.

## 2. Reproduce narrowly

Create the smallest reliable reproduction. Prefer:

- one failing test;
- one request;
- one job invocation;
- one command;
- one minimal dataset.

Do not change code until the failure is understood well enough to state a hypothesis.

## 3. Build an evidence table

| Hypothesis | Supporting evidence | Contradicting evidence | Test |
|---|---|---|---|
| [Hypothesis] | [Evidence] | [Evidence] | [Command/inspection] |

## 4. Ask Codex for analysis only

```text
Read AGENTS.md and relevant context. Analyze this failure without editing files.

Failure:
[paste exact output]

Reproduction:
[steps]

Return:
1. the execution path;
2. ranked hypotheses;
3. evidence for each;
4. the smallest diagnostic checks;
5. likely files involved.
Do not propose a broad rewrite.
```

## 5. Test one hypothesis at a time

Prefer temporary observability, a focused test, or a read-only query over changing
production behavior.

Do not:

- rescue broad exceptions merely to hide the failure;
- remove validations;
- weaken tests;
- add arbitrary delays;
- retry indefinitely;
- mutate production data without a recovery plan.

## 6. Fix the root cause

The fix prompt should identify:

- confirmed cause;
- intended invariant;
- smallest change;
- regression test;
- compatibility constraints.

## 7. Validate

At minimum:

- regression test fails before the fix when practical;
- regression test passes after the fix;
- adjacent behavior remains valid;
- logs no longer show the failure;
- the diff does not contain diagnostic debris.

## 8. Record the lesson

Use `.ai/templates/experiment-log.md` for a difficult investigation and add a concise
lesson to `.ai/context/progress.md`.
