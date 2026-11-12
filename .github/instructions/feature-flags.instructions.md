---
description: 'Feature flag rules: naming, never renaming, initial values versus per-environment values, fail-closed checks, hiding menu and route, testing both paths and cleaning up.'
applyTo: '**/AppConfiguration.FeatureFlags.json, src/**, ui/**'
---

# Feature flags

Feature flags are stored in a configuration store (for example Azure App Configuration). Each app has
a flag file, `AppConfiguration.FeatureFlags.json`, that is imported during deployment. The
[azure-app-configuration-playbook](https://github.com/iverburgh/azure-app-configuration-playbook)
shows how such files are filled, validated, imported and rolled back.

Circuit breakers that switch processing on and off at runtime are a different mechanism and are not
covered here.

## Naming

Format: `{team}_{workitem}_{PascalCaseName}`, for example `payments_4711_SplitInvoices`.

- `team`: a short, lowercase team or area prefix agreed in your repository.
- `workitem`: the number of the backlog item that introduces the flag.
- `PascalCaseName`: what the flag switches on. No `Enabled`, `Toggle` or `Flag` suffix — every flag is
  a toggle.

A pattern to check names with: `^[a-z]+_\d+_[A-Z][A-Za-z0-9]*$`.

**If the team prefix or the work item number is unknown, ask.** Do not invent one.

## Never rename an existing flag

A renamed flag is a new flag. Its value in every environment starts over from the initial value in the
file, so a feature that was on in production turns off at the next deployment. Keep the existing name,
even when it does not follow the convention.

## Adding a flag

- A new flag starts with `"enabled": false`.
- Add it to the flag file of **every** app that reads it.
- The value in the file is only the initial value. After the first import, the value per environment
  is managed in the configuration store, not in the file.

## Reading a flag

- **No string literals.** Refer to flags through constants, in the backend and in the frontend, so a
  search finds every use and a typo is a compile error.
- **Fail closed.** A flag that cannot be read counts as off. Never default to on
  (`isEnabled ?? true`).
- In the frontend, hide **both** the menu item and the route. Hiding only the menu leaves the page
  reachable by URL.

## Testing

Test both paths — flag on and flag off — for as long as the flag exists. For .NET, see the toggle
section in `dotnet-tests.instructions.md`.

## Cleaning up

When a flag has been on everywhere long enough, remove it in one pull request: the flag from every
flag file, its constant, and the code branch that is no longer reachable, together with the tests for
that branch.
