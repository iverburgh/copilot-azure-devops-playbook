---
description: 'Before starting any task: list what is ambiguous and resolve it through multiple-choice questions.'
argument-hint: 'The task, or a work item ID'
---

Before you change anything, clarify this task with me:

${input:task:describe the task or give a work item ID}

1. Gather context: read the relevant code, and fetch the work item and its parent if an ID is given.
2. List every open point where two reasonable readings would lead to a different result: scope,
   expected behaviour, edge cases, naming, compatibility, what "done" means.
3. Ask them with the ask-questions tool as multiple choice: one question per open point, two to
   four concrete options, your recommended option marked, free text allowed. At most five questions
   per round.
4. Summarise the decisions in a short list and ask whether to proceed.

Do not ask about things you can find out yourself from the code or the work item.
