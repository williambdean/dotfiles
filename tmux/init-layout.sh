#!/usr/bin/env bash
# Initialize standard 2-window project layout for current tmux session

set -e

# Get current session info
SESSION=$(tmux display-message -p '#S')
DIR=$(tmux display-message -p '#{pane_current_path}')

# Window 0: OpenCode
tmux rename-window -t "$SESSION:0" "opencode"
tmux send-keys -t "$SESSION:0" "opencode" C-m

# Window 1: Terminal (pane 0) + Neovim (pane 1)
tmux new-window -t "$SESSION:1" -n "dev" -c "$DIR"
# Split to create second pane for Neovim
tmux split-window -t "$SESSION:1" -c "$DIR"
tmux send-keys -t "$SESSION:1.1" "nvim" C-m

# Zoom terminal pane (pane 0) by default
tmux resize-pane -Z -t "$SESSION:1.0"

# Switch to dev window (will show zoomed terminal)
tmux select-window -t "$SESSION:1"
