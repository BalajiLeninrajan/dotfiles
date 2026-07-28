#!/usr/bin/env bash

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/colors.sh"

if ! pgrep -x paneru >/dev/null; then
  sketchybar --animate tanh 12 --set "$NAME" label.drawing=off icon.color="$MAUVE"
  exit 0
fi

VW=$(paneru query active --json 2>/dev/null | jq -r '.virtual_workspace_number // empty')

if [ -n "$VW" ]; then
  sketchybar --animate tanh 12 --set "$NAME" \
    icon.color="$MAUVE" \
    label="$VW" \
    label.drawing=on \
    label.color="$SUBTEXT0" \
    label.font="JetBrainsMono Nerd Font:Medium:11.0" \
    label.padding_left=2 \
    label.padding_right=6
else
  sketchybar --animate tanh 12 --set "$NAME" label.drawing=off icon.color="$MAUVE"
fi
