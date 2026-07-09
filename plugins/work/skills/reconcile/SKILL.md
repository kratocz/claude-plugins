---
name: work-reconcile
description: Backfill missing timesheet entries at the end of a period. Reconstructs what you actually worked on — primarily from Claude Code session logs, confirmed by git/GitHub/Calendar/ClickUp — diffs it against what is already logged in Toggl/ClickUp, and after you approve each item writes only the missing time. Use when the user says "/work-reconcile", "doplň výkaz", "dorovnej timesheet", "co jsem zapomněl vykázat", "fill my timesheet", "reconcile my hours", "co chybí ve výkazu za minulý měsíc".
argument-hint: [--since YYYY-MM-DD] [--until YYYY-MM-DD] [--project <name>] [--dry-run]
version: 0.3.0
allowed-tools: Read, Bash, ToolSearch, AskUserQuestion, mcp__toggl__toggl_get_time_entries, mcp__toggl__toggl_list_projects, mcp__github__search_pull_requests, mcp__github__search_issues, mcp__github__list_commits, mcp__plugin_ntit-common_clickup__clickup_filter_tasks, mcp__plugin_ntit-common_clickup__clickup_get_task_comments, mcp__plugin_ntit-common_clickup__clickup_add_time_entry, mcp__claude_ai_Google_Calendar__list_events
---

# Work Reconcile

Retrospective timesheet backfill: **what did I actually work on that I never
logged — and write the missing time.** The forward-looking siblings answer
different questions:

| Skill | Question | Direction |
|-------|----------|-----------|
| `/work-start` | What should I do? | forward |
| `/work-status` | What changed? | since AM |
| `/work-end` | What did I close today? | today |
| `/work-standup` | What did I do since last time? | back (report) |
| **`/work-reconcile`** | **What did I do but not log — and fill it in** | **back (write)** |

Unlike the others, this skill **writes** to the tracker. It never writes
automatically: the flow is always **propose → confirm → write**.

## Arguments

- `--since YYYY-MM-DD` (optional): start of the reconcile window (bare date = `T00:00` local). Default: see step 2.
- `--until YYYY-MM-DD` (optional): end of the window (bare date = `T23:59:59` local). Default: now.
- `--project <name>` (optional): restrict to one project by name (case-insensitive substring).
- `--dry-run` (optional): run the full flow through review and **only print** the proposals — write nothing.

## Steps

1. **Load effective config.** Read `~/.claude/plugins/work/config.json` with the
   Read tool.
   - If missing: stop with (in the configured language) "Žádná konfigurace work
     pluginu. Spusť `/work-setup`." / "No work plugin config. Run `/work-setup`."
   - Parse it. Read `config.language` (default `cs`, fallback `en`); phrase all
     user-facing text in it, keeping proper nouns/IDs/URLs/durations unchanged.
   - Build `effective_config` by overlaying the `reconcile` block on these
     defaults (a MISSING `reconcile` block or any missing key falls back here —
     do not crash):
     `default_window=last_month`, `gap_threshold_min=15`, `edge_pad_min=2`,
     `round_to_min=5`, `min_block_min=5`, `coverage_covered=0.9`,
     `coverage_missing=0.1`, `ai_sessions.enabled=true`,
     `ai_sessions.projects_dir=~/.claude/projects`, `calendar.as_work=true`,
     `calendar.exclude_all_day=true`, `calendar.exclude_declined=true`,
     `calendar.exclude_keywords=["oběd","lunch","dovolená"]`,
     `sink.target=toggl`, `sink.billable=true`, `sink.reconciled_tag=reconciled`.

2. **Resolve the window `[since, until]`.**
   - `until`: `--until` if given (bare date → `T23:59:59` local), else now.
   - `since`: `--since` if given (bare date → `T00:00` local), else derive from
     `effective_config.reconcile.default_window`:
     - `last_month` (default): first day of the **previous** calendar month at
       `00:00` local; and if `--until` was not given, set `until` to the last
       moment of that previous month (so the default run reconciles exactly last
       month).
     - `last_week`: now minus 7 days at `00:00` local.
     - a bare `YYYY-MM`: that whole month.
   Compute `last_month` boundaries with `date` (never by hand):
   ```bash
   # macOS: first day of previous month 00:00 local
   date -v1d -v-1m -v0H -v0M -v0S +%Y-%m-%dT%H:%M:%S
   # macOS: last moment of previous month = (first day this month) - 1 second
   date -v1d -v0H -v0M -v0S -v-1S +%Y-%m-%dT%H:%M:%S
   # Linux: date -d "$(date +%Y-%m-01) -1 month" +%Y-%m-%dT00:00:00
   #        date -d "$(date +%Y-%m-01) -1 second" +%Y-%m-%dT%H:%M:%S
   ```
   - Store `project_filter` = `--project` value or null; `dry_run` = whether
     `--dry-run` was passed.
   - **Echo the resolved window** before doing anything else, e.g. "Dorovnávám
     výkaz od **<since>** do **<until>**." so an unexpected default is visible.
