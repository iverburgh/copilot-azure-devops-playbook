# Planning, REPs and specialists

From a refined backlog item to code, in three steps that each have their own command:

1. **Break the item down** into tasks, one branch and pull request each — `/breakdown-pbi <id>`.
2. **Create a REP** for the task you pick up — `/create-rep <task id>`.
3. **Implement the REP**, one specialist at a time — `/implement-rep <specialist> <task id>`.

## 1. Breaking an item into tasks

The instruction that works, and that `/breakdown-pbi` sends to the **PBI Planner**:

> Can you break backlog item X down into Azure DevOps tasks that can each go through their own branch
> and pull request? Create these tasks with as much information as a REP. Preferably everything
> test-driven: every change to or addition of functionality comes with tests that prove the change is
> correct.

What comes back first is an overview:

| # | Task | Change type | Specialists | Depends on | Suggested branch |
|---|---|---|---|---|---|
| 01 | Add nullable `Remarks` column to `Order` | Behavioral | Database Engineer | — | `feature/1234-order-remarks-column` |
| 02 | Accept and return remarks in the order API | Behavioral | Backend Developer, Backend Tester | 01 | `feature/1234-order-remarks-api` |
| 03 | Show and edit remarks on the order screen | Behavioral | Frontend Developer, Frontend Tester | 02 | `feature/1234-order-remarks-ui` |

After you confirm, the Planner creates the tasks as children of the item, numbered in order, each
with a full REP as its description.

Why tasks per pull request rather than one big branch:

- **Every PR is deployable on its own.** The Planner orders tasks with *expand and contract*: the
  schema is extended first, the code moves to it while tolerating the old shape, and destructive
  clean-up comes last. No PR breaks production while waiting for the next.
- **Small reviews get real reviews.** A PR that fits in one sitting gets read; one that doesn't gets
  approved.
- **Test-driven by default.** Each behavioural task specifies the tests that prove it — happy path,
  invalid input, edge case — and the specialist writes them first and sees them fail first.
- **One change type per task.** Refactoring and behaviour change are never mixed in one PR, so a
  reviewer knows whether to look for "nothing changed" or "exactly this changed".

Tasks that are pure research (inventory, assess, advise) get no REP: their result goes on the item as
a discussion comment, and REPs follow for the items that come out of it.

## 2. Creating a REP for one task

When you pick up a task: `/create-rep <task id>`, or in words: *"Create a REP for task X"*.

The Planner reads the task, its parent and its siblings, and **checks every assumption in the task
description against the current code**. A task written last week may describe code that a sibling
task has since changed. It tells you what it corrected, classifies the change type, and saves the REP
to `~/.copilot/reps/REP-<task id>.md`.

The REP lives outside the repository on purpose: it never ends up in a commit, and every worktree on
your machine sees the same file.

### What a REP is

A Refined Execution Packet describes **what must be true when the task is done**, not how to write
the code:

- **What:** desired behaviour, invariants, acceptance criteria, scope, the public contract touched.
- **Not how:** no step-by-step instructions, no prescribed class or method names.
- **Hints** are allowed — a comparable implementation, a starting file, a known pitfall — as
  suggestions the implementer may ignore.

That split keeps the REP stable while the implementer is free to find the better design. The full
template and validation rules are in the [rep-protocol skill](../.github/skills/rep-protocol/SKILL.md).

### Change types

| Type | When | What the implementer must prove |
|---|---|---|
| **Behavioral** | Observable behaviour changes | Tests written first, seen failing, then passing; invariants enforced |
| **Structural** | Internal restructuring, same behaviour | All existing tests green, no public API change, coverage not lower |
| **Sweep** | Removal or simplification only | Diff-scoped, no assertion changes, coverage not lower |

## 3. Implementing a REP, specialist by specialist

A REP names the specialists it needs in a table:

| Specialist | Action | Reason |
|---|---|---|
| Database Engineer | implement | New nullable column |
| Backend Developer | implement | Domain property, handler, endpoint |
| Backend Tester | review + write | Component tests for the new behaviour |

Run each one separately: `/implement-rep Backend Developer 1240`, or in words: *"Implement the REP
for specialist Backend Developer"*.

Each specialist is its own agent with a hard scope: the Backend Developer does not touch schema
files, the testers never change production code, the Platform Engineer never touches application
code. When a specialist needs something outside its scope, it stops and names who should do it.
That is what keeps a task from quietly growing into a different one.

| Specialist | Owns |
|---|---|
| Backend Developer | Domain logic, handlers, APIs, background jobs, their unit tests |
| Database Engineer | Schema, migrations, change data capture impact, ORM mapping review |
| Frontend Developer | Components, hooks, services, routes, frontend unit tests |
| Frontend Tester | Component and browser tests; reviews frontend unit tests |
| Backend Tester | Component and integration tests; coverage audits |
| Platform Engineer | Infrastructure as code, configuration, secrets, pipelines |

Which paths each one owns is set in the
[specialist-routing skill](../.github/skills/specialist-routing/SKILL.md) — adapt it to your layout.

Each specialist ends with a table of acceptance criteria, what was implemented and which test proves
it, and one line: done, missing, or blocked.
