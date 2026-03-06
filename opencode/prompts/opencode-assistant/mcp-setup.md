# MCP Server Setup Guide

This document covers MCP (Model Context Protocol) server configuration, including types, setup patterns, and best practices.

## MCP Server Types

OpenCode supports two types of MCP servers:

- **`local`**: Runs as subprocess (stdio communication)
- **`docker`**: Runs in Docker container

---

## Basic MCP Configuration

### Local MCP Server
```json
{
  "mcp": {
    "github": {
      "type": "local",
      "command": ["npx", "-y", "@modelcontextprotocol/server-github"],
      "enabled": true
    }
  }
}
```

### Docker MCP Server
```json
{
  "mcp": {
    "my-custom-server": {
      "type": "docker",
      "image": "myorg/mcp-server:latest",
      "enabled": true
    }
  }
}
```

---

## Environment Variables

MCP servers often need API keys, tokens, or configuration values.

### Using Environment Variables
```json
{
  "mcp": {
    "github": {
      "type": "local",
      "command": ["npx", "-y", "@modelcontextprotocol/server-github"],
      "environment": {
        "GITHUB_TOKEN": "${GITHUB_TOKEN}"
      },
      "enabled": true
    }
  }
}
```

**How it works:**
- `${GITHUB_TOKEN}` references environment variable from your shell
- Set in shell: `export GITHUB_TOKEN="ghp_xxxxx"`
- Or in `~/.zshrc`: `export GITHUB_TOKEN="ghp_xxxxx"`

### Multiple Environment Variables
```json
{
  "mcp": {
    "my-server": {
      "type": "local",
      "command": ["my-mcp-server"],
      "environment": {
        "API_KEY": "${MY_API_KEY}",
        "API_SECRET": "${MY_API_SECRET}",
        "BASE_URL": "https://api.example.com",
        "DEBUG": "true"
      },
      "enabled": true
    }
  }
}
```

---

## Official MCP Servers

### GitHub MCP Server
```json
{
  "mcp": {
    "github": {
      "type": "local",
      "command": ["npx", "-y", "@modelcontextprotocol/server-github"],
      "environment": {
        "GITHUB_TOKEN": "${GITHUB_TOKEN}"
      },
      "enabled": true
    }
  }
}
```

**Tools provided:**
- `github_create_issue`
- `github_create_pr`
- `github_list_prs`
- `github_get_pr`
- `github_merge_pr`
- And more...

### File System MCP Server
```json
{
  "mcp": {
    "filesystem": {
      "type": "local",
      "command": ["npx", "-y", "@modelcontextprotocol/server-filesystem"],
      "enabled": true
    }
  }
}
```

**Tools provided:**
- `filesystem_read_file`
- `filesystem_write_file`
- `filesystem_read_directory`
- `filesystem_delete_file`

### Stripe MCP Server
```json
{
  "mcp": {
    "stripe": {
      "type": "local",
      "command": ["npx", "-y", "@stripe/mcp-server"],
      "environment": {
        "STRIPE_SECRET_KEY": "${STRIPE_SECRET_KEY}"
      },
      "enabled": true
    }
  }
}
```

---

## Docker MCP Servers

Docker MCP servers run in isolated containers.

### Basic Docker Setup
```json
{
  "mcp": {
    "custom-tool": {
      "type": "docker",
      "image": "myorg/custom-mcp:v1.0",
      "enabled": true
    }
  }
}
```

### Docker with Environment Variables
```json
{
  "mcp": {
    "postgres-query": {
      "type": "docker",
      "image": "mcp/postgres:latest",
      "environment": {
        "DATABASE_URL": "${DATABASE_URL}",
        "DB_PASSWORD": "${DB_PASSWORD}"
      },
      "enabled": true
    }
  }
}
```

### Docker with Build Steps

Skills can include Docker build steps for complex setups:

```yaml
---
name: docker-skill
description: Runs complex Docker-based workflow
runtime: docker
docker:
  image: python:3.11-slim
  steps:
    - script: "./setup.sh"
      workdir: "/project"
    - script: "./build.sh"
      workdir: "/project"
    - script: "./test.sh"
      workdir: "/project"
---
```

**How it works:**
1. OpenCode builds/pulls the Docker image
2. Runs each script in sequence inside the container
3. Working directory set via `workdir` parameter
4. Scripts from skill folder are mounted into container

---

## MCP Server Discovery

OpenCode discovers MCP tools automatically when servers are enabled.

### Viewing Available MCP Tools
```bash
# List all available tools (including MCP)
opencode tools list

# Debug specific MCP server
opencode debug mcp github
```

### Tool Naming Convention
MCP tools are prefixed with server name:
- Server `github` → tools like `github_create_pr`
- Server `stripe` → tools like `stripe_create_payment`
- Server `my-server` → tools like `my_server_do_thing`

---

## Permission Control for MCP Tools

Use wildcards to control MCP tool access.

### Allow All Tools from Server
```json
{
  "permission": {
    "github_*": "allow"  // All GitHub MCP tools
  }
}
```

### Selective Tool Permissions
```json
{
  "permission": {
    "github_create_issue": "allow",
    "github_create_pr": "ask",      // Require approval
    "github_merge_pr": "deny",      // Block merging
    "github_delete_*": "deny"       // Block all delete operations
  }
}
```

### Server-Wide Control
```json
{
  "mcp": {
    "github": {
      "enabled": false  // Disable entire server
    }
  }
}
```

---

## Multiple Runtimes in Skills

Skills can specify different executors beyond Docker.

### Bash Runtime (Default)
```yaml
---
name: build-script
description: Runs build scripts
runtime: bash
---

Execute build:
```bash
npm run build
npm run test
```
```

### TypeScript/Bun Runtime
```yaml
---
name: typescript-skill
description: Runs TypeScript with Bun
runtime: bun
---

This skill runs TypeScript directly using Bun.
```

### Python Runtime
```yaml
---
name: data-analysis
description: Analyzes data with Python
runtime: python
---

This skill executes Python scripts for data analysis.
```

**Note:** Ensure the runtime is available in your environment.

---

## Custom MCP Server Development

### Building a Local MCP Server

**1. Create server script** (`my-mcp-server.js`):
```javascript
#!/usr/bin/env node
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';

const server = new Server({
  name: 'my-mcp-server',
  version: '1.0.0',
});

// Define a tool
server.tool({
  name: 'my_tool',
  description: 'Does something useful',
  inputSchema: {
    type: 'object',
    properties: {
      input: { type: 'string' }
    }
  }
}, async ({ input }) => {
  // Tool implementation
  return { result: `Processed: ${input}` };
});

// Start server
const transport = new StdioServerTransport();
await server.connect(transport);
```

**2. Make executable**:
```bash
chmod +x my-mcp-server.js
```

**3. Configure in OpenCode**:
```json
{
  "mcp": {
    "my-server": {
      "type": "local",
      "command": ["node", "/path/to/my-mcp-server.js"],
      "enabled": true
    }
  }
}
```

### Building a Docker MCP Server

**1. Create Dockerfile**:
```dockerfile
FROM node:18-slim
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm install
COPY . .
CMD ["node", "server.js"]
```

**2. Build image**:
```bash
docker build -t myorg/my-mcp:v1.0 .
```

**3. Configure in OpenCode**:
```json
{
  "mcp": {
    "my-docker-server": {
      "type": "docker",
      "image": "myorg/my-mcp:v1.0",
      "environment": {
        "API_KEY": "${MY_API_KEY}"
      },
      "enabled": true
    }
  }
}
```

---

## Troubleshooting MCP Servers

### Server Not Starting
```bash
# Check if server is enabled
opencode debug mcp <server-name>

# Check environment variables
echo $GITHUB_TOKEN

# Test server manually
npx @modelcontextprotocol/server-github
```

### Tools Not Appearing
```bash
# List all available tools
opencode tools list

# Check server logs
opencode logs mcp <server-name>
```

### Permission Denied
Check permissions in `opencode.jsonc`:
```json
{
  "permission": {
    "github_*": "allow"  // Ensure MCP tools are allowed
  }
}
```

---

## Best Practices

### Security
1. **Never hardcode secrets** - Use environment variables
2. **Use wildcards for permissions** - Control tool access granularly
3. **Disable unused servers** - Set `enabled: false`
4. **Review MCP tools** - Know what each server exposes

### Performance
1. **Enable only needed servers** - Each server adds startup time
2. **Use local servers when possible** - Docker adds overhead
3. **Cache Docker images** - Pre-pull images to avoid build time

### Organization
1. **Group related servers** - Name servers descriptively
2. **Document requirements** - Note which env vars are needed
3. **Version Docker images** - Use specific tags, not `latest`

### Development Workflow
1. **Test servers standalone** - Verify they work before integrating
2. **Use debug commands** - `opencode debug mcp` for troubleshooting
3. **Check tool output** - Validate MCP tools return expected results

---

## Example: Complete MCP Setup

Full setup with multiple servers, permissions, and environment variables:

```json
{
  "mcp": {
    "github": {
      "type": "local",
      "command": ["npx", "-y", "@modelcontextprotocol/server-github"],
      "environment": {
        "GITHUB_TOKEN": "${GITHUB_TOKEN}"
      },
      "enabled": true
    },
    "stripe": {
      "type": "local",
      "command": ["npx", "-y", "@stripe/mcp-server"],
      "environment": {
        "STRIPE_SECRET_KEY": "${STRIPE_SECRET_KEY}"
      },
      "enabled": true
    },
    "custom-analytics": {
      "type": "docker",
      "image": "myorg/analytics-mcp:v2.1",
      "environment": {
        "DATABASE_URL": "${ANALYTICS_DB_URL}",
        "REDIS_URL": "${REDIS_URL}"
      },
      "enabled": true
    },
    "filesystem": {
      "type": "local",
      "command": ["npx", "-y", "@modelcontextprotocol/server-filesystem"],
      "enabled": false  // Disabled in this example
    }
  },
  "permission": {
    "github_create_issue": "allow",
    "github_create_pr": "ask",
    "github_merge_pr": "deny",
    "github_delete_*": "deny",
    "stripe_create_payment": "ask",
    "stripe_refund_*": "ask",
    "stripe_delete_*": "deny",
    "custom_analytics_*": "allow",
    "filesystem_*": "deny"  // Server disabled anyway
  }
}
```

**Environment variables needed** (`~/.zshrc`):
```bash
export GITHUB_TOKEN="ghp_xxxxxxxxxxxxx"
export STRIPE_SECRET_KEY="sk_test_xxxxxxxxxxxxx"
export ANALYTICS_DB_URL="postgresql://user:pass@localhost/analytics"
export REDIS_URL="redis://localhost:6379"
```
