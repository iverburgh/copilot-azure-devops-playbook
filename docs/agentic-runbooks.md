# Agent-guided runbooks for risky operations

Some operations are rare, stressful and hard to undo: restoring a production database to a point
in time, pausing message processing during an incident, rotating a compromised secret. The steps
live in a script, the context in a wiki page nobody has read since the last incident.

We put such procedures in a **skill** that drives an idempotent PowerShell script. The agent becomes
the guide: it asks the questions, runs the read-only steps, explains what it is about to change, and
waits for a yes before every change. This page describes the rules that make that safe. They came
out of building and rehearsing a database restore with an agent.

## The shape

```
.github/skills/<operation>/
  SKILL.md                 Workflow, safety rules, what to report
  scripts/<Operation>.ps1  Read-only actions, dry-run by default, -Execute to change anything
```

The script does the work and is safe on its own: every action is read-only or a dry-run unless
`-Execute` is passed, every changing action asks for confirmation, and running a step twice does
nothing the second time. The skill adds the conversation around it.

## Rules for the agent

Write these into the skill, in this order of importance.

### 1. Ask for the environment first, and assume nothing

The very first question is which environment. Do not take a default, the current `az account`
context, or an environment mentioned earlier in the conversation. Run nothing, not even a dry-run
or a read-only query, until the user has named the environment in this conversation.

A dry-run against the wrong subscription still reads production data and still produces a plan that
looks right.

### 2. Read, plan, then ask

1. Read-only analysis and a dry-run of the whole procedure.
2. A plan: which steps, in which order, what each one changes, how long it takes, how to go back.
3. Explicit approval of the plan before the first `-Execute`.
4. A separate confirmation before **each** step that changes something.

On production, require a second person (four-eyes) and say so in the plan.

### 3. Never skip the confirmations

The script may have a `-Force` or `-Yes` switch for automation. The agent never uses it. That switch
exists for a human or a pipeline that has made the decision elsewhere; an agent passing it removes
exactly the checkpoints the skill is built around.

### 4. Ask before every delete

Deleting the backup copy, removing a temporary resource and other cleanup are separate questions,
even when the plan already mentioned them. After the main step, offer a read-only check, such as
an integrity check of the restored data, before suggesting any cleanup.

### 5. Let long steps finish

A restore can take ten minutes or more. The agent must not move the command to the background,
interrupt it, or start polling whether the new resource exists yet. Halfway through a restore the
target does not exist; that is normal, not an error, and not a reason to stop or to ask the user
what to do next.

Make the script wait until the step is complete and print one clear marker, such as
`RESTORE COMPLETE`. Tell the agent in the skill to wait for that marker.

### 6. No radio silence

Before a long step, report what starts and how long it usually takes. Report milestones while it
runs, if the script prints them. Afterwards, summarise what changed and what the next step is.

### 7. A question is not a stop

When the user asks something in the middle of the procedure, answer it and continue from where you
were. Stop only when the user explicitly asks to stop, or when something does not match the plan.

### 8. When in doubt, stop

An unexpected state, an error the skill does not describe, or output that contradicts the plan:
stop, report what you see, and ask. A runbook never improvises.

## Routing

Users in an incident do not remember skill names. Make the skill load by itself:

- Write a `description` that contains the phrases people actually type, such as *"start the
  restore"*, *"restore the orders database"* or *"pause processing"*.
- Add a short entry to `copilot-instructions.md` that names those phrases and the skill, together
  with the two rules that must hold even before the skill is read: ask for the environment first,
  and never change anything without a yes. See the routing example in
  [the template](../templates/copilot-instructions.azure-devops.md).

The skill can also be invoked by name. Skills in `.github/skills/` are read by VS Code, Copilot CLI
and the Copilot app, and the same `SKILL.md` format works in other agents that support skills.

## Rehearse it

Run the procedure end to end in a test environment with the agent, before you need it. Add a rule
to the skill for everything the agent did that you did not expect. Keep the script's dry-run output
in the skill as an example, so the agent can tell a normal run from an abnormal one.
