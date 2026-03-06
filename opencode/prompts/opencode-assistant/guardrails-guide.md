# Guardrails for Agentic Workflows

As agents gain more autonomy, you need proportional guardrails to prevent quality degradation. The key principle: **more autonomy requires more constraints**.

## Core Principles

1. **Tools over prompts** - Use deterministic tools (linters, type checkers, formatters) instead of hoping the model follows instructions
2. **Run on diffs** - Validate only changed files, not the entire codebase, for faster feedback loops
3. **Reduce token burn** - Strip verbose output when tests pass; only show errors on failure
4. **Shift left** - Put guardrails inside the agent loop, not just in CI/PR review
5. **Non-optional enforcement** - Use hooks to make guardrails unavoidable

---

## Guardrail Patterns

### Permission-Based Guardrails

Use permission levels to control what agents can do.

```yaml
permission:
  bash: "ask"           # Require approval for shell commands
  edit: "deny"          # Disable file edits for read-only agents
  webfetch: "allow"     # Allow web fetches
```

**When to use:**
- Read-only agents (code reviewers, analyzers)
- Production environments
- Sensitive operations (deployments, database changes)

**Example: Code Reviewer**
```yaml
---
description: Reviews code without making changes
mode: subagent
tools:
  bash: false
  write: false
  edit: false
  read: true
  grep: true
---
```

### Tool Restriction Patterns

Explicitly disable tools that shouldn't be used.

```yaml
tools:
  bash: true
  grep: true
  read: true
  write: false          # Read-only agent
  edit: false
```

**When to use:**
- Task-specific agents (e.g., documentation generator only edits docs)
- Safety-critical agents (e.g., deployer can execute but not modify code)
- Specialized agents (e.g., test writer only creates test files)

**Example: Documentation Generator**
```yaml
---
description: Generates and updates documentation
mode: subagent
tools:
  bash: true
  read: true
  write: true
  edit: true
permission:
  rm docs/*: "deny"     # Cannot delete docs
  rm *.md: "deny"       # Cannot delete markdown
---
```

### Task Delegation Controls

Control which subagents can be invoked.

```yaml
permission:
  task:
    "*": "deny"                   # Default: no subagents
    "code-reviewer": "allow"      # Explicitly allow specific agents
    "test-writer": "allow"
```

**When to use:**
- Preventing infinite agent loops
- Controlling cost (expensive subagents)
- Enforcing workflow order (must review before deploy)

**Example: Controlled Delegation**
```json
{
  "agent": {
    "main": {
      "mode": "primary",
      "permission": {
        "task": {
          "*": "deny",
          "code-reviewer": "allow",
          "test-runner": "allow",
          "expensive-researcher": "ask"
        }
      }
    }
  }
}
```

---

## Anti-Patterns to Avoid

### 1. Hopeful Prompting

**Don't do this:**
```markdown
Always run tests before committing. Never commit without tests passing.
Make sure to format your code. Always check for lint errors.
```

**Problem:** The model may ignore these instructions under pressure or when context is full.

**Do this instead:**
- Use pre-commit hooks to enforce formatting
- Make test execution non-optional via commands
- Use permissions to prevent commits without validation

### 2. Full Codebase Validation

**Don't do this:**
```bash
# Run all tests on every change
pytest tests/
eslint src/
```

**Problem:** Too slow, floods context with passing test output.

**Do this instead:**
```bash
# Only validate changed files
git diff --name-only | grep '\.py$' | xargs pytest
git diff --name-only | grep '\.js$' | xargs eslint
```

### 3. Verbose Output

**Don't do this:**
```bash
pytest -v  # Prints every passing test
```

**Problem:** Context window filled with noise.

**Do this instead:**
```bash
pytest -q  # Quiet mode: only show failures
# Or custom output format
pytest --tb=short --no-header
```

### 4. Late-Stage Guardrails

**Don't do this:**
- Write code → commit → push → PR → CI catches issues

**Problem:** Long feedback loop, expensive to fix after merge.

**Do this instead:**
- Pre-commit hooks run checks before commit
- Commands enforce validation before push
- Subagents validate before invoking next step

---

## Integrating Deterministic Tools

For each quality check, ask: "Can a tool do this instead of the model?"

| Task | Use Tool Instead Of |
|------|---------------------|
| Code formatting | Prompting "format your code" |
| Style enforcement | Prompting "follow style guide" |
| Type checking | Prompting "use correct types" |
| Security scanning | Prompting "check for vulnerabilities" |
| Dependency checks | Prompting "verify dependencies" |
| Test execution | Prompting "make sure tests pass" |
| Linting | Prompting "follow best practices" |

### Example: Formatting Enforcement

**Bad (prompting):**
```markdown
Always format Python code with Black. Ensure line length is 88 characters.
Use double quotes for strings.
```

**Good (tooling):**
```yaml
---
description: Write Python code with auto-formatting
mode: subagent
---

After writing Python files:
1. Run `black .` to format code
2. Run `isort .` to sort imports
3. Run `flake8` to check style
4. Only proceed if all checks pass
```

### Example: Type Checking

**Bad (prompting):**
```markdown
Use type hints for all functions. Make sure types are correct.
```

**Good (tooling):**
```bash
# In command or pre-commit hook
mypy src/ --strict
```

---

## Hooks for Enforcement

Use hooks to make guardrails non-optional.

### Pre-Write Hook (Conceptual)
Before writing a file:
1. Run formatter on content
2. Check if file matches linter rules
3. Only write if passes

### Pre-Bash Hook (Conceptual)
Before executing shell command:
1. Check if command is in allowlist
2. Scan for dangerous patterns (rm -rf, etc.)
3. Require approval for unknown commands

### Pre-Task-Completion Hook (Conceptual)
Before marking task complete:
1. Run test suite
2. Check for uncommitted changes
3. Validate no errors in output

### Pre-PR Hook
Before creating PR:
1. Run security scan
2. Check test coverage
3. Validate commit messages
4. Ensure branch is up to date

**Example Command with Hooks:**
```yaml
---
description: Complete feature with full validation
agent: build
---

1. Run tests: `pytest`
2. Run linter: `ruff check .`
3. Run type checker: `mypy .`
4. Check security: `bandit -r src/`
5. Only proceed if all pass

Then:
- Commit changes
- Push to remote
- Create PR
```

---

## Permission Guidelines

### 1. Default to Restrictive
Start with minimal permissions, open as needed.

```json
{
  "permission": {
    "bash": "ask",
    "write": "ask",
    "edit": "ask",
    "webfetch": "deny"
  }
}
```

### 2. Use "ask" for Bash
Require approval for shell commands to prevent accidents.

```json
{
  "permission": {
    "bash": "ask"
  }
}
```

### 3. Use "deny" for Write/Edit
Read-only agents should not modify files.

```yaml
tools:
  write: false
  edit: false
```

### 4. Control Subagent Invocation
Prevent expensive or dangerous subagents from running freely.

```json
{
  "permission": {
    "task": {
      "*": "deny",
      "code-reviewer": "allow"
    }
  }
}
```

### 5. Use Wildcards for Bulk Permissions
Control related operations with patterns.

```json
{
  "permission": {
    "git push*": "ask",
    "git reset --hard*": "deny",
    "rm -rf*": "deny",
    "docker run*": "ask"
  }
}
```

---

## Validation Strategies

### Diff-Only Validation
Only validate files that changed.

```bash
# Get changed files
CHANGED_FILES=$(git diff --name-only main...HEAD)

# Validate only changed Python files
echo "$CHANGED_FILES" | grep '\.py$' | xargs pytest
echo "$CHANGED_FILES" | grep '\.py$' | xargs ruff check
```

### Staged-Only Validation
Only validate files staged for commit.

```bash
# Get staged files
STAGED_FILES=$(git diff --cached --name-only)

# Validate only staged files
echo "$STAGED_FILES" | grep '\.py$' | xargs black --check
echo "$STAGED_FILES" | grep '\.py$' | xargs mypy
```

### Smart Test Selection
Only run tests for changed modules.

```bash
# Run tests for changed modules
pytest --testmon  # Only tests affected by changes
```

---

## Output Control

### Quiet Successful Operations
Only show output when something fails.

```bash
# Bad: Verbose success output
pytest -v

# Good: Quiet unless errors
pytest -q

# Good: Only show failures
pytest --tb=short --no-header -q
```

### Summarize Long Output
Don't flood context with full output.

```bash
# Bad: All test output
pytest

# Good: Summary only
pytest -q || echo "Tests failed - see above"
```

### Structured Error Reporting
Make errors easy to parse and fix.

```bash
# Use JSON output for programmatic parsing
eslint src/ --format json

# Or structured output
pytest --tb=short --no-header
```

---

## Progressive Guardrails

Start loose, tighten over time.

### Phase 1: Development (Loose)
```json
{
  "permission": {
    "bash": "allow",
    "write": "allow",
    "edit": "allow"
  }
}
```

### Phase 2: Stabilization (Medium)
```json
{
  "permission": {
    "bash": "ask",
    "write": "allow",
    "edit": "allow",
    "git push*": "ask"
  }
}
```

### Phase 3: Production (Strict)
```json
{
  "permission": {
    "bash": "ask",
    "write": "ask",
    "edit": "ask",
    "git push*": "deny",
    "task": {
      "*": "deny",
      "code-reviewer": "allow"
    }
  }
}
```

---

## Example: Complete Guardrail Setup

Full example with multiple guardrail layers:

```json
{
  "agent": {
    "production": {
      "mode": "primary",
      "description": "Production-safe development agent",
      "permission": {
        "bash": "ask",
        "write": "allow",
        "edit": "allow",
        "git push --force*": "deny",
        "git reset --hard*": "deny",
        "rm -rf*": "deny",
        "docker run --privileged*": "deny",
        "task": {
          "*": "deny",
          "code-reviewer": "allow",
          "test-runner": "allow"
        }
      },
      "instructions": [
        "docs/coding-standards.md",
        "docs/security-checklist.md"
      ]
    }
  }
}
```

**Command with validation:**
```yaml
---
description: Complete feature with full validation
agent: production
---

# Pre-commit validation
1. Format code: `black . && isort .`
2. Type check: `mypy src/ --strict`
3. Run tests: `pytest -q`
4. Security scan: `bandit -r src/`
5. Check coverage: `pytest --cov=src --cov-fail-under=80`

# Only if all pass:
6. Commit changes with semantic message
7. Push to feature branch
8. Invoke @code-reviewer to review changes

# After review passes:
9. Create pull request with summary
```

---

## Key Takeaways

1. **Prefer tools over prompts** - Deterministic validation beats hopeful instructions
2. **Start restrictive** - Easier to open permissions than tighten them
3. **Validate early** - Shift left, catch issues in agent loop, not CI
4. **Control delegation** - Use `permission.task` to prevent agent loops
5. **Make it fast** - Diff-only validation, quiet output, smart test selection
6. **Make it unavoidable** - Use hooks, commands, and permissions, not prompts
