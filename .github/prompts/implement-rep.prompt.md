---
description: 'Implement the part of a REP that belongs to one specialist.'
argument-hint: 'Specialist name, and optionally the task ID'
---

Implement the REP for specialist **${input:specialist:for example Backend Developer}** — task
${input:task:task ID, or leave empty to use the only REP for this branch}.

1. Load the REP from `~/.copilot/reps/REP-<task id>.md`. Without a task ID, derive it from the
   current branch name; if that is ambiguous, list the REPs present and ask.
2. Find the row for this specialist in the REP's Specialists table. If there is none, stop and say
   which specialists the REP does list.
3. Check the PR plan: if this specialist's PR depends on a PR that is not merged yet, warn me before
   starting.
4. Run the specialist as a subagent with the agent of that exact name, and pass the REP path and its
   row (action, reason, paths). If subagents are unavailable, read
   `.github/agents/<specialist>.agent.md` and follow it yourself.
5. Stay within that specialist's paths. When work is needed outside them, stop and name the
   specialist who should do it.
6. Finish with the specialist's acceptance-criteria table and one line: done, missing, or blocked.
