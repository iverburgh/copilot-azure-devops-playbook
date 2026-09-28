<#
.SYNOPSIS
    Lists and reads architecture decision records (ADRs) from an Azure DevOps wiki or a repository
    folder.

.DESCRIPTION
    Without a filter the script prints an index: number, title and link per ADR. With -Number,
    -Query or -All it prints the full content, each ADR followed by its source link.

    Wiki mode requires Azure CLI with the azure-devops extension and an authenticated session.
    Repository mode (-RepoPath) reads Markdown files from disk and needs nothing else.

    Recognised file names: 'ADR-001-Title.md', 'ADR001 Title.md' and adr-tools style
    '0001-title.md'.

.PARAMETER Number
    One or more ADR numbers to fetch, for example 1, 12 or 'ADR-012'.

.PARAMETER Query
    Fetches every ADR whose title contains this text (case-insensitive).

.PARAMETER All
    Fetches the full content of every ADR. Use sparingly.

.PARAMETER RepoPath
    Folder in the repository that holds the ADRs, for example 'docs/adr'. Switches to repository mode.

.PARAMETER RootPath
    Wiki path of the ADR folder. Defaults to $env:AZDO_ADR_ROOT, then '/Architecture-Decision-Records'.

.EXAMPLE
    ./Get-Adrs.ps1

.EXAMPLE
    ./Get-Adrs.ps1 -Number 3, 11

.EXAMPLE
    ./Get-Adrs.ps1 -RepoPath docs/adr -Query 'messaging'
#>
[CmdletBinding()]
param(
    [string[]] $Number,
    [string] $Query,
    [switch] $All,
    [string] $RepoPath,

    [ValidateSet('markdown', 'json')]
    [string] $OutputFormat = 'markdown',

    [string] $RootPath = $env:AZDO_ADR_ROOT,
    [string] $Organization = $env:AZDO_ORG_URL,
    [string] $Project = $env:AZDO_PROJECT,
    [string] $WikiName = $env:AZDO_WIKI
)

$ErrorActionPreference = 'Stop'

function Get-AdrKey {
    param([string] $Name)
    if ($Name -match '^(?i)ADR[-\s]?(\d+)') { return [int] $Matches[1] }
    if ($Name -match '^(\d{3,4})-') { return [int] $Matches[1] }
    return $null
}

function Get-AdrTitle {
    param([string] $Name)
    ($Name -replace '^(?i)ADR[-\s]?\d+[-:\s]*', '' -replace '^\d{3,4}-', '' -replace '-', ' ').Trim()
}

if ($RepoPath) {
    $adrs = Get-ChildItem -Path $RepoPath -Filter '*.md' -File -Recurse | ForEach-Object {
        $key = Get-AdrKey $_.BaseName
        if ($null -eq $key) { return }
        [pscustomobject]@{
            Key     = $key
            Number  = 'ADR-{0:000}' -f $key
            Title   = Get-AdrTitle $_.BaseName
            Url     = [IO.Path]::GetRelativePath((Get-Location).Path, $_.FullName) -replace '\\', '/'
            Source  = $_.FullName
        }
    }
}
else {
    if (-not $RootPath) { $RootPath = '/Architecture-Decision-Records' }
    if (-not $Organization -or -not $Project -or -not $WikiName) {
        throw 'Organization, Project and WikiName are required in wiki mode. Pass them, set AZDO_ORG_URL, AZDO_PROJECT and AZDO_WIKI, or use -RepoPath.'
    }
    $Organization = $Organization.TrimEnd('/')

    $wiki = az devops wiki show --wiki $WikiName --project $Project --org $Organization --output json 2>$null | ConvertFrom-Json
    if (-not $wiki) { throw "Wiki '$WikiName' not found. Check authentication and the azure-devops extension." }

    $scopePath = ($RootPath -replace ' ', '-').TrimEnd('/')
    $items = az devops invoke `
        --area git --resource items `
        --route-parameters "repositoryId=$($wiki.repositoryId)" "project=$Project" `
        --query-parameters "scopePath=$scopePath" 'recursionLevel=Full' "versionDescriptor.version=$($wiki.versions[0].version)" `
        --org $Organization --output json 2>$null | ConvertFrom-Json
    if (-not $items -or -not $items.value) { throw "No ADRs found under '$scopePath'." }

    $projectSegment = [uri]::EscapeDataString($Project)
    $wikiBaseUrl = "$Organization/$projectSegment/_wiki/wikis/$([uri]::EscapeDataString($WikiName))"

    $adrs = foreach ($file in $items.value) {
        if ($file.gitObjectType -ne 'blob' -or $file.path -notlike '*.md') { continue }
        $pagePath = [uri]::UnescapeDataString((($file.path -replace '\.md$', '') -replace '-', ' '))
        $leaf = Split-Path ([uri]::UnescapeDataString(($file.path -replace '\.md$', ''))) -Leaf
        $key = Get-AdrKey $leaf
        if ($null -eq $key) { continue }
        [pscustomobject]@{
            Key    = $key
            Number = 'ADR-{0:000}' -f $key
            # The page path already has spaces restored and literal hyphens kept.
            Title  = ((Split-Path $pagePath -Leaf) -replace '^(?i)ADR[-\s]?\d+[-:\s]*', '').Trim()
            Url    = '{0}?pagePath={1}' -f $wikiBaseUrl, [uri]::EscapeDataString($pagePath)
            Source = "$Organization/$projectSegment/_apis/git/repositories/$($wiki.repositoryId)/blobs/$($file.objectId)?api-version=7.1&`$format=text"
        }
    }
}

$adrs = @($adrs | Sort-Object Key)
if ($adrs.Count -eq 0) { Write-Output 'No ADRs found.'; return }

$fetch = $All -or $Number -or $Query
if ($Number) {
    $keys = $Number | ForEach-Object { [int] ($_ -replace '\D', '') }
    $adrs = @($adrs | Where-Object { $keys -contains $_.Key })
}
if ($Query) { $adrs = @($adrs | Where-Object { $_.Title -like "*$Query*" }) }

if (-not $fetch) {
    if ($OutputFormat -eq 'json') { $adrs | Select-Object Number, Title, Url | ConvertTo-Json; return }
    Write-Output "# Architecture decision records - $($adrs.Count)"
    Write-Output ''
    Write-Output '> Use -Number, -Query or -All to read the content. Cite the link of every ADR you rely on.'
    Write-Output ''
    foreach ($a in $adrs) { Write-Output "- **$($a.Number)** [$($a.Title)]($($a.Url))" }
    return
}

if (-not $RepoPath) {
    $token = az account get-access-token --resource '499b84ac-1321-427f-aa17-267ca6975798' --query accessToken -o tsv 2>$null
    if (-not $token) { throw 'No access token. Run az login first.' }
    $headers = @{ Authorization = "Bearer $($token.Trim())" }
}

$result = foreach ($a in $adrs) {
    $content = if ($RepoPath) { Get-Content -LiteralPath $a.Source -Raw }
    else {
        try { Invoke-RestMethod -Uri $a.Source -Headers $headers -Method Get }
        catch { "(content could not be retrieved: $($_.Exception.Message))" }
    }
    [pscustomobject]@{ Number = $a.Number; Title = $a.Title; Url = $a.Url; Content = $content }
}

if ($OutputFormat -eq 'json') { $result | ConvertTo-Json -Depth 10; return }
foreach ($r in $result) {
    Write-Output "# $($r.Number): $($r.Title)"
    Write-Output ''
    Write-Output $r.Content
    Write-Output ''
    Write-Output "**Source:** [$($r.Number)]($($r.Url))"
    Write-Output ''
    Write-Output '---'
    Write-Output ''
}
