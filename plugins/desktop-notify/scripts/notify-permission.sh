#!/usr/bin/env bash
# Fired by Claude Code PermissionRequest hook — notifies user that Claude needs tool approval.
# Reads JSON from stdin: { "tool_name": "Bash", "tool_input": { "command": "..." } }
# shellcheck source=lib.sh
source "$(dirname "$0")/lib.sh"

DATA=$(cat)
TOOL=$(echo "$DATA" | jq -r '.tool_name // "?"')
DETAIL=$(echo "$DATA" | jq -r '(.tool_input.command // .tool_input.file_path // "") | .[0:80]')
PROJECT=$(basename "$PWD")

notify "Claude Code – $PROJECT" "Approval: $TOOL${DETAIL:+: $DETAIL}" "critical"
exit 0
