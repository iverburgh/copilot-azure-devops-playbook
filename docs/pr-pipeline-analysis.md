# Analysing failing pull request pipelines

A pull request with five validation pipelines, two of them red, and a log of 40,000 lines each. The
**PR Pipeline Analyzer** turns that into one report.

Run `/analyze-pr-pipelines <id>`, or pick the agent and write:

> Builds are failing on PR 4321, analyse.

## What it does

1. Fetches the pull request and its latest run per pipeline — from `refs/pull/<id>/merge`, which is
   where PR builds actually run; filtering on the source branch finds nothing.
2. Finds the failed stages, jobs and tasks and pulls only the relevant log lines.
3. Classifies each failure: compilation, test, runtime or startup, infrastructure, configuration,
   policy.
4. **Checks whether the PR caused it** by looking at the same pipeline on the target branch. A
   failure that is already there is not yours to fix in this PR; a test that fails on and off across
   recent runs is called flaky, with the evidence.
5. Reads the PR diff near each error.
6. For each root cause, advises:
   - *Mitigation* — how to unblock now: a rerun only with evidence of flakiness, a rebase once the
     target is fixed;
   - *Temporary fix* — the smallest change that turns it green without hiding the problem;
   - *Change* — the proper fix, with file and line.

## The report

```markdown
## Pipeline analysis — PR #4321: Accept remarks on orders

| Pipeline | Run | Result | Failed task | Introduced by PR? |
|---|---|---|---|---|
| orders-api | 98765 | ❌ | dotnet test | Yes |
| ui | 98766 | ❌ | npm test | No — fails on the target branch too |

### 1. Remarks longer than 500 characters are truncated silently
Category: Test · Related code: OrderMapper.cs line 42 ...
```

Afterwards you can ask it to implement a fix, show more of a log, or compare with the last green run.

## Why the commands look the way they do

The agent and its skill use single-line commands chained with `;`, `az devops invoke` instead of
`az rest`, and git instead of a PR diff command. Each of those avoids a failure that costs a round
trip; the reasons are in [pitfalls](pitfalls.md#pipelines-and-pull-requests).
