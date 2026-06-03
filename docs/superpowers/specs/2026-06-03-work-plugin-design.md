# Work Plugin — Design Spec

**Status:** Draft for review
**Date:** 2026-06-03
**Author:** Petr Kratochvíl + Claude (brainstorming session)

## Goal

A new Claude Code plugin named `work` that gives the user a structured "what to work on" view by aggregating tasks, issues, PRs, and calendar events across multiple configured sources (Todoist, ClickUp, GitHub, Google Calendar, ...). The plugin replaces the manual ritual of opening 4-5 tabs every morning with a single slash command that prints a scored, deduplicated, action-oriented briefing.

## Scope (MVP)

Four skills under one plugin:

| Skill | Slash command | Purpose |
|---|---|---|
| `setup` | `/work-setup` | Interactive configuration — detects available MCP sources, asks user which to enable, writes config |
| `start` | `/work-start` | Morning briefing — pulls items from all enabled sources, scores them, prints top N with categories and a 1-sentence recommendation |
| `status` | `/work-status` | Mid-day check — diffs current state against last briefing snapshot, shows what closed, what's new, what's still open |
| `end` | `/work-end` | End-of-day summary — what got done, what carries over, optional save to session log |

## Non-goals

- No task creation/modification (read-only briefing; create tasks via Todoist/ClickUp directly)
- No notifications, no scheduling, no recurring runs (user invokes manually; `/loop` skill can wrap if desired)
- No analytics/trends (no historical data store beyond `last-briefing.json` snapshot)
- No integration beyond what user has configured via MCP — plugin does not bundle REST clients for sources not exposed as MCP

## Architecture

Pure SKILL.md instructions. No Python/Node runtime. Skills invoke MCP tools directly via Claude's tool system. Same convention as `session-tracker`.

### Plugin layout

```
plugins/work/
├── .claude-plugin/plugin.json   # name: "work", version: 0.1.0
├── README.md                    # Install + usage
├── CLAUDE.md                    # Internal notes for future Claude editing this plugin
└── skills/
    ├── setup/SKILL.md           # name: work-setup
    ├── start/SKILL.md           # name: work-start
    ├── status/SKILL.md          # name: work-status
    └── end/SKILL.md             # name: work-end
```

Skill names prefixed `work-*` to avoid collision with other plugins (e.g. `session-tracker` exposes `/start`).

### Skill frontmatter pattern

```yaml
---
name: work-start
description: Morning briefing — pull tasks/PRs from configured sources and score them. Use when the user says "/work-start", "morning briefing", "co dneska řešit".
argument-hint: [--fresh]
version: 0.1.0
allowed-tools: Read, Write, Bash, mcp__claude_ai_Todoist__*, mcp__github__*, mcp__plugin_ntit-common_clickup__*, mcp__claude_ai_Google_Calendar__*
---
```

## Configuration

### Global config: `~/.claude/plugins/work/config.json`

Persists across plugin upgrades (only `~/.claude/plugins/cache/<marketplace>/work/` gets refreshed during plugin updates, never `~/.claude/plugins/work/` itself — verified by inspecting `session-tracker` layout).

```json
{
  "language": "cs",
  "sources": {
    "todoist": {
      "enabled": true,
      "mcp_prefix": "mcp__claude_ai_Todoist__",
      "filters": {
        "priorities": ["p1", "p2"],
        "scope": "today_and_overdue"
      }
    },
    "github": {
      "enabled": true,
      "mcp_prefix": "mcp__github__",
      "username": "kratocz",
      "include": ["assigned_issues", "review_requested_prs", "my_open_prs"]
    },
    "clickup": {
      "enabled": false,
      "mcp_prefix": "mcp__plugin_ntit-common_clickup__"
    },
    "google_calendar": {
      "enabled": true,
      "mcp_prefix": "mcp__claude_ai_Google_Calendar__",
      "window_hours": 12
    }
  },
  "scoring": {
    "weights": {
      "priority": 40,
      "due_proximity": 30,
      "age": 15,
      "type_assignment": 15
    },
    "top_n": 8
  }
}
```

### Per-project override: memory file + JSON payload

Location: `~/.claude/projects/<project-slug>/memory/work_config.md`

Frontmatter type `project`. Memory system auto-loads it via `MEMORY.md` index. `/work-start` reads it during context bootstrap. Body contains a **fenced `json` block** with the override payload — same schema as global config, but only the keys to override. The surrounding markdown is for human readers. The skill parses only the JSON block; surrounding prose is ignored.

```markdown
---
name: work-config-override
description: Per-project work plugin overrides for claude-plugins repo
metadata:
  type: project
---

Overrides for the global work config in this project. The skill reads only the JSON block below.

```json
{
  "sources": {
    "clickup": { "enabled": false },
    "github": { "repos": ["kratocz/claude-plugins"] }
  },
  "scoring": {
    "weights": { "type_assignment": 25 }
  }
}
```

Why: this is a personal/OSS repo, no ClickUp tasks here; PRs to review matter more than usual.
```

**Merge semantics:** override JSON is deep-merged onto global config. Object keys override individually (e.g. setting `sources.clickup.enabled: false` only changes that field, leaves `mcp_prefix` from global). Arrays in override **replace** arrays in global (no concat — predictable).

If the fenced JSON block is missing or unparseable → warn, fall back to global config (don't crash).

## Scoring model

All component scores normalized to 0-100. Final score is weighted sum (weights from config):

```
score = 0.40 * priority_score
      + 0.30 * due_proximity_score
      + 0.15 * age_score
      + 0.15 * type_assignment_score
```

| Component | Calculation |
|---|---|
| `priority_score` | p1=100, p2=75, p3=50, p4=25, no_priority=10. PRs review-requested default 75. |
| `due_proximity_score` | overdue=100, due today=90, due tomorrow=70, due ≤7 days=linear 60→20, due >7 days=10, no due=0 |
| `age_score` | `min(100, age_days * 5)` — item assigned/created 20+ days ago hits ceiling |
| `type_assignment_score` | PR review-requested=90, directly-assigned issue/task=80, task in my project without assignee=40, calendar event ≤2h=100, ≤6h=70 |

Tie-break: higher `priority_score` → shorter due → older `age_days` → alphabetical title.

## Data flow: `/work-start`

```
1. Read ~/.claude/plugins/work/config.json
   - If missing: prompt user to run /work-setup, stop
2. Read per-project memory override (if present in current project's memory dir)
3. Compute effective config (override merged onto global)
4. For each enabled source (in parallel via single message with multiple MCP calls):
   a. Verify MCP prefix via ToolSearch lookup
   b. If missing → collect warning, skip
   c. If present → fetch raw items per source-specific MCP calls (table below)
5. Normalize each item to common shape:
   { source, id, title, url, priority, due, assigned_at, type, raw }
6. Score every item with the formula above; sort desc
7. Bucket items by data attributes (not by score):
   - 🔥 OVERDUE      — due < today
   - 📅 TODAY         — due == today OR no due but p1/p2
   - 👀 WAITING ON REVIEW — PRs review-requested
   - 📆 UPCOMING      — due tomorrow..7 days
   Score determines order WITHIN bucket. Total items displayed ≤ top_n.
8. Render markdown briefing + 1-sentence recommendation:
   "Start with [item] because [reason from highest score component]."
9. Write snapshot to ~/.claude/plugins/work/last-briefing.json (schema below)
10. Print collected MCP warnings at the bottom (if any)
```

### Per-source fetch reference

| Source | MCP tool | Filter |
|---|---|---|
| Todoist | `find-tasks-by-date` | scope=today + overdue |
| Todoist | `find-tasks` | priority=p1,p2 (regardless of due) |
| GitHub | `search_issues` | `is:open assignee:@me` |
| GitHub | `search_pull_requests` | `is:open review-requested:@me` |
| GitHub | `search_pull_requests` | `is:open author:@me draft:false` |
| ClickUp | `clickup_filter_tasks` | assignee=me, due_date_lt=tomorrow OR overdue |
| Calendar | `list_events` | timeMin=now, timeMax=now+config.window_hours |

### `last-briefing.json` schema

```json
{
  "schema_version": 1,
  "timestamp": "2026-06-03T08:14:00Z",
  "effective_config_hash": "sha256:abc123...",
  "items": [
    {
      "source": "github",
      "id": "kratocz/claude-plugins#42",
      "title": "Add work plugin",
      "url": "https://github.com/kratocz/claude-plugins/pull/42",
      "score": 78,
      "bucket": "WAITING_ON_REVIEW",
      "status": "open"
    }
  ],
  "warnings": ["clickup MCP not available in session"]
}
```

`status` is always `"open"` at write time (briefing only includes open items). `/work-status` and `/work-end` re-fetch and compare against this baseline to detect transitions to `"closed"` / `"completed"`. `effective_config_hash` lets `/work-status` warn if config changed between briefing and status check (e.g. user enabled a new source — diff would be misleading).

If `schema_version` in the file doesn't match the skill's expected version → warn "Snapshot is from older plugin version", continue best-effort (don't crash).

## Data flow: `/work-status`

Lightweight diff against last `/work-start` snapshot. Filosofie: "co se změnilo".

```
1. Read ~/.claude/plugins/work/last-briefing.json
   - If missing: "Run /work-start first."
   - If timestamp > 12h ago: "Last briefing is stale. Re-run /work-start."
2. Read effective config (same load path as /work-start: global + per-project override)
3. Re-fetch only volatile sources that are also enabled in effective config (in parallel):
   - GitHub PRs review-requested + assigned issues (if github source enabled)
   - Todoist tasks completed since snapshot via find-activity OR find-completed-tasks (if todoist source enabled)
   - Skip calendar (events don't "complete" in actionable sense) and ClickUp (heavy re-fetch, defer to next /work-start)
4. Diff snapshot vs. current:
   - ✅ Closed: items in snapshot now closed/completed
   - 🆕 New: items in current not in snapshot
   - 🔥 Still open (top 3): items in both, sorted by score desc
5. Render terse 3-5 line summary
```

No recommendation in `/work-status`. No bucketing. No render of stable sources (calendar past events, ClickUp full re-pull).

## Data flow: `/work-end`

```
1. Read last-briefing.json (must be < 24h old; else warn)
2. Re-fetch current state of same sources as /work-start
3. Compute:
   - Completed today: snapshot items now closed + items completed today not in snapshot
     - Todoist find-completed-tasks since=midnight
     - GitHub closed issues/PRs assigned to me, closed today
   - Carry-over: snapshot items still open
   - New unhandled: items created today, not in snapshot, still open
4. Render:
   📊 Souhrn dne (Xh od /work-start):
   ✅ Dokončeno: N (z toho M z ranního briefingu)
       - [list]
   📝 Přechází na zítra: N
       - [list]
   ⚠️ Nové během dne, neřešeno: N
       - [list]
5. Optionally ask: "Save this summary to today's session log?" (synergy with session-log plugin)
   If yes, append to current day's session log file (path read from session-log config if installed)
```

## `/work-setup` flow

```
1. Read existing config (if any) — distinguishes create vs. edit mode
2. Detect MCP availability:
   For each known prefix, call ToolSearch with select:<sample tool> to verify the server is in this session
   Build list of detected sources
3. For each detected source, Q&A (AskUserQuestion):
   - Enable? (y/n, default y)
   - GitHub only: ask for username (for @me resolution in search queries)
   - Optional: advanced filters? (skip for v1 — use defaults)
4. Scoring: prompt "Use default weights (40/30/15/15)? [Y/n]" — if n, ask each weight, must sum to 100
5. top_n: default 8 (or ask)
6. Language: auto-detect from session-tracker config if present, else default "cs"
7. Write ~/.claude/plugins/work/config.json (creating dir if needed)
8. Project override prompt: "You're in project <cwd basename>. Save per-project overrides? [y/N]"
   If yes: write ~/.claude/projects/<slug>/memory/work_config.md + add line to MEMORY.md
9. Confirm: print enabled sources + paths to config files
```

## Error handling

| Situation | Response |
|---|---|
| Config file missing | Skill prompts user to run `/work-setup`, stops cleanly |
| MCP prefix enabled in config but `ToolSearch` doesn't find it in current session | Warning in output, skip source, continue with rest |
| MCP call fails (network, auth, rate limit) | Warning in output, skip source, continue. No retry. |
| No source returned any items | Print 🎉 "Nic relevantního. Žádné overdue tasky, žádné PRs k review." |
| `/work-status` without prior briefing snapshot | "Spusť `/work-start` nejdřív." |
| `last-briefing.json` >24h old for `/work-end` | Warning "Briefing is from yesterday." but still computes against it |
| Per-project memory override unparseable | Warning, fall back to global config |
| User runs `/work-start` twice in 5 min | No special handling — just re-fetch and overwrite snapshot |

## Non-goals (additional)

- **No GitHub `gh` CLI fallback** when the GitHub MCP server is missing. The plugin uses MCP exclusively. Future enhancement: detect `gh` CLI as a fallback transport for the GitHub source.
- **No history beyond the latest snapshot.** Only `last-briefing.json` is kept. No daily archives, no week-over-week trend.

## Open questions for implementation phase

Deferred to writing-plans / implementation. Each must be answered before that source can ship:

1. **GitHub @me resolution:** does `mcp__github__search_pull_requests` accept `@me` literally, or does the skill need to substitute the username from config? Implementation must verify against the MCP server's actual query parsing.
2. **ClickUp user/team resolution:** ClickUp MCP uses internal IDs. `/work-setup` may need to call `clickup_get_workspace_members` and ask user to pick their member ID.
3. **Todoist priority shape:** Todoist MCP uses `p1`-`p4` strings (per MCP server instructions). Implementation must confirm the score table maps actual returned values — if priorities come back as integers somewhere, scoring breaks silently.
4. **Single-instance behavior:** if user runs `/work-start` twice in parallel sessions, the second overwrites the first's snapshot. Acceptable for v1; revisit if it bites.

## Success criteria

- `/work-start` returns a sensible, ranked briefing in under 15 seconds on a typical workload (≤30 items across all sources)
- Sources are pluggable via config — adding JIRA later means adding entries to the source table and the SKILL.md fetch reference, no code changes
- Plugin upgrade preserves config (verified by following `session-tracker` layout convention)
- Per-project overrides work for at least: disabling sources, narrowing GitHub repo scope, adjusting weights
- Graceful degradation when MCP servers are missing — never fails completely, just skips and warns

## Marketplace entry

After implementation, add to `.claude-plugin/marketplace.json`:

```json
{
  "name": "work",
  "source": "./plugins/work",
  "description": "Morning briefing across task trackers and code review queues — pulls Todoist/ClickUp/GitHub/Calendar into a single scored todo list",
  "version": "0.1.0",
  "added": "2026-06-03"
}
```

And prepend a row to README.md's Available plugins table.
