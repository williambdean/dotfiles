---
name: informative-commit-messages
description: >
  How to create helpful commit messages when making changes.
---

Keep commit messages brief. Do *not* add too many details. Use the semantic
conventions like:

- feat - new feature
- fix - bug fix
- chore - maintenance, tooling
- docs - documentation
- refactor - code refactoring
- test - adding or updating tests
- perf - performance improvements

Use a prefix of `!` in the case of a breaking change.

If a specific commit will close a GitHub issue, use "Closes #<issue-number>" in
order to trigger GitHub automation.

Get the commit style for the current repo:

```bash
git log --oneline -10
```
