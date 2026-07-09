# CLAUDE.md

## Plugin overview

`work` is a Claude Code plugin that aggregates tasks/issues/PRs/calendar events from MCP-configured sources into a scored daily briefing.

## Structure

```
work/
├── .claude-plugin/
│   └── plugin.json        ← plugin manifest
├── skills/
│   ├── setup/SKILL.md     ← /work-setup
│   ├── start/SKILL.md     ← /work-start
│   ├── status/SKILL.md    ← /work-status
│   ├── end/SKILL.md       ← /work-end
│   ├── standup/SKILL.md   ← /work-standup
│   └── reconcile/SKILL.md ← /work-reconcile
├── README.md
└── CLAUDE.md
```

## Config file

Global config at `~/.claude/plugins/work/config.json`:

```json
{
  "language": "cs",
  "sources": {
    "todoist": { "enabled": true, "mcp_prefix": "mcp__claude_ai_Todoist__", "filters": { "priorities": ["p1", "p2"], "scope": "today_and_overdue" } },
    "github":  { "enabled": true, "mcp_prefix": "mcp__github__", "username": "kratocz", "include": ["assigned_issues", "review_requested_prs", "my_open_prs"] },
    "clickup": { "enabled": false, "mcp_prefix": "mcp__plugin_ntit-common_clickup__" },
    "google_calendar": { "enabled": true, "mcp_prefix": "mcp__claude_ai_Google_Calendar__", "window_hours": 12 },
    "toggl":   { "enabled": true, "mcp_prefix": "mcp__toggl__", "project_id": null, "project_name": null, "billable_only": false }
  },
  "standup": { "default_window": "last_workday_noon" },
  "scoring": {
    "weights": { "priority": 40, "due_proximity": 30, "age": 15, "type_assignment": 15 },
    "top_n": 8
  }
}
```

Persists across plugin upgrades (lives outside `~/.claude/plugins/cache/`).

The `toggl` source and the top-level `standup` block are consumed **only by
`/work-standup`** (the daily briefing skills ignore them). `toggl.project_id`
/ `toggl.project_name` scope the recap to one project — leave both null to
recap all tracked time. `standup.default_window` sets the default recap start
(`last_workday_noon` | `24h`/`48h`/`72h` | a bare `YYYY-MM-DD`); override
per-run with `--since`. Toggl reads prefer the Toggl MCP server and fall back
to `session-tracker`'s API key when the MCP server is absent.

The top-level `reconcile` block is consumed **only by `/work-reconcile`** and
is entirely optional — a missing block (or missing individual keys) falls
back to these built-in defaults:

- `default_window` (`last_month`) — default reconcile window when `--since`/`--until` aren't passed.
- `gap_threshold_min` (`15`) — inter-message gap, in minutes, below which AI-session time counts in full.
- `edge_pad_min` (`2`) — padding added per message gap/session edge instead of the full gap.
- `round_to_min` (`5`) — rounding granularity for estimated block durations.
- `min_block_min` (`5`) — blocks shorter than this after rounding are dropped as noise.
- `coverage_covered` (`0.9`) — overlap ratio at/above which a block is considered already logged and dropped.
- `coverage_missing` (`0.1`) — overlap ratio below which a block is treated as fully missing.
- `ai_sessions.enabled` (`true`) — whether Claude Code session logs are used as a work source.
- `ai_sessions.projects_dir` (`~/.claude/projects`) — root directory scanned for session `*.jsonl` files.
- `calendar.as_work` (`true`) — treat Calendar events as work time; also gates whether the Calendar source is fetched at all.
- `calendar.exclude_all_day` (`true`) — drop all-day events.
- `calendar.exclude_declined` (`true`) — drop events the user declined.
- `calendar.exclude_keywords` (`["oběd", "lunch", "dovolená"]`) — drop events whose title matches any keyword (case-insensitive substring).
- `sink.target` (`toggl`) — where to write reconciled time: `toggl` | `clickup` | `both`.
- `sink.billable` (`true`) — billable flag set on written entries.
- `sink.reconciled_tag` (`reconciled`) — tag applied to every entry the skill writes (also used for idempotency on re-run).

`/work-setup` can optionally write a `reconcile` block letting the user
override `sink.target` and `default_window`; all other keys keep their
built-in defaults unless hand-edited in the JSON.

## Per-project override

`~/.claude/projects/<slug>/memory/work_config.md` — markdown with a fenced `json` block. The skill parses only the JSON block; surrounding prose is for human readers. Deep-merged onto global config (arrays replace, scalars override).

## Skills

| Skill | Trigger | Description |
|-------|---------|-------------|
| `/work-setup`  | First run / reconfigure | Interactive setup, detects MCP sources, writes config |
| `/work-start`  | Morning | Fetches all enabled sources, scores items, prints top N briefing |
| `/work-status` | Mid-day | Diffs current state against last briefing snapshot |
| `/work-end`    | Evening | Summarises what got done and what carries over |
| `/work-standup`| Standup | Recap since last standup from Toggl + git + GitHub reviews/merges; paste-ready |
| `/work-reconcile`| Period-end (e.g. monthly) | Backfills missing timesheet entries — reconstructs work from Claude Code sessions/Calendar/git/GitHub/ClickUp, diffs against what's logged, writes only the gap after user approval |

## Scoring formula

```
score = 0.40 * priority_score
      + 0.30 * due_proximity_score
      + 0.15 * age_score
      + 0.15 * type_assignment_score
```

See `docs/superpowers/specs/2026-06-03-work-plugin-design.md` for full scoring tables, data flows, and error handling rules. Update the spec if you change behavior.

## Snapshot file

`/work-start` writes `~/.claude/plugins/work/last-briefing.json`. Consumed by `/work-status` and `/work-end`. Schema versioned (`schema_version: 1`).

## Release workflow

Same as session-tracker:

1. Bump `version` in `plugin.json` AND in every skill's frontmatter (keep in sync).
2. Commit with `feat:` / `fix:` / `chore:` subject and bulleted body.
3. Lightweight tag: `git tag work-vX.Y.Z` (prefix with plugin name in monorepo).
4. Push and create GitHub Release with `gh release create work-vX.Y.Z --generate-notes`.

SemVer: patch for hardening, minor for new sources/config fields, major for breaking config schema changes.
