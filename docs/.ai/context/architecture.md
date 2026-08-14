# Architecture and Engineering Conventions

## System overview

[Describe the system in a few paragraphs. Link to canonical diagrams or detailed
architecture documents rather than duplicating them.]

## Main components

| Component | Responsibility | Must not do |
|---|---|---|
| [Component] | [Responsibility] | [Boundary] |

## Dependency direction

```text
[Higher-level component]
        |
        v
[Lower-level component]
```

State the permitted direction clearly:

- [Layer A] may depend on [Layer B].
- [Layer B] must not depend on [Layer A].

## Repository map

| Path | Purpose |
|---|---|
| `[path]` | [Purpose] |

## Established patterns

### [Pattern name]

Use when:

- [Condition]

Do not use when:

- [Condition]

Reference implementation:

- `[path/to/example]`

## Data ownership and consistency

- **System of record:** [component/table/external system]
- **Transaction boundaries:** [description]
- **Idempotency requirements:** [description]
- **Deletion/retention policy:** [description]

## Security boundaries

- Authentication: [approach]
- Authorization: [approach]
- Tenant isolation: [approach]
- Sensitive data: [rules]

## Error-handling conventions

- [Convention]
- [Convention]

## Testing strategy

- Unit: [scope]
- Integration: [scope]
- System/end-to-end: [scope]
- External services: [mock/contract/sandbox policy]

## Naming and style

- [Project-specific naming rule]
- [Project-specific organization rule]

## Architectural constraints

- [Do not introduce X]
- [Keep Y backward compatible]

## Canonical decisions

See `docs/decisions/` for accepted Architecture Decision Records.
