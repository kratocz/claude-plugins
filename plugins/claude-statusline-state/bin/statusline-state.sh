#!/bin/sh
# Read Claude Code statusline JSON from stdin and print the current
# session's state line (set by claude-statusline-state hooks), if any.
#
# Usage (inside your ~/.claude/statusline-command.sh):
#
#   input=$(cat)
#   state_line=$(printf '%s' "$input" | /path/to/statusline-state.sh)
#   [ -n "$state_line" ] && printf '%s\n' "$state_line"
#   # ... rest of your statusline ...
#
# Prints nothing (exit 0) when no state file exists for this session.

set -eu

input=$(cat 2>/dev/null || true)
session_id=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null || true)
session_name=$(printf '%s' "$input" | jq -r '.session_name // empty' 2>/dev/null || true)

[ -n "$session_id" ] || exit 0

# Try the same dirs set-state.sh might have used. Claude Code does not
# pass $CLAUDE_PLUGIN_DATA to statusline commands (only to hooks), so
# fall back to the well-known plugin data location and finally $TMPDIR.
candidate_dirs="${CLAUDE_PLUGIN_DATA:-} $HOME/.claude/plugins/data/claude-statusline-state-local-test $HOME/.claude/plugins/data/claude-statusline-state-kratocz ${TMPDIR:-/tmp}"

state_file=""
for d in $candidate_dirs; do
    [ -n "$d" ] || continue
    f="$d/state-$session_id"
    if [ -r "$f" ]; then
        state_file=$f
        break
    fi
done

[ -n "$state_file" ] || exit 0

# Strip a possible trailing newline; statusline caller adds its own.
state=$(cat "$state_file")
[ -n "$state" ] || exit 0

if [ -n "$session_name" ]; then
    # Bold ANSI cyan for the chat title; reset right after to avoid leaking.
    BOLD_CYAN=$(printf '\033[1;36m')
    RESET=$(printf '\033[0m')
    printf '%s%s | %s%s' "$state" "$BOLD_CYAN" "$session_name" "$RESET"
else
    printf '%s' "$state"
fi
