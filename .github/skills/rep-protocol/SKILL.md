---
name: rep-protocol
description: >-
  Shared protocol for Refined Execution Packets (REPs): the contract for one task that goes through
  one branch and one pull request. Defines the REP template, change type classification
  (Behavioral / Structural / Sweep), expand-and-contract PR ordering, validation rules and storage.
  Use when creating a REP (PBI Planner), implementing one (specialists) or reviewing against one.
  Triggers on 'REP', 'execution packet', 'change type', 'Behavioral', 'Structural', 'Sweep'.
---

# REP protocol

A Refined Execution Packet (REP) is the contract between the planner, the specialists who build and
whoever reviews. One REP describes exactly one task: one branch, one pull request, mergeable and
deployable on its own.

## Design philosophy: what, not how

A REP describes **what** must be achieved, not **how** to build it.

- **What:** desired behaviour, invariants, acceptance criteria, scope boundaries.
- **Not how:** no step-by-step instructions, no prescribed internal class or method names, no
  dictated internal structure.

The specialist is free to choose the implementation as long as the result meets the acceptance
criteria and invariants.

### Hints

A REP may contain hints: files or code paths to start from, comparable implementations, known
pitfalls. Hints are suggestions. Write *"See `<path>` for a comparable pattern"*, not *"Implement
it like `<path>`"*.

## Change type

Every REP has exactly one change type. It never changes halfway through; reclassify by replanning.

### Decision tree

Answer in order:

```
1. Does the task restructure INTERNAL code without changing observable behaviour?
   (moving code, renaming internals, splitting classes, dependency refactoring,
    extracting a base class or interface, migrating to a new pattern)
   ├─ YES → STRUCTURAL
   └─ NO  → 2. Does the task change OBSERVABLE behaviour?
               (business rules, API endpoints, events, validation, error messages,
                response contracts)
               ├─ YES → BEHAVIORAL
               └─ NO  → 3. Is it ONLY removal or simplification of existing code?
                           (dead code, warnings, unused imports, redundancy, formatting)
                           ├─ YES → SWEEP
                           └─ NO  → STOP and ask the user
```

Mixed work is split into separate tasks, one change type each.

Borderline cases:

| Case | Type |
|---|---|
| Schema change that affects behaviour | Behavioral |
| Schema change without behaviour change (rename a column) | Structural |
| Removing deprecated code after an earlier migration | Sweep |
| Adding logging or metrics without behaviour change | Structural |
| Adding a validation rule | Behavioral — it changes error behaviour |
| Moving an existing validation to another place, identical behaviour | Structural |

### What each type requires

| Type | Requires |
|---|---|
| **Behavioral** | Test-first; at least three test intentions (happy path, invalid input, edge case); explicit invariants |
| **Structural** | No public API change; all existing tests stay green; coverage does not drop; no semantic change |
| **Sweep** | Only reduction; no assertion changes; no public API change; coverage does not drop |

## Template

```markdown
**Execution Packet (REP)**

**Work item:** #<id> — <title> (parent: #<id>)
**Change type:** Behavioral | Structural | Sweep
**Use case:** <short title>

**Why:**
<one or two sentences: which problem does this task solve?>

**Scope:**
- In scope: ...
- Out of scope: ...

**Desired result:**
<the expected end state as observable behaviour or structural improvement — not the steps>

**Contract:**
<the public entry point or interface touched — what, not the internal implementation>

**Invariants:**
- ...

**Acceptance criteria:**
- ...
<testable statements about the end result, matching the change type>

**Minimal test intentions:**
- Happy path
- Invalid input
- Edge case (Behavioral only)

**Build constraints:**
- Allowed layers: ...
- Forbidden changes: ...
- Dependency rules: ...

**Hints:** (optional)
- Comparable pattern: `<path>` — inspiration, not prescription
- Starting point: `<path>`
- Watch out: <known pitfall>

**Specialists:**
| Specialist | Action | Reason | Paths |
|---|---|---|---|
| <agent name> | implement / review / review + write | <why> | <paths> |

**Lead implementer:** <agent name>

**PR plan (deployment order):**
| PR | Specialist | Scope | Backwards compatible? | Depends on |
|---|---|---|---|---|

**Definition of done:**
- Behavioral: tests failed first → all tests green → invariants enforced
- Structural: all existing tests green → no API change → coverage unchanged
- Sweep: diff-scoped → no assertion changes → coverage unchanged
```

List only specialists who actually have work; the `specialist-routing` skill decides who that is.
Each row is something a user can run as *"Implement the REP for specialist X"*.

### What versus how

| Do (what) | Do not (how) |
|---|---|
| "An order with a negative quantity is rejected" | "Add an `if` to `OrderValidator.cs` line 42" |
| "An event is published when the order is closed" | "Create an `OrderClosedEvent` record and raise it in `Close()`" |
| "The endpoint returns 404 for an unknown ID" | "Throw a `NotFoundException` in the handler" |
| "See `Orders/` for a comparable pattern" | "Copy the structure of `OrderHandler`" |

## PR ordering: expand and contract

Database, backend and infrastructure are released separately, so each PR must be deployable without
breaking the others.

1. **Expand** (Database Engineer): extend the schema — nullable column or column with a default, new
   table. Old code keeps working.
2. **Migrate** (Backend Developer): the application uses the new schema and still tolerates the old
   one during rollout.
3. **Contract** (Database Engineer, optional): tighten constraints, drop old columns — only after
   every consumer has moved.

Rules:

- One PR per specialist per deployment step.
- Platform PRs are independent of database and backend unless the configuration is a feature flag
  that activates the new code.
- A task that touches one specialist is one PR; no ordering needed.
- Mark each PR as backwards compatible yes or no. "No" is only allowed for the last PR in the chain.

## Validation

Reject a REP that misses a required field for its type, is vague, or is prescriptive:

```
REP rejected.
Change type: <type>
Reason:
- <missing, unclear or prescriptive element>
```

Then ask targeted questions and stop.

Required fields — **Behavioral:** use case, desired result as behaviour, contract, three test
intentions, invariants, build constraints, specialists, PR plan when more than one specialist
implements, definition of done. **Structural:** use case, desired structural improvement, contract,
build constraints, specialists, PR plan, definition of done, explicit statements "no public API
change" and "no behaviour change". **Sweep:** use case, diff scope, reduction rules, build
constraints, specialists, definition of done, explicit statements "no assertion change" and "no
public API change".

Anti-patterns: step-by-step instructions, prescribed internal names, no room for the implementer's
choices, hints phrased as orders.

## Storage

REPs live outside the repository, so they never end up in a commit and are shared across worktrees:

```
~/.copilot/reps/REP-<workItemId>.md
```

On Windows that is `$env:USERPROFILE\.copilot\reps\`. When an orchestrating agent passes an explicit
path, that path wins.

```powershell
$repPath = Join-Path $HOME ".copilot/reps/REP-$workItemId.md"
New-Item -ItemType Directory -Path (Split-Path $repPath) -Force | Out-Null
Set-Content -Path $repPath -Value $repMarkdown -Encoding utf8
```

When a specialist cannot find the REP, it stops and asks for one to be created with the PBI Planner
(*"Create a REP for task X"*).

When the task itself already contains a REP (created by the planner in `create-tasks` mode), the
local file is derived from it — after checking every assumption against the current code.
