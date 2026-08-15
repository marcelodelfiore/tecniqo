# Project Brief

## Project

- **Name:** Técniqo
- **Description:** Industrial Maintenance Engineering Platform for maintenance service companies.
- **Current stage:** MVP foundation
- **Repository role:** Rails monolith and primary web application

## Why it exists

Técniqo connects field maintenance work to structured engineering facts, traceable
evidence, technical review, revisions, and customer-facing reports. Expected field
service functionality captures the context required by that technical process; it is
not the product's strategic endpoint.

## Primary outcomes

1. Make field capture fast while retaining rich operational and engineering context.
2. Preserve evidence-backed technical history across visits, reviews, and revisions.
3. Build a reliable dataset for engineering intelligence and future AI assistance.

## Non-goals for the current phase

- Generating the complete maintenance domain or generic CRUD screens.
- Native iOS/Android shells, advanced offline/PWA behavior, or AI integration.
- ERP, accounting, inventory, route optimization, or arbitrary workflow builders.

## Current development focus

Phase 2 — Customer → Site → Asset operational-context vertical slice.

## Success criteria

- Existing passwordless authentication remains intact.
- Customer, Site, and Asset have explicit, testable tenant and role boundaries.
- New UI remains responsive, Turbo-compatible, and ready to serve future thin
  Hotwire Native shells.

## Important constraints

- Organization is the tenant boundary; cross-organization access must be difficult by default.
- Founder is a platform-level exception, not an organization role.
- Implement realistic vertical slices; do not map every domain noun directly to a model.
- Multiple executions per Work Order and multiple participants per execution are MVP requirements.
