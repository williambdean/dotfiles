# Open page in Google Chrome
function chrome() {
    open -a "Google Chrome" http://$1
}

# Open Github of the local
function gh() {
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

    local url_name="$url_root$separator$current_branch"
    chrome $url_name
}

function wrap-pr() {
    local branch_name="${1:-main}"
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

# Add location to PYTHONPATH
function addpp() {
    export PYTHONPATH=${PYTHONPATH}:${HOME}/$1
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
function new_kernel() {
    ipython kernel install --name "$1" --user
}

function remove_kernel() {
    jupyter kernelspec remove "$1"
}

# Link file to ZSH_CUSTOM
function zsh-link() {
    ln -s $(pwd)/$1 $ZSH_CUSTOM
}


# From https://blog.mattclemente.com/2020/06/26/oh-my-zsh-slow-to-load/#how-to-test-your-shell-load-time
timezsh() {
  shell=${1-$SHELL}
  for i in $(seq 1 10); do /usr/bin/time $shell -i -c exit; done
}
