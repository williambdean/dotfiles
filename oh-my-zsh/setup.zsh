# I want to create a tmux session named default when I open the terminal
# if no tmux is current running. Else, I want to attach to the current tmux session
if [ -z "$TMUX" ]; then
    tmux new-session -A -s default
fi

export FZF_DEFAULT_OPTS="--tmux 70%"

export EDITOR=nvim
