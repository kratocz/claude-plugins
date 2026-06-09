# claude-statusline-state

Publish per-session Claude Code lifecycle state (idle / working / waiting) to a small file, ready to be rendered as an extra line on top of your statusline. Pairs well with [`tmux-hooks`](https://github.com/kratocz/tmux-hooks) if you also want the same info on tmux pane borders.

## States

| Emoji | Event | Meaning |
| --- | --- | --- |
| 🤖 | `SessionStart`, `Stop` | Idle, ready for input |
| ⚡ | `UserPromptSubmit` | Working on a prompt |
| 💬 | `Notification`, `PermissionRequest` | Waiting for your attention |
| *(removed)* | `SessionEnd` | State file is deleted |

The state line is `<emoji> <project>` and, when the project is a git repository, the current branch in parentheses — e.g. `🤖 tmux-hooks (main)`. When Claude Code provides a `session_name` (the chat title / live conversation summary), it is appended after a ` | ` separator: `🤖 tmux-hooks (main) | Add pane_title to Claude Code statusline`.

## Installation

```
/plugin marketplace add kratocz/claude-plugins
/plugin install claude-statusline-state@kratocz
```

The hooks start writing state into `$CLAUDE_PLUGIN_DATA/state-<session_id>` immediately. To actually see the state, wire `bin/statusline-state.sh` into your existing statusline command.

## Wiring it into your statusline

Claude Code statusline supports multi-line output — any `\n` in the command's stdout becomes a new line. Read the JSON from stdin once, pipe a copy into `statusline-state.sh`, and prepend its output to whatever your statusline already prints.

Minimal example (`~/.claude/statusline-command.sh`):

```sh
#!/usr/bin/env bash
input=$(cat)

state_line=$(printf '%s' "$input" | "$HOME/.claude/plugins/claude-statusline-state/bin/statusline-state.sh")
[ -n "$state_line" ] && printf '%s\n' "$state_line"

# ... your existing statusline rendering ...
cwd=$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd')
printf '%s\n' "$(basename "$cwd")"
```

The exact path under `~/.claude/plugins/...` depends on how the plugin is installed; adjust if you cloned it elsewhere.

Result (the state line appears **above** your normal statusline):

```
🤖 tmux-hooks (main) | Add pane_title to Claude Code statusline
tmux-hooks git:(main) ctx: 12% │ …
```

## Behavior notes

- **Per-session**: state is keyed by `session_id` from the statusline JSON, so multiple Claude Code sessions don't collide.
- **No state, no line**: if no file exists for the current session, `statusline-state.sh` prints nothing — your normal statusline renders unchanged.
- **Auto-cleanup on SessionEnd**: the SessionEnd hook removes the state file. Files from sessions that died uncleanly will linger in `$CLAUDE_PLUGIN_DATA` until you clean them up manually.
- **Works without tmux**: unlike `tmux-hooks`, this plugin doesn't touch tmux. Use both side by side if you want the state visible in both places.
- **Statusline can't read `$CLAUDE_PLUGIN_DATA`**: Claude Code only sets it for hooks, not for statusline commands. `statusline-state.sh` therefore searches a list of candidate directories (`$CLAUDE_PLUGIN_DATA`, `~/.claude/plugins/data/claude-statusline-state-<marketplace>`, `$TMPDIR`) and uses the first one that has a state file for the current session.

## Requirements

- `jq` on `PATH` (used by both the hook and the statusline reader to parse Claude Code's JSON).

## License

MIT
