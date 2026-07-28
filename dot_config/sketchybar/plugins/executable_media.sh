#!/usr/bin/env bash

if ! command -v nowplaying-cli >/dev/null; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

state="$(nowplaying-cli get playbackRate 2>/dev/null)"
artist="$(nowplaying-cli get artist 2>/dev/null)"
title="$(nowplaying-cli get title 2>/dev/null)"

if [ -z "$title" ] || [ "$state" = "0" ]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

label="$title"
[ -n "$artist" ] && label="$artist - $title"

sketchybar --set "$NAME" drawing=on label="$label"
