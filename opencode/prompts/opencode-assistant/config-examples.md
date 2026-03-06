# Configuration Examples

This document contains detailed configuration examples for OpenCode agents, subagents, skills, and commands.

## Frontmatter Examples

### Subagent Configuration
```yaml
---
description: Reviews code for best practices and potential issues
mode: subagent
temperature: 0.1
verbose: false
prompt: {file:./prompts/code-reviewer.md}
tools:
  bash: false
  read: true
  grep: true
  glob: true
  write: false
  edit: false
---
```

### Primary Agent Configuration (in opencode.jsonc)
```json
{
  "agent": {
    "build": {
      "mode": "primary",
      "description": "Default development agent",
      "tools": {
        "bash": true,
        "read": true,
        "write": true,
        "edit": true
      }
    },
    "plan": {
      "mode": "primary",
      "description": "Planning and analysis without making changes",
      "permission": {
        "edit": "deny",
        "write": "deny",
        "bash": "ask"
      }
    }
  }
}
```

### Skill Configuration
```yaml
---
name: tdd-workflow
description: >
  Use when user wants test-driven development with red-green-refactor loop.
  Activated by keywords: TDD, test-first, red-green-refactor, write tests first.
metadata:
  category: testing
  difficulty: intermediate
---
```

### Command Configuration
```yaml
---
description: Run the test suite and report failures
agent: build
model: anthropic/claude-sonnet-4.5
subtask: false
---

Run the full test suite using pytest:
```bash
pytest -v --cov=. --cov-report=term-missing
```

If any tests fail:
1. Show the failure output
2. Analyze the root cause
3. Suggest fixes
4. Ask if user wants you to fix them
```

---

## Command Templates with Placeholders

### Using $ARGUMENTS
```yaml
---
description: Deploy to specified environment
agent: deploy
---

Deploy the application to $ARGUMENTS environment.

Steps:
1. Verify environment exists: $1
2. Run pre-deployment checks
3. Execute deployment script for $1
4. Run post-deployment tests
```

**Usage:**
```
/deploy staging
/deploy production
```

### Using Individual Positional Arguments
```yaml
---
description: Create a new component with tests
agent: build
---

Create a new $1 component named $2.

Tasks:
1. Create component file: src/components/$2.tsx
2. Create test file: tests/components/$2.test.tsx
3. Add component to index exports
4. Generate basic $1 structure with props
```

**Usage:**
```
/create-component Button PrimaryButton
# $1 = Button, $2 = PrimaryButton
```

### Using Bash Command Injection
```yaml
---
description: Commit changes with generated message
agent: build
---

Current git status:
!`git status --short`

Staged changes:
!`git diff --staged --stat`

Generate an appropriate commit message based on the changes above and create the commit.
```

### Using File Content Injection
```yaml
---
description: Review the current feature branch
agent: code-reviewer
---

Review the following files that changed in this branch:

!`git diff main --name-only`

For each file, check:
1. Code quality and best practices
2. Test coverage
3. Documentation completeness

Current test results:
!`pytest --collect-only`
```

---

## Agent Mode Configurations

### Subagent (Invoked via @mention)
```yaml
---
description: Expert in building OpenCode configurations
mode: subagent
temperature: 0.1
tools:
  bash: true
  read: true
  grep: true
  glob: true
  write: true
  edit: true
---
```

### Primary Agent (Tab switching)
```json
{
  "agent": {
    "dev": {
      "mode": "primary",
      "description": "Full development mode with all tools",
      "tools": {
        "bash": true,
        "write": true,
        "edit": true
      }
    },
    "review": {
      "mode": "primary",
      "description": "Read-only code review mode",
      "tools": {
        "bash": false,
        "write": false,
        "edit": false,
        "read": true,
        "grep": true
      }
    }
  }
}
```

### Hidden Agent (Only invoked by other agents)
```yaml
---
description: Internal helper for data processing
mode: subagent
hidden: true
tools:
  bash: true
  read: true
  write: false
---
```

---

## Tool Configurations

### Available Tools
```yaml
tools:
  bash: true          # Execute shell commands
  read: true          # Read files
  grep: true          # Search file contents
  glob: true          # Find files by pattern
  write: true         # Create new files
  edit: true          # Modify existing files
  webfetch: true      # Fetch web content
  websearch: true     # Search the web
  question: true      # Ask user questions
```

### Tool Permission Levels
```json
{
  "permission": {
    "bash": "allow",      // Run without approval
    "write": "ask",       // Prompt for approval
    "edit": "deny",       // Disabled
    "webfetch": "allow"
  }
}
```

---

## Model Overrides

### Command with Specific Model
```yaml
---
description: Quick syntax check using fast model
agent: build
model: anthropic/claude-haiku-4
---

Run syntax check on $ARGUMENTS:
- Check for common errors
- Validate imports
- Quick type check
```

### Agent with Model Override
```json
{
  "agent": {
    "quick-review": {
      "mode": "subagent",
      "description": "Fast code review with cheaper model",
      "model": "anthropic/claude-haiku-4",
      "tools": {
        "write": false,
        "edit": false
      }
    }
  }
}
```

---

## Subtask Mode (Force Subagent)

Forces the command to run in a separate subagent window, keeping main context clean.

```yaml
---
description: Run comprehensive test suite
agent: build
subtask: true
---

Run all tests including:
1. Unit tests
2. Integration tests
3. E2E tests
4. Performance benchmarks

This will run in a separate window to avoid polluting the main conversation.
```

---

## Steps Property (Cost Control)

Limit maximum agentic iterations for expensive operations.

```yaml
---
description: Generate API documentation
agent: docs
steps: 10
---

Generate comprehensive API documentation:
1. Scan all API endpoints
2. Extract parameters and responses
3. Generate OpenAPI spec
4. Create markdown docs
5. Add code examples

Limited to 10 agentic steps to control costs.
```

---

## External Prompt Files

Keep complex prompts in separate files for better organization.

### Agent with External Prompt
```yaml
---
description: Manages Kanban board tasks
mode: subagent
prompt: {file:./prompts/kanban-manager.md}
tools:
  write: false
  edit: false
---
```

### Command with External Template
```yaml
---
description: Create new feature with full scaffolding
agent: build
prompt: {file:./templates/feature-scaffold.md}
---
```

**`prompts/kanban-manager.md`:**
```markdown
# Kanban Manager Agent

You are an expert at managing tasks using the Kanban board.

## Your Role
Help users create, organize, and track tasks effectively.

## Available Tools
You have access to kanban_* tools for task management.

## Best Practices
- Keep task titles concise (under 50 chars)
- Use categories to organize related tasks
- Set appropriate stages: backlog, in_progress, done
- Use blocking relationships for dependencies
```

---

## Instructions Array (Multiple Rule Files)

Instead of one massive AGENTS.md, use multiple specialized rule files.

```json
{
  "instructions": [
    "AGENTS.md",
    "docs/api-standards.md",
    "docs/ui-guidelines.md",
    "docs/security-checklist.md"
  ]
}
```

This loads all files as project-wide instructions at session start.

---

## Complete Agent Example

Full-featured agent configuration with all options:

```json
{
  "agent": {
    "fullstack-dev": {
      "mode": "primary",
      "description": "Full-stack development with guardrails",
      "model": "anthropic/claude-sonnet-4.5",
      "temperature": 0.3,
      "verbose": false,
      "tools": {
        "bash": true,
        "read": true,
        "grep": true,
        "glob": true,
        "write": true,
        "edit": true,
        "webfetch": true,
        "websearch": false,
        "question": true
      },
      "permission": {
        "bash": "ask",
        "write": "allow",
        "edit": "allow",
        "task": {
          "*": "deny",
          "code-reviewer": "allow",
          "test-writer": "allow"
        },
        "git push*": "ask",
        "rm -rf*": "deny"
      },
      "instructions": [
        "docs/coding-standards.md",
        "docs/testing-requirements.md"
      ]
    }
  }
}
```
