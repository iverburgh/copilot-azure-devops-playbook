<#
.SYNOPSIS
    Fails if any organisation-specific reference leaks into this repository.

.DESCRIPTION
    Everything published here must be generic: no organisation or product names, no internal
    hostnames, no work item numbers, no callable endpoints.

    Generic patterns are built in. Names of the organisation and product this playbook was extracted
    from are deliberately NOT in this file — listing them here would publish them. They are loaded
    from, in this order:

      - tools/forbidden-terms.local.txt  (git-ignored; one regular expression per line, # comments)
      - the FORBIDDEN_TERMS environment variable (patterns separated by newlines or semicolons),
        which CI fills from a repository secret

    With -Placeholders the script instead lists every <placeholder> left in agent, skill, prompt and
    instruction files. Use that on your own repository after copying the playbook in.

.PARAMETER Path
    Root to scan. Defaults to the repository root (the parent of this script's folder).

.PARAMETER Placeholders
    List leftover <placeholders> instead of scanning for leaks.

.EXAMPLE
    pwsh ./tools/Test-NoInternalReferences.ps1

.EXAMPLE
    pwsh ./tools/Test-NoInternalReferences.ps1 -Path ../my-repo -Placeholders
#>
[CmdletBinding()]
param(
    [string] $Path = (Split-Path $PSScriptRoot -Parent),
    [switch] $Placeholders
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$binary = '\.(png|jpe?g|gif|ico|svg|pdf|zip|gz|7z|dll|exe|pfx|snk|woff2?|ttf)$'
$localTerms = Join-Path $PSScriptRoot 'forbidden-terms.local.txt'

# Scan everything except binaries. An extension allow-list would skip dotfiles, which is exactly
# where a stray reference hides.
$files = @(Get-ChildItem -Path $Path -Recurse -File -Force |
    Where-Object {
        $_.FullName -notmatch '[\\/]\.git[\\/]' -and
        $_.FullName -notmatch '[\\/]node_modules[\\/]' -and
        $_.Extension -notmatch $binary -and
        $_.FullName -ne $PSCommandPath -and
        $_.FullName -ne $localTerms
    })

if ($Placeholders) {
    $targets = $files | Where-Object {
        $_.FullName -match '[\\/]\.github[\\/](agents|skills|prompts|instructions)[\\/]' -or $_.Name -eq 'copilot-instructions.md'
    }
    $hits = $targets | Select-String -Pattern '<[a-z][a-z0-9 _.-]{1,40}>' -AllMatches |
        Where-Object { $_.Line -notmatch '</?(div|p|ul|li|h\d|br|code|pre|table|tr|td|th|strong|em)>' }
    if (-not $hits) { Write-Host 'No placeholders left.' -ForegroundColor Green; exit 0 }
    foreach ($h in $hits) {
        $rel = [IO.Path]::GetRelativePath($Path, $h.Path)
        Write-Host ("{0}:{1}  {2}" -f $rel, $h.LineNumber, (($h.Matches | ForEach-Object Value) -join ' '))
    }
    exit 1
}

$forbidden = [System.Collections.Generic.List[hashtable]]::new()
@(
    @{ Name = 'Signed webhook URL';   Pattern = 'sig=[A-Za-z0-9_\-%]{20,}';                               Why = 'A callable endpoint with its signature is a credential.' }
    @{ Name = 'Organisation URL';     Pattern = 'dev\.azure\.com/(?!<)[A-Za-z0-9._-]+/[A-Za-z0-9._-]';   Why = 'Use dev.azure.com/<org>/<project>.' }
    @{ Name = 'Legacy org URL';       Pattern = '(?<![./-])\b(?!(code|marketplace|app)\.)[A-Za-z0-9-]+\.visualstudio\.com'; Why = 'Use dev.azure.com/<org>.' }
    @{ Name = 'Private feed';         Pattern = 'pkgs\.dev\.azure\.com/(?!<)[A-Za-z0-9._-]+/';           Why = 'Use <org> and <feed> placeholders.' }
    @{ Name = 'Internal mail domain'; Pattern = '@(?!example\.com)[A-Za-z0-9-]+\.(nl|local|internal)\b'; Why = 'Use example.com.' }
    @{ Name = 'Work item reference';  Pattern = '(?i)\b(PBI|task|feature|bug)\s*#?\s*\d{5,}\b|#\d{6,}';  Why = 'Internal tracking numbers.' }
    @{ Name = 'Sprint reference';     Pattern = '(?i)\bsprint\s+\d{2,}\b';                               Why = 'Internal planning. Single-digit examples such as "Sprint 1" are allowed.' }
    @{ Name = 'Tenant or object ID';  Pattern = '(?i)\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b(?<!499b84ac-1321-427f-aa17-267ca6975798)'; Why = 'GUIDs identify real tenants, subscriptions and identities. (The public Azure DevOps resource ID is allowed.)' }
    @{ Name = 'Windows user path';    Pattern = '(?i)C:\\Users\\(?!<)[A-Za-z0-9._-]+\\';                 Why = 'Personal paths identify people.' }
    @{ Name = 'Dutch text';           Pattern = '(?i)\b(werd|wordt|niet|geen|deze|zodat|omdat|waardoor|bijvoorbeeld|voorkomt)\b'; Why = 'Repository is English-only.' }
) | ForEach-Object { $forbidden.Add($_) }

$extra = @()
if (Test-Path $localTerms) { $extra += Get-Content $localTerms }
if ($env:FORBIDDEN_TERMS) { $extra += $env:FORBIDDEN_TERMS -split '[;\r\n]+' }
$extra = @($extra | ForEach-Object { $_.Trim() } | Where-Object { $_ -and -not $_.StartsWith('#') })
foreach ($term in $extra) {
    $forbidden.Add(@{ Name = 'Organisation-specific term'; Pattern = "(?i)$term"; Why = 'Listed in forbidden-terms.local.txt or FORBIDDEN_TERMS.' })
}

Write-Host "Scanning $($files.Count) files under $Path"
if ($extra.Count -eq 0) {
    Write-Warning 'No organisation-specific terms loaded: create tools/forbidden-terms.local.txt or set FORBIDDEN_TERMS. Only generic patterns are checked.'
}
else {
    Write-Host "Loaded $($extra.Count) organisation-specific term(s)."
}

$findings = @()
foreach ($rule in $forbidden) {
    foreach ($file in $files) {
        $hits = Select-String -Path $file.FullName -Pattern $rule.Pattern -AllMatches -ErrorAction SilentlyContinue
        foreach ($hit in $hits) {
            $findings += [pscustomobject]@{
                Rule = $rule.Name
                File = [IO.Path]::GetRelativePath($Path, $hit.Path)
                Line = $hit.LineNumber
                # Never echo an organisation-specific match in full: CI logs are public.
                Text = if ($rule.Name -eq 'Organisation-specific term') { '(match hidden)' } else { $hit.Line.Trim() }
                Why  = $rule.Why
            }
        }
    }
}

if ($findings.Count -eq 0) {
    Write-Host 'No internal references found.' -ForegroundColor Green
    exit 0
}

Write-Host ''
Write-Host "$($findings.Count) potential leak(s) found:" -ForegroundColor Red
foreach ($group in $findings | Group-Object Rule) {
    Write-Host ''
    Write-Host "  $($group.Name) - $($group.Group[0].Why)" -ForegroundColor Yellow
    foreach ($f in $group.Group) {
        $snippet = if ($f.Text.Length -gt 110) { $f.Text.Substring(0, 110) + '...' } else { $f.Text }
        Write-Host "    $($f.File):$($f.Line)  $snippet"
    }
}
Write-Host ''
exit 1
