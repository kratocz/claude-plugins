#!/bin/sh
# Publish "<emoji> <project> [(<branch>)]" to a per-session state file
# that statusline-state.sh can pick up and render as an extra statusline
# line.
#
# Usage: set-state.sh [emoji]
#   - With emoji: writes state for the current session.
#   - Without emoji (SessionEnd): removes the state file.
#
# Reads JSON from stdin to extract session_id. Falls back gracefully if
# session_id is missing — in that case no file is written/removed.

set -eu

emoji=${1:-}

input=$(cat 2>/dev/null || true)
session_id=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null || true)

[ -n "$session_id" ] || exit 0

state_dir=${CLAUDE_PLUGIN_DATA:-${TMPDIR:-/tmp}}
mkdir -p "$state_dir" 2>/dev/null || true
state_file="$state_dir/state-$session_id"

if [ -z "$emoji" ]; then
    rm -f "$state_file"
    exit 0
fi

proj_dir=${CLAUDE_PROJECT_DIR:-$PWD}
proj=$(basename "$proj_dir")
branch=$(git -C "$proj_dir" symbolic-ref --short HEAD 2>/dev/null || true)

if [ -n "$branch" ]; then
    info="$emoji $proj ($branch)"
else
    info="$emoji $proj"
fi

printf '%s\n' "$info" > "$state_file"
