# Design: `/work-standup` skill

- **Date:** 2026-07-07
- **Plugin:** `work` (bumped 0.1.0 → 0.2.0)
- **Status:** implemented
- **Related:** [work plugin design](./2026-06-03-work-plugin-design.md)

## Problem

The `work` plugin covers the *forward* and *same-day* parts of a workday
(`/work-start`, `/work-status`, `/work-end`) but has no answer to the single
most common recurring question a standup asks: **"what did I do since the last
standup?"** That recap was being assembled ad-hoc each time by hand — querying
Toggl, `git log`, and GitHub PR/review search, then grouping the results.

## Why a new skill in `work` (not a new plugin, not a project skill)

- It belongs to the same "daily work orchestration" domain and reuses `work`'s
  config, per-project override, GitHub username, and language settings. A
  separate plugin would duplicate `/work-setup` and fragment the domain.
- It is not project-specific — the recap works for any repo/project — so a
  project-local `.claude/skills/` skill would wrongly lock it to one repo.

## Why Toggl is the spine (the key design point)

`/work-end` diffs task-tracker snapshots. That under-reports review-heavy or
ops-heavy stretches, because **code reviews, incident firefighting, and
meetings leave no commit and often no closed task**. Toggl time entries *do*
capture them. So the recap's primary source is Toggl, enriched with:

- **git** `log --all --author=<name/email> --since` — commits (frequently
  empty in a review-only window, which is exactly why Toggl matters),
- **GitHub** — merged PRs authored, PRs reviewed, open PRs still involved in
  (the carry-over hook), issues closed.

This mirrors the real, verified data flow used to produce the recap manually:
Toggl project `NTIT/PMA` (billable) + `git log` + GitHub `reviewed-by:` /
`involves:` / `author:…merged:`.

## Sources of truth this skill relies on

- Toggl read via the **MCP** `mcp__toggl__toggl_get_time_entries` (returns
  hydrated `project_name`/`client_name`/`duration_seconds`/`tag_names`/
  `billable` — no manual project lookup). The `session-tracker` plugin's
  curl + API-key path is the documented fallback when the Toggl MCP server is
  absent. (Note: `session-tracker` docs record that the Toggl *write* path is
  finicky; the **read** endpoint used here is reliable.)
- git identity from `git config user.name` / `user.email` (two `--author`
  passes, unioned by short-SHA, because commits attribute inconsistently).
- GitHub login from `sources.github.username` (the MCP may not resolve `@me`).

## Window resolution

Default `standup.default_window = "last_workday_noon"`: most recent previous
weekday at 12:00 local (Mon→Fri, weekend→Fri, else yesterday). This fits a
daily standup that skips the weekend. Overridable per run with
`--since YYYY-MM-DD[THH:MM]`, or config values `24h`/`48h`/`72h` / a bare date.
Because the Toggl MCP `start_date` is date-granular, entries before the
`since` time-of-day on the boundary day are filtered out client-side.

## Config additions (schema, minor bump)

```json
"sources": {
  "toggl": { "enabled": true, "mcp_prefix": "mcp__toggl__",
             "project_id": null, "project_name": null, "billable_only": false }
},
"standup": { "default_window": "last_workday_noon" }
```

`toggl` + `standup` are consumed only by `/work-standup`; the briefing skills
ignore them. This is additive → **minor** version bump per the plugin's SemVer
rule ("minor for new sources/config fields").

## Output

A paste-ready markdown recap, most-important-first, grouped into: Ops/
incidents · Code reviews · Development/commits · Merged PRs & closed issues ·
Carry-over (open PRs still involved in). Toggl durations are authoritative;
commit-only / review-only items without tracked time are listed without a
duration. Toggl entries and GitHub items describing the same work (e.g. a
`CR PR #76` entry + the #76 PR) are merged into one line. Nothing is posted
automatically — an optional `pbcopy` is offered.

## Non-goals

- No posting to Slack/ClickUp/any channel (user's call).
- No scoring (this is a recap, not a prioritized briefing — scoring lives in
  `/work-start`).
- No snapshot file (unlike `/work-start`; the recap is stateless and derives
  its window from the clock/args, not from a prior run).
