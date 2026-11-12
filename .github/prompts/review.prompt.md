---
description: 'Review the current branch or change: functional and architectural correctness first, then code quality.'
agent: Functional Reviewer
argument-hint: 'Backlog item ID, and optionally "branch" for a full branch review'
---

Review my work for backlog item ${input:item:Backlog item ID}. Use `change-review` mode unless I
asked for a branch review.

When your outcome is `APPROVED` or `FEEDBACK_MINOR`, tell me to run the Code Quality Reviewer next as
the second gate.
