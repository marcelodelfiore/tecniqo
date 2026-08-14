# Git Workflow Runbook

Adapt this runbook to the repository's actual collaboration policy.

## Before starting

```sh
git status --short --branch
git log -5 --oneline --decorate
git fetch --all --prune
```

Never switch, pull, reset, clean, or rebase until local changes are understood.

## Create a focused branch

```sh
git switch -c type/short-description
```

Common types: `feature`, `fix`, `refactor`, `docs`, `test`, `chore`.

## During work

Use checkpoints:

```sh
git diff --stat
git diff
```

Codex must not commit unless explicitly requested.

## Before commit

```sh
git status --short
git diff --check
git diff
```

Then run project validation.

## Commit message structure

```text
type(scope): concise behavior-oriented summary

Optional explanation of why the change is needed and any important trade-off.
```

Prefer behavior-oriented commits over vague messages such as "updates" or "fix stuff."

## Before opening a PR

- [ ] Branch contains one coherent activity.
- [ ] Commits contain no secrets or temporary logs.
- [ ] Tests and checks are recorded.
- [ ] Migration/deployment implications are explained.
- [ ] Screenshots or request examples are included when useful.
- [ ] Context documents are updated only when they add durable value.

## Dangerous commands

Do not let an assistant run these without explicit understanding and approval:

```text
git reset --hard
git clean -fd
git checkout -- .
git restore .
git push --force
```
