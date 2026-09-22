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

Linux only:

- Niri, with DankMaterialShell (DMS) and its companions: dankcal, danksearch, qt5ct/qt6ct, and the `environment.d` entry DMS needs
- GTK 3/4 settings
- T2 Macs only, gated on `/sys/module/apple_bce`: the libinput palm-rejection plugin, tiny-dfr Touch Bar config and resume unit, and the kanata resume unit
- Claude Code, Codex, and Cursor share one `~/.agents` tree; the per-tool paths are symlinks into it

UW student.cs login nodes, matched on a `.student.cs.uwaterloo.ca` FQDN:

- Shell and CLI config only: zsh, Neovim, git, bat, btop, delta, eza, yazi, and the agent trees
- Every desktop config is ignored, along with herdr, Zellij, Vesktop, and Cursor
- `.bash_profile` hands interactive logins to zsh. The account's login shell is bash and chsh cannot change that against LDAP
- `.bashrc` is cut down to a PATH export. `ssh host command` sources it non-interactively, so output or key bindings there break scp and rsync
- The prompt is the `simple` theme with `%m` in front of it. The load balancer moves you between nodes, so the prompt says which one you are on
- Hadoop, Spark, and the dnf plugin drop out of `.zshrc`, since the `/opt` paths and the package manager they assume are not there
- The Claude Code SessionStart hook drops out of `settings.json`, because it drives the herdr status line

Platform selection is defined in `.chezmoiignore`.

## Bootstrap

```sh
chezmoi init BalajiLeninrajan/dotfiles
chezmoi apply
```

### student.cs

The login nodes share one NFS home, so this is done once for all of them.

```sh
chezmoi init BalajiLeninrajan/dotfiles
mkdir -p ~/.config/chezmoi
printf 'persistentState = "/run/user/%s/chezmoistate.boltdb"\n' "$(id -u)" \
    > ~/.config/chezmoi/chezmoi.toml
chezmoi apply
```

That config file is the one manual step and stays unmanaged. chezmoi keeps its
state in boltdb, which cannot lock across NFS: two login nodes running chezmoi
at the same time leave the file corrupt, and every later command then fails
with `invalid database`. Pointing it at `/run/user` keeps the state on the node
it was written from. The state only caches script hashes and applied-entry
hashes, so losing it at logout costs nothing.

`run_onchange_after_install-student-cli.sh.tmpl` installs what the box does not
ship: ripgrep, fd, bat, zoxide, and delta as static musl binaries under
`~/.local/bin`, oh-my-zsh with zsh-autosuggestions and zsh-syntax-highlighting,
and a rebuilt bat theme cache. Versions are pinned with the tarball checksum,
same as the Zellij plugins. eza, fzf, Neovim, tmux, git, btop, go, rust, and uv
are already on the machine.

The Zellij plugin installer runs on macOS and Linux. It downloads zjstatus, zjstatus-hints, and zellij-palette with pinned SHA-256 checksums. curl is required.

Kanata ships one layout for both platforms. `dot_config/kanata/config.kbd.tmpl` differs by OS in three places:

- Device filter. macOS includes `Apple Internal Keyboard / Trackpad` by name. Linux instead *excludes* `Apple Headset`, whose media buttons otherwise run through the layers. It has to be an exclude: on this hardware the keyboard and the trackpad report the same name, so an include list matches both, and an include list also replaces kanata's default keyboard-only detection rather than narrowing it (`linux-device-detect-mode keyboard-only` does not win it back). Kanata then grabs the trackpad exclusively and the pointer stops working. Excluding keeps default detection, which picks the keyboard and the touch bar function row and leaves the trackpad alone.
- Cmd+H swallow, which Linux drops so the compositor keeps Super+H.
- `linux-continue-if-no-devs-found`, so kanata waits rather than exits when the keyboard has not reappeared yet.

Home row mods are the same on both platforms: Cmd/Super on the ring finger (`s`/`l`), Alt on the middle finger (`d`/`k`). The `num` layer mirrors that one row up, on `w`/`e`.

### Kanata on Linux

The daemon runs as a systemd **user** service, `.config/systemd/user/kanata.service`. It needs no root at runtime, given a udev rule granting the `input` group access to `/dev/uinput`:

```sh
sudo install -m 0644 -o root -g root \
  ~/.config/kanata/99-kanata.rules /etc/udev/rules.d/99-kanata.rules
sudo udevadm control --reload && sudo udevadm trigger --name-match=uinput
sudo usermod -aG input "$USER"   # log out and back in
systemctl --user enable --now kanata.service
```

On a T2 Mac, suspend tears down the keyboard and `apple-bce` recreates it under a new event number. Kanata releases its old devices and never picks up the new ones, staying alive but deaf, so it has to be restarted on resume. Sleep targets exist only in the system manager, so that hook cannot live in this repo's `~/.config` tree; install it from the copy kept alongside the kanata config:

```sh
sudo install -m 0644 -o root -g root \
  ~/.config/kanata/kanata-resume.service /etc/systemd/system/kanata-resume.service
sudo systemctl daemon-reload
sudo systemctl enable kanata-resume.service
```

Forced exit from any layer is `lctl+spc+esc`, in `defsrc` terms, i.e. before remapping.

### T2 Macs

`.chezmoiignore` skips the T2 files unless `/sys/module/apple_bce` exists, which it does on any T2 Mac booting Linux since that driver carries the internal keyboard.

Root-owned files are tracked as copies under `~/.config` and installed by hand. Nothing in this repo runs `sudo` for you.

#### Trackpad palm rejection

`.config/libinput/plugins/10-t2-palm.lua` is a libinput Lua plugin niri loads at startup. It holds each new touch briefly, rejects contacts by size relative to typing context, and re-creates the edge zones libinput compiles out for Apple pads. Edit, then log out and in.

It works alongside size thresholds in a libinput quirks override. libinput only reads quirks from `/etc/libinput`, so the tracked copy has to be installed:

```sh
sudo install -m 0644 -o root -g root \
  ~/.config/libinput/local-overrides.quirks /etc/libinput/local-overrides.quirks
```

Check it with `libinput quirks list /dev/input/eventN` for the trackpad, then log out and in.

#### Touch Bar after suspend

The Touch Bar comes back from suspend on the wrong USB configuration. `.config/tiny-dfr/touchbar-force-config2` switches it back and `touchbar-resume.service` runs it on resume:

```sh
sudo install -m 0755 -o root -g root \
  ~/.config/tiny-dfr/touchbar-force-config2 /usr/local/bin/touchbar-force-config2
sudo install -m 0644 -o root -g root \
  ~/.config/tiny-dfr/touchbar-resume.service /etc/systemd/system/touchbar-resume.service
sudo systemctl daemon-reload
sudo systemctl enable touchbar-resume.service
```

The kanata resume unit is installed the same way; see the Kanata section above.

### Niri

Linux only, and only partly tracked. `.config/niri/config.kdl` is hand-written and
holds the custom binds. `.config/niri/dms/binds.kdl` came from DankMaterialShell but
carries real edits, so it is tracked too; expect it to show up in `chezmoi status`
occasionally, since DMS rewrites it.

The other files under `.config/niri/dms/` are left untracked on purpose. Five of them
say `AUTO-GENERATED BY DMS` in their header and are rebuilt from
`~/.config/DankMaterialShell/settings.json`; tracking them would fight DMS on every
theme or monitor change.

Custom binds belong in `config.kdl`, never in `dms/binds.kdl`. Niri accepts the same
key bound in two included files without warning and picks a winner arbitrarily, so a
key defined in one must not appear in the other.

## Themes and fonts

Not tracked here. Install them from upstream:

- Font: [JetBrainsMono Nerd Font](https://github.com/ryanoasis/nerd-fonts) (`JetBrainsMono.zip` from the releases page, unpacked into `~/.local/share/fonts/`)
- Icons: [Colloid icon theme](https://github.com/vinceliuice/Colloid-icon-theme), installed with `./install.sh -s catppuccin -t purple`
- Shell theme: the DMS catppuccin theme is tracked under `.config/DankMaterialShell/themes/`
- Delta and DMS both use Catppuccin Mocha; the delta theme file is tracked under `.config/delta/`

## Local secrets

Secrets are not stored in this repository. Copy the example and populate it locally:

```sh
mkdir -p ~/.config/zsh
cp ~/.config/zsh/secrets.zsh.example ~/.config/zsh/secrets.zsh
chmod 600 ~/.config/zsh/secrets.zsh
```

`~/.zshrc` sources this file when it exists.
