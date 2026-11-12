# Copilot CLI and the Copilot app

The agents, skills and instructions in this playbook were written in VS Code, but most of the team
now runs them from the terminal with GitHub Copilot CLI, or from the GitHub Copilot app, which runs
one CLI session per worktree. The same files work there. This page covers the differences and the
three repository-level files that only matter outside VS Code.

## What carries over

| Customization | VS Code | Copilot CLI and app |
|---|---|---|
| `copilot-instructions.md` and `*.instructions.md` | ✓ | ✓ |
| Custom agents (`.github/agents/`) | ✓ | ✓ — pick one with `/agent` |
| Skills (`.github/skills/`) | ✓ | ✓ — loaded when their `description` matches the task |
| Prompt files (`.github/prompts/`) | ✓ | ✗ |

Source: the support matrix in the
[customization cheat sheet](https://docs.github.com/en/copilot/reference/customization-cheat-sheet).

Prompt files are the one gap. In the CLI, select the agent the prompt would have used and type the
request yourself, for example `/agent` → *Functional Reviewer* → *"review my changes"*. Because the
prompts in this repository are thin wrappers around an agent or skill, nothing is lost.

## Repository-level configuration

Three optional files configure the CLI and the app for everyone who clones the repository. Examples
are in [templates/](../templates/); copy them into `.github/` (renaming where shown) and fill in the
placeholders. They sit outside `.github/` here so they do nothing in this repository.

| Template | Copy to | Purpose |
|---|---|---|
| [copilot-settings.json](../templates/copilot-settings.json) | `.github/copilot/settings.json` | Make a team plugin marketplace available and enable plugins by default |
| [lsp.json](../templates/lsp.json) | `.github/lsp.json` | Give the agent a language server for precise code navigation |
| [github-app.yml](../templates/github-app.yml) | `.github/github-app.yml` | Run setup scripts when the app creates a session |

### Plugins from a team marketplace

A plugin bundles agents, skills and other customizations so they can be installed in more than one
repository. A marketplace is a repository with a `.github/plugin/marketplace.json` catalog that lists
the plugins. Customizations that apply to one repository belong in that repository's `.github/`;
customizations that several repositories share are easier to maintain as plugins in one
marketplace.

`.github/copilot/settings.json` declares the marketplace under `extraKnownMarketplaces` and turns
plugins on by default under `enabledPlugins`, keyed as `plugin-name@marketplace-name`. A marketplace
in GitHub uses `"source": "github"` with `"repo": "OWNER/REPO"`; a marketplace hosted elsewhere, such
as Azure Repos, uses `"source": "git"` with a `url`, as in the template.

Things to know:

- Everyone who uses the marketplace needs read access to its repository.
- Contributors can turn off a repository default in `.github/copilot/settings.local.json` with a
  `false` entry. Never commit that file; add it to `.gitignore`.
- Copilot in the cloud reads the same two keys from the repository settings and has no local
  override.
- Only a fixed set of keys is read from the repository settings file; anything else is silently
  ignored.

Sources:
[repository settings](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-config-dir-reference#repository-settings-githubcopilotsettingsjson),
[finding and installing plugins](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/plugins-finding-installing),
[creating a plugin marketplace](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/create-and-share-plugin-marketplaces),
[supported source types](https://docs.github.com/en/copilot/reference/enterprise-administrators/enterprise-managed-settings).

### A language server for C#

Without a language server, the agent finds symbols by searching text: slower, more tokens, and
easy to miss an overload or an interface implementation. With one, it can go to a definition, find
references and list the callers of a method.

1. Every developer installs the server once:

   ```powershell
   dotnet tool install --global csharp-ls
   ```

2. Commit [lsp.json](../templates/lsp.json) as `.github/lsp.json`, pointing `--solution` at your
   solution file. That pins the solution when the repository holds more than one. Our monorepo uses
   a `.slnx` solution file, and a current `csharp-ls` loads it.
3. In a running session, `/lsp reload` picks up a changed configuration.

A user-level `~/.copilot/lsp-config.json` uses the same format and applies to all your projects.

Sources:
[adding LSP servers](https://docs.github.com/en/copilot/how-tos/copilot-cli/set-up-copilot-cli/add-lsp-servers),
[csharp-ls](https://github.com/razzmatazz/csharp-language-server).

### Setup scripts in the Copilot app

The app creates a separate worktree for every session. `.github/github-app.yml` can hold
repository instructions for the app and scripts that run on `session.create` or `session.archive`,
or by hand. The template restores the local .NET tools and installs the Git hooks, so pre-commit
checks also run for commits made in a new session.

The app does not apply a repository configuration until you have reviewed and accepted it, and it
asks again after every change to the file, including whitespace. Scripts run with your GitHub
credentials in their environment, so review every command before accepting.

Source:
[repository configuration for the Copilot app](https://docs.github.com/en/copilot/reference/github-copilot-app-reference/repository-configuration).

## Personal configuration

`~/.copilot` (or the folder in `COPILOT_HOME`) is your user level: `copilot-instructions.md`,
`instructions/`, `agents/` and `skills/` there apply to every repository you work in.

Put personal working preferences there, not in the repository. For example, *"Never commit or push;
I handle version control myself."* belongs in `~/.copilot/copilot-instructions.md`: it is true for
you, not for every contributor.

A personal agent with the same ID as a repository agent wins. That is handy for trying a change to
a shared agent before you open a pull request, and confusing if you forget the copy is there.

Sources:
[CLI configuration directory](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-config-dir-reference),
[custom agents for the CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/create-custom-agents-for-cli).
