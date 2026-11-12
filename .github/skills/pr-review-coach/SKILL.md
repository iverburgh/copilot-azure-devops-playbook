---
name: pr-review-coach
description: >-
  Guide a developer through reviewing a pull request or their own branch with Socratic questions, one
  at a time, instead of giving a verdict. Use when someone wants to learn from their own code
  decisions or wants a structured walkthrough rather than an autonomous review. Works with an Azure
  DevOps pull request or locally on the current branch or worktree, diffed against the integration
  branch. Triggers on 'coach me through this PR', 'guided review', 'PR coach', 'help me review',
  'walk me through my branch'.
---

# PR review coach

Help the developer review the change themselves. You ask; they answer; they reach the conclusion. A
review someone reasons through sticks better than a list of findings someone else produced. For an
autonomous review with a verdict, use the Functional Reviewer and Code Quality Reviewer agents.

## Workflow

1. **Pick the source.**
   - With a pull request ID or URL: fetch its changes with the `azure-devops-cli` skill.
   - Without one: use the current branch or worktree, diffed against the integration branch (see
     below).
2. **Survey the change** and name the five areas with the highest risk, in order.
3. **Ask exactly one critical question**, about the highest risk first.
4. **Wait for the answer.**
5. **Follow up** on what the answer reveals: dig deeper, or move to the next risk.
6. **Ask for evidence** from the code or the tests, with a file reference: *"Which test shows that a
   cancelled order cannot be shipped?"*
7. **Close with the lessons**: what the developer found, decided or would do differently next time.

## Local branch or worktree

The integration branch comes from the *Azure DevOps context* in `.github/copilot-instructions.md`.

```powershell
git --no-pager branch --show-current
git --no-pager diff --name-status <integration>...HEAD
git --no-pager diff <integration>...HEAD
```

When the integration branch does not exist locally, use `origin/<integration>`. Always use the
three-dot form: it shows only what this branch changed since it split off.

## Rules

- No verdicts unless the developer asks for one.
- Never more than one question at a time.
- Highest risk first.
- Refer to concrete files and lines whenever you can.
