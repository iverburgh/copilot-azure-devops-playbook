# Third-party notices

Some files in this repository come from
[github/awesome-copilot](https://github.com/github/awesome-copilot).

## Included unmodified

These are verbatim copies, so that every workflow works out of the box and so that you can diff them
against upstream to pick up improvements.

| File | Upstream path |
|---|---|
| [.github/agents/research-technical-spike.agent.md](.github/agents/research-technical-spike.agent.md) | `agents/research-technical-spike.agent.md` |
| [.github/skills/create-technical-spike/](.github/skills/create-technical-spike/SKILL.md) | `skills/create-technical-spike/` |
| [.github/skills/azure-devops-cli/](.github/skills/azure-devops-cli/SKILL.md) | `skills/azure-devops-cli/` (SKILL.md and all `references/`) |
| [.github/instructions/azure-devops-pipelines.instructions.md](.github/instructions/azure-devops-pipelines.instructions.md) | `instructions/azure-devops-pipelines.instructions.md` |
| [.github/instructions/powershell.instructions.md](.github/instructions/powershell.instructions.md) | `instructions/powershell.instructions.md` |

## Derived from awesome-copilot

These started from an awesome-copilot file and were changed substantially. Each carries a comment at
the top naming its origin.

| File | Based on | Changes |
|---|---|---|
| [.github/instructions/csharp.instructions.md](.github/instructions/csharp.instructions.md) | `instructions/csharp.instructions.md` | Rewritten: Clean Code comment rules, nullable flow attributes, CA1068, exception constructors |
| [.github/instructions/powershell-pester-5.instructions.md](.github/instructions/powershell-pester-5.instructions.md) | `instructions/powershell-pester-5.instructions.md` (upstream now `powershell-pester-6`) | Condensed; mocking guidance for CLI and REST calls |

[.github/instructions/powershell-scripts.instructions.md](.github/instructions/powershell-scripts.instructions.md)
is original to this repository and adds to the unmodified upstream PowerShell instructions instead of
changing them.

Pinned upstream commit: `6c4d33b9cfca967a28bb2962ef4d55e4a384c88c`

To update, download the same paths from a newer commit, or install them with the GitHub CLI:

```powershell
gh skills install github/awesome-copilot azure-devops-cli
gh skills install github/awesome-copilot create-technical-spike
```

Everything else — the Azure DevOps write patterns, the REP protocol, the specialist agents, the
investigation agents and the remaining instruction files — is original to this repository and
covered by its own [LICENSE](LICENSE).

## awesome-copilot license

```
MIT License

Copyright GitHub, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
