---
description: Expert in building OpenCode configurations - agents, subagents, skills, commands, tools, and MCP server setup
mode: subagent
temperature: 0.1
verbose: false
prompt: {file:./prompts/opencode-assistant.md}
tools:
  bash: true
  read: true
  grep: true
  glob: true
  write: true
  edit: true
---
