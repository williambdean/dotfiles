---
name: working-in-parallel
description: >
  Multiple changes at the same time. Working in parallel using git worktrees. Use
  this when trying to develop in parallel. This is process of navigation of git
  worktrees and their PRs. If you are making many changes at the same time, this
  might be a good way to handle this work load.
---

Do not make changes to the `main` branch.

The `main` branch is checked out and then all development is done within the `worktrees`
directory.

```
... # main
./worktrees/
```

Within the `worktrees` directory will be branches in parallel. Each directory in the
worktrees will be a branch of work.

For example that looks like:

```
.   # main branch
├── src/
├── tests/
├── README.md
├── package.json  # or pyproject.toml, Cargo.toml, etc.
├── lock file
└── ...
worktrees/  # all branches being worked on
├── add-login-feature
├── fix-memory-leak
├── refactor-auth
├── update-docs
├── performance-improvements
├── fix-bug-123
└── ...
```

## Branch naming conventions

Branches follow a `<type>/<short-description>` prefix pattern:

| Prefix | Use for |
|--------|---------|
| `feat/` | new features |
| `fix/`  | bug fixes |
| `chore/` | maintenance, CI, tooling |
| `docs/` | documentation |
| `perf/` | performance improvements |
| `refactor/` | code refactoring |
| `test/` | adding or updating tests |

The worktree directory name should match the short-description part of the branch name.

```
feat/add-login  →  worktrees/add-login
fix/memory-leak →  worktrees/fix-memory-leak
```

## If needed, look for existing work that might exist

Scan the worktrees directory for existing work, or look at open PRs with:

```bash
ls worktrees/
gh pr list --json number,title,headRefName,body
```

## Starting new work

Make sure that the `main` branch is up to date before branching off.

```bash
git pull origin main
```

Use `git worktree add` to create a new worktree and branch in one step:

```bash
git worktree add worktrees/<name> -b <branch-name>
```

Example:

```bash
git worktree add worktrees/add-login-feature -b feat/add-login
```

## Continuing with work

If a branch exists remotely but not yet as a local worktree, add it via:

```bash
git fetch origin
git worktree add worktrees/<name> <branch-name>
```

Example:

```bash
git fetch origin
git worktree add worktrees/fix-memory-leak fix/memory-leak
```

## Updating from main

To pull the latest changes from `main` into a worktree:

```bash
git -C worktrees/<name> rebase main
```

Or, if a merge commit is preferred:

```bash
git -C worktrees/<name> merge main
```

Always ensure `main` is up to date first:

```bash
git pull origin main
```

## Running commands in a worktree

For git commands, use `-C` to target the worktree without changing directory:

```bash
git -C worktrees/<name> status
git -C worktrees/<name> log --oneline -5
```

For non-git commands (e.g. npm, cargo, pytest), change into the worktree directory first:

```bash
cd worktrees/<name>
# then run your test/build/lint commands
npm test
# or
cargo test
# or
pytest tests/ -q
```

Or use a subshell to avoid affecting your current shell session:

```bash
(cd worktrees/<name> && <your-command>)
```

## Removing a worktree

Once a branch has been merged (or abandoned), clean up the worktree and branch:

```bash
# Remove the worktree directory
git worktree remove worktrees/<name>

# Delete the local branch
git branch -d <branch-name>
```

Use `-D` instead of `-d` to force-delete an unmerged branch.

To prune stale worktree metadata (e.g. after a directory was deleted manually):

```bash
git worktree prune
```

## Isolated Environments

For applications, please leverage `directory` specification. For example, in a python
project using `uv`, you can do:

```bash
uv run --directory ./worktrees/some-feature <your-command>
```

This is also available using `pixi` as well.

This keeps the environment isolation!
