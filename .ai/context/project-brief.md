# Project Brief

## Project

- **Name:** Base App 1
- **Description:** An opinionated Rails starter copied to create the author's applications.
- **Current stage:** Hardening
- **Repository role:** Starter monolith

## Why it exists

Repeated applications need the same secure authentication, UI shell, development
workflow, and production foundations. This repository makes those decisions once so
work on a derived application can begin with its domain rather than infrastructure.

## Primary outcomes

1. A copied application can be safely renamed and booted with minimal manual work.
2. Shared defaults are secure, tested, understandable, and Rails-native.
3. Humans and AI agents begin with accurate operational and architectural context.

## Non-goals

- Remaining synchronized with applications after they are copied.
- Providing every feature a Rails product might eventually need.
- Being an unopinionated or public universal Rails template.

## Current development focus

Make copying, authentication, validation, and documentation reliable enough to
replicate into future applications.

## Success criteria

- `bin/bootstrap MyProduct "My Product"` produces a freshly named application.
- Local and GitHub CI exercise tests, lint, autoloading, and security checks.
- Magic-link requests resist replay, concurrency, link scanners, and basic abuse.

## Important constraints

- Prefer Rails 8 built-ins and existing dependencies.
- Keep the starter small and easy to remove or adapt.
