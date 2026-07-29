# Script to setup all of the dotfiles on
# local machine
ln -s $PWD/tmux/.tmux.conf $HOME/.tmux.conf
ln -s $PWD/vim/.vimrc $HOME/.vimrc

# OpenCode config (entire folder symlinked for all sessions)
ln -s "$PWD/opencode" "$HOME/.config/opencode"

# IPython config
mkdir -p "$HOME/.ipython/profile_default/startup"
ln -sf "$PWD/ipython/ipython_config.py" "$HOME/.ipython/profile_default/ipython_config.py"
ln -sf "$PWD/ipython/01-custom-startup.py" "$HOME/.ipython/profile_default/startup/01-custom-startup.py"

cd oh-my-zsh
for file in *.zsh; do
	ln -s $(pwd)/$file $ZSH_CUSTOM/$file
done
cd ..

# HEIC to PNG Folder Action
bash "$PWD/scripts/install-heic-to-png.sh"
