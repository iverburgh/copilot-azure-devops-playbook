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

## Build and test

- Backend build: `<command, for example dotnet build path/to/Project.csproj>`
- Backend tests: `<command>`
- Frontend unit tests: `<command, for example npm test>`
- Frontend component tests: `<command, for example npx playwright test>`
- Database project build: `<command, if any>`

Never build or test the whole solution when a project-scoped command exists.

## Instruction files (active by path)

| Path | Instructions |
|---|---|
| `src/**, tests/**` | `backend.instructions.md` |
| `src/**/Domain/**` | `domain-layer.instructions.md` |
| `src/**/Application/**` | `application-layer.instructions.md` |
| `src/**/Infrastructure/**` | `infrastructure.instructions.md` |
| `src/**/Database/**/*.sql` | `database.instructions.md` |
| `tests/**` | `component-tests.instructions.md` |
| `tests/Integration/**` | `integration-tests.instructions.md` |
| `ui/**` | `frontend.instructions.md` |
| `ui/test/component/**` | `frontend-component-tests.instructions.md` |
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
