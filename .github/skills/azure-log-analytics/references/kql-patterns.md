# KQL patterns

## Schema first

Workspace-based Application Insights tables use PascalCase column names. The classic lowercase
names (`message`, `success`, `duration`, `operation_Id`, `cloud_RoleName`) found in most online
examples do not exist here.

| Concept | Column | Tables |
|---|---|---|
| Service name | `AppRoleName` | all |
| Instance | `AppRoleInstance` | all |
| Operation ID (end-to-end correlation) | `OperationId` | all |
| Operation name | `OperationName` | all |
| Span ID / parent span ID | `Id`, `ParentId` | all |
| Log message | `Message` | `AppTraces` |
| Severity (0 verbose … 4 critical) | `SeverityLevel` | `AppTraces`, `AppExceptions` |
| Request name / URL | `Name`, `Url` | `AppRequests` |
| Duration in ms | `DurationMs` | `AppRequests`, `AppDependencies` |
| Result code | `ResultCode` | `AppRequests`, `AppDependencies` |
| Succeeded | `Success` | `AppRequests`, `AppDependencies` |
| Exception type | `ExceptionType` | `AppExceptions` |
| Outer / innermost message | `OuterMessage`, `InnermostMessage` | `AppExceptions` |
| Stack trace (JSON) | `Details` | `AppExceptions` |
| Dependency type / target / data | `DependencyType`, `Target`, `Data` | `AppDependencies` |
| Custom properties (dynamic) | `Properties` | all |
| Deployed version | `AppVersion` | all |
| Table name in a `union` | `Type` | all |

`Success` is a boolean in the documented schema. If `Success == false` returns nothing while
failures clearly exist, inspect the table with `take 1`: some workspaces store it as a string, in
which case compare with `tostring(Success) == "False"`.

## Contents

1. [Broad exploration](#broad-exploration)
2. [Exceptions](#exceptions)
3. [Requests](#requests)
4. [Dependencies](#dependencies)
5. [Function apps](#function-apps)
6. [Messaging](#messaging)
7. [Performance](#performance)
8. [End-to-end tracing](#end-to-end-tracing)
9. [Trends and baselines](#trends-and-baselines)

## Broad exploration

```kusto
AppExceptions
| where TimeGenerated > ago(4h)
| summarize Count=count() by ExceptionType, OuterMessage, AppRoleName
| order by Count desc
| take 20
```

```kusto
AppRequests
| where TimeGenerated > ago(4h)
| where Success == false
| summarize Count=count() by AppRoleName, Name, ResultCode
| order by Count desc
| take 20
```

```kusto
AppDependencies
| where TimeGenerated > ago(4h)
| where Success == false
| summarize Count=count() by DependencyType, Target, AppRoleName
| order by Count desc
| take 20
```

Error rate per service:

```kusto
AppRequests
| where TimeGenerated > ago(24h)
| summarize Total=count(), Failed=countif(Success == false) by AppRoleName
| extend FailRate=round(100.0 * Failed / Total, 2)
| order by FailRate desc
```

## Exceptions

Details with stack trace:

```kusto
AppExceptions
| where TimeGenerated > ago(4h)
| where ExceptionType contains "<type>"
| project TimeGenerated, ExceptionType, OuterMessage, InnermostMessage, Details, AppRoleName, OperationId
| order by TimeGenerated desc
| take 10
```

Exceptions never seen before in the last week:

```kusto
let recent = AppExceptions | where TimeGenerated > ago(1h) | distinct ExceptionType, OuterMessage;
let baseline = AppExceptions | where TimeGenerated between (ago(7d) .. ago(1h)) | distinct ExceptionType, OuterMessage;
recent
| join kind=leftanti baseline on ExceptionType, OuterMessage
```

Per service over time:

```kusto
AppExceptions
| where TimeGenerated > ago(24h)
| where AppRoleName == "<service>"
| summarize Count=count() by bin(TimeGenerated, 15m), ExceptionType
| render timechart
```

## Requests

```kusto
AppRequests
| where TimeGenerated > ago(4h)
| where Success == false
| project TimeGenerated, Name, ResultCode, DurationMs, AppRoleName, OperationId
| order by TimeGenerated desc
| take 50
```

Volume, latency and failure rate per operation:

```kusto
AppRequests
| where TimeGenerated > ago(24h)
| where AppRoleName == "<service>"
| summarize Count=count(), P95=percentile(DurationMs, 95), FailRate=round(100.0 * countif(Success == false) / count(), 2) by Name
| order by Count desc
```

## Dependencies

SQL failures, with the statement:

```kusto
AppDependencies
| where TimeGenerated > ago(4h)
| where DependencyType == "SQL" and Success == false
| project TimeGenerated, Name, Target, ResultCode, DurationMs, Data, AppRoleName, OperationId
| order by TimeGenerated desc
| take 20
```

Slow SQL:

```kusto
AppDependencies
| where TimeGenerated > ago(4h)
| where DependencyType == "SQL" and DurationMs > 3000
| project TimeGenerated, Data, DurationMs, Target, AppRoleName, OperationId
| order by DurationMs desc
| take 20
```

Dependency health for one service:

```kusto
AppDependencies
| where TimeGenerated > ago(24h)
| where AppRoleName == "<service>"
| summarize Count=count(), P95=percentile(DurationMs, 95), FailRate=round(100.0 * countif(Success == false) / count(), 2) by DependencyType, Target
| order by FailRate desc
```

## Function apps

Executions per function (functions report as requests):

```kusto
AppRequests
| where TimeGenerated > ago(4h)
| where AppRoleName == "<function app>"
| summarize Count=count(), Failed=countif(Success == false), AvgMs=avg(DurationMs) by Name
| order by Failed desc
```

Host logs — a separate table with its own schema; check columns with `take 1` first:

```kusto
FunctionAppLogs
| where TimeGenerated > ago(4h)
| where Level in ("Error", "Warning")
| project TimeGenerated, FunctionName, Level, Message, ExceptionDetails, HostInstanceId
| order by TimeGenerated desc
| take 50
```

## Messaging

Service Bus failures:

```kusto
AppDependencies
| where TimeGenerated > ago(4h)
| where DependencyType == "Azure Service Bus" and Success == false
| project TimeGenerated, Name, Target, ResultCode, DurationMs, AppRoleName, OperationId
| order by TimeGenerated desc
| take 20
```

Send versus receive volume per entity — a gap between them points at a stalled consumer:

```kusto
AppDependencies
| where TimeGenerated > ago(24h)
| where DependencyType == "Azure Service Bus"
| summarize Sent=countif(Name has "Send" or Name has "Schedule"), Received=countif(Name has "Receive" or Name has "Process") by Target
| order by Sent desc
```

Dead-letter counts live in platform metrics, not in Application Insights; use
`az monitor metrics list --resource <namespace id> --metric DeadletteredMessages`.

## Performance

Percentiles per service:

```kusto
AppRequests
| where TimeGenerated > ago(24h)
| summarize P50=percentile(DurationMs, 50), P95=percentile(DurationMs, 95), P99=percentile(DurationMs, 99) by AppRoleName
| order by P95 desc
```

Degradation compared with the same hour yesterday:

```kusto
let now_ = AppRequests | where TimeGenerated > ago(1h) | summarize P95_now=percentile(DurationMs, 95) by AppRoleName;
let prev = AppRequests | where TimeGenerated between (ago(25h) .. ago(24h)) | summarize P95_prev=percentile(DurationMs, 95) by AppRoleName;
now_
| join kind=inner prev on AppRoleName
| extend DegradationPct = round(100.0 * (P95_now - P95_prev) / P95_prev, 2)
| where DegradationPct > 20
| order by DegradationPct desc
```

## End-to-end tracing

Everything in one operation:

```kusto
union AppRequests, AppDependencies, AppTraces, AppExceptions
| where OperationId == "<operation id>"
| project TimeGenerated, Type, AppRoleName, Name, ResultCode, DurationMs, Message, ExceptionType, OuterMessage
| order by TimeGenerated asc
```

Every operation that hit a given exception:

```kusto
let ops = AppExceptions
| where TimeGenerated > ago(1h)
| where ExceptionType == "<type>"
| distinct OperationId;
union AppRequests, AppDependencies, AppTraces, AppExceptions
| where OperationId in (ops)
| project TimeGenerated, Type, AppRoleName, Name, ResultCode, DurationMs, Message, OuterMessage
| order by TimeGenerated asc
| take 200
```

`OperationId` correlates across services within one operation. `Id` and `ParentId` describe the span
hierarchy.

## Trends and baselines

When did it start, and which version was deployed then:

```kusto
AppExceptions
| where TimeGenerated > ago(3d)
| where AppRoleName == "<service>"
| summarize Count=count() by bin(TimeGenerated, 1h), AppVersion
| order by TimeGenerated asc
```

Today versus the same day last week:

```kusto
let today = AppExceptions | where TimeGenerated > ago(24h) | summarize Today=count() by AppRoleName;
let lastWeek = AppExceptions | where TimeGenerated between (ago(8d) .. ago(7d)) | summarize LastWeek=count() by AppRoleName;
today
| join kind=fullouter lastWeek on AppRoleName
| extend Change=iff(LastWeek > 0, round(100.0 * (Today - LastWeek) / LastWeek, 2), 100.0)
| order by Change desc
```

Spikes against the average of the previous day:

```kusto
let recent = AppExceptions | where TimeGenerated > ago(4h) | summarize Recent=count() by ExceptionType, AppRoleName;
let baseline = AppExceptions | where TimeGenerated between (ago(28h) .. ago(4h)) | summarize Base=count() by ExceptionType, AppRoleName | extend PerFourHours=Base / 6.0;
recent
| join kind=inner baseline on ExceptionType, AppRoleName
| extend Spike=round(Recent / PerFourHours, 2)
| where Spike > 3
| order by Spike desc
```
