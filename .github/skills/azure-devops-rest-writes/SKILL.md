---
name: azure-devops-rest-writes
description: >-
  Write to Azure DevOps safely where the CLI silently loses data: HTML fields on work items
  (description, acceptance criteria), creating and linking child items, and updating pages in a code
  wiki. Always verify by reading back. Use whenever an agent creates or updates work items with rich
  text, or edits wiki pages. Triggers on 'update work item description', 'acceptance criteria',
  'create child tasks', 'publish to Azure DevOps', 'update wiki page'.
---

# Azure DevOps REST writes

The `azure-devops-cli` skill covers reading and most writing. This skill covers the writes where the
CLI fails **silently**: it reports success and stores something else. Every pattern here ends with a
read-back check, because none of these failures produce an error.

## Rule 1: never send HTML through the CLI

`az boards work-item create/update --description "<html>"` and `--fields "Field=<html>"` keep only
the text up to the **first newline**. The command returns a valid work item, so the damage only
shows when somebody opens it.

Use the CLI for fields without newlines (title, type, area, iteration), and the REST API for rich
text.

## Authentication

```powershell
$token = (az account get-access-token --resource '499b84ac-1321-427f-aa17-267ca6975798' --query accessToken -o tsv).Trim()
```

The GUID is the Azure DevOps resource ID; it is the same for every organization.

If a REST call returns an HTML page with status 200 instead of JSON, the token was not accepted.
Run `az login` again.

## Update HTML fields on a work item

```powershell
$org = 'https://dev.azure.com/<org>'; $id = <ID>
$headers = @{ Authorization = "Bearer $token"; 'Content-Type' = 'application/json-patch+json; charset=utf-8' }
$body = ConvertTo-Json -Compress -Depth 5 @(
    @{ op = 'add'; path = '/fields/System.Description'; value = $descriptionHtml }
    @{ op = 'add'; path = '/fields/Microsoft.VSTS.Common.AcceptanceCriteria'; value = $acceptanceHtml }
)
$r = Invoke-RestMethod -Uri "$org/_apis/wit/workitems/${id}?api-version=7.1" -Method Patch -Headers $headers -Body $body
"Description: $($r.fields.'System.Description'.Length)  Acceptance criteria: $($r.fields.'Microsoft.VSTS.Common.AcceptanceCriteria'.Length)"
```

- Send the body as a **string**. Never as a byte array.
- A length of 0 means the field was not stored: patch that field again on its own.
- Read the item back with a separate GET before reporting success.

Markdown to HTML: `(ConvertFrom-Markdown -InputObject $markdown).Html` in PowerShell 7 renders pipe
tables correctly.

### Azure DevOps rewrites your HTML

The stored HTML differs from what you sent — lengths change and a space is inserted before closing
tags (`<h3>Goal</h3>` comes back as `<h3>Goal </h3>`). Consequences:

- Never verify with an exact `.Contains()` on your own source string; use a regex such as
  `<h3>\s*Goal\s*</h3>`.
- For a second edit, GET the **stored** version first and replace inside that.
- For scripted edits, work with a `.ps1` file that has an `-Execute` switch: the default dry run
  checks that every block to replace occurs exactly once, and only `-Execute` writes.

## Create a child item and link it

```powershell
$org = 'https://dev.azure.com/<org>'; $project = '<project>'
$new = az boards work-item create --org $org --project $project --type 'Task' --title '[01] <title>' --area '<area path>' --output json | ConvertFrom-Json
az boards work-item relation add --id $new.id --relation-type parent --target-id <PARENT_ID> --org $org --output none
# then write the HTML fields with the PATCH above, using $new.id
```

- Parse output with `ConvertFrom-Json` and take `.id`. Never `Select-String` raw JSON: nested
  `"id"` fields give false matches.
- For several items, loop over the same three steps and print a table of IDs at the end.

## Update a page in a code wiki

A *code wiki* is a Git repository published as a wiki. Page updates through the Pages API need a
branch version descriptor and the page's ETag.

```powershell
$org = 'https://dev.azure.com/<org>'; $project = '<project>'; $wikiId = '<wiki id or name>'; $pagePath = '/Folder/Page name'
$base = "$org/$project/_apis/wiki/wikis/$wikiId/pages"
$get = Invoke-WebRequest -UseBasicParsing -Uri "${base}?path=$([uri]::EscapeDataString($pagePath))&includeContent=true&api-version=7.1" -Headers @{ Authorization = "Bearer $token" }
$etag = @($get.Headers.ETag)[0]
$page = $get.Content | ConvertFrom-Json
$body = @{ content = $newContent } | ConvertTo-Json -Compress
$headers = @{ Authorization = "Bearer $token"; 'Content-Type' = 'application/json; charset=utf-8'; 'If-Match' = $etag }
$uri = "${base}?path=$([uri]::EscapeDataString($pagePath))&versionDescriptor.versionType=branch&versionDescriptor.version=<branch>&comment=$([uri]::EscapeDataString('<why>'))&api-version=7.1"
Invoke-RestMethod -Uri $uri -Method Put -Headers $headers -Body $body | Out-Null
$check = Invoke-RestMethod -Uri "${base}?path=$([uri]::EscapeDataString($pagePath))&includeContent=true&api-version=7.1" -Headers @{ Authorization = "Bearer $token" }
"Stored length: $($check.content.Length)"
```

- **Never send the body as a byte array.** The PUT succeeds and creates a commit, but the page is
  stored **empty**. Send the JSON string with `charset=utf-8` in the content type; accented
  characters survive.
- Page paths in the Pages API use **spaces**, not the hyphens you see in the URL. Hyphens return a
  page-not-found error. Discover the exact path with `?path=/&recursionLevel=oneLevel`.
- The ETag header can arrive as an array; take the first element.
- Normalise line endings to LF before editing. A regex replace with multiline `$` on CRLF content
  keeps the CR in the match; adding CRLF then yields CR-CR-LF, which renders as a blank line and
  breaks Markdown tables.
- A heading directly after a list item needs a blank line before it, or it renders as list text.
- PUT without `If-Match` on a path that returns 404 creates a new page; the response contains its
  `id`.
- Read local files with `[IO.File]::ReadAllText($path, [Text.UTF8Encoding]::new($false))`, not
  `Get-Content`, to keep the encoding intact.

If a page was wiped, the wiki's Git history still has it: find the commit before the bad PUT and
read the file at that commit through the Git Items API (it returns raw bytes; strip the BOM).

## Why not `az rest`

- It crashes on Unicode characters in responses on Windows (charmap codec).
- It URL-encodes `&` inside the URL as `%26`, which breaks query strings.

Use `Invoke-RestMethod` or `Invoke-WebRequest` for these calls.
