---
description: 'Additions to the awesome-copilot PowerShell guidelines for scripts run by people and agents: script structure, safety switches and PowerShell 5.1/7 compatibility.'
applyTo: '**/*.ps1, **/*.psm1'
---

# PowerShell scripts

These rules complement `powershell.instructions.md` (from awesome-copilot). Where they differ, these
win: they come from scripts that coding agents run and edit every day.

## Structure

- Use `begin`/`process`/`end` blocks **only** in functions that accept pipeline input
  (`ValueFromPipeline` or `ValueFromPipelineByPropertyName`). A standalone script or a function
  without pipeline parameters puts its code directly in the body.
- Start scripts with `[CmdletBinding()]`, a `param()` block, `Set-StrictMode -Version Latest` and
  `$ErrorActionPreference = 'Stop'`.
- Put comment-based help (`.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`) at the top of every
  script that someone else will run.

## Safety

- A script that changes anything outside the working copy — work items, wiki pages, cloud
  resources, databases — **defaults to a dry run** and only writes with an explicit `-Execute`
  switch. The dry run shows exactly what would change and validates its assumptions first (for
  example: every block to replace occurs exactly once).
- Never add a switch that skips confirmations (`-Force`, `-Yes`) to a script an agent is meant to
  run.
- Read back what you wrote and verify it; several Azure DevOps APIs report success while storing
  something else.
- Never print secrets or tokens. Print lengths or the first characters when you need to prove a
  value is present.

## Output

- Return objects; use `Write-Verbose` and `Write-Warning` for progress. `Write-Host` only for
  interactive UI text.
- Keep output compact: an agent pays for every line in its context window. Print summaries and the
  first N items, with a way to get the rest.

## Commands for agents

- Terminal commands that an agent runs are single lines chained with `;`. Anything longer belongs in
  a `.ps1` file.
- Never pipe an interactive command through a filter: it hides the prompt.

## PowerShell 5.1 and 7

- Prefer PowerShell 7. When a script must also run in Windows PowerShell 5.1:
  - no `??`, `?:` or `-Parallel`;
  - `Invoke-RestMethod -ResponseHeadersVariable` does not exist; use `Invoke-WebRequest` and
    `.Headers`;
  - `Invoke-WebRequest` needs `-UseBasicParsing`;
  - `.Content` is a string in 7 but may be bytes in 5.1 — check the type before decoding.
- Read files with an explicit encoding: `[IO.File]::ReadAllText($path, [Text.UTF8Encoding]::new($false))`.
- Inside a method call, wrap operator expressions in parentheses:
  `[uri]::UnescapeDataString(($path -replace '-', ' '))`. Without them the comma after `-replace`
  is read as an argument separator.
