---
name: informative-pull-requests
description: >
  How to best create or edit pull requests title and body in order to be precise and
  informative. Use this when creating or editing GitHub issues or Pull Requests.
---

Use the GitHub CLI while creating Pull Requests.

For example:

```terminal
gh pr create --title <some-title> --body <some-body>
gh pr edit <some-number> --title <some-title> --body <some-body>
```

## Title and Body Style

Please be brief with the title and the body.

Please omit obvious details like:

- summary of the file changes
- which tests are being added

Note that `!` prefixed on the PR title indicates a *BREAKING* change.

## Template

```
feat/chore/perf/fix/etc: <title>

<optional-closing-issue>

<one-sentence summary>

<code-block-on-how-to-leverage-these-changes>

<where-else-this-will-impact-in-repo>

<brief-but-informative-details-to-provide-context>
```

## Style

- Don't use em-dash
- Use casual but precise language
- Be brief
- Focus on the "why" not the "what"

## Examples

Adding to documentation:

```
docs(readme): add installation instructions

The installation instructions were missing. This PR adds details for various
package managers.
```

Dropping support for an older version:

```
!main: drop support for Neovim 0.7.0

The latest features require neovim 0.7.0 to be dropped.

Please update neovim version or pin version to ...
```

Adding a new feature:

```
feat(module): add new capability

This adds a new feature that enables X. Use it like:

    command --flag

For more examples, look at recent merged PRs in this repository.
```
