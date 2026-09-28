# Getting started

What you need, in order, to use these agents in your own repository. Steps 1 to 3 take half an
hour; step 4 is where the real decisions are.

## 1. Check the prerequisites

- **VS Code with GitHub Copilot**, agent mode enabled. Custom agents, skills and prompt files are
  picked up from `.github/` automatically.
- **Azure CLI** with the DevOps extension: `az extension add --name azure-devops`.
- **Logged in**: `az login`. The scripts get their token with `az account get-access-token`, so no
  personal access token is needed and none expires on someone's last day.
- **PowerShell 7** for the scripts. Most commands also run in Windows PowerShell 5.1, but
  `ConvertFrom-Markdown` and a few response-handling details need 7.
- **Behind a TLS-inspecting proxy**: `$env:AZURE_CLI_DISABLE_CONNECTION_VERIFICATION = 'true'`.
- For the Azure Issue Investigator: read access (*Log Analytics Reader* or *Monitoring Reader*) on the
  workspaces you want to query.

## 2. Copy the files in

| From here | To your repository |
|---|---|
| `.github/agents/*` | `.github/agents/` |
| `.github/skills/*` | `.github/skills/` |
| `.github/instructions/*` | `.github/instructions/` — only the ones that match your stack |
| `.github/prompts/*` | `.github/prompts/` |
| `templates/copilot-instructions.azure-devops.md` | paste into `.github/copilot-instructions.md` |

Take only what you use. The dependencies between the parts:

| Part | Needs |
|---|---|
| PBI Refiner | skills `azure-devops-cli`, `azure-devops-rest-writes`, `functional-design-wiki`, `adr-compliance` |
| PBI Planner | skills `azure-devops-cli`, `azure-devops-rest-writes`, `rep-protocol`, `specialist-routing` |
| Specialists | skills `rep-protocol`, `specialist-routing` |
| Azure Issue Investigator | skill `azure-log-analytics` |
| PR Pipeline Analyzer | skill `azure-devops-pipeline-logs` |
| Technical spike research mode | skill `create-technical-spike` |
| `/pr-description` | `pull-requests.instructions.md` |

The path-specific instruction files are independent of the agents: every agent, and Copilot without
an agent, picks them up for the files it edits. See [instructions.md](instructions.md).

## 3. Fill in the configuration

Replace every `<placeholder>` in the block you pasted into `copilot-instructions.md`: organization,
project, integration branch, wiki, functional design root, ADR location, and your build and test
commands. The agents read these values instead of hardcoding them; when one is missing they ask.

Then fill in `.github/skills/azure-log-analytics/references/resources.md` with your environments,
workspaces and service names, if you want to use the Azure Issue Investigator.

Tip: `pwsh ./tools/Test-NoInternalReferences.ps1 -Path <your repo> -Placeholders` lists every
placeholder you have not replaced yet.

## 4. Map your repository to the specialists

Open `.github/skills/specialist-routing/SKILL.md` and replace the example path mapping with your
own layout. This table decides which specialist owns which paths, and therefore what each one may
touch. Worth deciding deliberately:

- **Do you need every specialist?** A backend-only repository can delete the frontend agents and
  their rows. A team without a separate database project can fold schema work into the Backend
  Developer.
- **Where do tests live?** If unit tests sit next to the code, the developer owns them and the tester
  reviews; if there is a separate test project, the tester can own it.
- **What counts as platform?** Pipelines, infrastructure as code, configuration files — and
  generated files that must never be edited by hand. List those in `copilot-instructions.md`.

Then align the `applyTo` globs of the instruction files with the same layout, so the conventions
for a layer load exactly where its specialist works. The table in the template you pasted lists
them all.

## 5. Tell the agents where the design lives

The PBI Refiner checks items against the functional design and the ADRs. Point it at them:

- **In a wiki:** set the wiki name and root paths. Test with
  `./.github/skills/functional-design-wiki/scripts/Get-FunctionalDesign.ps1 -Query <term>` and
  `./.github/skills/adr-compliance/scripts/Get-Adrs.ps1`.
- **In the repository:** set the ADR location to `repo:docs/adr` (or your folder). The ADR script
  reads it with `-RepoPath`; the functional design skill tells the agent to read the files directly.
- **Nowhere yet:** the Refiner still works, and will propose documentation tasks for everything it
  cannot find — a reasonable way to start a design document.

## 6. Try it

Open Copilot Chat and run, in this order, on a small backlog item:

1. `/refine 1234`
2. `/breakdown-pbi 1234`
3. `/create-rep 1240` for one of the created tasks
4. `/implement-rep Backend Developer 1240`
5. `/pr-description`

Every step that writes to Azure DevOps asks for confirmation first.
