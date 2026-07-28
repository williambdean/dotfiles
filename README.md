# Version control on dotfiles

> [!WARNING]
>
> These are subject to change and constantly updating!

> [!TIP]
>
> Symbolic links between these files using `ln -s $(pwd)/source target`

Install list:

- ghostty
- oh-my-zsh
- git
- gh
- tmux
- bob & neovim
- aerospace
- fzf
- tree-sitter-cli
- prek

Others

- tree

Install zsh-autosuggestions for oh-my-zsh

```terminal
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
```

GitHub Scopes:
  - `admin:public_key`
  - `gist`
  - `read:org`
  - `read:project`
  - `repo`

Good scopes to have.

```bash
gh auth refresh --scopes admin:public_key,gist,read:org,read:project,repo
```
