# Code Review Runbook

## Preparation

```sh
git status --short
git diff --stat
git diff
```

Identify the task brief and acceptance criteria before reviewing.

## Review prompt

```text
Review this diff against the stated goal and repository instructions. Do not edit files.

Focus on:
- correctness and edge cases;
- security, authentication, and authorization;
- data consistency, transactions, and idempotency;
- backward compatibility;
- concurrency and failure handling;
- performance and N+1 risks;
- framework and repository conventions;
- test coverage and test quality;
- unnecessary complexity or scope expansion.

Report only actionable findings. Rank each as critical, high, medium, or low. Include
file and line references, reasoning, and a concrete correction. Then list open
questions and residual risks.
```

## Human review checklist

### Scope

- [ ] Diff matches the task.
- [ ] No unrelated cleanup.
- [ ] No accidental generated or secret files.

### Behavior

- [ ] Acceptance criteria are demonstrated.
- [ ] Error paths are handled.
- [ ] Boundary and empty states are considered.

### Security

- [ ] Authorization is server-side and complete.
- [ ] Input is validated.
- [ ] Secrets and sensitive data are not logged.
- [ ] Tenant/data boundaries are preserved.

### Data

- [ ] Migration is safe and reversible where practical.
- [ ] Constraints match application assumptions.
- [ ] Multiple writes have correct transaction behavior.
- [ ] Idempotency is addressed for retries/webhooks/jobs.

### Maintainability

- [ ] Existing patterns are followed.
- [ ] Names communicate intent.
- [ ] Abstraction is justified.
- [ ] Comments explain why, not obvious mechanics.

### Verification

- [ ] Relevant tests exist and pass.
- [ ] Linters/static/security checks pass.
- [ ] Manual verification is recorded when necessary.

## Review outcome

Record:

- accepted findings;
- rejected findings and why;
- corrections made;
- remaining risk;
- validation rerun after corrections.
