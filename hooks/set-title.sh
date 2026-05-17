#!/bin/sh
# Publish "<emoji> <project> [(<branch>)]" to the tmux pane-local user
# option @claude_info, so the user's pane-border-format can show it
# alongside Claude Code's own pane_title (which carries the spinner +
# conversation summary).
#
# Usage: set-title.sh [emoji]
# Empty/missing emoji clears @claude_info (used on SessionEnd).
# No-op when not running inside tmux.

[ -n "$TMUX_PANE" ] || exit 0

emoji=$1

if [ -z "$emoji" ]; then
    info=""
else
    proj=$(basename "$CLAUDE_PROJECT_DIR")
    branch=$(git -C "$CLAUDE_PROJECT_DIR" symbolic-ref --short HEAD 2>/dev/null)
    if [ -n "$branch" ]; then
        info="$emoji $proj ($branch)"
    else
        info="$emoji $proj"
    fi
fi

tmux set-option -p -t "$TMUX_PANE" @claude_info "$info"
