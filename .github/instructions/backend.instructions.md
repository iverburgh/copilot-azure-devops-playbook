---
description: 'General backend rules: build and test scope, API design, configuration and the test pyramid.'
applyTo: 'src/**, tests/**'
---

# Backend

Architecture, component names and folder layout are described in `copilot-instructions.md`. The
layer-specific rules are in `domain-layer`, `application-layer` and `infrastructure` instructions.

## Build and test

- **Build the smallest project that proves the change** — the relevant test project, never the whole
  solution. The commands are in the *Build and test* section of `copilot-instructions.md`.
- Keep build output quiet (`--nologo -v quiet` for `dotnet`) and show details only on failure.
- **Wait for builds to finish.** They can take minutes; never cancel one and never start a second
  build while the first is running.
- Run the narrowest tests first (one test, one class, one project); run broader suites only when
  shared test infrastructure or cross-cutting code changed.

## API design

- Request and response contracts live in dedicated DTO or contract types, never domain objects.
- Errors use `ProblemDetails` (RFC 9457, formerly 7807) for a consistent shape.
- Every endpoint requires authentication and authorisation, except health checks.
- Changing a published contract is a breaking change: add fields, do not rename or remove them,
  unless every consumer moves in the same release.

## Configuration

- Configuration comes from a configuration store and secrets from a vault — never hardcoded, never
  in `appsettings.json` for anything environment-specific.
- Every configuration key read by code must exist in every environment's configuration; the Platform
  Engineer checks this.

## Test pyramid

| Level | Scope | Needs cloud resources |
|---|---|---|
| Unit tests | Domain logic, pure functions | No |
| Component tests | One deployable component end to end, in memory | No |
| Integration tests | Several components together in a real environment | Yes |

Write component tests by default. See the `component-tests` and `integration-tests` instructions.
