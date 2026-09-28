---
description: 'Summarise the changes in this branch against the integration branch as a pull request title and description (around 2000 characters, at most 4000).'
argument-hint: 'Target branch (default: the integration branch from copilot-instructions)'
---

Can you summarise the changes in this branch, compared with the
${input:targetBranch:integration branch} branch, for a pull request description? Shorter is better:
ideally around 2000 characters, at most 4000 — Azure DevOps rejects longer descriptions.

## How

1. `git fetch origin`, then compare against the merge base, not against the branch tip:
   `git diff origin/<target>...HEAD --stat`, `git log origin/<target>..HEAD --oneline`, and read the
   diffs of the files that matter.
2. Find the work item: from the branch name or the commit messages. Fetch its title and acceptance
   criteria with the `azure-devops-cli` skill when available.
3. If a REP exists in `~/.copilot/reps/`, use its acceptance criteria and change type.
4. Describe *why* and *what changed in behaviour*, not a file-by-file list. Group by component.
5. Only report verification you can prove: tests you ran in this session, or pipeline results. Do
   not claim green builds you did not see.
6. Count the characters of the description and state the count.

## Output

Follow `.github/instructions/pull-requests.instructions.md` for the title format and the description
template. Give the title first, then the description in one fenced Markdown block so it can be pasted
as-is, and state the character count.

Do not create the pull request unless I ask; if I do, create it as a draft targeting the same branch.
