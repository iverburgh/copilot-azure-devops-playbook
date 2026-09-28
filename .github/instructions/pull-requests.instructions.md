---
description: 'Pull request, branch and commit conventions for Azure DevOps: draft-first, title format, description template within the 4000-character limit, work item linking.'
---

# Pull requests

## Creating a pull request

- **Always create it as a draft**: `az repos pr create ... --draft true`. Review it yourself, then
  publish it.
- Target the integration branch from the *Azure DevOps context* in `copilot-instructions.md`, never
  the release branch directly.
- Link the work item: `--work-items <id>`, or put `#<id>` in the title.
- Only create a pull request when asked to.

```powershell
az repos pr create --org https://dev.azure.com/<org> --project <project> --repository <repository> --source-branch feature/1234-order-remarks --target-branch <integration-branch> --title 'Feature #1234: Accept remarks on orders' --description (Get-Content pr-description.md -Raw) --work-items 1234 --draft true
```

## Branch names

| Prefix | For |
|---|---|
| `feature/<id>-<short-name>` | New behaviour |
| `fix/<id>-<short-name>` | Bug fixes |
| `refactor/<id>-<short-name>` | Structural changes |
| `test/<id>-<short-name>` | Test-only changes |
| `docs/<short-name>` | Documentation |
| `chore/<short-name>` | Build, dependencies, tooling |

## Title

```
<Type> #<WorkItemId>: <short description>
```

Type is one of `Feature`, `Fix`, `Refactor`, `Test`, `Docs`, `Chore`. Imperative mood, at most about
70 characters. Example: `Fix #1234: Release reserved stock when an order is cancelled`.

## Description

Azure DevOps rejects descriptions longer than **4000 characters**. Aim for about 2000.

Describe *why* and *what changed in behaviour*, grouped by component — not a list of files. Report
only verification you have actually seen. Leave out empty sections.

```markdown
## Problem
<why this change is needed>

## Solution
<the approach, and why this one>

## Changes
- **<component>**: <what changed>
- **Tests**: <what is proven, and how>

## Verification
- <tests run and their result>

## Acceptance criteria
- ✅ <criterion from the work item>

## Notes
<optional: trade-offs, follow-ups, deployment order>
```

## Commits

```
<Type> #<WorkItemId>: <short description>

- <detail>
- <detail>
```

- First line at most 72 characters, imperative mood ("Fix", not "Fixed").
- An empty line between subject and body.
