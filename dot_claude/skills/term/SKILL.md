---
name: term
description: Open a terminal pane below the current Claude Code pane in the current working directory.
disable-model-invocation: true
allowed-tools: Bash(${CLAUDE_SKILL_DIR}/term.sh)
---

!`${CLAUDE_SKILL_DIR}/term.sh`

The shell command above fully handled `/term`. Do not invoke `/term`, another skill, an agent, Bash, or any other tool. Reply with only the emitted status line.
