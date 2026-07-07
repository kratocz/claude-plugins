# work

A Claude Code plugin for daily work orchestration. Pulls tasks, issues, PRs, and calendar events from your configured MCP sources (Todoist, ClickUp, GitHub, Google Calendar) into a scored briefing.

## Install

```
/plugin install work@kratocz
```

## Setup

Run once to configure which sources to track:

```
/work-setup
```

The skill auto-detects MCP servers available in your Claude Code session and asks which to enable.

## Usage

Daily flow:

```
/work-start    # Morning: scored briefing of what to work on
/work-status   # Anytime: diff since last briefing (what closed, what's new)
/work-end      # Evening: summary of what got done, what carries over
/work-standup  # Standup: recap of what you did since last time (Toggl + git + GitHub)
```

`/work-standup` is backward-looking and standalone (no morning snapshot
needed): it pulls Toggl time entries, git commits, and GitHub reviews/merges
since the last standup and groups them into a paste-ready recap. Because it
reads Toggl, it captures review- and ops-heavy work that leaves no commit.

## Supported sources

- [Todoist](https://todoist.com/) — via Todoist MCP server
- [ClickUp](https://clickup.com/) — via ClickUp MCP server
- [GitHub](https://github.com/) — issues + PRs to review, via GitHub MCP server
- [Google Calendar](https://calendar.google.com/) — upcoming events, via Calendar MCP server
- [Toggl Track](https://toggl.com/) — tracked time for the standup recap, via Toggl MCP server (or `session-tracker`'s API key as fallback); used by `/work-standup` only

A source is used only if its MCP server is connected to your Claude Code session. Missing sources are skipped with a warning.

## Config

Stored at `~/.claude/plugins/work/config.json`. Persists across plugin upgrades. Re-run `/work-setup` to change settings.

Per-project overrides can be saved in `~/.claude/projects/<slug>/memory/work_config.md`.
