# session-log

A Claude Code plugin that saves a **structured markdown summary** of each session to disk automatically. No configuration needed — just install it and every session you finish leaves a readable record behind.

## Install

```
/plugin install session-log@kratocz
```

## What it does

At the end of every Claude Code session, the plugin writes a short markdown summary to Claude Code's plugin data directory:

```
~/.claude/plugins/data/session-log-kratocz/logs/<encoded-cwd>/<date>_<session-id>.md
```

Where `<encoded-cwd>` is the working directory encoded the same way Claude Code encodes paths in `~/.claude/projects/` (both `/` and `.` become `-`). So if you ran Claude Code in `/home/user/code/my-app`, the summary lands in:

```
~/.claude/plugins/data/session-log-kratocz/logs/-home-user-code-my-app/
```

This matches the directory key Claude Code uses for raw JSONL transcripts, giving you a 1:1 mapping between a session summary and its full transcript.

The path uses Claude Code's official `${CLAUDE_PLUGIN_DATA}` convention — auto-namespaced by marketplace, so it won't collide with a differently-published plugin of the same name.

The summary includes:

- **YAML frontmatter** with `session_id`, `project`, `cwd`, `started` / `ended` timestamps, `duration`, `turns`, and a link to the raw JSONL transcript.
- **Goal** — your first real message (what you asked Claude to do).
- **Files touched** — every file modified via `Edit`, `Write`, or `NotebookEdit`.
- **Git commits** — commit messages made during the session.
- **Tool stats** — count per tool (`Bash`, `Read`, `Edit`, …).

## Finding your logs

Use the `/log-where` slash command inside any Claude Code session. It prints the log directory for the current project plus the 10 most recent summaries.

```
/log-where
```

## Why summaries and not full transcripts?

Claude Code already keeps the raw JSONL transcript of every session in `~/.claude/projects/<encoded-path>/*.jsonl`. Duplicating that in markdown would waste disk space and increase the surface area for accidentally leaking secrets.

Summaries are much smaller (typically < 2 KB), and they're optimized for the real use case: "when did I work on X?" / "which session fixed that bug?". If you need the full context of a past session, the `transcript:` field in the frontmatter points straight to the raw JSONL.

## Security note

Summaries can contain fragments of anything you discussed with Claude — including file paths, commit messages, and the first few hundred characters of your initial message. The directory lives under `~/.claude/plugins/data/session-log-kratocz/` which is **never inside a project repo**, so there's no risk of accidentally committing them.

Still, don't copy summary files into repositories you publish without review.

## Platform support

| Platform | Support | Notes |
|----------|:-------:|-------|
| Linux | 🟢 Full | |
| macOS | 🟡 Partial | Duration calculation requires GNU date: `brew install coreutils`. All other features work. |
| Windows | 🔴 None | Use WSL — inside WSL it works like Linux. |

## Requirements

- Claude Code `>= 2.1.78` (for `${CLAUDE_PLUGIN_DATA}` support)
- `bash`
- `jq`
- GNU `date` (standard on Linux; on macOS install via `brew install coreutils`)

The plugin runs as a fire-and-forget `SessionEnd` hook — it never blocks Claude Code and never writes anywhere outside its own data directory.

## Uninstall

```
/plugin uninstall session-log@kratocz
```

**By default this also deletes all your logs** (Claude Code wipes the plugin data directory when the plugin is uninstalled from the last scope). To keep the logs across uninstall/reinstall, pass `--keep-data`:

```
/plugin uninstall session-log@kratocz --keep-data
```

The logs are then preserved at `~/.claude/plugins/data/session-log-kratocz/logs/` and will be picked up again when you reinstall.

If you want the logs gone completely, uninstalling without `--keep-data` is enough — or delete `~/.claude/plugins/data/session-log-kratocz/` manually.
