---
name: github-review-analyzer
description: >
  Use when analyzing how a specific user reviews code in the current repository.
  Activates when user asks about review patterns, style, or feedback from a
  specific GitHub user. Examples: "how does @user review code", "analyze
  review style for <login>", "find <login>'s review patterns", "what does
  <user> typically comment on", "show me @username's review examples".
---

# GitHub Review Analyzer

Analyzes a specific user's code review patterns, style, and behavior in the current repository.

## Context

- **Repository**: Current repo (discovered via `gh repo view --json nameWithOwner`)
- **Data source**: GitHub API via `gh` CLI
- **Time range**: Last 6 months (default), configurable

## Inputs

| Parameter | Required | Default |
|-----------|----------|---------|
| username | Yes | Prompt if missing |
| time_range | No | 6 months |

## Workflow

### Step 1: Validate & Get Repo Context

```bash
# Get current repo
REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')
OWNER=$(echo $REPO | cut -d/ -f1)
NAME=$(echo $REPO | cut -d/ -f2)

# Validate username exists
gh api users/{username} --jq '.login' 2>/dev/null || echo "USER_NOT_FOUND"
```

### Step 2: Collect Review Data

```bash
# Get current repo info
REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')
OWNER=$(echo $REPO | cut -d/ -f1)
NAME=$(echo $REPO | cut -d/ -f2)

# Get all PR numbers (exclude user's own PRs)
gh api repos/{owner}/{repo}/pulls?state=all --jq '[.[] | select(.user.login != "{username}")] | .[].number' \
  > /tmp/{username}_prs.txt

# For each PR, collect reviews and comments
for pr in $(cat /tmp/{username}_prs.txt); do
  # Review submission (body, state, timestamp)
  gh api repos/{owner}/{repo}/pulls/{pr}/reviews \
    --jq '[.[] | select(.user.login == "{username}")] | .[] | {
      pr: {pr},
      state: .state,
      body: .body,
      submitted: .submitted_at
    }' 2>/dev/null

  # Inline comments with location
  gh api repos/{owner}/{repo}/pulls/{pr}/comments \
    --jq '[.[] | select(.user.login == "{username}")] | .[] | {
      pr: {pr},
      path: .path,
      line: .line,
      body: .body,
      diff: .diff_hunk | split("\n")[0]
    }' 2>/dev/null
done
```

### Step 3: Analyze Patterns

Group collected data by:

| Dimension | Data Points |
|-----------|-------------|
| **Location** | File paths, line numbers, code context |
| **Content** | Phrases, tone, question vs directive ratio |
| **Types** | Bug reports, style suggestions, architecture feedback, tests |
| **Frequency** | Reviews/month, comments/review ratio |

### Step 4: Generate Report

```markdown
## @{username} Review Style Analysis

Repository: {owner}/{repo}
Time Range: last {N} months
Total Reviews: {X} | Comments: {Y}

### Style Summary
- Tone: [questioning / directive / collaborative / mixed]
- Typical length: [short / medium / verbose]
- Follow-up ratio: [high / medium / low]

### Location Patterns
| File | Count | Percentage |
|------|-------|------------|
| {file1} | {n} | {x}% |
| {file2} | {n} | {x}% |
| ... | ... | ... |

### Content Types
| Type | Frequency |
|------|-----------|
| Questions | {n}% |
| Suggestions | {n}% |
| Approvals | {n}% |
| Requests | {n}% |

### Example Comments
[{pr}@{path}:{line}]
{body}

[{pr}@{path}:{line}]
{body}

[{pr}@{path}:{line}]
{body}
```

## Quick Query Examples

Run these directly in any repo for ad-hoc analysis:

```bash
# List all comments by user with location
gh api repos/{owner}/{repo}/pulls/comments \
  --jq '[.[] | select(.user.login == "<username>")] | .[] |
    "[\(.path):\(.line // "file")] \(.body[0:150])"'

# Files most reviewed by user
gh api repos/{owner}/{repo}/pulls/comments \
  --jq '[.[] | select(.user.login == "<username>")] |
    group_by(.path) | .[] | {file: .[0].path, count: length}' \
  | jq -s 'sort_by(.count) | reverse | .[0:5]'

# Get user's review bodies (for phrase analysis)
gh api repos/{owner}/{repo}/pulls?state=all --jq '.[] | .number' \
  | while read pr; do
    gh api repos/{owner}/{repo}/pulls/{pr}/reviews \
      --jq '[.[] | select(.user.login == "<username>")] | .[].body'
  done | grep -v '^$'

# Recent activity timeline
gh api repos/{owner}/{repo}/pulls?state=all \
  --jq '[.[] | {num: .number, created: .created_at, title: .title[0:50]}] |
    sort_by(.created) | reverse | .[0:20]'

# Count reviews by state (approved, changes requested, commented)
gh api repos/{owner}/{repo}/pulls?state=all --jq '.[] | .number' \
  | while read pr; do
    gh api repos/{owner}/{repo}/pulls/{pr}/reviews \
      --jq '[.[] | select(.user.login == "<username>")] | .[].state'
  done | sort | uniq -c

# Get comments with code context
gh api repos/{owner}/{repo}/pulls/comments \
  --jq '[.[] | select(.user.login == "<username>")] | .[] | {
    file: .path | split("/")[-1],
    line: .line,
    body: .body[0:200],
    context: .diff_hunk | split("\n")[0]
  }'
```

## Notes

- Exclude user's own PRs from analysis (self-reviews not meaningful)
- Use `--paginate` for repos with many PRs
- For large repos, consider limiting time range (e.g., `created:>2026-01-01`)
- Review bodies may be empty even when inline comments exist
- Check both `reviews` (state, body) and `comments` (location, detail) endpoints
