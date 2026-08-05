---
name: verify
description: Verify the Claude-Zellij bridge through its HTTP and Zellij process surfaces.
---

# Verify Claude-Zellij bridge

1. Build the bridge release binary with `cargo build --release --package claude-zellij-bridge --manifest-path ~/.local/share/chezmoi/vendor/claude-zellij/Cargo.toml`.
2. Start the release binary on an unused loopback port with a unique token and fake `CLAUDE_ZELLIJ_ZELLIJ_BIN` / `CLAUDE_ZELLIJ_ALERTER_BIN` executables that record their arguments.
3. POST hook payloads with `X-Zellij-Session` and `X-Zellij-Pane` headers to `/hook/<token>`.
4. Confirm notification title, subtitle, message, and group in the fake Alerter capture.
5. Have fake Zellij return `list-clients` with the event's `terminal_<pane>` and confirm no Alerter invocation occurs and `alerts_suppressed` increments.
6. Send an event for a different pane and confirm Alerter is invoked normally.
7. Have the fake Alerter emit `{"activationType":"contentsClicked"}` and confirm the fake Zellij capture receives `-s <session> action focus-pane-id terminal_<pane>`.
8. Probe a timeout activation and confirm no focus command is emitted.
9. Query `/health/<token>` and confirm no child remains in flight. Stop the isolated bridge with SIGTERM.

Use isolated ports and fake Zellij targets so verification never changes the user's active pane or session. The installed launchd service can take a moment to bind after `launchctl kickstart`; poll health rather than treating the first connection refusal as a service failure.
