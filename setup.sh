# Script to setup all of the dotfiles on
# local machine
ln -s $PWD/tmux/.tmux.conf $HOME/.tmux.conf
ln -s $PWD/vim/.vimrc $HOME/.vimrc

# OpenCode config (entire folder symlinked for all sessions)
ln -s "$PWD/opencode" "$HOME/.config/opencode"

cd oh-my-zsh
for file in *.zsh; do
	ln -s $(pwd)/$file $ZSH_CUSTOM/$file
done
cd ..
