alias c=clear
# Since I've been on windows recently...
alias cls=clear

alias ..="cd .."
alias back="cd -"

alias llpy="ll *.py"

alias reload="c && exec zsh"

alias v=vim
alias vim=nvim

alias rc="vim ~/.zshrc"

# Git Helpers
alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gcnf='git commit --no-verify -m'
alias gd='git diff'
alias gp='git push'
alias gls='git ls-tree --full-tree --name-only -r HEAD'
alias gg="git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)'"
alias gdelete="git branch --merged | grep -v \* | xargs git branch -D "
alias gr="git restore"

alias cleanup="git fetch --prune && git branch --merged | grep -v '\*\|main\|master\|develop' | xargs -r git branch -d"

# GitHub CLI
alias ic="gh issue create -e"
alias issues="nvim -c ':Octo issue list'"
alias discussions="nvim -c ':Octo discussion list'"
alias prs="nvim -c ':Octo pr list'"
alias develop="nvim -c ':Octo issue develop'"
alias merged="nvim -c ':Octo search repo:{owner}/{repo} is:merged'"
alias db="nvim -c ':DBUI'"

# Docker
alias enter-docker="docker run --rm -it --entrypoint bash"

# Turn the screen off
alias off="pmset displaysleepnow"

alias cd=z

alias bvim="NVIM_APPNAME=bare-config nvim"

alias todo="nvim todo.md"
alias q=exit

# Define a function to search DuckDuckGo

function \? () {
    # Join arguments or read from pipe
    local input="${*:-$(cat)}"
    # URL encode spaces to %20
    local query=$(echo "$input" | sed 's/ /%20/g')
    w3m -o confirm_qq=false -no-cookie "https://duckduckgo.com/?q=$query"
}
# The 'noglob' alias makes it work without quotes
alias \?='noglob \?'

alias '??'='opencode run --model opencode/big-pickle'

alias wts"wt switch"
