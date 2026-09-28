---
name: azure-devops-pipeline-logs
description: Retrieve and analyse logs of failed Azure DevOps pipeline runs with single-line PowerShell commands, including runs triggered by pull requests. Use when troubleshooting pipeline failures, build errors, failing tests or tasks, or when the user mentions pipeline logs or build failures.
---

# Azure DevOps pipeline logs

Get from "the build is red" to the relevant log lines quickly.

## Prerequisites

- `az extension add --name azure-devops`, logged in with `az login` or `az devops login`.
- Organization URL and project from the *Azure DevOps context* in `.github/copilot-instructions.md`.
- Behind a TLS-inspecting proxy: `$env:AZURE_CLI_DISABLE_CONNECTION_VERIFICATION = 'true'`.

## Constraints

| Issue | Problem | Solution |
|---|---|---|
| Multi-line scripts | The terminal tool runs only the first line | Single-line commands chained with `;` |
| TLS and encoding | `az rest` fails behind proxies and on Unicode | `az devops invoke` |
| PR builds | Filtering on the source branch returns nothing | Use `refs/pull/<PR_ID>/merge` |
| Status filter | `--status failed` does not exist | `--status completed`, then filter on `result` |

Each command below starts with the same two variables; replace the placeholders once.

## 1. Run details

A run URL looks like `https://dev.azure.com/<org>/<project>/_build/results?buildId=<id>`.

```powershell
$org = 'https://dev.azure.com/<org>'; $project = '<project>'; $buildId = <BUILD_ID>; az pipelines runs show --id $buildId --org $org --project $project --output json | ConvertFrom-Json | Select-Object buildNumber, status, result, sourceBranch, @{n='Pipeline';e={$_.definition.name}}, startTime, finishTime
```

## 2. Failed records and their logs

```powershell
$org = 'https://dev.azure.com/<org>'; $project = '<project>'; $buildId = <BUILD_ID>; $t = az devops invoke --area build --resource timeline --route-parameters project=$project buildId=$buildId --org $org --output json | ConvertFrom-Json; $t.records | Where-Object { $_.result -eq 'failed' } | Select-Object type, name, @{n='LogId';e={$_.log.id}}, @{n='Issues';e={($_.issues | ForEach-Object message) -join ' | '}} | Format-Table -Wrap
```

The `issues` column often already contains the error, which saves fetching the log.

## 3. Error lines from one log

First 25 matches with context, or the last 40 lines when nothing matches:

```powershell
$org = 'https://dev.azure.com/<org>'; $project = '<project>'; $buildId = <BUILD_ID>; $logId = <LOG_ID>; $log = az devops invoke --area build --resource logs --route-parameters project=$project buildId=$buildId logId=$logId --org $org --output json | ConvertFrom-Json; $lines = $log.value -split "`n"; $hits = $lines | Select-String -Pattern 'error CS\d+|##\[error\]|Error:|Exception|FAILED|Failed ' -Context 2,3; if ($hits) { $hits | Select-Object -First 25 | ForEach-Object { $_.ToString().Trim() } } else { $lines | Select-Object -Last 40 }
```

Search for a specific term:

```powershell
$org = 'https://dev.azure.com/<org>'; $project = '<project>'; $buildId = <BUILD_ID>; $logId = <LOG_ID>; $log = az devops invoke --area build --resource logs --route-parameters project=$project buildId=$buildId logId=$logId --org $org --output json | ConvertFrom-Json; $log.value -split "`n" | Select-String -Pattern '<term>' -Context 3,3
```

## 4. Pull request runs

```powershell
$org = 'https://dev.azure.com/<org>'; $project = '<project>'; $prId = <PR_ID>; az pipelines runs list --org $org --project $project --branch "refs/pull/$prId/merge" --top 20 --output json | ConvertFrom-Json | Group-Object { $_.definition.name } | ForEach-Object { $_.Group | Sort-Object id -Descending | Select-Object -First 1 } | Select-Object id, @{n='Pipeline';e={$_.definition.name}}, status, result | Format-Table
```

Source and target branch:

```powershell
$org = 'https://dev.azure.com/<org>'; $prId = <PR_ID>; $pr = az repos pr show --id $prId --org $org --output json | ConvertFrom-Json; "Source: $($pr.sourceRefName -replace 'refs/heads/')"; "Target: $($pr.targetRefName -replace 'refs/heads/')"
```

## 5. Same pipeline on the target branch

Tells you whether a failure is introduced by the PR or already present:

```powershell
$org = 'https://dev.azure.com/<org>'; $project = '<project>'; $definitionId = <DEFINITION_ID>; az pipelines runs list --org $org --project $project --pipeline-ids $definitionId --branch 'refs/heads/<target>' --top 5 --output table
```

## Classification

| Pattern | Category | Likely cause |
|---|---|---|
| `error CS\d+`, `error TS\d+` | Compilation | Code or missing reference in the diff |
| `NU1\d{3}` | Restore | Package version conflict or feed access |
| `Failed <test name>`, assertion messages | Test | Behaviour change, brittle test, or flakiness |
| `SetUp failed`, fixture errors | Test infrastructure | Shared fixture, container or database start-up |
| `502`, `503`, health check timeouts | Runtime or startup | Missing configuration, crash at startup |
| `403 Forbidden`, `AuthorizationFailed` | Permissions | Service connection or identity lacks a role |
| `Timeout`, `Connection refused` | Infrastructure | Network, agent or dependency |
| Path filter or validation scripts | Policy | Pipeline configuration out of sync with the change |

## Output

```markdown
## Pipeline failure: run <id>

**Pipeline:** <name> · **Branch:** <branch> · **Result:** failed
**Failed:** <stage> / <job> / <task>

<relevant log lines>

**Category:** <category> · **Root cause:** <one or two sentences>
```
