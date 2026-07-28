#!/usr/bin/env bash

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
PLUGIN_DIR="$CONFIG_DIR/plugins"

source "$CONFIG_DIR/colors.sh"

MAX_WINS=20
FONT="${FONT:-JetBrainsMono Nerd Font}"

hide_windows() {
  local i
  for i in $(seq 0 $((MAX_WINS - 1))); do
    sketchybar --set "win.$i" drawing=off 2>/dev/null
  done
}

if ! pgrep -x paneru >/dev/null; then
  hide_windows
  exit 0
fi

VW_JSON=$(paneru query virtual-workspaces --json 2>/dev/null)
ACTIVE_JSON=$(paneru query active --json 2>/dev/null)

if [ -z "$VW_JSON" ] || ! jq -e 'length > 0' >/dev/null <<<"$VW_JSON"; then
  hide_windows
  exit 0
fi

VIRTUAL_WS=$(jq -r '.virtual_workspace_number // empty' <<<"$ACTIVE_JSON")
FOCUSED_ID=$(jq -r '.focused_window_id // empty' <<<"$ACTIVE_JSON")

WINDOW_ROWS=$(jq -r --arg fid "$FOCUSED_ID" '
  (.[] | select(.active == true)).windows[]?
  | [
      (.window_id | tostring),
      (if (.app_name | length) > 0 then .app_name
       elif (.title | length) > 0 then .title
       else (.bundle_id | split(".") | last)
       end),
      (.bundle_id // ""),
      (if .focused then "1"
       elif (($fid | length) > 0 and (.window_id | tostring) == $fid) then "1"
       else "0" end)
    ] | @tsv
' <<<"$VW_JSON")

INDEX=0
while IFS= read -r row; do
  [ -z "$row" ] && continue
  [ "$INDEX" -ge "$MAX_WINS" ] && break

  IFS=$'\t' read -r WINDOW_ID LABEL _BUNDLE FOCUSED <<<"$row"
  [ -z "$WINDOW_ID" ] && continue

  ITEM_NAME="win.$INDEX"

  if [ "$FOCUSED" = "1" ]; then
    BG_COLOR="$MAUVE"
    TEXT_COLOR="$CRUST"
  else
    BG_COLOR="$SURFACE0"
    TEXT_COLOR="$TEXT"
  fi

  CLICK="$PLUGIN_DIR/paneru_focus_window.sh $WINDOW_ID ${VIRTUAL_WS:-}"

  sketchybar --add item "$ITEM_NAME" left 2>/dev/null
  sketchybar --set "$ITEM_NAME" \
    drawing=on \
    click_script="$CLICK" \
    label="$LABEL" \
    label.max_chars=26 \
    label.color="$TEXT_COLOR" \
    label.font="$FONT:Medium:12.0" \
    label.padding_left=8 \
    label.padding_right=8 \
    icon.drawing=off \
    background.drawing=on \
    background.color="$BG_COLOR" \
    background.height=26 \
    background.corner_radius=7 \
    padding_left=3 \
    padding_right=0

  INDEX=$((INDEX + 1))
done <<<"$WINDOW_ROWS"

hide_from=$INDEX
while [ "$hide_from" -lt "$MAX_WINS" ]; do
  sketchybar --set "win.$hide_from" drawing=off 2>/dev/null
  hide_from=$((hide_from + 1))
done
