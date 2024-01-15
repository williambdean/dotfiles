alias c=clear
# Since I've been on windows recently...
alias cls=clear

alias ..="cd .."
alias back="cd -"

alias llpy="ll *.py"

alias reload="c && exec zsh"

alias vim=nvim

alias rc="vim ~/.zshrc"

# Git Helpers
alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gd='git diff'
alias gp='git push'
alias gpom='git pull origin master'
alias gls='git ls-tree --full-tree --name-only -r HEAD'
alias gg="git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)'"
alias gdelete="git branch --merged | grep -v \* | xargs git branch -D "

alias gdblack="gdext .py | xargs python -m black"

# Python files
alias unused_imports="flake8 --select=F401, F841"

# Docker 
alias enter-docker="docker run --rm -it --entrypoint bash"

