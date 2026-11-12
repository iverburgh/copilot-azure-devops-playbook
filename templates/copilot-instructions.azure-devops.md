<!--
Paste the sections below into your repository's .github/copilot-instructions.md and replace every
<placeholder>. The agents and skills in this playbook read these values instead of hardcoding an
organization, so this is the one place you configure them.
-->

## Azure DevOps context

| Setting | Value |
|---|---|
| Organization URL | `https://dev.azure.com/<org>` |
| Project | `<project>` |
| Repository | `<repository>` |
| Integration branch (pull request target) | `<development>` |
| Backlog item type | `Product Backlog Item` |
| Default area path | `<project>\<team>` |
| Wiki | `<wiki-name>` |
| Functional design root (wiki path) | `/<Functional-Design>` |
| Architecture decision records | `wiki:/<Architecture-Decision-Records>` or `repo:docs/adr` |
| Monitoring resources | `.github/skills/azure-log-analytics/references/resources.md` |

- Pull requests are always created as drafts: `az repos pr create --draft true`.
- PR title format: `<Type> #<WorkItemId>: <short description>`, where Type is one of
  Feature, Fix, Refactor, Test, Docs, Chore.

## Critical rules

- **Branch policies are protected configuration.** Never create, update, delete, enable, disable,
  or broaden Azure DevOps branch policies or their path filters unless the user explicitly requests
  that exact policy change in the current request. Read-only inspection is allowed; a request to
  run checks, update a PR, or change pipeline YAML is not permission to change policies. If policy
  changes seem necessary, explain the proposed change and wait for explicit approval.
- **Never commit secrets.** Configuration comes from `<your configuration store>` and secrets from
  `<your secret store>`.
- **Never edit generated files.** `<list them, for example generated pipeline variables, migration
  bundles, API clients>`. Change the source they are generated from.
- **Always call `SaveChangesAsync`** after changing an aggregate; domain events are dispatched there.
  <Remove this rule if your solution dispatches events differently.>

## File changes

- Change files with the edit and create tools, not with shell commands such as `Set-Content`,
  `Out-File`, `Add-Content` or output redirection.
- Use the shell for build, test, git, search and diagnostics only.

## Build and test

- Backend build: `<command, for example dotnet build path/to/Project.csproj>`
- Backend tests: `<command>`
- Frontend unit tests: `<command, for example npm test>`
- Frontend component tests: `<command, for example npx playwright test>`
- Database project build: `<command, if any>`

Never build or test the whole solution when a project-scoped command exists.

Load the `dotnet-build` skill before any `dotnet build` or `dotnet test`: it keeps the output short
and shows only what failed. Builds can take minutes; never cancel one, wait for it to finish.

## Instruction files (active by path)

| Path | Instructions |
|---|---|
| `src/**, tests/**` | `backend.instructions.md` |
| `src/**/Domain/**` | `domain-layer.instructions.md` |
| `src/**/Application/**` | `application-layer.instructions.md` |
| `src/**/Infrastructure/**` | `infrastructure.instructions.md` |
| `src/**/Database/**/*.sql` | `database.instructions.md` |
| `tests/**, **/*Tests/**` | `dotnet-tests.instructions.md` |
| `tests/Integration/**` | `integration-tests.instructions.md` |
| `ui/**` | `frontend.instructions.md` |
| `ui/test/component/**` | `frontend-component-tests.instructions.md` |
| `**/AppConfiguration.FeatureFlags.json, src/**, ui/**` | `feature-flags.instructions.md` |
| `infra/**, pipelines/**` | `platform.instructions.md` |
| `**/*.cs` | `csharp.instructions.md` |
| `**/*.ps1, **/*.psm1` | `powershell.instructions.md`, `powershell-scripts.instructions.md` |
| `**/*.Tests.ps1` | `powershell-pester-5.instructions.md` |
| `**/azure-pipelines*.yml` | `azure-devops-pipelines.instructions.md` |
| on demand | `pull-requests.instructions.md` |

## Repository layout

The specialist agents decide ownership by path. Keep this summary in sync with the mapping table in
`.github/skills/specialist-routing/SKILL.md` and with the `applyTo` globs of the instruction files.

```
<src/.../Domain>          Backend Developer
<src/.../Data>            Database Engineer
<src/.../ui>              Frontend Developer
<infra>, <pipelines>      Platform Engineer
<tests>                   Backend Tester / Frontend Tester
```

## Runbooks (optional)

<!-- One entry per agent-guided runbook skill. See docs/agentic-runbooks.md in the playbook. -->

When the user wants to <restore the orders database> — recognisable by phrases such as
*"<start the restore>"* or *"<restore orders database>"* — load
`.github/skills/<restore-orders-database>/SKILL.md` and follow it. Ask first which environment;
never assume a default, the current `az` context or an earlier conversation, and run nothing, not
even a dry-run, before the user has named it. Change nothing without an explicit yes, and never
pass `-Force` or `-Yes` to the script.
