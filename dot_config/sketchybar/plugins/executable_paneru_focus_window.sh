#!/usr/bin/env bash

TARGET_ID="$1"
VIRTUAL_WS="$2"

[ -n "$TARGET_ID" ] || exit 0
pgrep -x paneru >/dev/null || exit 0

if [ -n "$VIRTUAL_WS" ]; then
  paneru send-cmd window virtualnum "$VIRTUAL_WS" 2>/dev/null
fi

paneru send-cmd window focus first 2>/dev/null

for _ in $(seq 1 50); do
  CURRENT=$(paneru query active --json 2>/dev/null | jq -r '.focused_window_id // empty')
  [ "$CURRENT" = "$TARGET_ID" ] && exit 0
  paneru send-cmd window focus east 2>/dev/null
done
