# Resources per environment

Fill this in for your platform. The Azure Issue Investigator reads it to find the right workspace;
without it, the agent has to ask for every name.

## Environments

| Environment | Subscription | Log Analytics workspace | Resource group |
|---|---|---|---|
| Development | `<subscription>` | `<workspace-name>` | `<resource-group>` |
| Test | `<subscription>` | `<workspace-name>` | `<resource-group>` |
| Acceptance | `<subscription>` | `<workspace-name>` | `<resource-group>` |
| Production | `<subscription>` | `<workspace-name>` | `<resource-group>` |

If your names follow a pattern, write the pattern down as well — it lets the agent derive a name
you forgot to list:

```
Workspace:      <prefix>monitoring-<env>-<region>-la
Resource group: <prefix>hub-<env>-<region>-rg
```

## Services

`AppRoleName` in the telemetry is usually the name of the function app or web app. List every
service so the agent can go from a functional name ("the order API") to the value to filter on.

| Service (functional name) | Component or team | Type | `AppRoleName` |
|---|---|---|---|
| `<Order API>` | `<Orders>` | Web app | `<app name>` |
| `<Order processing>` | `<Orders>` | Function app | `<app name>` |

## Messaging

| Topic or queue | Publisher | Subscribers |
|---|---|---|
| `<topic>` | `<service>` | `<service>, <service>` |
