<#
.SYNOPSIS
    Validates the agent, skill and prompt files: frontmatter, names and cross-references.

.DESCRIPTION
    Copilot silently ignores a customization file with broken frontmatter, and an agent that refers
    to a skill that does not exist simply works worse. This script turns both into a failing check:

      - every *.agent.md has a name and a description
      - every SKILL.md has a description and a name equal to its folder name
      - every *.prompt.md has a description, and its agent (if any) exists
      - every *.instructions.md has a description or an applyTo
      - every skill referred to as `name` skill (or skill `name`) exists
      - every <name>.instructions.md referred to exists

.PARAMETER Path
    Root to scan. Defaults to the repository root.

.EXAMPLE
    pwsh ./tools/Test-CustomizationFiles.ps1
#>
[CmdletBinding()]
param(
    [string] $Path = (Split-Path $PSScriptRoot -Parent)
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-Frontmatter {
    param([string] $File)
    $text = Get-Content -LiteralPath $File -Raw
    if ($text -notmatch '(?s)^---\r?\n(?<fm>.*?)\r?\n---') { return $null }
    $fm = $Matches['fm']
    $result = @{}
    foreach ($key in 'name', 'description', 'agent', 'applyTo') {
        if ($fm -match "(?m)^$key\s*:\s*(?<v>.*)$") {
            $value = $Matches['v'].Trim().Trim("'", '"')
            # Folded or literal block scalars carry their value on the following lines.
            if ($value -in '>', '>-', '|', '|-') { $value = '(block)' }
            $result[$key] = $value
        }
    }
    return $result
}

$github = Join-Path $Path '.github'
$findings = @()

$agents = @(Get-ChildItem -Path (Join-Path $github 'agents') -Filter '*.agent.md' -File -ErrorAction SilentlyContinue)
$agentNames = @('agent', 'ask', 'edit', 'plan')
foreach ($file in $agents) {
    $fm = Get-Frontmatter $file.FullName
    if (-not $fm) { $findings += "no frontmatter    $($file.Name)"; continue }
    if (-not $fm['description']) { $findings += "no description    $($file.Name)" }
    if ($fm['name']) { $agentNames += $fm['name'] } else { $findings += "no name           $($file.Name)" }
}

$skills = @(Get-ChildItem -Path (Join-Path $github 'skills') -Directory -ErrorAction SilentlyContinue)
$skillNames = @($skills | ForEach-Object Name)
foreach ($dir in $skills) {
    $file = Join-Path $dir.FullName 'SKILL.md'
    if (-not (Test-Path $file)) { $findings += "no SKILL.md       skills/$($dir.Name)"; continue }
    $fm = Get-Frontmatter $file
    if (-not $fm) { $findings += "no frontmatter    skills/$($dir.Name)/SKILL.md"; continue }
    if (-not $fm['description']) { $findings += "no description    skills/$($dir.Name)/SKILL.md" }
    if ($fm['name'] -ne $dir.Name) { $findings += "name mismatch     skills/$($dir.Name)/SKILL.md has name '$($fm['name'])'" }
}

$prompts = @(Get-ChildItem -Path (Join-Path $github 'prompts') -Filter '*.prompt.md' -File -ErrorAction SilentlyContinue)
foreach ($file in $prompts) {
    $fm = Get-Frontmatter $file.FullName
    if (-not $fm) { $findings += "no frontmatter    $($file.Name)"; continue }
    if (-not $fm['description']) { $findings += "no description    $($file.Name)" }
    if ($fm['agent'] -and $agentNames -notcontains $fm['agent']) { $findings += "unknown agent     $($file.Name) -> '$($fm['agent'])'" }
}

$instructions = @(Get-ChildItem -Path (Join-Path $github 'instructions') -Filter '*.instructions.md' -File -ErrorAction SilentlyContinue)
$instructionNames = @($instructions | ForEach-Object Name)
foreach ($file in $instructions) {
    $fm = Get-Frontmatter $file.FullName
    if (-not $fm) { $findings += "no frontmatter    $($file.Name)"; continue }
    if (-not $fm['description'] -and -not $fm['applyTo']) { $findings += "no description or applyTo  $($file.Name)" }
}

$sources = @($agents) + @($prompts) + @($instructions) + @(Get-ChildItem -Path (Join-Path $github 'skills') -Filter 'SKILL.md' -File -Recurse -ErrorAction SilentlyContinue)
foreach ($file in $sources) {
    $text = Get-Content -LiteralPath $file.FullName -Raw
    foreach ($m in [regex]::Matches($text, '`(?<a>[a-z0-9]+(?:-[a-z0-9]+)+)` skill|skill `(?<b>[a-z0-9]+(?:-[a-z0-9]+)+)`')) {
        $name = if ($m.Groups['a'].Success) { $m.Groups['a'].Value } else { $m.Groups['b'].Value }
        if ($skillNames -notcontains $name) {
            $findings += "unknown skill     $([IO.Path]::GetRelativePath($Path, $file.FullName)) -> '$name'"
        }
    }
    foreach ($m in [regex]::Matches($text, '(?<n>[a-z0-9-]+\.instructions\.md)')) {
        if ($instructionNames -notcontains $m.Groups['n'].Value) {
            $findings += "unknown instructions  $([IO.Path]::GetRelativePath($Path, $file.FullName)) -> '$($m.Groups['n'].Value)'"
        }
    }
}

Write-Host "Checked $($agents.Count) agents, $($skills.Count) skills, $($prompts.Count) prompts, $($instructions.Count) instruction files"
if ($findings.Count -eq 0) {
    Write-Host 'All customization files are valid.' -ForegroundColor Green
    exit 0
}
Write-Host ''
Write-Host "$($findings.Count) problem(s):" -ForegroundColor Red
$findings | Sort-Object -Unique | ForEach-Object { Write-Host "  $_" }
exit 1
