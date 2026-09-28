---
name: specialist-routing
description: >-
  Decide which specialists (Backend Developer, Database Engineer, Frontend Developer, Platform
  Engineer, Backend Tester, Frontend Tester) a task needs, based on the paths it touches. Produces
  the Specialists table, the lead implementer and PR plan hints for a REP. Use from the PBI Planner
  or when asked who should build what. Triggers on 'specialist', 'routing', 'who does what',
  'lead implementer', 'Specialists table'.
---

# Specialist routing

Route work to the right specialist based on the paths it touches.

> **Adapt the mapping table to your repository.** It is the one part of this playbook that must
> match your layout exactly. The example below assumes a typical monorepo with a .NET backend, a
> TypeScript frontend, a database project and infrastructure as code.

## Path → specialist mapping

| Path pattern (example) | Specialist | Action |
|---|---|---|
| `src/<Component>/Domain/**` | Backend Developer | implement |
| `src/<Component>/Application/**` | Backend Developer | implement |
| `src/<Component>/Infrastructure/**` | Backend Developer | implement |
| `src/<Component>/Api/**` | Backend Developer | implement |
| `src/<Component>/Functions/**` | Backend Developer | implement |
| `src/Shared/**` | Backend Developer | implement — shared code, watch for breaking changes |
| `src/<Component>/Database/**` | Database Engineer | implement |
| `ui/src/**` | Frontend Developer | implement |
| `ui/test/unit/**` | Frontend Developer | implement (unit tests) |
| `ui/test/component/**` | Frontend Tester | implement |
| `infra/**` | Platform Engineer | implement |
| `pipelines/**` | Platform Engineer | implement |
| `tests/**` | Backend Tester | review + write |

### A path that is not in the table

1. Use the closest parent path that is in the table.
2. No match: assign to Backend Developer.
3. Say in the REP that the path is not classified, so the table can be extended.

## Lead implementer

The lead implementer is the specialist with the largest share of the work; they coordinate the
order.

| Situation | Lead |
|---|---|
| One specialist | That specialist |
| Backend + database | Backend Developer |
| Backend + frontend | Backend Developer, unless the frontend is dominant |
| Backend + platform | Backend Developer |
| Frontend + database, or database + platform | Specialist with the most files |
| Three or more | Backend Developer, unless database or frontend is dominant |

Rule of thumb: more than 60% of the touched files belong to one specialist → that one leads.

## Tester routing

| Domain | Tester |
|---|---|
| Backend component and integration tests | Backend Tester |
| Frontend component and browser tests | Frontend Tester |
| Frontend unit tests (review) | Frontend Tester |

- Both testers get at least `review` when the task is Behavioral in their domain, or when existing
  tests in their domain are affected.
- A tester gets `review + write` when new scenarios are needed that the developer does not write.
- Backend-only task → Backend Tester only. Frontend-only → Frontend Tester only. Both → both.

## Producing the Specialists table

1. Classify every touched path with the mapping.
2. Group by specialist and count files.
3. Pick the action: `implement`, `review`, or `review + write`.
4. Pick the lead implementer.
5. Drop specialists without work.

```markdown
**Specialists:**

| Specialist | Action | Reason | Paths |
|---|---|---|---|
| Database Engineer | implement | New nullable column `Remarks` on `Order` | `src/Orders/Database/` |
| Backend Developer | implement | Domain property, handler and endpoint | `src/Orders/Domain/`, `src/Orders/Api/` |
| Backend Tester | review + write | New behaviour needs component tests | `tests/Orders/` |

**Lead implementer:** Backend Developer (8 files versus 2)
```

## PR plan hints

Needed when more than one specialist has `implement`.

| Combination | Order |
|---|---|
| Database + backend | PR 1 database (expand) → PR 2 backend (migrate) |
| Database + backend + platform | PR 1 database → PR 2 backend → platform independent |
| Database + backend + frontend | PR 1 database → PR 2 backend → frontend independent unless the API contract changes |
| Backend + frontend | Independent, unless the API contract changes: then backend first, backwards compatible |
| Backend + platform, frontend + platform, database + platform | Independent |
| One specialist | One PR |

See the `rep-protocol` skill for expand-and-contract.
