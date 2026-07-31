#!/bin/sh

if [ -z "${ZELLIJ_SESSION_NAME:-}" ] || [ -z "${ZELLIJ_PANE_ID:-}" ]; then
  printf '%s\n' 'ERROR: /term should only be run inside a Zellij session.'
  exit 0
fi

cwd=$(pwd -P) || {
  printf '%s\n' 'ERROR: /term could not determine the current working directory.'
  exit 0
}

tab_id=$(zellij action list-panes --all --json 2>/dev/null | jq -r --argjson pane_id "$ZELLIJ_PANE_ID" 'first(.[] | select(.is_plugin == false and .id == $pane_id) | .tab_id) // empty')
if [ -z "$tab_id" ]; then
  printf 'ERROR: /term could not find the current Zellij pane (terminal_%s).\n' "$ZELLIJ_PANE_ID"
  exit 0
fi

if created_pane_id=$(zellij action new-pane --tab-id "$tab_id" --direction down --cwd "$cwd" -- /bin/zsh -l 2>&1); then
  printf 'Opened terminal pane %s below in %s.\n' "$created_pane_id" "$cwd"
else
  printf 'ERROR: /term could not open a Zellij pane: %s\n' "$created_pane_id"
fi
