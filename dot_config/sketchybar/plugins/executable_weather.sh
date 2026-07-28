#!/usr/bin/env bash

source "$HOME/.config/sketchybar/icons.sh"
source "$HOME/.config/sketchybar/colors.sh"

weather="$(curl -fsS --max-time 4 'https://wttr.in/?m&format=%t' 2>/dev/null | /usr/bin/sed 's/+//g')"

if [ -z "$weather" ]; then
  weather="Weather"
  color="$OVERLAY1"
else
  color="$SAPPHIRE"
fi

sketchybar --animate tanh 12 --set "$NAME" \
  icon="$ICON_WEATHER" \
  icon.color="$color" \
  label="$weather"
