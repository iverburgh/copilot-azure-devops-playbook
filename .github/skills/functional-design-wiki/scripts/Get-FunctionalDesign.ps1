<#
.SYNOPSIS
    Searches and reads the functional design pages in an Azure DevOps wiki.

.DESCRIPTION
    A functional design kept in a wiki is usually far too large to load in one go. This script
    supports progressive disclosure:

      1. search page paths and titles (cheap: paths only);
      2. fetch the full content of the few pages that matter.

    Every page comes back with an exact deep link, so an answer can cite the precise page instead of
    the wiki root.

    Requires Azure CLI with the azure-devops extension and an authenticated session (az login).

.PARAMETER Query
    Filters page paths and titles (case-insensitive). Without -Path only the matching paths are
    listed.

.PARAMETER Path
    Full or partial page path. Fetches the full Markdown of every page whose path contains this
    value (case-insensitive). Make it specific enough to avoid fetching dozens of pages.

.PARAMETER Section
    Restricts the search to one top-level folder under the root, for example 'Orders'.

.PARAMETER RootPath
    Wiki path of the functional design, as it appears in the wiki URL. Defaults to $env:AZDO_FD_ROOT,
    then '/Functional-Design'.

.PARAMETER Organization
    Organization URL, for example https://dev.azure.com/<org>. Defaults to $env:AZDO_ORG_URL.

.PARAMETER Project
    Project name. Defaults to $env:AZDO_PROJECT.

.PARAMETER WikiName
    Wiki name. Defaults to $env:AZDO_WIKI.

.EXAMPLE
    ./Get-FunctionalDesign.ps1 -Query 'invoice'

.EXAMPLE
    ./Get-FunctionalDesign.ps1 -Section 'Orders' -Query 'cancel'

.EXAMPLE
    ./Get-FunctionalDesign.ps1 -Path 'Orders/Cancel order/Processes'
#>
[CmdletBinding()]
param(
    [string] $Query,
    [string] $Path,
    [string] $Section,

    [ValidateSet('markdown', 'json')]
    [string] $OutputFormat = 'markdown',

    [string] $RootPath = $env:AZDO_FD_ROOT,
    [string] $Organization = $env:AZDO_ORG_URL,
    [string] $Project = $env:AZDO_PROJECT,
    [string] $WikiName = $env:AZDO_WIKI
)

$ErrorActionPreference = 'Stop'

if (-not $RootPath) { $RootPath = '/Functional-Design' }
if (-not $Organization -or -not $Project -or -not $WikiName) {
    throw 'Organization, Project and WikiName are required. Pass -Organization/-Project/-WikiName or set AZDO_ORG_URL, AZDO_PROJECT and AZDO_WIKI.'
}
$Organization = $Organization.TrimEnd('/')

$token = az account get-access-token --resource '499b84ac-1321-427f-aa17-267ca6975798' --query accessToken -o tsv 2>$null
if (-not $token) { throw 'No access token. Run az login first.' }
$headers = @{ Authorization = "Bearer $($token.Trim())" }

$wiki = az devops wiki show --wiki $WikiName --project $Project --org $Organization --output json 2>$null | ConvertFrom-Json
if (-not $wiki) { throw "Wiki '$WikiName' not found. Check authentication and the azure-devops extension." }
$repositoryId = $wiki.repositoryId
$branch = $wiki.versions[0].version

# Wiki file names store spaces as hyphens.
$scopePath = ($RootPath -replace ' ', '-').TrimEnd('/')
if ($Section) { $scopePath = "$scopePath/$(($Section -replace ' ', '-').Trim('/'))" }

$items = az devops invoke `
    --area git --resource items `
    --route-parameters "repositoryId=$repositoryId" "project=$Project" `
    --query-parameters "scopePath=$scopePath" 'recursionLevel=Full' "versionDescriptor.version=$branch" `
    --org $Organization --output json 2>$null | ConvertFrom-Json

if (-not $items -or -not $items.value) { throw "No pages found under '$scopePath'." }

$projectSegment = [uri]::EscapeDataString($Project)
$wikiBaseUrl = "$Organization/$projectSegment/_wiki/wikis/$([uri]::EscapeDataString($WikiName))"
$rootPagePath = [uri]::UnescapeDataString(($RootPath -replace '-', ' ')).TrimEnd('/')

$pages = foreach ($file in $items.value) {
    if ($file.gitObjectType -ne 'blob' -or $file.path -notlike '*.md') { continue }

    # Hyphens are spaces; a literal hyphen is stored as %2D, so replace before decoding.
    $pagePath = [uri]::UnescapeDataString((($file.path -replace '\.md$', '') -replace '-', ' '))
    $relative = if ($pagePath.StartsWith($rootPagePath)) { $pagePath.Substring($rootPagePath.Length).TrimStart('/') } else { $pagePath }

    [pscustomobject]@{
        Path     = $relative
        Title    = Split-Path $pagePath -Leaf
        ObjectId = $file.objectId
        Url      = '{0}?pagePath={1}' -f $wikiBaseUrl, [uri]::EscapeDataString($pagePath)
    }
}

if ($Query) { $pages = $pages | Where-Object { $_.Path -like "*$Query*" -or $_.Title -like "*$Query*" } }
if ($Path) { $pages = $pages | Where-Object { $_.Path -like "*$Path*" } }
$pages = @($pages | Sort-Object Path)

if ($pages.Count -eq 0) {
    Write-Output "No pages found (Query='$Query', Path='$Path', Section='$Section')."
    return
}

if (-not $Path) {
    if ($OutputFormat -eq 'json') {
        $pages | Select-Object Path, Title, Url | ConvertTo-Json -Depth 5
        return
    }
    Write-Output "# Functional design - $($pages.Count) page(s)"
    Write-Output ''
    Write-Output "> Use -Path '<part of path>' to fetch full content. Cite the link of every page you use."
    Write-Output ''
    foreach ($p in $pages) { Write-Output "- [$($p.Path)]($($p.Url))" }
    return
}

$result = foreach ($p in $pages) {
    $blobUrl = "$Organization/$projectSegment/_apis/git/repositories/$repositoryId/blobs/$($p.ObjectId)?api-version=7.1&`$format=text"
    try { $content = Invoke-RestMethod -Uri $blobUrl -Headers $headers -Method Get }
    catch { $content = "(content could not be retrieved: $($_.Exception.Message))" }
    [pscustomobject]@{ Path = $p.Path; Title = $p.Title; Url = $p.Url; Content = $content }
}

if ($OutputFormat -eq 'json') {
    $result | ConvertTo-Json -Depth 10
    return
}
foreach ($r in $result) {
    Write-Output "# Functional design: $($r.Path)"
    Write-Output ''
    Write-Output $r.Content
    Write-Output ''
    Write-Output "**Source:** [$($r.Path)]($($r.Url))"
    Write-Output ''
    Write-Output '---'
    Write-Output ''
}
