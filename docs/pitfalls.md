# Pitfalls

The traps that shaped these agents. Most of them fail **silently**: the command reports success and
stores something else, or nothing. That is why every write in this playbook ends with a read-back.

## Work items

### The CLI keeps only the first line of HTML

`az boards work-item create` and `update` with `--description "<html>"` or
`--fields "Microsoft.VSTS.Common.AcceptanceCriteria=<html>"` store the text up to the **first
newline** and drop the rest. The command returns a valid work item ID and no warning. We found out
when a carefully refined item turned out to hold fourteen characters: its first heading.

**Do instead:** create the item with the CLI without HTML fields, then write the HTML with a REST
PATCH (`application/json-patch+json`), and read the lengths back. The pattern is in the
[azure-devops-rest-writes skill](../.github/skills/azure-devops-rest-writes/SKILL.md).

### Azure DevOps rewrites the HTML you store

Read back what you wrote and it is different: lengths change, and a space appears before closing
tags — `<h3>Goal</h3>` becomes `<h3>Goal </h3>`. A verification with an exact `Contains()` on your own
source string fails, and a second edit that replaces a block from your source finds nothing.

**Do instead:** verify with a tolerant regex, and base every follow-up edit on a fresh GET of the
stored value.

### Scripted edits need a dry run

When an agent edits an existing description, the safest shape is a `.ps1` file with an `-Execute`
switch. By default it only checks that every block it is about to replace occurs exactly once; only
`-Execute` writes. This caught the rewritten-HTML problem above before it touched a single item.

### Never parse raw JSON with `Select-String`

Work item JSON contains many nested `"id"` fields. Grepping for the ID picks the wrong one. Always
`--output json | ConvertFrom-Json` and take `.id`.

## Wiki pages

### A byte-array body stores an empty page

Sending the PUT body for a wiki page as a byte array — a common way to force UTF-8 — succeeds, creates
a commit, and stores the page **empty**. On a shared wiki that is a production incident.

**Do instead:** send the JSON as a string with `Content-Type: application/json; charset=utf-8`.
Accented characters survive. Read the page back and check the content length. If it already
happened: a code wiki is a Git repository, and the previous version is one commit back.

### Page paths use spaces, URLs use hyphens

The wiki shows `/Functional-Design/Order-Processes` in the browser. The Pages API wants
`/Functional Design/Order Processes`; the hyphenated version returns page-not-found. A literal hyphen
in a page name is stored as `%2D` in the Git path.

### Code wikis need a branch and an ETag

A wiki published from a Git repository rejects page updates without
`versionDescriptor.versionType=branch` and the branch name, and needs the page's ETag in `If-Match`.
The ETag header can come back as an array; take the first element.

### Line endings break tables

Wiki content may use CRLF. A regex replace with multiline `$` keeps the CR inside the match; append a
CRLF and you get CR-CR-LF, which renders as an empty line — and a Markdown table ends at the first
empty line, so every row after it becomes plain text. Normalise to LF before editing.

Related: a heading directly after a list item, without an empty line in between, renders as part of
the list.

## Pipelines and pull requests

### PR builds run on the merge ref

Pipelines triggered by a pull request run against `refs/pull/<id>/merge`. Listing runs for the PR's
source branch returns nothing, which looks like "no pipeline ran".

### There is no `--status failed`

`az pipelines runs list --status` accepts statuses like `completed`; failure is a *result*. Filter
`--status completed`, then on `result`.

### There is no `az repos pr diff`

Use `git fetch origin <branch>` and `git diff origin/<target>...FETCH_HEAD`. Three dots: against the
merge base, so changes on the target branch do not show up as the PR's.

### Pull request descriptions stop at 4000 characters

Azure DevOps rejects longer descriptions. Aim for about 2000; that is also roughly where reviewers
stop reading.

### "Fix the pipeline" is not permission to change a branch policy

Asked to get a pull request green, an agent with the Azure CLI can widen a build validation path
filter or switch a policy off, and the build passes. That is a change to protected configuration
that nobody asked for. Put the branch policy rule from the
[template](../templates/copilot-instructions.azure-devops.md) in your `copilot-instructions.md`:
read-only inspection is fine, any policy change needs an explicit request for that exact change.

### Path filters live in two places

A pipeline's YAML trigger and the build validation policy on the integration branch each have
their own path filter, in a different syntax. Add a project reference and update only one, and a
pull request either skips a build it needs or runs one it does not. The
[`path-filter-sync`](../.github/skills/path-filter-sync/SKILL.md) skill checks both.

## Agents and long-running work

### Full build output eats the context

`dotnet build` and `dotnet test` print hundreds of lines on success. An agent reading all of them
loses room for the code, and the one error that matters scrolls past. The
[`dotnet-build`](../.github/skills/dotnet-build/SKILL.md) skill runs them quietly and shows only
errors and failed tests. Builds can take minutes; let them finish instead of cancelling and
starting again.

### An agent interrupts long steps

Agents tend to move a long command to the background, then poll for its result, or stop to ask what
to do while it is still running. For a restore or a deployment, that is dangerous. Write in the
skill that the step must run to completion, and let the script print one clear marker when it is
done. See [agentic-runbooks.md](agentic-runbooks.md).

### The agent assumes an environment

A runbook that starts with a dry-run against "the current subscription" can read production when
you meant test. Make the first question always *which environment*, and run nothing until the user
names it.

## Terminal and CLI

### Multi-line commands get cut off

In agent terminals, multi-line scripts are often executed only up to the first line, or hang on the
continuation prompt when a quote is escaped wrongly. Every command in these skills is a single line
chained with `;`. Anything longer goes in a `.ps1` file.

### `az rest` is not your friend here

On Windows it crashes on Unicode characters in responses, and it URL-encodes `&` inside the URL to
`%26`, which silently breaks query strings. `az devops invoke` covers most Azure DevOps endpoints;
for the rest use `Invoke-RestMethod` with a token from `az account get-access-token`.

### A 200 with an HTML page means you are not logged in

When the token is not accepted, some endpoints return the sign-in page with status 200. Parse the
response as JSON and fail loudly when that does not work; then `az login`.

### Windows PowerShell 5.1 differs

`Invoke-RestMethod -ResponseHeadersVariable` does not exist in 5.1; use `Invoke-WebRequest` and read
`.Headers`. In PowerShell 7 `.Content` is already a string, so decoding it as bytes crashes. Code that
must run in both checks the type.

## Telemetry

### Most KQL examples use the wrong column names

Workspace-based Application Insights tables use `AppRoleName`, `OperationId`, `DurationMs`,
`ExceptionType`. The classic names — `cloud_RoleName`, `operation_Id`, `duration`, `type` — appear in
most examples online and return nothing or an error. When in doubt, `<Table> | take 1` shows the real
schema.
