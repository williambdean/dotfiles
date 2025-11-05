# Recent Repositories - Neovim Plugin

A Neovim plugin for tracking recent repositories and creating issues through a flexible callback system.

## Features

- **Track Recent Repositories**: Automatically tracks repositories you work with
- **Configurable Limit**: Set a maximum number of repositories to track (default: 10)
- **Callback System**: Register custom callbacks for issue creation
- **Interactive UI**: Select repositories and create issues through vim.ui
- **Persistent Storage**: Repositories are saved to disk and restored on startup

## Installation

This plugin is part of the dotfiles configuration and is automatically loaded when Neovim starts.

## Usage

### User Commands

#### `:RecentRepos`
Shows a picker with recent repositories you've worked with.

```vim
:RecentRepos
```

#### `:CreateIssueForRepo`
Interactive command to create an issue for a recent repository.

```vim
:CreateIssueForRepo
```

This will:
1. Show a picker with recent repositories
2. Prompt for issue title
3. Prompt for issue body (optional)
4. Create the issue using all registered callbacks

#### `:ClearRecentRepos`
Clears all tracked repositories.

```vim
:ClearRecentRepos
```

### Lua API

```lua
local recent_repos = require('config.recent_repos')

-- Add a repository
recent_repos.add_repository(
  'owner/repo',
  'https://github.com/owner/repo',
  'Optional description'
)

-- Get recent repositories
local repos = recent_repos.get_recent_repositories() -- All repos
local limited = recent_repos.get_recent_repositories(5) -- Only 5 most recent

-- Register a custom callback
recent_repos.register_callback(function(issue_data)
  -- issue_data contains:
  --   .repository (name, url, description, timestamp)
  --   .title (issue title)
  --   .body (issue body)
  
  print('Creating issue: ' .. issue_data.title)
  return { status = 'created' }
end)

-- Create an issue programmatically
local results = recent_repos.create_issue_for_repository(
  'owner/repo',
  'Bug: Something broke',
  'Here are the details...'
)

-- Clear callbacks
recent_repos.clear_callbacks()

-- Clear repositories
recent_repos.clear_repositories()
```

### Configuration

You can modify the maximum number of repositories to track:

```lua
local recent_repos = require('config.recent_repos')
recent_repos.max_repos = 20  -- Track up to 20 repositories
```

## Default Behavior

By default, the plugin:
1. Automatically tracks the current repository when you open Neovim in a git directory
2. Registers a default callback that uses Octo.nvim to create issues
3. Persists repositories to `~/.local/share/nvim/recent_repos/recent_repos.json`

## Examples

### Custom Callback for Logging

```lua
local recent_repos = require('config.recent_repos')

recent_repos.register_callback(function(issue_data)
  local log_file = vim.fn.stdpath('data') .. '/issue_log.txt'
  local f = io.open(log_file, 'a')
  f:write(string.format(
    '[%s] %s: %s\n',
    os.date(),
    issue_data.repository.name,
    issue_data.title
  ))
  f:close()
  return { logged = true }
end)
```

### Custom Callback for External Tool

```lua
recent_repos.register_callback(function(issue_data)
  local cmd = string.format(
    'gh issue create --repo %s --title "%s" --body "%s"',
    issue_data.repository.name,
    issue_data.title,
    issue_data.body
  )
  vim.fn.system(cmd)
  return { tool = 'gh', status = 'created' }
end)
```

## Testing

Run the Lua tests with busted:

```bash
busted tests/test_recent_repos_spec.lua
```

## Storage Location

Repository data is stored in:
```
~/.local/share/nvim/recent_repos/recent_repos.json
```

## Requirements

- Neovim 0.7+
- Octo.nvim (for default GitHub integration)

## License

Part of the personal dotfiles configuration.
