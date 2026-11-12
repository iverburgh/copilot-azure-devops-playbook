# Reviews before the pull request

Two review agents check a change before a human reviewer sees it, and a skill helps you review your
own branch. None of them edits code.

| Tool | Question | How to start |
|---|---|---|
| **Functional Reviewer** | Does the change do the right thing, in the right place, and is it safe to deploy? | `/review <item id>`, or `/review <item id> branch` before merging |
| **Code Quality Reviewer** | Was it built cleanly? | Select the agent after the Functional Reviewer approves |
| **`pr-review-coach` skill** | Do *you* understand and stand behind every change? | *"Coach me through a review of my branch"* |

## Two gates, in order

The **Functional Reviewer** runs first. In `change-review` mode it reviews the diff against the
integration branch: the right layer, invariants enforced inside the domain, no hidden behaviour change in
a refactoring. In `branch-review` mode it compares the whole branch with the backlog item and gives
every acceptance criterion a status (✅ ⚠️ ❌ ❓) with file and line as evidence. It also checks
compatibility, because the old and new version may run side by side and the deploy order is not
guaranteed: message and API contracts, database schema in both directions, messages already queued,
new configuration keys, deploy order.

Both modes search for **leftover workarounds**: `TODO(remove-before-merge)`, `workaround`,
`fallback`, `temporary`, `hack`, reflection. Temporary code is fine when it is marked and a clean-up
decision is recorded; unmarked, it is a rejection.

The **Code Quality Reviewer** runs second, on the diff only, with six checks: duplication,
unnecessary dependencies, contract shortcuts, hardcoded values, leftover temporary work and
architecture shortcuts. It searches the codebase before calling a new method unique.

Splitting the two keeps each review focused. A single reviewer that checks everything tends to
report twenty style remarks and miss the one invariant that moved into a handler.

## A machine-readable outcome

Both agents end every review with the same block:

```
---OUTCOME---
OUTCOME: APPROVED | FEEDBACK_MINOR | FEEDBACK_MAJOR | BLOCKED
SUMMARY: <one line>
---END_OUTCOME---
```

`FEEDBACK_MAJOR` means a rejection criterion was met and the change needs another review after the
fix. Because the format is fixed, a script or another agent can act on it, for example to stop a
chain of specialists until the feedback is processed.

## Coaching instead of reviewing

The `pr-review-coach` skill works the other way round: it asks you questions about your own diff
instead of giving findings. Use it when you want to learn from your choices, or before you defend a
pull request in a team review. It works on a pull request or on the current branch, always against
the integration branch.
