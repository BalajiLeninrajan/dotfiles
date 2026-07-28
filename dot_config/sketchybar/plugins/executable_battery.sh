#!/usr/bin/env bash

source "$HOME/.config/sketchybar/icons.sh"
source "$HOME/.config/sketchybar/colors.sh"

if [ "$SENDER" = "power_source_change" ]; then
  sleep 1
fi

battery_info="$(ioreg -n AppleSmartBattery -r)"
percent="$(printf '%s\n' "$battery_info" | awk '/"CurrentCapacity"/ { print $3; exit }')"
charging="$(printf '%s\n' "$battery_info" | awk '/"IsCharging"/ { print $3; exit }')"

[ -z "$percent" ] && percent="--"

icon="$ICON_BATTERY"

if [ "$percent" != "--" ]; then
  if [ "$percent" -le 5 ]; then
    icon="$ICON_BATTERY_EMPTY"
  elif [ "$percent" -le 10 ]; then
    icon="$ICON_BATTERY_10"
  elif [ "$percent" -le 20 ]; then
    icon="$ICON_BATTERY_20"
  elif [ "$percent" -le 30 ]; then
    icon="$ICON_BATTERY_30"
  elif [ "$percent" -le 40 ]; then
    icon="$ICON_BATTERY_40"
  elif [ "$percent" -le 50 ]; then
    icon="$ICON_BATTERY_50"
  elif [ "$percent" -le 60 ]; then
    icon="$ICON_BATTERY_60"
  elif [ "$percent" -le 70 ]; then
    icon="$ICON_BATTERY_70"
  elif [ "$percent" -le 80 ]; then
    icon="$ICON_BATTERY_80"
  elif [ "$percent" -le 90 ]; then
    icon="$ICON_BATTERY_90"
  fi
fi

if [ "$charging" = "Yes" ]; then
  sketchybar --set "$NAME" icon="$ICON_BATTERY_CHARGING" icon.color="$GREEN" label="${percent}%"
elif [ "$percent" != "--" ] && [ "$percent" -le 20 ]; then
  sketchybar --set "$NAME" icon="$icon" icon.color="$RED" label="${percent}%"
else
  sketchybar --set "$NAME" icon="$icon" icon.color="$PEACH" label="${percent}%"
fi
