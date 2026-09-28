# Investigating Azure issues

The **Azure Issue Investigator** answers "what is going wrong, why, and what do we do about it"
from Application Insights and Log Analytics — and then reads the code the telemetry points at.

Run `/investigate-azure-issue`, or pick the agent and describe the symptom in plain words:

> The order function has thrown many timeouts in test since yesterday 14:00.

## Why it is worth having

Telemetry alone tells you *that* something fails and where. Code alone tells you what *could* fail.
The expensive part of an investigation is going back and forth between the two: finding the
exception, the operation, the stack frame, the file, the commit that changed it, the deployment that
shipped it. The agent does that loop in minutes, and writes down every query it used so you can check
it.

## What it does

1. **Asks for the environment** if you did not give one. It never assumes production.
2. **Explores broadly**: exceptions by type and service, failed requests, failing dependencies.
3. **Zooms in** on what stands out: stack traces, one operation end to end across services,
   latency percentiles, messaging failures.
4. **Compares with a baseline**: new, recurring or worsening? It correlates the start with deployed
   versions and pipeline runs.
5. **Reads the code**: maps stack frames and operation names to files, reads the path, checks recent
   history for that area.
6. **Names the root causes** — often more than one — each with its evidence and a confidence level:
   confirmed, likely, or hypothesis.
7. **Advises in three horizons:**
   - *Mitigation now* — scale, restart, disable a flag, pause a consumer;
   - *Temporary fix* — the smallest safe change, with its risk;
   - *Follow-up items* — the structural fix as backlog items with acceptance criteria, ready for the
     [PBI Refiner](refinement.md).

## Safety

The agent is read-only. It recommends restarts, replays or configuration changes but never performs
them. It masks personal data from logs in its report.

## Setting it up

Fill in [resources.md](../.github/skills/azure-log-analytics/references/resources.md) with your
environments, workspaces and service names. Without it the agent can still work, but has to ask for
every name.

One thing that trips up almost every KQL example on the internet: workspace-based Application
Insights tables use **PascalCase** columns (`AppRoleName`, `OperationId`, `DurationMs`), not the
classic `cloud_RoleName` and `operation_Id`. The skill's
[KQL patterns](../.github/skills/azure-log-analytics/references/kql-patterns.md) use the right names
throughout.
