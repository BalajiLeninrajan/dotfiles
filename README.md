# dotfiles

Cross-platform dotfiles managed with [chezmoi](https://www.chezmoi.io/).

## Platforms

Shared between macOS and Linux:

- Ghostty
- Kanata, with platform-specific keyboard layouts
- Neovim
- Zathura
- Zellij and the Claude Zellij integration
- Zsh
- Vesktop/Vencord preferences

macOS only:

- Paneru

Linux only:

- DankMaterialShell
- Danksearch
- Niri

Platform selection is defined in `.chezmoiignore`.

## Bootstrap

```sh
chezmoi init BalajiLeninrajan/dotfiles
chezmoi apply
```

The Zellij installer runs on macOS and Linux. It initializes the pinned `vendor/claude-zellij` submodule, builds the custom bridge and status plugin with the repository's pinned Rust toolchain, and downloads third-party plugins with pinned SHA-256 checksums. Rustup/Cargo and curl are required.

Kanata renders the active local Apple keyboard layout on macOS and the final pre-macOS layout from `kanata-dotfiles` commit `737ae339479de91772b0414ab40d5c411e7db4fa` on Linux.

The token-bearing Claude Zellij LaunchAgent and Claude Code hook settings remain machine-local and are not managed by this repository.

DankMaterialShell plugin preferences are managed, but third-party plugin implementations are not vendored. Install the corresponding plugins through DMS's plugin manager on a new Linux machine.

Niri's DMS output include is intentionally an empty seed file. DMS replaces it with machine-specific monitor settings.

## Local secrets

Secrets are not stored in this repository. Copy the example and populate it locally:

```sh
mkdir -p ~/.config/zsh
cp ~/.config/zsh/secrets.zsh.example ~/.config/zsh/secrets.zsh
chmod 600 ~/.config/zsh/secrets.zsh
```

`~/.zshrc` sources this file when it exists.
