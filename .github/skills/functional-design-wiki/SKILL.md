---
name: functional-design-wiki
description: >-
  Look up the functional design (desired behaviour, business rules, processes, messages, screens,
  validations) in an Azure DevOps wiki, and cite the exact pages. Use for functional questions such
  as "how should this work", and during refinement to check each change in a backlog item against
  the documented design. Triggers on 'functional design', 'desired behaviour', 'business rule',
  'check the wiki', 'functional specification', or when a backlog item must be verified
  functionally.
---

# Functional design wiki

Look up desired behaviour in the functional design instead of deriving it from the code. The code
shows what the system *does*; the design shows what it *should* do. Refinement needs both.

## Configuration

Values come from the *Azure DevOps context* section in `.github/copilot-instructions.md`: organization
URL, project, wiki and functional design root. Pass them as parameters, or set them once per shell:

```powershell
$env:AZDO_ORG_URL = 'https://dev.azure.com/<org>'; $env:AZDO_PROJECT = '<project>'; $env:AZDO_WIKI = '<wiki>'; $env:AZDO_FD_ROOT = '/<Functional-Design>'
```

If the functional design lives in the repository instead (for example `docs/functional-design/`),
skip the script and search and read those files directly. The rest of this skill still applies.

## Workflow: progressive disclosure

A functional design is often hundreds of pages. Never load the whole tree.

**1. Search — paths only, cheap:**

```powershell
./.github/skills/functional-design-wiki/scripts/Get-FunctionalDesign.ps1 -Query '<term>'
./.github/skills/functional-design-wiki/scripts/Get-FunctionalDesign.ps1 -Section '<top-level folder>' -Query '<term>'
```

Pick the one to three most relevant pages.

**2. Read only those pages:**

```powershell
./.github/skills/functional-design-wiki/scripts/Get-FunctionalDesign.ps1 -Path '<part of page path>'
```

`-Path` matches every page whose path contains the text, so make it specific.

## Using it during refinement

For each change a backlog item introduces, record one verdict:

| Verdict | Meaning | What the refiner does |
|---|---|---|
| ✅ Aligned | The design describes this behaviour | Cite the page |
| ➕ Extends | New behaviour the design does not cover | Add an acceptance criterion and a documentation task to update the design |
| ⚠️ Conflicts | The change contradicts the design | Ask for explicit confirmation before continuing |
| ❓ Unclear | The design is silent or ambiguous | Record an open point |

## Citing sources (required)

End every answer based on the design with a `## Sources` section that links to the **exact** pages
read — never to the wiki root or a parent folder:

```markdown
## Sources
- [Orders/Cancel order/Processes](<the Url returned by the script>)
```

- Copy the URL the script returns; never construct or shorten one.
- List only pages you actually read.
- When a finding rests on a specific table or rule on a page, name it next to the link.

## Tips

- Search with functional terms from the backlog item (process, message or screen names), not with
  class names.
- Process pages often have sub-pages for processes, messages, screens, non-functionals and design
  decisions. The design-decisions page explains the *why*.
- Some pages hold only a diagram and return empty text; read the neighbouring process page instead.
- Add `-OutputFormat json` for machine-readable output.

## Prerequisites

Azure CLI with the `azure-devops` extension, logged in with `az login`.
