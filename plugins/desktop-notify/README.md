# desktop-notify

A [Claude Code](https://claude.ai/claude-code) plugin that sends desktop notifications whenever Claude is waiting for your response or needs your approval to run a tool.

Never miss a paused session again — get notified even when you're in another window.

## Preview

![desktop-notify notifications](screenshot.png)

## What it does

| Event | When | Notification example |
|---|---|---|
| `Stop` | Claude finished its response | `Claude Code – myproject` / `Waiting for your response` |
| `PermissionRequest` | Claude needs tool approval | `Claude Code – myproject` / `Approval: Bash: git status` |

Each notification includes the **project name** in the title so you always know which Claude Code session needs attention.

## Configuration

Set `DESKTOP_NOTIFY_METHOD` in your `~/.claude/settings.json` to choose how you're notified:

```json
{
  "env": {
    "DESKTOP_NOTIFY_METHOD": "visual"
  }
}
```

| Value | Behavior |
|---|---|
| `visual` | Desktop notification popup *(default)* |
| `sound` | Text-to-speech reads the project name and message aloud |
| `both` | Visual notification + TTS simultaneously |

## Requirements

| Platform | `visual` | `sound` |
|---|---|---|
| Linux | `notify-send` (libnotify) + `jq` | `spd-say`, `espeak-ng`, or `espeak` |
| macOS | `jq` (notifications via built-in `osascript`) | built-in `say` |
| Windows | Not supported yet | Not supported yet |

### Install dependencies

**Ubuntu / Debian:**
```bash
sudo apt install libnotify-bin jq
# for sound:
sudo apt install speech-dispatcher  # provides spd-say
```

**Fedora / RHEL:**
```bash
sudo dnf install libnotify jq
# for sound:
sudo dnf install speech-dispatcher
```

**macOS:**
```bash
brew install jq
# sound uses built-in 'say' — no extra dependencies
```

## Installation

```
/plugin marketplace add kratocz/claude-plugins
/plugin install desktop-notify@kratocz
```

## How it works

The plugin registers two [Claude Code hook](https://docs.anthropic.com/en/docs/claude-code/hooks) events:

- **`Stop`** — fires when Claude finishes its response and waits for your next message
- **`PermissionRequest`** — fires when Claude needs your approval to execute a tool (Bash command, file write, etc.)

Both hooks run **asynchronously** so they never slow down Claude Code.

The `PermissionRequest` notification includes the tool name and a short preview of the command or file path, so you immediately know what needs your attention.

## Acknowledgements

Sound notification support was inspired by [Radim Klaška](https://github.com/radimklaska).

## Contributing

Issues and PRs are welcome at [github.com/kratocz/desktop-notify](https://github.com/kratocz/desktop-notify).

## License

MIT — © [Petr Kratochvíl](https://krato.cz/)
