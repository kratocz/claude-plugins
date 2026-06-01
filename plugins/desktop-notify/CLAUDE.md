# CLAUDE.md

## Project overview

`claude-code-notify` is a Claude Code plugin that sends desktop notifications when Claude Code pauses to wait for user input or approval.

## Structure

```
claude-code-notify/
├── .claude-plugin/
│   └── plugin.json           # Plugin manifest (name, version, author)
├── hooks/
│   └── hooks.json            # Hook event declarations
├── scripts/
│   ├── notify-stop.sh        # Runs on Stop event
│   └── notify-permission.sh  # Runs on PermissionRequest event
├── README.md
└── CLAUDE.md
```

## Key files

- **`hooks/hooks.json`** — maps hook events to scripts via `${CLAUDE_PLUGIN_ROOT}`. Uses `async: true` so hooks never block Claude Code.
- **`scripts/notify-stop.sh`** — shows a normal-priority notification. Uses `$PWD` for the project name.
- **`scripts/notify-permission.sh`** — reads JSON from stdin (tool_name, tool_input), extracts tool name and command/file path, shows a critical-priority notification.

## Platform detection

Scripts detect the OS via `$OSTYPE`:
- `darwin*` → `osascript` (built-in macOS notifications)
- anything else with `notify-send` available → `notify-send` (Linux/libnotify)

## Adding new hook events

1. Add a new entry in `hooks/hooks.json` referencing a new script
2. Create the script in `scripts/`
3. Available hook events: `Stop`, `PermissionRequest`, `PreToolUse`, `PostToolUse`, `Notification`, `SessionStart`, etc.

See [Claude Code hooks reference](https://docs.anthropic.com/en/docs/claude-code/hooks) for full event list and stdin payload schemas.
