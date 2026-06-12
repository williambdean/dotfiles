# Ghostty

Configuration for the [Ghostty](https://ghostty.org) terminal emulator.

## Setup

Symlink the config into place:

```sh
ln -s ~/github/dotfiles/ghostty/config ~/.config/ghostty/config
```

## Notable settings

### `term = xterm-256color`

Ghostty defaults to its own `ghostty` terminfo, which enables the
[Kitty Keyboard Protocol](https://sw.kovidgoyal.net/kitty/keyboard-protocol/).
This causes raw escape sequences (e.g. `[106;5u`) to bleed into pasted text
in apps that don't support the protocol (zsh readline, vim, etc.).

Setting `term = xterm-256color` reverts to standard key encoding so paste
works correctly everywhere. The trade-off is losing the ability to distinguish
keys that are normally ambiguous (e.g. `Ctrl+I` vs `Tab`) in apps that do
support the protocol.
