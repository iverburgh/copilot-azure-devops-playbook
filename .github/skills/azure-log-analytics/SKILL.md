---
name: azure-log-analytics
description: >-
  Query Azure Log Analytics and workspace-based Application Insights with KQL through the Azure CLI
  to investigate production issues: exceptions, failed requests, slow dependencies, messaging
  problems, end-to-end traces and trends. Use when users report Azure errors, performance problems
  or failed requests, or ask to investigate logs.
---

# Azure Log Analytics and Application Insights

Investigate issues by running KQL against a Log Analytics workspace through the Azure CLI.

## Prerequisites

- Azure CLI, logged in with `az login`.
- Behind a TLS-inspecting proxy: `$env:AZURE_CLI_DISABLE_CONNECTION_VERIFICATION = 'true'`.
- Your environments and resource names filled in: [references/resources.md](references/resources.md).

## Constraints

| Issue | Solution |
|---|---|
| Multi-line scripts get cut off in the terminal tool | Single-line commands chained with `;` |
| Large results | `| take 50` or `| top 50 by ...` |
| Time zones | Log Analytics stores UTC; use `ago()` |
| Wrong environment | Always confirm the environment first; never default to production |

## Schema: workspace-based, PascalCase

Workspace-based Application Insights tables (`AppRequests`, `AppDependencies`, `AppExceptions`,
`AppTraces`) use **PascalCase** columns: `AppRoleName`, `OperationId`, `DurationMs`, `Success`,
`ResultCode`, `ExceptionType`, `OuterMessage`, `DependencyType`. Most online examples use the
classic Application Insights schema (`cloud_RoleName`, `operation_Id`, `duration`, `success`) and
fail here. The full mapping is in [references/kql-patterns.md](references/kql-patterns.md).

When unsure about a table, inspect it first:

```powershell
$workspaceId = '<id>'; az monitor log-analytics query --workspace $workspaceId --analytics-query '<Table> | take 1' --output json
```

## Workflow

1. **Environment.** Ask when not given. Look up workspace and resource group in
   `references/resources.md`.
2. **Workspace ID:**
   ```powershell
   $rg = '<resource-group>'; $ws = '<workspace>'; $workspaceId = az monitor log-analytics workspace show --resource-group $rg --workspace-name $ws --query customerId -o tsv
   ```
3. **Pick the table:**

   | Problem | Table |
   |---|---|
   | Errors and exceptions | `AppExceptions` |
   | Failed or slow HTTP requests, function executions | `AppRequests` |
   | Logs and traces | `AppTraces` |
   | SQL, HTTP, messaging calls | `AppDependencies` |
   | Function host logs | `FunctionAppLogs` (check columns with `take 1`) |
   | Metrics | `AppMetrics` |
   | Availability tests | `AppAvailabilityResults` |

4. **Run it:**
   ```powershell
   $workspaceId = '<id>'; $query = '<KQL>'; az monitor log-analytics query --workspace $workspaceId --analytics-query $query --output table
   ```
   Use `--output json` when you need full stack traces.
5. **Deepen:** follow `OperationId` from an exception to every request, dependency and trace in the
   same operation; compare percentiles with a baseline; check messaging failures and dead-letter
   symptoms.

Query patterns: [references/kql-patterns.md](references/kql-patterns.md).
