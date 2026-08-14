# Installing This Workflow in a Project

## Copy the template

Copy `AGENTS.md`, `.ai/`, and `docs/decisions/` into the repository root.

Example:

```sh
cp -R /path/to/codex-project-workflow-template/AGENTS.md /path/to/project/
cp -R /path/to/codex-project-workflow-template/.ai /path/to/project/
mkdir -p /path/to/project/docs
cp -R /path/to/codex-project-workflow-template/docs/decisions /path/to/project/docs/
```

## Customize before use

At minimum complete:

1. `.ai/context/project-brief.md`
2. `.ai/context/technical-context.md`
3. `.ai/context/architecture.md`
4. `.ai/context/active-context.md`

Remove irrelevant Rails defaults from `AGENTS.md` for non-Rails repositories, or add
technology-specific instructions beneath them.

## Verify Codex discovery

Start from the Git repository or relevant subdirectory:

```sh
cd /path/to/project
codex
```

Then ask:

```text
List the instruction files you loaded, their scope, and the boot sequence you will
follow. Do not edit files.
```

## Optional hierarchy

For a monorepo or component with special rules, add a narrower file:

```text
apps/web/AGENTS.md
services/analytics/AGENTS.md
firmware/AGENTS.md
```

Use `AGENTS.override.md` only when that directory must replace, rather than merely
supplement, the normal instruction file at that level.

## Version control

Commit the durable workflow files. Decide whether session logs should be committed.
For a solo project, committed logs may be useful. For a team, keep only logs with
lasting engineering value.

## First project initialization prompt

```text
Read AGENTS.md. Inspect this repository without editing. Help me replace every
placeholder in `.ai/context/` using evidence from the code, configuration, tests, and
existing documentation. Mark uncertain conclusions explicitly. Do not invent product
rules.
```
