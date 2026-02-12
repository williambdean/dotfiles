# Copilot Instructions for Dotfiles Repository

This repository contains personal configuration files (dotfiles) for various development tools and applications.

## Repository Overview

This is a dotfiles repository containing configuration files for:
- **Neovim** (nvim/) - Modern Vim configuration with Lua-based plugins
- **Vim** (vim/) - Classic Vim configuration
- **Tmux** (tmux/) - Terminal multiplexer configuration
- **WezTerm** (.wezterm.lua) - Terminal emulator configuration
- **Git** (.gitconfig) - Git aliases and settings
- **Oh My Zsh** (oh-my-zsh/) - Zsh shell customizations
- **AeroSpace** (aerospace.toml) - Window manager configuration

## Languages and File Types

- **Lua**: Used for Neovim and WezTerm configurations
- **Shell scripts**: Setup and utility scripts
- **YAML**: Pre-commit configuration and test files
- **TOML**: AeroSpace and StyLua configuration
- **Python**: Test files

## Code Style and Formatting

### Lua
- Use StyLua for formatting (configured in `.stylua.toml`)
- 2-space indentation
- Follow Lua best practices for Neovim plugins

### Shell Scripts
- Use shfmt for formatting
- Follow POSIX shell script conventions where possible

### General
- Trailing whitespace should be removed
- Files should end with a newline
- Run `make format` to format all files using pre-commit hooks

## Testing

- Tests are located in the `tests/` directory
- Use pytest for Python tests
- Run tests with: `python -m pytest tests/ -v`

## Setup and Installation

- The `setup.sh` script creates symbolic links from this repository to home directory
- Use `ln -s` to create symbolic links (as shown in setup.sh)
- Test files in `tests/` are used to validate pre-commit hooks

## Pre-commit Hooks

The repository uses pre-commit hooks for code quality:
- StyLua for Lua formatting
- shfmt for shell script formatting
- Standard pre-commit hooks (trailing whitespace, YAML validation, etc.)

Configuration is in `.pre-commit-config.yaml`

## Making Changes

When working with this repository:

1. **Configuration files**: Edit the files directly in this repository
2. **Symbolic links**: Remember that changes to linked files in the home directory affect this repository
3. **Testing changes**: Test configuration changes manually in their respective applications
4. **Format before commit**: Run `make format` before committing changes

## Important Conventions

- Configuration files should be well-commented to explain non-obvious settings
- Keep configurations portable across different systems where possible
- Avoid hardcoding absolute paths (except in setup.sh for linking)
- Test configuration changes before committing

## File Organization

- Root level: Main configuration files and scripts
- Subdirectories: Organized by tool/application (nvim/, tmux/, vim/, etc.)
- tests/: Sample files for testing pre-commit hooks
