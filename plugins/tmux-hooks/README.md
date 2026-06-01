# tmux-hooks

Publish a per-pane Claude Code status to a tmux pane-local user option (`@claude_info`), so the pane border can show which project a pane belongs to and what state Claude Code is in — alongside Claude Code's own pane title (spinner + conversation summary). Handy when you run multiple Claude Code sessions across panes/windows.

## States

| Emoji | Event | Meaning |
| --- | --- | --- |
| 🤖 | `SessionStart`, `Stop` | Idle, ready for input |
| ⚡ | `UserPromptSubmit` | Working on a prompt |
| 💬 | `Notification`, `PermissionRequest` | Waiting for your attention |
| *(empty)* | `SessionEnd` | Session over |

The pane-local option `@claude_info` is set to `<emoji> <project>` and, when the project is a git repository, the current branch in parentheses — e.g. `🤖 tmux-hooks (main)`.

## Installation

```
/plugin marketplace add kratocz/claude-plugins
/plugin install tmux-hooks@kratocz
```

## Required tmux configuration

Pane borders aren't visible by default. Add to `~/.tmux.conf`:

```tmux
set -g pane-border-status top
set -g pane-border-format " #{@claude_info} #{?@claude_info,| ,}#{pane_title} "
```

That gives you something like:

```
 🤖 tmux-hooks (main) | ⠐ Working on the next prompt
```

The `#{@claude_info}` placeholder is what this plugin sets; `#{pane_title}` is whatever the foreground app (Claude Code, your shell, etc.) writes. The `#{?...}` guard hides the `|` separator in panes where `@claude_info` isn't set.

Reload: `tmux source-file ~/.tmux.conf`.

## Behavior notes

- **Safe outside tmux.** Hooks no-op if `$TMUX_PANE` is unset.
- **No focus stealing.** The plugin writes a pane-local option (`set -p`) rather than calling `select-pane`, so background panes update without grabbing focus.
- **Pane title is left alone.** Claude Code's own pane title (spinner + conversation summary) is not touched.
- **No window renaming.** Your tmux window names stay untouched.

## License

MIT
