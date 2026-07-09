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

3. **Fetch all enabled sources — IN PARALLEL** where they are MCP calls (one
   message, multiple tool_use blocks). Probe each MCP source with `ToolSearch`
   first; if absent, append a warning and skip. Build the list `blocks`.

   **A. Claude Code session logs** (primary, if
   `effective_config.reconcile.ai_sessions.enabled`):

   Session logs live under `<projects_dir>/<encoded-path>/*.jsonl`, one file per
   session. The directory name is the working directory with `/` → `-`. Each
   line is a JSON object with `timestamp` (ISO 8601 UTC), `type`
   (`user`/`assistant`/`ai-title`/…). Find sessions overlapping the window and
   turn each into one `candidate_block`:

   ```bash
   DIR="${projects_dir/#\~/$HOME}"        # expand ~
   SINCE_UTC=$(date -u -j -f "%Y-%m-%dT%H:%M:%S" "<since>" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null \
             || date -u -d "<since>" +%Y-%m-%dT%H:%M:%SZ)
   UNTIL_UTC=$(date -u -j -f "%Y-%m-%dT%H:%M:%S" "<until>" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null \
             || date -u -d "<until>" +%Y-%m-%dT%H:%M:%SZ)
   find "$DIR" -name '*.jsonl' -type f
   ```

   For each `*.jsonl`, extract with a small Python filter (robust to non-JSON
   lines) the sorted list of message timestamps and the `ai-title` value:

   ```bash
   python3 - "$f" "$SINCE_UTC" "$UNTIL_UTC" <<'PY'
   import json, sys
   f, since, until = sys.argv[1], sys.argv[2], sys.argv[3]
   ts, title = [], None
   for line in open(f, encoding='utf-8'):
       try: d = json.loads(line)
       except Exception: continue
       t = d.get('timestamp')
       if t: ts.append(t)
       if d.get('type') == 'ai-title':
           title = (d.get('content') or title)
   ts = sorted(t for t in ts if t)
   if not ts: sys.exit(0)
   # keep session if it overlaps [since, until]
   if ts[-1] < since or ts[0] > until: sys.exit(0)
   print(json.dumps({'first': ts[0], 'last': ts[-1], 'n': len(ts),
                     'title': title, 'ts': ts}))
   PY
   ```

   For each surviving session, create a `candidate_block`:
   - `source='ai'`, `raw_messages_ts=ts` (kept for Task 3's duration math),
     `start`/`end` = first/last ts **converted to local** (via `date`),
     `title` = the `ai-title` (or, if null, "Práce v <dir>"),
   - `project_hint` = the repo/dir name decoded from the directory name (last
     path segment of the decoded working directory),
   - `origin_marks=[]`.
   - Clip `start`/`end` to `[since, until]` if the session spills over an edge.

   **B. Google Calendar** (primary, if `calendar` source enabled and MCP
   present — probe `select:mcp__claude_ai_Google_Calendar__list_events`):

   Call `mcp__claude_ai_Google_Calendar__list_events` for `[since, until]`. For
   each returned event, apply the work filter from
   `effective_config.reconcile.calendar`:
   - drop all-day events if `exclude_all_day`,
   - drop events the user declined if `exclude_declined`,
   - drop events whose title matches any `exclude_keywords` (case-insensitive
     substring).
   Each surviving event → a `candidate_block` with `source='calendar'`,
   `start`/`end` = event start/end (local), `title` = event summary,
   `project_hint` = null (resolved in Task 4), `origin_marks=[]`,
   `raw_messages_ts=[]`.
   If the MCP is absent, append a one-line warning "Kalendář nedostupný —
   schůzky vynechány." and skip.
