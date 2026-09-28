---
description: 'Create a local REP for one Azure DevOps task, verified against the current code.'
agent: PBI Planner
argument-hint: 'Task ID'
---

Create a REP for task ${input:task:task ID} (`single-rep` mode).

1. Fetch the task, its parent backlog item and its sibling tasks.
2. Use the task description as a draft. Verify every assumption in it against the current code and
   against what sibling tasks have already merged; correct what no longer holds and tell me what you
   changed.
3. Classify the change type with the decision tree in the `rep-protocol` skill.
4. Fill in the full REP template, including the Specialists table (via `specialist-routing`) and the
   PR plan.
5. Save it to `~/.copilot/reps/REP-<task id>.md` and show me the path and a summary: change type,
   specialists, and the command to run for each of them (*"Implement the REP for specialist X"*).
