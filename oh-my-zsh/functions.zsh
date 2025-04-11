# Open page in Google Chrome
function chrome() {
    open -a "Google Chrome" http://$1
}

function localhost() {
    open http://localhost:$1
}

function local-docker() {
    enter-docker -v $(pwd):/app -w /app $1
}

function remote-url() {
    local url_root="$(git config --get remote.origin.url)"
    if [ -z  "$url_root" ]
    then
        echo "There is no remote!"
        return;
    fi

    local python_code="import sys
x = sys.argv[1]
for prefix in ('git@', 'https://', 'http://'):
    x = x.replace(prefix, '')

x = x.replace(':', '/')
print(x)
    "
    url_root=$(python3 -c $python_code $url_root)
    url_root=${url_root%.git}
    # Optional branch selection
    if [ -z "$1" ]
    then
        local current_branch="$(git branch --show-current)"
    else
        local current_branch="$1"
    fi

    if [[ $url_root == gitlab* ]]
    then
        separator="/-/tree/"
    else
        separator="/tree/"
    fi

    echo "https://www.$url_root$separator$current_branch"
}

# Open Github of the local
function open-remote() {
    local url_name=$(remote-url $1)
    echo $url_name
    xdg-open $url_name
}

function default-branch() {
    local branch_name=$(git remote show origin | sed -n '/HEAD branch/s/.*: //p')
    echo $branch_name
}

function gpom() {
    default_branch=$(default-branch)
    git pull origin $default_branch
}

function wrap-pr() {
    default_branch=$(default-branch)
    local branch_name="${1:-$default_branch}"
    git checkout $branch_name && git pull origin $branch_name && gdelete
}

function gdext() {
    git diff --name-only | grep "$1"
}

function finder() {
    local dir="$PWD"
    open $dir
}

# Add a remote and push up to main
function add_remote() {
    local git_url=$1

    git remote add origin $git_url
    git push -uf origin main
}

# Use rich to print out the current readme
function readme() {
    if [ "$1" != "" ]
    then
        python3 -m rich.markdown $1 --hyperlinks
    else
        python3 -m rich.markdown README.md --hyperlinks
    fi
}

# Adding and removing jupyter kernels
function list-kernels() {
    python -m jupyter kernelspec list --json | jq -r '.kernelspecs | keys[]'
}

function add-kernel() {
    read "name?Enter the name of the kernel: "
    read "display_name?Enter the display name of the kernel: "
    python -m ipykernel install --user --name=$name --display-name $display_name
}

function remove-kernel() {
    local kernel=$(list-kernels | fzf)
    if [ -z "$kernel" ]
    then
        return
    fi
    jupyter kernelspec remove "$kernel"
}

# Link file to ZSH_CUSTOM
function zsh-link() {
    ln -s $(pwd)/$1 $ZSH_CUSTOM
}

# New tmux session with the name of current directory
# Video from Josh Medeski
# Modified
function tn() {
    local session_name=$(pwd | sed 's/.*\///g')

    if [ -n "$TMUX" ]; then
        if tmux has-session -t="$session_name" 2> /dev/null; then
            tmux switch-client -t "$session_name"
            return
        fi
        tmux new-session -d -s "$session_name"
        tmux switch-client -t "$session_name"
    else
        if tmux has-session -t="$session_name" 2> /dev/null; then
            tmux attach -t "$session_name"
            return
        fi
        tmux new -s "$session_name"
    fi
}

# From https://blog.mattclemente.com/2020/06/26/oh-my-zsh-slow-to-load/#how-to-test-your-shell-load-time
function timezsh() {
  shell=${1-$SHELL}
  for i in $(seq 1 10); do /usr/bin/time $shell -i -c exit; done
}


function windows() {
    local window
    window=$(tmux list-windows -F "#{window_id}: #{window_name}")

    if [ -z "$window" ]; then
        return 1
    fi

    selected_window=$(echo "$window" | fzf)

    if [ -n "$TMUX" ]; then
        tmux select-window -t "${selected_window%%:*}"
    else
        echo "Not in a tmux session."
    fi
}

alias w=windows

function list-branches() {
    local selected_branch
    selected_branch=$(git branch --all | fzf)
    # Trim any whitespaces at the beginning
    selected_branch=$(echo $selected_branch | xargs)

    for remote in $(git remote)
    do
        selected_branch=${selected_branch#remotes/$remote/}
    done

    echo $selected_branch
}

function branches() {
    local selected_branch
    selected_branch=$(git branch --all | fzf)
    # Trim any whitespaces at the beginning
    selected_branch=$(echo $selected_branch | xargs)

    for remote in $(git remote)
    do
        selected_branch=${selected_branch#remotes/$remote/}
    done

    git checkout $selected_branch
}

alias b=branches

function gitignore-template() {
    local language=${1:-$(gh api /gitignore/templates --jq '.[]' | fzf)}
    if [ -z "$language" ]
    then
        return
    fi
    gh api /gitignore/templates/$language --jq '.source'
}

function conda-envs() {
    micromamba env list --json | jq -r '
        .envs |
        map(. | split("/") | .[-1]) |
        join("\n")
    '
}

function activate() {
    local env=$(micromamba env list --json | jq -r '
        .envs |
        .[1:] |
        map(. | split("/") | .[-1]) |
        ["base"] + . |
        join("\n")
    ' | fzf)
    if [ -z "$env" ]
    then
        return
    fi
    micromamba activate $env
}
alias a=activate

function prs_since_last_release() {
    local publishedAt=$(gh release list \
        --limit 1 \
        --json publishedAt \
        --jq '.[0].publishedAt')
    gh pr list --search "is:merged merged:>=${publishedAt}"
}


function pr {
    local current_branch=$(git branch --show-current)
    local pr_number=$(gh pr list --head "$current_branch" --json number --jq '.[0].number')
    if [ -z "$pr_number" ]
    then
        echo "No PR found for branch $current_branch"
        return
    fi

    nvim -c ":Octo pr edit $pr_number"
}

sessions () {
    sesh connect $(sesh list | grep -v '~/github' | fzf)
}

alias s=sessions

pr-branches () {
        local author_filter=""
        if [ -n "$1" ]
        then
                author_filter="author:$1"
        fi
        local branches=$(gh pr list --search "$author_filter" --json headRefName --jq '.[].headRefName')
        if [ -n "$branches" ]
        then
                echo $branches | fzf
        else
            echo "No branches found using that filter"

        fi
}

# Taken from https://www.youtube.com/watch?v=0Z71je-X6YM
field() {
    awk -F "${2:- }" "{ print \$${1:-1} }"
}

total() {
    awk -F "${2:- }" "{ s += \$${1:-1} } END { print s }"
}

ff() {
    aerospace list-windows --all | fzf --bind 'enter:execute(bash -c "aerospace focus --window-id {1}")+abort'
}

transfer-files() {
    if [[ -z "$1" ]]; then
        echo "Usage: transfer-files <source_directory> [destination_directory]"
        return 1
    fi
    local source=$1
    local destination=${2:-$(pwd)}
    local locations=$(FZF_DEFAULT_COMMAND="find $source -mindepth 1 -maxdepth 1" fzf -m)

    echo "$locations" | while IFS= read -r location; do
        if [[ -n "$location" ]]; then
            mv "$location" "$destination"
            echo "Moved: $(basename "$location")"
        fi
    done
}

move-from-downloads() {
    transfer-files $HOME/Downloads
}

downloads() {
    local source=${1:-$HOME/Downloads}
    FZF_DEFAULT_COMMAND="find $source -mindepth 1 -maxdepth 1" fzf -m
}


repos() {
    local first=${2:-15}
    gh search repos $1 --limit $first --json fullName --jq '.[].fullName' | fzf
}

org-repos() {
    repos "org:$1" 100
}

star() {
  if [ -z "$1" ]; then
    echo "Usage: star <owner>/<repo>"
    return 1
  fi

  # Split the input by '/'
  IFS='/' read -r owner repo <<< "$1"

  if [ -z "$owner" ] || [ -z "$repo" ]; then
    echo "Invalid format. Usage: add-star <owner>/<repo>"
    return 1
  fi

  repo_id=$(gh api graphql -f query='query($owner: String!, $name: String!) {
    repository(owner: $owner, name: $name) { id }
  }' -f owner="$owner" -f name="$repo" | jq -r '.data.repository.id')

  if [ -z "$repo_id" ]; then
    echo "Repository $owner/$repo not found"
    return 1
  fi

  if gh api graphql -f query='mutation($starrableId: ID!) {
    addStar(input: {starrableId: $starrableId}) { starrable { id } }
  }' -f starrableId="$repo_id" > /dev/null 2>&1; then
    echo "Starred $owner/$repo"
  else
    echo "Failed to star $owner/$repo"
  fi
}
