#!/usr/bin/env bash

PIDFILE="/tmp/sketchybar-paneru-subscribe.pid"

if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
  exit 0
fi

echo $$ >"$PIDFILE"
trap 'rm -f "$PIDFILE"' EXIT INT TERM

while pgrep -x paneru >/dev/null; do
  paneru subscribe --json 2>/dev/null | while IFS= read -r line; do
    [ -z "$line" ] && continue
    case "$(jq -r '.event // empty' <<<"$line")" in
      virtual_workspace_changed | windows_changed | window_focused | display_changed)
        sketchybar --trigger paneru_update
        ;;
    esac
  done
  sleep 1
done
