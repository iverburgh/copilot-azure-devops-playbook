---
name: path-filter-sync
description: >-
  Keep Azure DevOps pipeline path filters in sync with the project dependency graph. Use whenever a
  ProjectReference is added or removed, or a project is moved: both the YAML trigger paths of every
  affected pipeline and the build validation path filters in the branch policy must then be updated.
  Triggers on 'path filter', 'trigger paths', 'ProjectReference added', 'ProjectReference removed',
  'pipeline did not run', 'build validation did not trigger'.
---

# Path filter sync

A pipeline that builds one app should run when anything that app depends on changes — and only then.
Path filters make that possible, but they do not follow the dependency graph by themselves. Add a
project reference without updating the filters, and a change in the referenced project ships without
the app's pipeline ever running.

## The rule

The path filters of an app's pipeline contain:

- the folder of every project in the **full, recursive** `ProjectReference` graph of the published
  project;
- the folder of every **test project** that references one of those projects.

There are **two** filters per app, and both must match:

| Filter | Where | Who changes it |
|---|---|---|
| YAML trigger paths | `trigger.paths.include` in the app's pipeline YAML | The agent may edit it |
| Build validation path filter | The branch policy on the integration branch | **Only a person.** The agent advises the exact value and never changes the policy |

Branch policies are protected configuration: see the guardrail in `copilot-instructions.md`.

## Workflow

### 1. Find the affected apps

With a validator script in your repository, run it. Without one, walk the graph offline:

```powershell
dotnet list src/Orders/Api/Orders.Api.csproj reference
```

Repeat for every reference until no new project appears. Then find the test projects that reference
any project in the graph:

```powershell
Get-ChildItem tests -Recurse -Filter *.csproj | Select-String -Pattern 'Orders\.Domain\.csproj' -List | Select-Object Path
```

### 2. Update the YAML trigger paths

- Add the project folders with forward slashes, in single quotes, with `/**`:
  `- 'src/Shared/Messaging/**'`.
- Put each new path next to the dependency that pulls it in, so a reader sees why it is there.
- Add the test project folders too.
- When a reference was removed, remove the paths that no other project in the graph still needs.
- Before replacing a block of YAML, check that the anchor text occurs exactly once in the file.

### 3. Advise the build validation path filter

Give the person who manages policies the complete new value, and where to set it: **Repos → Branches →
the integration branch → Branch policies → Build validation → the app's pipeline → Path filter**.

The format differs from the YAML:

| | YAML trigger paths | Branch policy path filter |
|---|---|---|
| Start | Relative to the repository root | Must start with `/` or a wildcard |
| Separator | One path per list item | `;` between paths |
| Exclude | `exclude:` list | Prefix the path with `!` |
| Example | `'src/Orders/**'` | `/src/Orders/*` |

Example value: `/src/Orders/*;/src/Shared/Messaging/*;/tests/Orders.ComponentTests/*`

Use a single `*`, as in the documented examples: `/WebApp/*` already covers everything under
`/WebApp`, including subfolders. Filters apply left to right, so an exclude only works after the
include it narrows (`/WebApp/*;!/WebApp/Tests/*`). See
[path filters in branch policies](https://learn.microsoft.com/azure/devops/repos/git/branch-policies#path-filters).

To find which policy belongs to which pipeline, look up the build definition ID by its YAML path (the
`yamlFilename` filter of the Definitions - List REST call):

```powershell
$defs = az devops invoke --area build --resource definitions --route-parameters project=<project> --query-parameters yamlFilename=pipelines/orders.yml includeAllProperties=true --org <org-url> --output json | ConvertFrom-Json; $defs.value | Select-Object id, name
```

Then compare with the build validation policies:

```powershell
az repos policy list --org <org-url> --project <project> --branch <integration> --query "[?type.displayName=='Build'].{id:id, definition:settings.buildDefinitionId, filter:settings.filenamePatterns}" --output json
```

These commands only read. Changing the policy is for a person, after review.

### 4. Verify

Run the validator again, if there is one, and re-queue the validation build on the pull request.

## Pitfalls

- **Fixing only the YAML.** The CI trigger then runs, but the pull request validation still does not.
- **Forgetting test projects.** A change to a test project should run its pipeline too.
- **Indirect references.** A shared contracts project can pull an app into the graph that you did not
  expect. Walk the whole graph, not only direct references.
- **Copying YAML syntax into the policy.** `**` and relative paths belong in the YAML. Keep the policy
  value to the format above: absolute paths starting with `/`, a single `*`, separated by `;`.

A small validation pipeline or script that walks the graph and compares it with both filters stops
this from drifting. Consider adding one when you have more than a few apps.
