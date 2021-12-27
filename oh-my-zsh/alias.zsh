alias c=clear

alias ..="cd .."
alias back="cd -"

alias llpy="ll *.py"

alias reload="source ~/.zshrc"

alias atom="atom ."

alias chrome="/Applications/Google\\ \\Chrome.app/Contents/MacOS/Google\\ \\Chrome"

alias confluence="chrome 'https://hyperionpath.atlassian.net/wiki/spaces/ANALYTICS/overview?homepageId=163842'"

# Github Helpers
alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gd='git diff'
alias gp='git push'
alias gpom='git pull origin master'
alias gls='git ls-tree --full-tree --name-only -r HEAD'
alias gg="git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)'"
alias gdelete="git branch --merged | grep -v \* | xargs git branch -D "

## Pipenv helpers
alias pes="pipenv shell"
alias jnb="pipenv run jupyter lab"
