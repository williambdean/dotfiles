# jq Query Examples for GitHub Review Analysis

Reusable queries for analyzing GitHub review patterns via `gh` CLI.

## Comments with Location

```bash
# Simple: list all comments with path and line
gh api repos/{owner}/{repo}/pulls/comments --paginate --slurp \
  --jq '.[] | "\(.path):\(.line // "file") \(.body[0:100])"'

# Filtered: comments by specific user with full context
gh api repos/{owner}/{repo}/pulls/comments --paginate --slurp \
  --jq '[.[] | select(.user.login == "<username>")] | .[] | {
    pr: .pull_request_url | split("/")[-1],
    file: .path,
    line: .line,
    body: .body
  }'

# With code snippet (first line of diff)
gh api repos/{owner}/{repo}/pulls/comments --paginate --slurp \
  --jq '.[] | {
    path: .path,
    line: .line,
    body: .body[0:200],
    snippet: .diff_hunk | split("\n")[0]
  }'
```

## File Statistics

```bash
# Files most reviewed by user (top 10)
gh api repos/{owner}/{repo}/pulls/comments --paginate --slurp \
  --jq '[.[] | select(.user.login == "<username>")] |
    group_by(.path) | .[] | {file: .[0].path, count: length}' \
  | jq -s 'sort_by(.count) | reverse | .[0:10]'

# Extension breakdown
gh api repos/{owner}/{repo}/pulls/comments --paginate --slurp \
  --jq '[.[] | select(.user.login == "<username>")] |
    .[].path | split(".")[-1]' \
  | sort | uniq -c | sort -rn

# Directory breakdown (tests/ vs src/ vs etc/)
gh api repos/{owner}/{repo}/pulls/comments --paginate --slurp \
  --jq '[.[] | select(.user.login == "<username>")] |
    .[].path | split("/")[0]' \
  | sort | uniq -c | sort -rn
```

## Review Bodies (Phrase Analysis)

```bash
# Get all non-empty review bodies by user
for pr in $(gh api repos/{owner}/{repo}/pulls?state=all --jq '.[] | .number'); do
  gh api repos/{owner}/{repo}/pulls/{pr}/reviews \
    --jq '[.[] | select(.user.login == "<username>") | select(.body != "")] | .[].body'
done

# Extract common phrases (words that appear frequently)
# Pipe output to: tr ' ' '\n' | sort | uniq -c | sort -rn | head -50

# Count question marks, suggestions, approvals
for pr in $(gh api repos/{owner}/{repo}/pulls?state=all --jq '.[] | .number'); do
  gh api repos/{owner}/{repo}/pulls/{pr}/reviews \
    --jq '[.[] | select(.user.login == "<username>")] | .[].body'
done | grep -c '?'

# Count "nit:" or "suggestion:" patterns
# grep -ci 'nit\|suggestion\|minor\|optional'
```

## Timeline & Frequency

```bash
# Recent reviews with dates
gh api repos/{owner}/{repo}/pulls?state=all --jq '.[] | .number' \
  | while read pr; do
    gh api repos/{owner}/{repo}/pulls/{pr}/reviews \
      --jq '[.[] | select(.user.login == "<username>")] |
        .[] | "\(.submitted_at[0:10]) #\(.pull_request_url | split("/")[-1])"'
  done | sort

# Reviews by month (aggregate)
# Use date extraction: .submitted_at[0:7] for YYYY-MM

# Count per repo (for org-wide analysis)
gh search prs "reviewed-by:<username>" --repo {owner}/{repo} --json number
```

## Review State Breakdown

```bash
# Count by state (APPROVED, CHANGES_REQUESTED, COMMENTED)
for pr in $(gh api repos/{owner}/{repo}/pulls?state=all --jq '.[] | .number'); do
  gh api repos/{owner}/{repo}/pulls/{pr}/reviews \
    --jq '[.[] | select(.user.login == "<username>")] | .[].state'
done | sort | uniq -c

# Percentage of approvals vs requests
# Calculate: approved / (approved + changes_requested) * 100
```

## Combined Reports

```bash
# Full analysis: comments grouped by file with examples
gh api repos/{owner}/{repo}/pulls/comments --paginate --slurp \
  --jq '[.[] | select(.user.login == "<username>")] |
    group_by(.path) | .[] | {
      file: .[0].path,
      count: length,
      examples: [.[] | {line: .line, body: .body[0:150]}] | .[0:3]
    }'

# PR-level summary
for pr in $(gh api repos/{owner}/{repo}/pulls?state=all --jq '.[] | .number'); do
  gh api repos/{owner}/{repo}/pulls/{pr}/reviews \
    --jq '[.[] | select(.user.login == "<username>")] | {
      pr: .[0].pull_request_url,
      state: .[0].state,
      comments: (. | length),
      body: .[0].body
    }'
done
```

## Useful jq Functions

```bash
# Split path to get filename
.path | split("/")[-1]

# Truncate long strings
.title[0:80]

# Extract date portion
.submitted_at[0:10]

# Filter non-empty strings
select(.body != "")

# Group and count
group_by(.path) | .[] | {file: .[0].path, count: length}

# Sort and limit
jq -s 'sort_by(.count) | reverse | .[0:10]'

# Extract domain (tests vs src)
.path | split("/")[0:2] | join("/")
```

## One-Liners for Quick Use

```bash
# "What files does @user review most?"
gh api repos/{owner}/{repo}/pulls/comments --paginate --slurp \
  --jq '[.[] | select(.user.login == "<username>")] | group_by(.path) |
    .[] | {file: .[0].path, count: length}' | jq -s 'sort_by(.count) | reverse'

# "Show me recent comments with context"
gh api repos/{owner}/{repo}/pulls/comments --paginate --slurp \
  --jq '.[] | select(.user.login == "<username>") |
    {file: .path | split("/")[-1], line: .line, text: .body[0:150]}'

# "What's @user's approval rate?"
# (requires counting APPROVED vs CHANGES_REQUESTED states)
```
