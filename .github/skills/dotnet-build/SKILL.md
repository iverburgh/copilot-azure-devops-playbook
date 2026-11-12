---
name: dotnet-build
description: >-
  Build and test .NET projects with minimal output, so a coding agent does not fill its context window
  with build noise. Provides the quiet dotnet flags and a wrapper script that prints one line on
  success and only the relevant errors or failed tests on failure. Use before every dotnet build or
  dotnet test. Triggers on 'dotnet build', 'dotnet test', 'build the project', 'run the tests',
  'build fails', 'tests fail'.
---

# dotnet build and test with minimal output

A default `dotnet build` or `dotnet test` prints hundreds of lines: restore progress, every project,
warnings, the test logger. An agent reads all of it, and pays for it in context and attention. This
skill keeps a successful run to one line and a failed run to the lines that explain the failure.

## Rules

- **Never build or test the whole solution.** Build the smallest project that proves the change —
  usually the test project, which builds what it references.
- **Restore once.** Pass `--no-restore` after the first restore, until a package reference changes.
- **Never cancel a build.** Builds can take minutes. Wait for the result.
- **One build at a time.** Parallel builds of overlapping projects lock each other's output files.
- Run the narrowest tests first: one test (`--filter`), then the class, then the project.

## The wrapper script (preferred)

```powershell
# First time, or after a package change: restore and build
./.github/skills/dotnet-build/scripts/Invoke-DotnetBuild.ps1 -ProjectPath tests/Orders.ComponentTests/Orders.ComponentTests.csproj -Restore

# Then test without building again
./.github/skills/dotnet-build/scripts/Invoke-DotnetBuild.ps1 -ProjectPath tests/Orders.ComponentTests/Orders.ComponentTests.csproj -Command test -NoBuild
```

| Parameter | Default | Meaning |
|---|---|---|
| `-ProjectPath` | (required) | A project file, never a solution |
| `-Command` | `build` | `build` or `test` |
| `-Restore` | off | Restore as part of the command; otherwise `--no-restore` is passed |
| `-NoBuild` | off | `test` only: skip the build |
| `-MaxErrorLines` | 25 | Maximum error lines or failed tests printed |
| `-TailLines` | 30 | Lines printed when no error line is recognised |

What it prints:

| Result | Output |
|---|---|
| Build succeeded | `build OK: <project>` |
| Tests passed | `test OK: <project> - 42/42 passed, 0 failed, 0 not executed - TRX: <path>` |
| Tests failed | The counters, then per failed test its name, the first line of the message and the first stack frame |
| Build failed | The compiler error lines (`error CS...`), or the last lines of the output when none are recognised |

The script exits with the exit code of `dotnet`. Test results go to `TestResults/dotnet-skill/` under
the repository root; add `TestResults/` to `.gitignore`.

## Without the script

```powershell
dotnet build <project> --no-restore --nologo -v quiet --tl:off -m
dotnet test <project> --no-build --no-restore --nologo -v quiet --tl:off --logger "trx;LogFileName=<project>.trx" --results-directory TestResults/dotnet-skill
```

| Flag | Effect |
|---|---|
| `--no-restore` | Skips the restore step and its output |
| `--no-build` | `test` only: uses the existing build |
| `--nologo` | No banner |
| `-v quiet` | Only errors and the final result |
| `--tl:off` | No terminal logger: its live progress display produces noise in a captured log |
| `-m` | Builds referenced projects in parallel |
| `--logger trx` | Writes the full test results to a file, so the console can stay quiet and the details can still be read |
| `--filter` | Runs a subset: `--filter "FullyQualifiedName~CancelOrder"` |

When a test fails and the console summary is not enough, read the failed `UnitTestResult` entries in
the TRX file instead of rerunning with more verbosity.
