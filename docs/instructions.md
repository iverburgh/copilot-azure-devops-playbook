# Instructions, skills, agents and prompts

Four kinds of customization, each loaded at a different moment. Knowing which is which explains
where a rule belongs.

| Kind | Location | Loaded | Holds |
|---|---|---|---|
| Repository instructions | `.github/copilot-instructions.md` | Always, in every chat | Facts about the repository: organization, branches, build commands, layout, hard rules |
| Path instructions | `.github/instructions/*.instructions.md` | Automatically, when a file matching `applyTo` is read or edited | Coding conventions for one layer or file type |
| Skills | `.github/skills/*/SKILL.md` | On demand, when the task matches the description | Procedures and knowledge, often with scripts |
| Agents | `.github/agents/*.agent.md` | When selected in the agent picker or started as a subagent | A role: goal, scope, workflow, output format |
| Prompts | `.github/prompts/*.prompt.md` | When you type `/<name>` (VS Code and Visual Studio; not Copilot CLI) | One reusable instruction, optionally bound to an agent |

Around these four sit a few configuration files that decide what is available rather than what
the agent is told:

| File | Holds |
|---|---|
| `.github/copilot/settings.json` | Plugin marketplaces and plugins enabled by default for the repository |
| `.github/lsp.json` | Language servers the CLI uses for precise code navigation |
| `.github/github-app.yml` | Instructions and setup scripts for the Copilot app |
| `~/.copilot/` | Your personal instructions, agents and skills, for every repository |

See [copilot-cli-and-app.md](copilot-cli-and-app.md) for all four, with templates.

In VS Code's Local sessions, a path instruction with a `description` can also be loaded when the
task matches that description, separately from `applyTo`. And a prompt that always needs one
instruction file can reference it with a Markdown link or `#file:`, so it does not depend on which
files happen to be open.

## How they work together

Take `/implement-rep Backend Developer 1240`:

1. The **prompt** loads the REP and starts the **Backend Developer agent**.
2. The agent loads the **`rep-protocol` skill** to validate the REP and the
   **`specialist-routing` skill** to know which paths it owns.
3. The moment it opens `src/Orders/Domain/Order.cs`, the **domain-layer** and **C#** instructions load
   by themselves; when it writes a test in `tests/`, the **dotnet-tests** instructions do.
4. Throughout, **`copilot-instructions.md`** supplies the build commands and the organization.

The agent never mentions the instruction files. Conventions follow the file being edited, whichever
agent — or no agent at all — is editing it. That is why coding conventions belong in path
instructions and not in agents: a convention written into the Backend Developer is missing when
someone edits the same file without that agent.

## Where does a new rule go?

| The rule is about… | Put it in |
|---|---|
| The repository as a whole (branch names, build commands, "never edit X") | `copilot-instructions.md` |
| How code in one layer or file type is written | A path instruction |
| How to perform a procedure, especially with commands or scripts | A skill |
| What a role is responsible for and may touch | An agent |
| A request you type often | A prompt |

## The instruction files

The `applyTo` globs assume the example layout used throughout this playbook — `src/<Component>/Domain`,
`Application`, `Infrastructure`, `Database`, a `ui/` frontend, `infra/` and `pipelines/`, and
`tests/`. Change them to match yours.

| File | Applies to | What it adds |
|---|---|---|
| `backend.instructions.md` | `src/**, tests/**` | Build and test scope, API design, configuration, test pyramid |
| `domain-layer.instructions.md` | `src/**/Domain/**` | Value objects, entities, aggregates, domain events, domain services |
| `application-layer.instructions.md` | `src/**/Application/**` | Thin handlers, result types, integration events after commit |
| `infrastructure.instructions.md` | `src/**/Infrastructure/**` | EF Core configuration, the save pipeline, test providers |
| `database.instructions.md` | `src/**/Database/**/*.sql` | Changes that survive any deploy order, the three-PR column pattern, permission scripts, change data capture impact |
| `dotnet-tests.instructions.md` | `tests/**, **/*Tests/**` | All .NET unit and component tests: system boundary, `fixture.Arrange`/`fixture.Assert`, every contract value covered, every consequence asserted |
| `integration-tests.instructions.md` | `tests/Integration/**` | When to write them at all, scenario structure |
| `frontend.instructions.md` | `ui/**` | React and TypeScript structure, typing, forms, errors, linting |
| `feature-flags.instructions.md` | `**/AppConfiguration.FeatureFlags.json, src/**, ui/**` | Flag naming, never renaming, fail-closed checks, testing both paths, clean-up |
| `frontend-component-tests.instructions.md` | `ui/test/component/**` | File responsibilities, locator strategy, coverage levels |
| `platform.instructions.md` | `infra/**, pipelines/**` | Generated files, Key Vault references, function bindings, deployment quirks |
| `csharp.instructions.md` | `**/*.cs` | Language conventions, comments, nullability, cancellation |
| `powershell.instructions.md` | `**/*.ps1, **/*.psm1` | Cmdlet design (awesome-copilot, unmodified) |
| `powershell-scripts.instructions.md` | `**/*.ps1, **/*.psm1` | Dry-run by default, compact output, 5.1 compatibility |
| `powershell-pester-5.instructions.md` | `**/*.Tests.ps1` | Pester 5 structure and mocking |
| `azure-devops-pipelines.instructions.md` | `**/azure-pipelines*.yml` | Pipeline YAML practices (awesome-copilot, unmodified) |
| `pull-requests.instructions.md` | on demand | Draft-first, title format, description template, 4000-character limit |

The layer instructions describe one opinionated architecture: domain-driven design with thin
command and query handlers, EF Core and a declarative database project. If yours differs, keep the
parts that match and rewrite the rest — they are short on purpose.

## Keeping them useful

- **Short beats complete.** Path instructions are loaded into the context for every matching file.
  A rule nobody breaks does not need to be there.
- **Rules, not tutorials.** Write what to do and what never to do, with one example where the right
  shape is not obvious.
- **One source of truth.** When a rule exists in an instruction file, refer to it from prompts and
  agents instead of repeating it — `/pr-description` uses `pull-requests.instructions.md` for its
  template rather than carrying its own.
- **Add rules after mistakes.** The best instruction line is the one written the day after Copilot got
  something wrong.
