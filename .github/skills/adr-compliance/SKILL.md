---
name: adr-compliance
description: >-
  Check a backlog item, a design or a code change against the architecture decision records (ADRs),
  kept in an Azure DevOps wiki or in the repository. Use during refinement to spot changes that need
  a new ADR or conflict with an existing one, and during review for ADR compliance. Triggers on
  'ADR', 'architecture decision', 'architecture review', 'ADR compliance', 'check against ADRs'.
---

# ADR compliance

Architecture decision records capture decisions that are expensive to reverse. A change that
silently contradicts one creates drift; a change that makes a new decision without recording it
creates the next surprise. This skill catches both — preferably during refinement, before any code
exists.

## Configuration

The ADR location comes from the *Azure DevOps context* section in `.github/copilot-instructions.md`:
either `wiki:/<path>` or `repo:<folder>`.

```powershell
# Wiki
$env:AZDO_ORG_URL = 'https://dev.azure.com/<org>'; $env:AZDO_PROJECT = '<project>'; $env:AZDO_WIKI = '<wiki>'; $env:AZDO_ADR_ROOT = '/<Architecture-Decision-Records>'
```

## Workflow

### 1. Get the index

```powershell
./.github/skills/adr-compliance/scripts/Get-Adrs.ps1                      # wiki
./.github/skills/adr-compliance/scripts/Get-Adrs.ps1 -RepoPath docs/adr   # repository
```

### 2. Read the relevant ADRs

Select by title first, then read only those:

```powershell
./.github/skills/adr-compliance/scripts/Get-Adrs.ps1 -Number 3, 11
./.github/skills/adr-compliance/scripts/Get-Adrs.ps1 -Query 'messaging'
```

Read an ADR fully before judging: the *context* and *consequences* sections often matter more than
the decision line. Ignore ADRs with status *Superseded* or *Deprecated*, except to follow the link to
their successor.

### 3. Judge each change

| Verdict | Meaning | Action |
|---|---|---|
| ✅ Compliant | The change follows the ADR | Cite it |
| 🆕 New decision | The change makes an architectural choice no ADR covers | Add a requirement to write an ADR, before or with the change |
| ⚠️ Needs attention | Compliant in letter, but the rationale no longer holds, or an exception is undocumented | Explain and recommend |
| ❌ Violation | The change contradicts the ADR | During refinement: ask for explicit confirmation — comply, or supersede the ADR (then add a task to write the superseding ADR). During review: report with location and remediation |

What counts as an architectural choice: a new external dependency or service, a new communication
pattern between components, a new way of storing or sharing data, a new cross-cutting mechanism
(authentication, retries, logging), or a change in deployment topology.

## Output format

```markdown
## ADR check

| Change | ADR | Verdict | Action |
|---|---|---|---|
| ... | ADR-011 | ✅ Compliant | — |
| ... | — | 🆕 New decision | Write ADR: "<decision to record>" |
| ... | ADR-004 | ❌ Violation | Confirm: comply or supersede |

## Sources
- [ADR-011: <title>](<link returned by the script>)
```

## Prerequisites

Wiki mode: Azure CLI with the `azure-devops` extension, logged in with `az login`. Repository mode:
nothing.
