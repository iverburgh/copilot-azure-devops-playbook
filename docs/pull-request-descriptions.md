# Pull request descriptions

Run `/pr-description` on your branch. The instruction behind it:

> Can you summarise the changes in this branch, compared with the development branch, for a pull
> request description? Shorter is better: ideally around 2000 characters, at most 4000.

## Why these numbers

Azure DevOps limits a pull request description to **4000 characters**; anything longer is rejected
when you create or update the PR. Around 2000 is where a description is still read in full by a
reviewer who has twenty other things open.

## What it does

1. Compares against the **merge base** with the target branch (`origin/<target>...HEAD`), so changes
   merged into the target after you branched do not show up as yours.
2. Finds the work item from the branch name or commit messages and fetches its acceptance criteria.
3. Uses the REP, if there is one, for acceptance criteria and change type.
4. Describes why and what changed in behaviour, grouped by component — not a file list.
5. Reports only verification it can prove: tests it ran in the session, or pipeline results.
6. States the character count.

## Output

A title in the format `<Type> #<WorkItemId>: <short description>` — putting `#<id>` in the title links
the work item automatically — and the description in a Markdown block you can paste as-is:

```markdown
## Problem
Cancelled orders kept their reserved stock until the nightly job ran.

## Solution
Release the reservation in the same transaction as the cancellation...

## Changes
- **Orders domain**: cancellation releases reservations
- **Tests**: component tests for cancel-before-ship and cancel-after-partial-ship

## Verification
- Order component tests: 48 passed

## Acceptance criteria
- ✅ Stock is available again immediately after cancellation
```

It does not create the pull request unless you ask. When you do, it creates a **draft** targeting the
same branch it compared against, so you review your own PR before anyone else is notified.
