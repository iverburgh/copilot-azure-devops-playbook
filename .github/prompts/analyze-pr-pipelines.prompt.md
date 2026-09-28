---
description: 'Analyse the failing pipelines on an Azure DevOps pull request and advise on fixes.'
agent: PR Pipeline Analyzer
argument-hint: 'Pull request ID or URL'
---

Builds are failing on pull request ${input:pr:PR ID or URL}. Analyse them.

For every root cause, tell me whether the PR introduced it, and advise on mitigation, a temporary
fix, and the proper change.
