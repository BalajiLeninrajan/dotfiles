#!/usr/bin/env bash

source "$HOME/.config/sketchybar/icons.sh"
source "$HOME/.config/sketchybar/colors.sh"

volume="$(osascript -e 'output volume of (get volume settings)')"
muted="$(osascript -e 'output muted of (get volume settings)')"

case "$SENDER" in
  mouse.clicked)
    if [ "$muted" = "true" ]; then
      osascript -e 'set volume without output muted'
    else
      osascript -e 'set volume with output muted'
    fi
    volume="$(osascript -e 'output volume of (get volume settings)')"
    muted="$(osascript -e 'output muted of (get volume settings)')"
    ;;
  mouse.scrolled)
    delta="${SCROLL_DELTA:-0}"
    current="$volume"
    if [ "$delta" -gt 0 ]; then
      volume=$((current + 5))
    else
      volume=$((current - 5))
    fi
    [ "$volume" -gt 100 ] && volume=100
    [ "$volume" -lt 0 ] && volume=0
    osascript -e "set volume output volume $volume"
    osascript -e 'set volume without output muted'
    muted="false"
    ;;
esac

if [ "$muted" = "true" ] || [ "$volume" = "0" ]; then
  sketchybar --animate tanh 12 --set "$NAME" icon="$ICON_MUTED" icon.color="$OVERLAY1" label="Muted"
else
  sketchybar --animate tanh 12 --set "$NAME" icon="$ICON_VOLUME" icon.color="$YELLOW" label="${volume}%"
fi
