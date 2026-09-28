# Refinement

A backlog item arrives with a title, a paragraph and some acceptance criteria that sound testable
until you try. The **PBI Refiner** turns it into something a developer can build without guessing,
and checks it against what the team already decided — before anyone writes code.

Run it with `/refine <id>`, or pick *PBI Refiner* in the agent picker and write "refine 1234".

## What it does

1. Fetches the item, its parent feature and linked items.
2. Analyses the codebase: which components are touched, what comparable code exists, which tests
   apply, what the infrastructure impact is.
3. **Puts every change next to the functional design.**
4. **Puts every change next to the architecture decision records.**
5. Writes an analysis with an acceptance-criteria status table, both checks, open points,
   non-functional requirements, risks and a proposed description.
6. **Resolves the open points with you as multiple-choice questions.**
7. Publishes to Azure DevOps only after you confirm the exact content.

## The functional design check

The code tells you what the system does. The functional design tells you what it should do.
Refining against the code alone reproduces whatever the code currently gets wrong; refining against
neither leaves the design to go stale with every item.

So the Refiner classifies each intended change:

| Verdict | Meaning | What happens |
|---|---|---|
| ✅ Aligned | The design already describes this | The page is cited in the analysis |
| ➕ Extends | New behaviour the design does not describe | A **documentation requirement** is added: an acceptance criterion that the design page is updated, and a documentation task when publishing |
| ⚠️ Conflicts | The change contradicts the design | The Refiner **stops and asks for explicit confirmation**: update the design, change the item, or split it |
| ❓ Unclear | The design is silent or ambiguous | It becomes an open point |

The effect over time is that the design keeps up with the product, because every item that changes
behaviour carries the work of documenting it. And conflicts surface at refinement, where changing
your mind costs a conversation, instead of in review or production.

Every claim links to the exact wiki page it rests on, so reviewers can check the reasoning in one
click.

## The ADR check

The same idea for architecture. For each change:

- **Compliant** with an ADR — cited.
- **A new architectural decision** that no ADR covers — a new external dependency, a new
  communication pattern, a new way of storing data — gets a requirement to write the ADR.
- **A violation** — the Refiner asks you to confirm: comply with the ADR, or supersede it. Superseding
  adds a task to write the new ADR before the change is built.

This catches the most expensive kind of drift: the decision that was made once, carefully, and then
quietly undone by an item nobody connected to it.

## Open points as multiple choice

Instead of a list of questions to answer in prose, the Refiner asks each open point through
VS Code's question tool: two to four concrete options, its recommendation marked, free text always
possible.

```
Open point 2 of 4 — Cancelled orders
What should happen to an order that is cancelled after the invoice was sent?
  ○ Send a credit note automatically          (recommended)
  ○ Flag for manual handling
  ○ Block cancellation once invoiced
  ○ Other…
```

Answering takes seconds, the options make the trade-offs visible, and the answers flow straight
back into the description and acceptance criteria. A refinement session with the product owner
becomes a short series of clicks with the analysis on screen.

### Also for loose tasks

The same technique works outside backlog items. `/clarify-open-points <task>` makes Copilot gather
context first, list every point where two readings would produce a different result, and ask those
as multiple choice before touching anything. It is the cheapest way to avoid a well-built wrong
answer.

## Publishing

In `publish-to-azure` mode the Refiner writes the description and acceptance criteria through the
REST API, never through `az boards work-item update --description`, which keeps only the text before
the first newline. It reads every field back and checks the stored length. Why that matters:
[pitfalls](pitfalls.md#the-cli-keeps-only-the-first-line-of-html).

It can also propose and create child items under a feature, with the same care.

## Rules it keeps

- Acceptance criteria are never changed without your approval.
- Nothing is written to Azure DevOps without confirmation of the exact content.
- Engineering decomposition is not its job — that is the [PBI Planner](planning-and-reps.md).
