#!/bin/sh
# Set tmux pane title to: <emoji> <project> [(<branch>)]
# Usage: set-title.sh [emoji]
# Empty/missing emoji clears the title (used on SessionEnd).
# No-op when not running inside tmux.

[ -n "$TMUX_PANE" ] || exit 0

emoji=$1

if [ -z "$emoji" ]; then
    title=""
else
    proj=$(basename "$CLAUDE_PROJECT_DIR")
    branch=$(git -C "$CLAUDE_PROJECT_DIR" symbolic-ref --short HEAD 2>/dev/null)
    if [ -n "$branch" ]; then
        title="$emoji $proj ($branch)"
    else
        title="$emoji $proj"
    fi
fi

cur=$(tmux display-message -p '#{pane_id}')
tmux select-pane -t "$TMUX_PANE" -T "$title"
[ "$cur" != "$TMUX_PANE" ] && tmux select-pane -t "$cur" || true
