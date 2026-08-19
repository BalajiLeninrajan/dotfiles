# dotfiles

Cross-platform dotfiles managed with [chezmoi](https://www.chezmoi.io/).

## Platforms

Shared between macOS and Linux:

- Cava
- Ghostty
- Git, with the delta theme wired in
- Kanata
- Neovim
- Zathura
- Zellij
- Zsh
- Vesktop/Vencord preferences

macOS only:

- Paneru
- SketchyBar, including the Paneru workspace plugins
- JankyBorders

Platform selection is defined in `.chezmoiignore`.

## Bootstrap

```sh
chezmoi init BalajiLeninrajan/dotfiles
chezmoi apply
```

The Zellij plugin installer runs on macOS and Linux. It downloads zjstatus, zjstatus-hints, and zellij-palette with pinned SHA-256 checksums. curl is required.

Kanata ships one layout for both platforms. `dot_config/kanata/config.kbd.tmpl` differs by OS in only two places: the macOS device filter and the Cmd+H swallow, which Linux drops so the compositor keeps Super+H.

## Local secrets

Secrets are not stored in this repository. Copy the example and populate it locally:

```sh
mkdir -p ~/.config/zsh
cp ~/.config/zsh/secrets.zsh.example ~/.config/zsh/secrets.zsh
chmod 600 ~/.config/zsh/secrets.zsh
```

`~/.zshrc` sources this file when it exists.
