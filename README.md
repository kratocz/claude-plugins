# tmux-hooks

Set the tmux pane title to reflect the current Claude Code lifecycle state. At a glance you can see which panes are working, which are waiting for input, and which project each one is in — useful when you run multiple Claude Code sessions across panes/windows.

## States

| Emoji | Event | Meaning |
| --- | --- | --- |
| 🤖 | `SessionStart`, `Stop` | Idle, ready for input |
| ⚡ | `UserPromptSubmit` | Working on a prompt |
| 💬 | `Notification`, `PermissionRequest` | Waiting for your attention |
| *(empty)* | `SessionEnd` | Session over |

The project directory name (`$(basename $CLAUDE_PROJECT_DIR)`) is appended to each state.

## Installation

```
/plugin marketplace add kratocz/claude-plugins
/plugin install tmux-hooks@kratocz
```

## Required tmux configuration

Pane titles aren't visible by default. Add to `~/.tmux.conf`:

```tmux
set -g pane-border-status top
set -g pane-border-format " #{pane_title} "
```

Reload: `tmux source-file ~/.tmux.conf`.

## Behavior notes

- **Safe outside tmux.** Hooks no-op if `$TMUX_PANE` is unset.
- **Focus-preserving.** Each hook records the currently active pane (`#{pane_id}`) before setting the title, then restores focus. Without this, finishing work in a background pane would steal focus from whatever pane you were viewing.
- **No window renaming.** The plugin sets pane title only — your tmux window names stay untouched.

## License

MIT
