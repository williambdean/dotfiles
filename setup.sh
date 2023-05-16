ln -s $PWD/tmux/.tmux.conf $HOME/.tmux.conf

ln -s $PWD/vim/.vimrc $HOME/.vimrc

for file in $PWD/oh-my-zsh/**/*.zsh
do ln -s $file $ZSH_CUSTOM
done 
