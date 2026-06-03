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
│   └── end/SKILL.md       ← /work-end
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
    "google_calendar": { "enabled": true, "mcp_prefix": "mcp__claude_ai_Google_Calendar__", "window_hours": 12 }
  },
  "scoring": {
    "weights": { "priority": 40, "due_proximity": 30, "age": 15, "type_assignment": 15 },
    "top_n": 8
  }
}
```

Persists across plugin upgrades (lives outside `~/.claude/plugins/cache/`).

## Per-project override

`~/.claude/projects/<slug>/memory/work_config.md` — markdown with a fenced `json` block. The skill parses only the JSON block; surrounding prose is for human readers. Deep-merged onto global config (arrays replace, scalars override).

## Skills

| Skill | Trigger | Description |
|-------|---------|-------------|
| `/work-setup`  | First run / reconfigure | Interactive setup, detects MCP sources, writes config |
| `/work-start`  | Morning | Fetches all enabled sources, scores items, prints top N briefing |
| `/work-status` | Mid-day | Diffs current state against last briefing snapshot |
| `/work-end`    | Evening | Summarises what got done and what carries over |

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
