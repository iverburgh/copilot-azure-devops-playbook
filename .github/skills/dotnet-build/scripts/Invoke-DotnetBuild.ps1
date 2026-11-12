<#
.SYNOPSIS
    Builds or tests one .NET project with minimal output, for use by coding agents.

.DESCRIPTION
    Runs `dotnet build` or `dotnet test` for a single project with quiet flags. On success it prints
    one line. On failure it prints the failed tests from the TRX file, or the error lines from the
    build output, or the last lines of the output when no error line is recognised — and exits with
    the exit code of dotnet.

    Test results are written to TestResults/dotnet-skill under the repository root. Add
    `TestResults/` to .gitignore.

.PARAMETER ProjectPath
    Path to the .csproj (or a folder that contains exactly one project). Never a solution.

.PARAMETER Command
    build or test. Default: build.

.PARAMETER Restore
    Restore packages as part of the command. Without this switch, --no-restore is passed; use it the
    first time, or after a package reference changed.

.PARAMETER NoBuild
    Test only: pass --no-build, for when the project was just built.

.PARAMETER MaxErrorLines
    Maximum number of error lines or failed tests to print. Default: 25.

.PARAMETER TailLines
    Number of output lines to print when no error line is recognised. Default: 30.

.EXAMPLE
    ./Invoke-DotnetBuild.ps1 -ProjectPath tests/Orders.ComponentTests/Orders.ComponentTests.csproj -Restore

.EXAMPLE
    ./Invoke-DotnetBuild.ps1 -ProjectPath tests/Orders.ComponentTests/Orders.ComponentTests.csproj -Command test -NoBuild
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ProjectPath,

    [ValidateSet('build', 'test')]
    [string]$Command = 'build',

    [switch]$Restore,

    [switch]$NoBuild,

    [ValidateRange(1, 1000)]
    [int]$MaxErrorLines = 25,

    [ValidateRange(1, 1000)]
    [int]$TailLines = 30
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-RepositoryRoot {
    param([string]$StartPath)

    $current = $StartPath
    while ($current) {
        # A worktree has a .git file instead of a .git folder; Test-Path accepts both.
        if (Test-Path -LiteralPath (Join-Path $current '.git')) { return $current }
        $parent = Split-Path -Path $current -Parent
        if (-not $parent -or $parent -eq $current) { break }
        $current = $parent
    }
    return $StartPath
}

function Get-TrxSummary {
    param([string]$TrxPath, [int]$MaxFailures)

    [xml]$trx = [IO.File]::ReadAllText($TrxPath, [Text.UTF8Encoding]::new($false))

    $counters = $trx.SelectSingleNode("//*[local-name()='Counters']")
    $summary = 'no counters in TRX'
    if ($counters) {
        $summary = '{0}/{1} passed, {2} failed, {3} not executed' -f $counters.GetAttribute('passed'),
            $counters.GetAttribute('total'), $counters.GetAttribute('failed'), $counters.GetAttribute('notExecuted')
    }

    $failedNodes = @($trx.SelectNodes("//*[local-name()='UnitTestResult'][@outcome='Failed']"))
    $failures = @()
    foreach ($node in @($failedNodes | Select-Object -First $MaxFailures)) {
        $message = $node.SelectSingleNode(".//*[local-name()='ErrorInfo']/*[local-name()='Message']")
        $stack = $node.SelectSingleNode(".//*[local-name()='ErrorInfo']/*[local-name()='StackTrace']")

        $messageText = ''
        if ($message) { $messageText = (($message.InnerText -split "`r?`n")[0]).Trim() }

        $frameText = ''
        if ($stack) {
            $frames = @(($stack.InnerText -split "`r?`n") | Where-Object { $_.Trim() })
            if ($frames.Count -gt 0) { $frameText = $frames[0].Trim() }
        }

        $line = "- $($node.GetAttribute('testName')): $messageText"
        if ($frameText) { $line += " | $frameText" }
        $failures += $line
    }

    [pscustomobject]@{
        Summary     = $summary
        FailedCount = $failedNodes.Count
        Failures    = $failures
    }
}

$resolvedProject = (Resolve-Path -LiteralPath $ProjectPath).Path
if ($resolvedProject -match '\.(sln|slnx)$') {
    throw "Pass a project, not a solution: $ProjectPath"
}

$projectFolder = $resolvedProject
if (-not (Test-Path -LiteralPath $resolvedProject -PathType Container)) {
    $projectFolder = Split-Path -Path $resolvedProject -Parent
}
$repositoryRoot = Get-RepositoryRoot -StartPath $projectFolder
$projectName = [IO.Path]::GetFileNameWithoutExtension($resolvedProject)

$arguments = @($Command, $resolvedProject, '--nologo', '-v', 'quiet', '--tl:off')
if (-not $Restore) { $arguments += '--no-restore' }

$trxPath = $null
if ($Command -eq 'build') {
    $arguments += '-m'
}
else {
    if ($NoBuild) { $arguments += '--no-build' }
    $resultsDirectory = Join-Path $repositoryRoot 'TestResults/dotnet-skill'
    $trxName = '{0}-{1}.trx' -f $projectName, (Get-Date -Format 'yyyyMMdd-HHmmss')
    $trxPath = Join-Path $resultsDirectory $trxName
    $arguments += @('--logger', "trx;LogFileName=$trxName", '--results-directory', $resultsDirectory)
}

Write-Verbose ('dotnet ' + ($arguments -join ' '))

# Native stderr must not become a terminating error; the exit code decides.
$previousPreference = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try {
    $output = @(& dotnet @arguments 2>&1 | ForEach-Object { "$_" })
    $exitCode = $LASTEXITCODE
}
finally {
    $ErrorActionPreference = $previousPreference
}

$trxSummary = $null
if ($trxPath -and (Test-Path -LiteralPath $trxPath)) {
    $trxSummary = Get-TrxSummary -TrxPath $trxPath -MaxFailures $MaxErrorLines
}

if ($exitCode -eq 0) {
    if ($trxSummary) {
        Write-Output "test OK: $projectName - $($trxSummary.Summary) - TRX: $trxPath"
    }
    else {
        Write-Output "$Command OK: $projectName"
    }
    exit 0
}

Write-Output "$Command FAILED (exit code $exitCode): $projectName"

if ($trxSummary -and $trxSummary.FailedCount -gt 0) {
    Write-Output $trxSummary.Summary
    $trxSummary.Failures | ForEach-Object { Write-Output $_ }
    if ($trxSummary.FailedCount -gt $MaxErrorLines) {
        Write-Output "... $($trxSummary.FailedCount - $MaxErrorLines) more failed tests in $trxPath"
    }
    else {
        Write-Output "TRX: $trxPath"
    }
}
else {
    $errorLines = @($output |
        Where-Object { $_ -match '(:|\s)error [A-Z]+\d+|##\[error\]|Build FAILED|Unhandled exception|Exception:' } |
        Select-Object -Unique -First $MaxErrorLines)
    if ($errorLines.Count -gt 0) {
        $errorLines | ForEach-Object { Write-Output $_ }
    }
    else {
        $output | Select-Object -Last $TailLines | ForEach-Object { Write-Output $_ }
    }
}

exit $exitCode
