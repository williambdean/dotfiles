ln -s $PWD/tmux/.tmux.conf $HOME/.tmux.conf
ln -s $PWD/vim/.vimrc $HOME/.vimrc

cd oh-my-zsh
for file in *.zsh
do ln -s $file $ZSH_CUSTOM/$file
done
cd ..
