---
description: 'Platform rules for Bicep and Azure DevOps: generated files, configuration and Key Vault references, function binding expressions, new resources, triggers and known deployment quirks.'
applyTo: 'infra/**, pipelines/**'
---

# Platform

## Critical rules

- **Never edit generated files by hand** — change their source and regenerate. Mark every generated
  file with a first-line header such as `# AUTO-GENERATED — DO NOT EDIT`, so both people and agents
  can recognise it.
- If pipeline variables are generated from a shared source file, a variable lives in **one** place:
  environment-independent values in the shared file, environment-specific values in the
  per-environment file. Document which one wins when a key appears in both.
- Secrets never appear in plain text — only as vault references.
- Every service has a health check endpoint.
- Azure Monitor alert descriptions are limited to 200 characters by ARM; keep them under 180 to leave
  room for interpolated values.

## Configuration store and Key Vault

```json
{ "key": "Orders:MaxLines", "value": "100", "label": "dev" }

{ "key": "Orders:PaymentApiKey", "value": "{\"uri\":\"https://<vault>.vault.azure.net/secrets/payment-api-key\"}", "contentType": "application/vnd.microsoft.appconfig.keyvaultref+json;charset=utf-8" }
```

Every configuration key read by code must exist for every environment.

## Azure Functions `%...%` binding expressions

Function bindings resolve `%Section:Property%` from the **function app's application settings**,
not from a configuration store. Without a mapping, a timer trigger such as
`[TimerTrigger("%CleanupOptions:Schedule%")]` does not start, and the function is disabled with
`'%CleanupOptions:Schedule%' does not resolve to a value`.

When adding options used in a binding expression:

1. Add the value to the configuration store.
2. Map it to an application setting in the infrastructure code (`CleanupOptions__Schedule`), for every
   property the binding uses.
3. Add the key to the local settings template, with a developer-friendly default.

## New Azure resource

1. Check for an existing shared type before defining a new one.
2. Export reusable types with `@export()`:
   `type storageAccount = resourceInput<'Microsoft.Storage/storageAccounts@<api-version>'>`.
3. Add the resource to the service's `main.bicep`.
4. Add parameters to **every** environment's `.bicepparam`.
5. Add configuration keys, with vault references for secrets.
6. Grant the service identity the least-privilege role it needs.

## Pipelines

- Pipelines use path-based triggers so only affected services build. When a project gains a new
  dependency, add that dependency's path to the trigger **and** to the pull request build validation
  policy; otherwise changes to it stop being validated.
- Local development infrastructure (for example per-developer messaging topics and subscriptions,
  including filters) must change together with the shared infrastructure code, or local runs drift
  from reality.

## Known deployment quirk: `existing` properties read at nested deployment start

A module parameter that reads a property of an `existing` resource — for example
`storage.properties.privateEndpointConnections` to approve pending private endpoint connections — is
evaluated when the nested deployment **starts**. A connection created as a side effect earlier in the
same deployment is not in that list, and `dependsOn` does not change this.

The module then approves nothing and reports **success**; the connection stays pending until the next
run. Either accept that new environments need two deployments, or approve in a separate step that
runs after the first deployment. Note that an empty result is indistinguishable from "nothing to do".
