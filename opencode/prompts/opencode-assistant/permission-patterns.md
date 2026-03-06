# Permission Patterns & Tool Restrictions

This document covers permission levels, tool restrictions, and access control patterns for OpenCode agents.

## Permission Levels

OpenCode supports three permission levels for all tools and operations:

- **`allow`**: Run without approval (auto-execute)
- **`ask`**: Prompt for approval before executing
- **`deny`**: Disabled (tool cannot be used)

---

## Basic Permission Configuration

### Tool-Level Permissions
```json
{
  "permission": {
    "bash": "ask",        // Require approval for shell commands
    "write": "allow",     // Allow file creation without approval
    "edit": "allow",      // Allow file edits without approval
    "webfetch": "deny"    // Disable web fetching
  }
}
```

### Agent-Specific Permissions (in frontmatter)
```yaml
---
description: Read-only code reviewer
mode: subagent
tools:
  bash: false
  write: false
  edit: false
  read: true
  grep: true
  glob: true
---
```

### Permission Override (in opencode.jsonc)
```json
{
  "agent": {
    "safe-reviewer": {
      "mode": "subagent",
      "description": "Code reviewer that cannot modify files",
      "permission": {
        "bash": "deny",
        "write": "deny",
        "edit": "deny"
      }
    }
  }
}
```

---

## Wildcard Patterns

Use wildcards for bulk permissions on commands or MCP tools.

### Command Wildcards
```json
{
  "permission": {
    "git status": "allow",
    "git diff": "allow",
    "git log": "allow",
    "git push*": "ask",        // Require approval for any push command
    "git reset --hard*": "deny", // Block force operations
    "rm -rf*": "deny",         // Block recursive force deletion
    "npm install*": "ask",     // Ask before installing packages
    "docker run*": "ask"       // Ask before running containers
  }
}
```

### MCP Tool Wildcards
```json
{
  "permission": {
    "mymcp_*": "ask",          // All MCP tools starting with mymcp_
    "github_*": "allow",       // All GitHub MCP tools
    "filesystem_read*": "allow",
    "filesystem_write*": "ask",
    "stripe_*": "deny"         // Disable all Stripe tools
  }
}
```

---

## Task Delegation Controls

Control which subagents can be invoked using `permission.task`.

### Default Deny with Allowlist
```json
{
  "permission": {
    "task": {
      "*": "deny",                  // Block all subagent invocations by default
      "code-reviewer": "allow",     // Explicitly allow code-reviewer
      "test-writer": "allow",       // Explicitly allow test-writer
      "docs-generator": "allow"     // Explicitly allow docs-generator
    }
  }
}
```

### Default Allow with Denylist
```json
{
  "permission": {
    "task": {
      "*": "allow",                 // Allow all subagents by default
      "dangerous-agent": "deny",    // Block specific agent
      "experimental-*": "deny"      // Block all experimental agents
    }
  }
}
```

### Require Approval for Expensive Agents
```json
{
  "permission": {
    "task": {
      "*": "allow",
      "web-researcher": "ask",      // Ask before invoking (makes API calls)
      "code-generator": "ask"       // Ask before invoking (uses many tokens)
    }
  }
}
```

---

## Read-Only Agent Patterns

### Pure Read-Only Agent
```yaml
---
description: Analyzes code without making changes
mode: subagent
tools:
  bash: false      # No shell access
  write: false     # Cannot create files
  edit: false      # Cannot modify files
  read: true       # Can read files
  grep: true       # Can search content
  glob: true       # Can find files
  webfetch: false  # No external fetching
---
```

### Read-Only with Safe Commands
```json
{
  "agent": {
    "analyzer": {
      "mode": "subagent",
      "description": "Analyzes code with safe shell commands",
      "permission": {
        "bash": "ask",           // Require approval for any bash
        "write": "deny",
        "edit": "deny",
        "git push*": "deny",     // Extra safety: block pushes
        "rm*": "deny",           // Extra safety: block deletions
        "mv*": "deny"            // Extra safety: block moves
      }
    }
  }
}
```

---

## Development vs Production Modes

### Development Mode (Permissive)
```json
{
  "agent": {
    "dev": {
      "mode": "primary",
      "description": "Full development access",
      "permission": {
        "bash": "allow",
        "write": "allow",
        "edit": "allow",
        "task": {
          "*": "allow"
        }
      }
    }
  }
}
```

### Production Mode (Restrictive)
```json
{
  "agent": {
    "prod": {
      "mode": "primary",
      "description": "Production environment with guardrails",
      "permission": {
        "bash": "ask",              // Require approval for all commands
        "write": "ask",             // Require approval for new files
        "edit": "ask",              // Require approval for edits
        "git push*": "deny",        // Block direct pushes
        "docker run*": "deny",      // Block container execution
        "npm install*": "deny",     // Block package changes
        "task": {
          "*": "deny",
          "code-reviewer": "allow"  // Only allow reviewer subagent
        }
      }
    }
  }
}
```

---

## Specialized Agent Patterns

### Code Reviewer (No Write Access)
```json
{
  "agent": {
    "reviewer": {
      "mode": "subagent",
      "description": "Reviews code for best practices",
      "permission": {
        "bash": "deny",
        "write": "deny",
        "edit": "deny",
        "task": {
          "*": "deny"  // Cannot invoke other agents
        }
      }
    }
  }
}
```

### Test Writer (Write Tests Only)
```json
{
  "agent": {
    "test-writer": {
      "mode": "subagent",
      "description": "Writes test files only",
      "permission": {
        "bash": "ask",
        "write": "allow",           // Can create new test files
        "edit": "ask",              // Ask before editing existing
        "rm tests/*": "deny",       // Cannot delete tests
        "task": {
          "*": "deny"
        }
      }
    }
  }
}
```

### Documentation Generator (Docs Only)
```json
{
  "agent": {
    "docs-writer": {
      "mode": "subagent",
      "description": "Generates documentation",
      "permission": {
        "bash": "allow",
        "write": "allow",
        "edit": "allow",
        "rm docs/*": "deny",        // Cannot delete docs
        "rm *.md": "deny",          // Cannot delete markdown files
        "task": {
          "code-reviewer": "allow"  // Can invoke reviewer for accuracy
        }
      }
    }
  }
}
```

### Deployer (Execute Only, No Code Changes)
```json
{
  "agent": {
    "deployer": {
      "mode": "subagent",
      "description": "Handles deployments",
      "permission": {
        "bash": "ask",              // Ask for all commands
        "write": "deny",            // Cannot change code
        "edit": "deny",             // Cannot modify files
        "git push*": "ask",         // Ask before pushing
        "docker*": "ask",           // Ask before Docker operations
        "npm run deploy*": "ask",   // Ask before deployment
        "task": {
          "*": "deny"               // Cannot delegate
        }
      }
    }
  }
}
```

---

## Progressive Permission Strategy

Start restrictive, open up as needed.

### Phase 1: New Agent (Very Restrictive)
```json
{
  "permission": {
    "bash": "ask",
    "write": "ask",
    "edit": "ask",
    "webfetch": "deny",
    "task": {
      "*": "deny"
    }
  }
}
```

### Phase 2: Trust Building (Selective Allow)
```json
{
  "permission": {
    "bash": "ask",
    "write": "allow",           // Opened after testing
    "edit": "allow",            // Opened after testing
    "git status": "allow",      // Safe read-only git commands
    "git diff": "allow",
    "webfetch": "deny",
    "task": {
      "*": "deny",
      "code-reviewer": "allow"  // Added after validation
    }
  }
}
```

### Phase 3: Mature Agent (Targeted Restrictions)
```json
{
  "permission": {
    "bash": "allow",            // Most commands allowed
    "write": "allow",
    "edit": "allow",
    "webfetch": "allow",
    "git push --force*": "deny", // Only block dangerous operations
    "rm -rf /*": "deny",
    "docker run --privileged*": "deny",
    "task": {
      "*": "allow",
      "experimental-*": "deny"  // Only block experimental agents
    }
  }
}
```

---

## Environment-Specific Permissions

Use different configs for different environments.

### Local Development (opencode.jsonc)
```json
{
  "permission": {
    "bash": "allow",
    "write": "allow",
    "edit": "allow",
    "task": {
      "*": "allow"
    }
  }
}
```

### CI/CD Environment (opencode.ci.jsonc)
```json
{
  "permission": {
    "bash": "allow",
    "write": "allow",
    "edit": "deny",             // Cannot modify existing files
    "git push*": "deny",        // Cannot push from CI
    "task": {
      "*": "deny",
      "test-runner": "allow"    // Only testing agent
    }
  }
}
```

---

## MCP Server Permissions

Control access to MCP server tools.

### GitHub MCP (Selective Access)
```json
{
  "mcp": {
    "github": {
      "type": "local",
      "command": ["npx", "-y", "@modelcontextprotocol/server-github"],
      "enabled": true
    }
  },
  "permission": {
    "github_create_issue": "allow",
    "github_create_pr": "ask",
    "github_merge_pr": "deny",
    "github_delete_*": "deny"
  }
}
```

### File System MCP (Read-Only)
```json
{
  "permission": {
    "filesystem_read_file": "allow",
    "filesystem_read_directory": "allow",
    "filesystem_write_file": "deny",
    "filesystem_delete_*": "deny"
  }
}
```

---

## Security Best Practices

1. **Default to restrictive** - Start with minimal permissions
2. **Use `ask` for bash** - Require approval for shell commands
3. **Use `deny` for destructive ops** - Block force operations, deletions
4. **Control subagent invocation** - Use `permission.task` to restrict agents
5. **Use wildcards carefully** - Broad patterns can have unintended effects
6. **Audit permissions regularly** - Review what agents can actually do
7. **Environment-specific configs** - Different permissions for dev vs prod
8. **Test in sandbox first** - Validate permission changes in safe environment
