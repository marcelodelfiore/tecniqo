# AI Workflow Installation

This repository already contains the canonical AI workflow under `.ai/` and the root
`AGENTS.md`. New applications created from this starter inherit it automatically.

After running `bin/bootstrap`, update these files as product knowledge becomes known:

1. `.ai/context/project-brief.md`
2. `.ai/context/product-context.md`
3. `.ai/context/technical-context.md`
4. `.ai/context/architecture.md`
5. `.ai/context/active-context.md`
6. `.ai/context/progress.md`

Keep the reusable engineering conventions, but replace starter-specific product and
operational details. Do not leave bracketed placeholders: use `Unknown` and record an
open question when the answer has not been decided.

To verify instruction discovery, start Codex at the repository root and ask:

```text
List the instruction files you loaded, their scope, and the boot sequence you will
follow. Do not edit files.
```

Narrower components may add their own `AGENTS.md`. Use `AGENTS.override.md` only when
that directory must replace, rather than supplement, the root instructions.
