---
description: 'PowerShell Pester testing best practices based on Pester v5 conventions'
applyTo: '**/*.Tests.ps1'
---

<!-- Condensed from awesome-copilot's powershell-pester-5.instructions.md (MIT). Upstream has since moved to Pester 6; see THIRD-PARTY-NOTICES.md. -->

# Pester v5

## Files

- Name test files `*.Tests.ps1`, next to the script they test.
- Load the code under test in `BeforeAll { . $PSScriptRoot/Get-MyFunction.ps1 }`.
- Put all code inside Pester blocks (`BeforeAll`, `Describe`, `Context`, `It`). Code outside them runs
  during discovery, not during the run.

## Structure

```powershell
BeforeAll { . $PSScriptRoot/Get-MyFunction.ps1 }

Describe 'Get-MyFunction' {
    Context 'When input is valid' {
        BeforeAll {
            Mock Get-ADUser { @{ Name = 'TestUser'; Enabled = $true } }
        }

        It 'Returns the user object' {
            $result = Get-MyFunction -Username 'TestUser'
            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'TestUser'
        }

        It 'Calls Get-ADUser once' {
            Get-MyFunction -Username 'TestUser'
            Should -Invoke Get-ADUser -Exactly 1
        }
    }

    Context 'When the user does not exist' {
        BeforeAll { Mock Get-ADUser { throw 'User not found' } }

        It 'Throws' {
            { Get-MyFunction -Username 'NonExistent' } | Should -Throw '*not found*'
        }
    }
}
```

## Assertions

| Category | Operators |
|---|---|
| Comparison | `-Be`, `-BeExactly`, `-Not -Be` |
| Collections | `-Contain`, `-BeIn`, `-HaveCount` |
| Strings | `-Match`, `-Like`, `-BeNullOrEmpty` |
| Types | `-BeOfType`, `-BeTrue`, `-BeFalse` |
| Exceptions | `-Throw`, `-Not -Throw` |

## Mocking

```powershell
Mock Get-Service { @{ Status = 'Running' } } -ParameterFilter { $Name -eq 'TestService' }
Should -Invoke Get-Service -Exactly 1 -ParameterFilter { $Name -eq 'TestService' }
```

Mock every external call — `az`, `Invoke-RestMethod`, `Invoke-WebRequest` — so tests never reach a
real organization.

## Data-driven tests

```powershell
It 'Returns <Expected> for <Value>' -TestCases @(
    @{ Value = 'value1'; Expected = 'result1' }
    @{ Value = 'value2'; Expected = 'result2' }
) {
    Get-Function $Value | Should -Be $Expected
}
```

Do not name a test case key `Input`: `$Input` is an automatic variable.

## Rules

- `BeforeAll`/`BeforeEach` for setup, `AfterAll`/`AfterEach` for teardown.
- Variables set in `BeforeAll` are read-only in child blocks; `BeforeEach`, `It` and `AfterEach`
  share a scope.
- `-Skip:$condition` for platform-dependent tests.
- No aliases: `Where-Object`, not `?`.
