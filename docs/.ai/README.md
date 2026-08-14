# AI-Assisted Development Workspace

This directory contains durable project context and human runbooks used while working
with Codex or another coding assistant.

The root `AGENTS.md` is the automatically discovered instruction entry point. It tells
Codex which files to read and how to behave. The files in this directory are divided
into:

- `context/`: durable knowledge about the product and codebase;
- `runbooks/`: procedures for recurring development activities;
- `templates/`: reusable task, decision, and session records;
- `logs/`: active and archived work-session notes.

## Maintenance rule

Keep stable knowledge in the context files and temporary work state in
`active-context.md` or session logs. Do not copy the same information into several
files.

Update context only when something meaningful changes. A stale context file is worse
than a short one.

## Recommended repository layout

```text
AGENTS.md
.ai/
├── README.md
├── context/
│   ├── project-brief.md
│   ├── product-context.md
│   ├── technical-context.md
│   ├── architecture.md
│   ├── active-context.md
│   └── progress.md
├── runbooks/
│   ├── start-workday.md
│   ├── task-workflow.md
│   ├── debugging.md
│   ├── testing.md
│   ├── code-review.md
│   ├── git-workflow.md
│   └── end-workday.md
├── templates/
│   ├── task-brief.md
│   ├── session-log.md
│   ├── experiment-log.md
│   └── adr.md
└── logs/
    └── README.md
docs/
└── decisions/
```

## What belongs outside `.ai/`

Normal product and engineering documentation should remain in `README.md`, `docs/`,
API documentation, diagrams, or other established locations. `.ai/` is not a parallel
documentation universe; it is a compact navigation and operational layer.
