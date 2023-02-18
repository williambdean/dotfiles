
# Some python setup
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

## Python Setup
# if which pyenv-virtualenv > /dev/null; then eval "$(pyenv virtualenv-init -)"; fi
if which pyenv > /dev/null; then eval "$(pyenv init --path)" && eval "$(pyenv init -)"; fi
export PATH=$PATH:${HOME}/Driver/
export PIPENV_VENV_IN_PROJECT=1

# Poetry
export PATH=$HOME/.local/bin:$PATH
