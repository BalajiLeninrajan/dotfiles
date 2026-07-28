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
- Zellij and the Claude Zellij integration
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

The Zellij installer runs on macOS and Linux. It initializes the pinned `vendor/claude-zellij` submodule, builds the custom bridge and status plugin with the repository's pinned Rust toolchain, and downloads third-party plugins with pinned SHA-256 checksums. Rustup/Cargo and curl are required.

Kanata ships one layout for both platforms. `dot_config/kanata/config.kbd.tmpl` differs by OS in only two places: the macOS device filter and the Cmd+H swallow, which Linux drops so the compositor keeps Super+H.

The token-bearing Claude Zellij LaunchAgent and Claude Code hook settings remain machine-local and are not managed by this repository.

## Local secrets

Secrets are not stored in this repository. Copy the example and populate it locally:

```sh
mkdir -p ~/.config/zsh
cp ~/.config/zsh/secrets.zsh.example ~/.config/zsh/secrets.zsh
chmod 600 ~/.config/zsh/secrets.zsh
```

`~/.zshrc` sources this file when it exists.
