---
description: 'Break a refined backlog item into Azure DevOps tasks, one branch and PR each, with REP-level detail and test-driven by default.'
agent: PBI Planner
argument-hint: 'Work item ID of the refined backlog item'
---

Can you break backlog item ${input:workItem:work item ID} down into Azure DevOps tasks that can each
go through their own branch and pull request?

- Create these tasks with as much information as a REP (see the `rep-protocol` skill).
- Preferably everything test-driven: every change to or addition of functionality comes with tests
  that prove the change is correct.
- Order the tasks so each PR can be merged and deployed on its own (expand and contract), and name
  the specialists per task.

Show me the overview first. Create the tasks in Azure DevOps only after I confirm (`create-tasks`
mode).
