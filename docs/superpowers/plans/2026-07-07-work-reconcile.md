# `/work-reconcile` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `/work-reconcile` skill to the `work` plugin that backfills missing timesheet entries by reconstructing real activity (primarily Claude Code session logs, confirmed by git/GitHub/Calendar/ClickUp), diffing it against what is already logged, and — after per-item approval — writing only the missing time to Toggl/ClickUp.

**Architecture:** The deliverable is a prose `SKILL.md` (Markdown instructions Claude executes at runtime), not executable code — consistent with the other `work` skills (`start`, `standup`, …). There are no unit tests; each task's "test" is a **manual scenario check** run via `--dry-run` against real data, plus a static review of the written instructions. Tasks are drawn along the skill's logical phases (scaffold+config → source collection → duration → diff → review → write → docs), each ending in an independently verifiable deliverable.

**Tech Stack:** Markdown skill (`SKILL.md` with YAML frontmatter), Bash (`date`, `git log`, `curl` for API fallback), MCP tools (`mcp__toggl__*`, `mcp__github__*`, `mcp__plugin_ntit-common_clickup__*`, `mcp__claude_ai_Google_Calendar__list_events`), `ToolSearch` for availability probing, `AskUserQuestion` for review UX. Reads Claude Code session logs from `~/.claude/projects/<enc-path>/*.jsonl`.

## Global Constraints

- **Deliverable is Markdown, not code** — no compile/unit-test step; verification is manual `--dry-run` scenarios + static review.
- **Language:** all user-facing text in the language from `config.language` (default `cs`, fallback `en`), matching existing `work` skills; keep proper nouns/IDs/URLs/durations unchanged.
- **Never write without approval** — the flow is strictly `propose → confirm → write`. `work` was read-only until now; this skill is the first writer.
- **API key never in argv** — read into a shell variable, pass via stdin/header (out of `ps` and transcripts). Same pattern as `session-tracker`'s `/log-entry`.
- **No timezone arithmetic by hand** — all time conversions via `date` (macOS `date -j -f`, Linux `date -d`).
- **No double-counting** — a commit/PR falling inside an AI session's window belongs to that session, never a separate block.
- **Availability probing** — before any MCP source, verify with `ToolSearch` (`select:<representative tool>`); if absent, warn once and skip, never fail.
- **Config keys (exact), under `reconcile` in `~/.claude/plugins/work/config.json`:** `default_window` (`last_month`), `gap_threshold_min` (15), `edge_pad_min` (2), `round_to_min` (5), `min_block_min` (5), `coverage_covered` (0.9), `coverage_missing` (0.1), `ai_sessions.enabled` (true), `ai_sessions.projects_dir` (`~/.claude/projects`), `calendar.as_work` (true), `calendar.exclude_all_day` (true), `calendar.exclude_declined` (true), `calendar.exclude_keywords` (`["oběd","lunch","dovolená"]`), `sink.target` (`toggl` | `clickup` | `both`), `sink.billable` (true), `sink.reconciled_tag` (`reconciled`).
- **Missing `reconcile` config block → use defaults, do not crash.**
- **Version bump:** `work` minor → `0.3.0` in three synced places: `plugins/work/.claude-plugin/plugin.json`, the new skill's frontmatter, and `work`'s entry in `.claude-plugin/marketplace.json`.
- **Spec reference:** `docs/superpowers/specs/2026-07-07-work-reconcile-design.md` — the authoritative source; this plan implements it.

---

### Task 1: Skill scaffold, frontmatter, arguments, config load

Establishes the skill file, its trigger surface, argument parsing, and the config/window-resolution preamble shared by every later phase. Deliverable: the skill loads config, resolves the window, and echoes both — runnable end-to-end even though it does nothing else yet.

**Files:**
- Create: `plugins/work/skills/reconcile/SKILL.md`
- Reference (read for pattern, do not modify): `plugins/work/skills/standup/SKILL.md` (steps 1–2: config load + window resolution), `plugins/work/skills/setup/SKILL.md` (config shape)

**Interfaces:**
- Consumes: `~/.claude/plugins/work/config.json` (existing `work` config; `language`, `sources.*`); optional fallback `~/.claude/plugins/session-tracker/config.json` for Toggl key.
- Produces: the skill's runtime contract — resolved variables later phases reference by name: `effective_config` (merged config incl. `reconcile` defaults), `since` / `until` (ISO local datetimes), `project_filter` (string or null), `dry_run` (bool).

- [ ] **Step 1: Write the frontmatter and title**

Create `plugins/work/skills/reconcile/SKILL.md` starting with:

```markdown
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
```

- [ ] **Step 2: Write the "Arguments" section**

Append:

```markdown
## Arguments

- `--since YYYY-MM-DD` (optional): start of the reconcile window (bare date = `T00:00` local). Default: see step 2.
- `--until YYYY-MM-DD` (optional): end of the window (bare date = `T23:59:59` local). Default: now.
- `--project <name>` (optional): restrict to one project by name (case-insensitive substring).
- `--dry-run` (optional): run the full flow through review and **only print** the proposals — write nothing.
```

- [ ] **Step 3: Write step 1 — "Load effective config"**

Append a `## Steps` heading, then:

```markdown
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
```

- [ ] **Step 4: Write step 2 — "Resolve the window"**

Append:

````markdown
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
````

- [ ] **Step 5: Manual verification (scaffold)**

This task has no automated test. Verify by static review and a scoped dry check:

Run: read the file back and confirm frontmatter parses (valid YAML, `name: work-reconcile`, `version: 0.3.0`).

```bash
grep -E "^name:|^version:|^argument-hint:" plugins/work/skills/reconcile/SKILL.md
```
Expected: prints the three lines with the values above.

Confirm the window-math commands produce sane output on this machine:

```bash
date -v1d -v-1m -v0H -v0M -v0S +%Y-%m-%dT%H:%M:%S 2>/dev/null || date -d "$(date +%Y-%m-01) -1 month" +%Y-%m-%dT00:00:00
```
Expected: an ISO datetime at the first day of the previous month, 00:00.

- [ ] **Step 6: Commit**

```bash
git add plugins/work/skills/reconcile/SKILL.md
git commit -m "feat(work): scaffold /work-reconcile skill (config + window)"
```

---

### Task 2: Collect candidate blocks from primary sources (AI sessions + Calendar)

Adds the primary-source collection: parse Claude Code session logs into candidate work blocks and pull Calendar events. These are the only sources that carry time. Deliverable: a `--dry-run` that lists raw primary blocks (no duration math yet — that's Task 3).

**Files:**
- Modify: `plugins/work/skills/reconcile/SKILL.md` (append step 3, part A)

**Interfaces:**
- Consumes: `since`, `until`, `project_filter`, `effective_config` (from Task 1).
- Produces: the concept `candidate_block` — a record every later phase uses, with fields: `source` (`ai` | `calendar`), `start`, `end` (local ISO), `raw_messages_ts` (list, AI only — used by Task 3), `title`, `project_hint` (repo/dir name or null), `origin_marks` (list, starts empty). Emit blocks into an ordered list `blocks`.

- [ ] **Step 1: Write step 3A — "Fetch AI session logs"**

Append under `## Steps`:

````markdown
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
````

- [ ] **Step 2: Write step 3B — "Fetch Calendar events"**

Append:

````markdown
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
````

- [ ] **Step 3: Manual verification (primary blocks)**

Static review: confirm the Python filter handles a session with **no** timestamps (exits 0, no block) and a session spanning the window edge (block clipped). Trace both by eye against the code.

Live probe (this repo has real session logs): run the `find` + Python filter over this project's session dir for a wide window and confirm it emits at least one JSON block with `first`/`last`/`title`:

```bash
DIR="$HOME/.claude/projects/-Users-krato-IdeaProjects-github-com-kratocz-claude-plugins"
for f in "$DIR"/*.jsonl; do
  python3 - "$f" "2026-01-01T00:00:00Z" "2027-01-01T00:00:00Z" <<'PY'
import json,sys
f,since,until=sys.argv[1:4]
ts=[];title=None
for line in open(f,encoding='utf-8'):
    try:d=json.loads(line)
    except:continue
    t=d.get('timestamp')
    if t:ts.append(t)
    if d.get('type')=='ai-title':title=d.get('content') or title
ts=sorted(t for t in ts if t)
if ts and not(ts[-1]<since or ts[0]>until):
    print(json.dumps({'first':ts[0],'last':ts[-1],'n':len(ts),'title':title}))
PY
done
```
Expected: one JSON line per real session, with plausible timestamps.

- [ ] **Step 4: Commit**

```bash
git add plugins/work/skills/reconcile/SKILL.md
git commit -m "feat(work): collect primary blocks from AI sessions + Calendar"
```

---

### Task 3: Duration estimation (gap-capping) + rounding + origin marks

Adds the duration algorithm to the collected AI blocks and the origin-mark vocabulary. Deliverable: a `--dry-run` where every primary block carries an estimated duration and an origin mark; the overnight-session case is demonstrably capped.

**Files:**
- Modify: `plugins/work/skills/reconcile/SKILL.md` (append step 4)

**Interfaces:**
- Consumes: `blocks` with `raw_messages_ts` (AI) / start+end (Calendar) from Task 2; `effective_config.reconcile` thresholds.
- Produces: each block gains `minutes` (int, rounded; may be `null` = "unknown, ask user") and `origin` (string mark). **Note `origin` (singular — the block's primary type: one of `ai-gapcapped`, `calendar-exact`, `commit-only`) is distinct from `origin_marks` (the list of confirmatory badges like `git✓`/`gh✓` that Task 4 appends).** Task 4 sets `origin='commit-only'` on promoted standalone hits.

- [ ] **Step 1: Write step 4 — "Estimate durations"**

Append:

````markdown
4. **Estimate a duration for each block.** The estimate is always a *default to
   hand-edit*, never authoritative.

   **AI blocks — gap-capping** (`raw_messages_ts` sorted, UTC is fine here since
   we only take differences). With `G = gap_threshold_min`, `E = edge_pad_min`:

   ```
   minutes_raw = 0
   for consecutive (a, b) in raw_messages_ts:
       gap = (b - a) in minutes
       minutes_raw += gap if gap <= G else E     # long pause = break → only pad
   minutes_raw += E                               # trailing pad after last msg
   ```

   Rationale: a session left open overnight has one huge inter-message gap; it
   contributes only one `E`, not 8 hours. Compute in Python:

   ```bash
   python3 - <<'PY'
   from datetime import datetime
   ts = [ ... raw_messages_ts ... ]
   G, E = 15, 2   # from config
   def m(x): return datetime.fromisoformat(x.replace('Z','+00:00'))
   secs = 0
   for a,b in zip(ts, ts[1:]):
       gap = (m(b)-m(a)).total_seconds()/60
       secs += min(gap, 0)*0 + (gap if gap<=G else E)
   secs += E
   print(round(secs))
   PY
   ```
   Then round to `round_to_min` and set `minutes`. If `minutes < min_block_min`,
   drop the block as noise. Set `origin='ai-gapcapped'`.

   **Calendar blocks:** `minutes` = exact `(end - start)` rounded to
   `round_to_min` (no gap-capping — a meeting is contiguous). Set
   `origin='calendar-exact'`.

   **Origin marks** drive the review display (Task 5):
   | `origin` | Review label |
   |----------|--------------|
   | `ai-gapcapped` | `~<m>m (AI, gap-capped)` |
   | `calendar-exact` | `<m>m (kalendář)` |
   | `commit-only` | `? (jen commit — DOPLŇ ČAS)` |
````

- [ ] **Step 2: Manual verification (gap-capping)**

The overnight case is the whole point — verify numerically. Take the real 31-hour session found during design and confirm gap-capping yields minutes, not ~1863:

```bash
DIR="$HOME/.claude/projects/-Users-krato-IdeaProjects-github-com-kratocz-claude-plugins"
F=$(ls "$DIR"/7c5de459*.jsonl 2>/dev/null | head -1)
[ -n "$F" ] && python3 - "$F" <<'PY'
import json,sys
from datetime import datetime
ts=[]
for line in open(sys.argv[1],encoding='utf-8'):
    try:d=json.loads(line)
    except:continue
    t=d.get('timestamp')
    if t:ts.append(t)
ts=sorted(ts)
def m(x):return datetime.fromisoformat(x.replace('Z','+00:00'))
wall=(m(ts[-1])-m(ts[0])).total_seconds()/60
G,E=15,2;secs=0
for a,b in zip(ts,ts[1:]):
    gap=(m(b)-m(a)).total_seconds()/60
    secs+=gap if gap<=G else E
secs+=E
print(f"wall-clock={wall:.0f}m  gap-capped={round(secs)}m")
PY
```
Expected: `wall-clock` is huge (~1863m) while `gap-capped` is a plausible working figure (far smaller). If gap-capped ≈ wall-clock, the algorithm is wrong — fix before committing.

- [ ] **Step 3: Commit**

```bash
git add plugins/work/skills/reconcile/SKILL.md
git commit -m "feat(work): gap-capped duration estimation + origin marks"
```

---

### Task 4: Confirmatory sources + project pairing + anti-double-count

Adds git/GitHub/ClickUp collection as *confirmation* (they enrich or, alone, create `commit-only` blocks), pairs every block to a project, and folds confirmatory hits that fall inside an AI session into that session. Deliverable: a `--dry-run` where blocks are project-tagged and no commit inside a session appears twice.

**Files:**
- Modify: `plugins/work/skills/reconcile/SKILL.md` (append step 3C + steps 5–6)

**Interfaces:**
- Consumes: `blocks` (with `minutes`, `origin`, `project_hint`) from Tasks 2–3; `effective_config.sources` (github/clickup config, reused from `/work-standup`).
- Produces: every block gains `project` (resolved Toggl project name / ClickUp list, or null with `origin_marks += 'project?'`); confirmatory items merged (`origin_marks` gains `git✓`/`gh✓`/`clickup✓`) or promoted to standalone `commit-only` blocks with `minutes=null`.

- [ ] **Step 1: Write step 3C — "Fetch confirmatory sources"**

Append (continuing the step-3 fetch list):

````markdown
   **C. Confirmatory sources** (git always; GitHub/ClickUp if enabled+present):

   - **git** (local, free): in the current repo (and, if configured, each repo
     under a known root), collect commits authored by the user in the window:
     ```bash
     git log --all --since="<since>" --until="<until>" \
       --author="$(git config user.email)" \
       --pretty='%h|%aI|%s' 2>/dev/null
     ```
     Each commit is a confirmatory hit with a timestamp, its repo name, and
     subject. Not a block yet — see step 5.
   - **GitHub** (probe `select:mcp__github__search_pull_requests`): search PRs
     reviewed/merged and issues closed by
     `effective_config.sources.github.username` in the window. Each is a
     confirmatory hit (timestamp = merged/review time, subject = title).
   - **ClickUp** (probe `select:mcp__plugin_ntit-common_clickup__clickup_filter_tasks`):
     tasks updated by the user in the window via `clickup_filter_tasks`;
     optionally `clickup_get_task_comments` for the user's comments. Confirmatory
     hits (timestamp = update/comment time, subject = task name).
   Absent MCP → warn once, skip that source.
````

- [ ] **Step 2: Write step 5 — "Pair each block to a project"**

Append:

````markdown
5. **Pair every block to a project** (same mechanism as `/start` and
   `/log-entry`):
   - Fetch active Toggl projects (`mcp__toggl__toggl_list_projects`, or the
     `session-tracker` key fallback).
   - For AI blocks: match `project_hint` (repo/dir name) case-insensitively
     against project names; on a hit set `project`. For Calendar blocks with no
     hint, leave `project=null` for now.
   - Fallback to `sources.toggl.default_project_id` /
     `session-tracker` `default_project_id` if no match (may be null).
   - If still unresolved, set `project=null` and add `'project?'` to
     `origin_marks` — the review (Task 5) will force the user to pick before this
     block can be approved.
   - If `project_filter` (`--project`) is set, drop blocks whose resolved
     `project` does not match it (case-insensitive substring).
````

- [ ] **Step 3: Write step 6 — "Fold confirmatory hits (anti-double-count)"**

Append:

````markdown
6. **Fold confirmatory hits into blocks — never double-count.** For each
   confirmatory hit (git commit / GitHub PR / ClickUp update):
   - If its timestamp falls **inside** an existing AI block's `[start, end]`
     (same repo/project where determinable), attach it: add a mark to that
     block's `origin_marks` (`git✓ Nc` with a commit count, `gh✓ #<pr>`,
     `clickup✓`), and optionally enrich the block `title`. Do **not** create a
     new block and do **not** add time.
   - If it falls **outside** every AI block, promote it to a standalone
     `candidate_block` with `source='commit'` (or `gh`/`clickup`),
     `origin='commit-only'`, `minutes=null` (unknown — user must fill in),
     `start` = the hit timestamp, `end` = null, `project` paired from its repo.
   - Merge multiple outside-hits that are close in time on the same project into
     one `commit-only` block (list their subjects) to avoid a flood of tiny
     rows.
````

- [ ] **Step 4: Manual verification (pairing + anti-double-count)**

Static trace (no live API needed): construct the walkthrough on paper and confirm the instructions produce the right result for each case —
1. Commit at 14:30 inside an AI block 14:00–15:30 → block gains `git✓`, **no** new block, **no** added minutes.
2. Commit at 22:15 with no session → one `commit-only` block, `minutes=null`.
3. AI block whose `project_hint` matches no Toggl project → `project=null`, `origin_marks` has `project?`.

Write the three expected outcomes as a comment block in the PR description; confirm each is unambiguously determined by the step-5/6 text. If any case is ambiguous, tighten the wording.

- [ ] **Step 5: Commit**

```bash
git add plugins/work/skills/reconcile/SKILL.md
git commit -m "feat(work): confirmatory sources, project pairing, anti-double-count"
```

---

### Task 5: Diff against the existing timesheet (coverage) + review UX

Adds the busy-map/coverage diff (so only missing time is proposed) and the interactive review with per-item edit, forced time for `?` items, and manual phone-call entry. Deliverable: a `--dry-run` prints the grouped proposal table with COVERED hidden, PARTIAL showing only the gap, and a review prompt.

**Files:**
- Modify: `plugins/work/skills/reconcile/SKILL.md` (append steps 7–8)

**Interfaces:**
- Consumes: project-tagged `blocks` with `minutes`/`origin`/`origin_marks` from Task 4; `effective_config.reconcile.coverage_*` and `sink.target`.
- Produces: `approved` — the list of blocks (with possibly user-edited `minutes`/`project`/`title`) the user explicitly OK'd for writing; plus any manually-added phone-call blocks (`source='manual'`, `origin='manual'`). When `sink.target` includes `clickup`, each approved block also carries `clickup_task_id` (chosen in review) — consumed by Task 6's ClickUp write.

- [ ] **Step 1: Write step 7 — "Diff against existing timesheet"**

Append:

````markdown
7. **Diff against what is already logged** — propose only the missing time.
   - Load existing entries for `[since, until]` **only from the trackers in
     `sink.target`** (reading a ClickUp busy-map is pointless when writing only
     to Toggl). Toggl: `mcp__toggl__toggl_get_time_entries`
     (`start_date`/`end_date`); ClickUp: its time-entries listing. Each existing
     entry → (start, end, project).
   - Build a **busy map** per (project, day): the union of already-logged
     intervals. Entries with no project go into a general per-day bucket.
   - For each candidate block, split it per calendar day if it crosses midnight,
     then compute against the same (project, day):
     ```
     overlap  = minutes of the block already inside busy intervals
     coverage = overlap / block_minutes        (block_minutes>0)
     ```
   - Decide with `coverage_covered` (0.9) and `coverage_missing` (0.1):
     - `coverage >= coverage_covered` → **COVERED**: drop the block; count it for
       the summary line only.
     - `coverage_missing <= coverage < coverage_covered` → **PARTIAL**: keep, but
       set proposed `minutes = round(block_minutes - overlap)`; label
       `~<m>m (doplněk k <overlap>m)`.
     - `coverage < coverage_missing` → **MISSING**: keep whole block; label
       `~<m>m (chybí)`.
   - `commit-only` blocks (`minutes=null`) skip coverage math (nothing to
     measure) and always appear, flagged to fill in.
````

- [ ] **Step 2: Write step 8 — "Review and approve"**

Append:

````markdown
8. **Review — the heart of "confirm".** First print a **grouped table**
   (by project, then day), each row: proposed minutes + origin label +
   `origin_marks`. End with a summary line: `N návrhů (Σ h) · K pokrytých skryto
   · M bez času`. Example:

   ```
   Projekt X — po 2026-06-02
     ~90m  fix auth bug        (AI, gap-capped)  [git✓ 3c, PR#42✓]
      35m  code review          (doplněk k 25m)   [GitHub✓]
      60m  Sprint planning      (kalendář)
      ?    hotfix deploy         (jen commit — DOPLŇ ČAS)
   Souhrn: 12 návrhů (8.5 h) · 5 pokrytých skryto · 1 bez času
   ```

   Then approve **in batches** via `AskUserQuestion`, one group (project/day) at
   a time, options: **Vše / Vybrat / Přeskočit / Upravit časy**.
   - **Vybrat** → list the group's items so the user picks a subset.
   - **Upravit** → let the user overwrite `minutes` (and optionally
     `project`/`title`) on a chosen item.
   - **A block with `minutes=null` (the `?` items) CANNOT be approved until the
     user supplies a duration** — force the prompt; never write a `null`.
   - **A block with `'project?'` in `origin_marks` CANNOT be approved until the
     user picks a project.**
   - **If `sink.target` includes `clickup`:** a ClickUp time entry must attach to
     a `task_id` (AI sessions / commits / meetings have no inherent ClickUp
     task). So for each block the user approves for a ClickUp write, prompt them
     to pick the target ClickUp task — offer a shortlist from
     `clickup_filter_tasks` (assigned to the user, active) via `AskUserQuestion`,
     or let them paste a task ID / custom ID (e.g. `DEV-1234`). Store it as the
     block's `clickup_task_id`. A block **CANNOT** be approved for a ClickUp
     write without a `clickup_task_id`. (Toggl writes need no task — this gate
     applies only to the ClickUp sink.)
   - Offer **"+ přidat ruční položku"** (phone call): ask start, duration,
     project, description → append as `source='manual'`, `origin='manual'`,
     fully specified.
   Everything the user OKs goes into `approved`. Nothing else is written.
   If `dry_run`, stop here after printing what *would* be written, grouped like
   the summary; write nothing.
````

- [ ] **Step 3: Manual verification (coverage + review)**

Static trace the three coverage branches with concrete numbers and confirm each maps to the right label and proposed minutes:
- block 90m, overlap 0m → MISSING, propose 90m.
- block 60m, overlap 35m → coverage 0.58 → PARTIAL, propose 25m, label `doplněk k 35m`.
- block 90m, overlap 85m → coverage 0.94 → COVERED, dropped.

Confirm the midnight-split rule is stated (a 23:30→00:45 block is diffed as two per-day pieces). Confirm `?` and `project?` blocks are both hard-gated in the approve step. Record these in the PR description.

- [ ] **Step 4: Commit**

```bash
git add plugins/work/skills/reconcile/SKILL.md
git commit -m "feat(work): coverage diff + interactive review with forced gates"
```

---

### Task 6: Write to sink (Toggl/ClickUp) safely + idempotency + summary

Adds the actual write of approved entries, reusing `/log-entry`'s safe pattern, the `reconciled` idempotency tag, per-item failure isolation, the no-key export fallback, and the final summary. Deliverable: a real (non-dry) run writes approved entries and reports; a second run writes nothing.

**Files:**
- Modify: `plugins/work/skills/reconcile/SKILL.md` (append steps 9–10)
- Reference (read for the safe-write pattern, do not modify): `plugins/session-tracker/skills/log-entry/SKILL.md` (steps 5–6)

**Interfaces:**
- Consumes: `approved` from Task 5; `effective_config.reconcile.sink` (`target`, `billable`, `reconciled_tag`); Toggl/ClickUp credentials (own config or `session-tracker` fallback).
- Produces: side effects (time entries created) + a printed summary. No downstream consumer.

- [ ] **Step 1: Write step 9 — "Write approved entries"**

Append:

````markdown
9. **Write the approved entries.** For each item in `approved`, write to every
   tracker in `sink.target` (`toggl`, `clickup`, or `both`).

   **Safety (identical to `session-tracker`'s `/log-entry`):** never put the API
   key in argv. Read it into a shell variable and pass it via a stdin-fed config
   / header, so it stays out of `ps` and transcripts. Do all time conversion
   with `date`, never by hand.

   **Toggl** — `POST /api/v9/workspaces/<wid>/time_entries`. Use the **exact
   auth pattern proven in `session-tracker`'s `/log-entry`**: Basic auth via
   `curl --config -` fed on stdin (so the key stays out of argv), with the
   credential line `user = "<token>:api_token"`. Body carries `start` (UTC ISO),
   `duration` (seconds), `description`, `project_id` (only when resolved),
   `billable` (from `sink.billable`), and `tags` including `sink.reconciled_tag`:
   ```bash
   KEY=<toggl api_key read into a shell var, not echoed>
   printf 'user = "%s:api_token"\n' "$KEY" | curl -sS --config - \
     -H "Content-Type: application/json" \
     -X POST "https://api.track.toggl.com/api/v9/workspaces/<wid>/time_entries" \
     --data-binary '{"created_with":"work-reconcile","workspace_id":<wid>,
       "start":"<utc>","duration":<secs>,"description":"<desc>",
       "billable":<bool>,"tags":["<reconciled_tag>"]}'
   ```
   (Add `"project_id":<pid>` only when a project was resolved.)
   **ClickUp** — `mcp__plugin_ntit-common_clickup__clickup_add_time_entry`
   with `task_id` (the block's `clickup_task_id`, chosen during review — Task 5),
   `start` (`YYYY-MM-DD HH:MM`), `duration` (`Xh Ym`), `description`, `billable`,
   `tags:[<reconciled_tag>]`. A block without a `clickup_task_id` was never
   approved for ClickUp (Task 5 gate) — skip it for this sink.

   **Per-item failure isolation:** if one write fails, record the error and
   **continue** with the rest; never abort the whole batch.
````

- [ ] **Step 2: Write step 9 idempotency + step 10 summary + no-key fallback**

Append:

````markdown
   **Idempotency:** before writing, and on any re-run, treat an existing entry
   that already carries `sink.reconciled_tag` overlapping the same block as
   already-written and skip it (belt-and-braces on top of the coverage diff, so
   a second `/work-reconcile` writes nothing).

   **No sink credentials** (neither Toggl nor ClickUp key available): do not
   write. Instead offer an **export** — print the approved items as a Markdown
   table (and offer to save a `.csv`) so the user can paste them manually. Say
   so explicitly.

10. **Summary.** Print what happened: per project, entries written (with
    durations) and total; then a line each for skipped-as-covered, skipped
    (user), and failed (with the error). If nothing was written, say why
    (dry-run / no approvals / no credentials).
````

- [ ] **Step 3: Manual verification (write + idempotency)**

This is the only task with real side effects — verify carefully but safely:
- First, run the whole skill with `--dry-run` over a **short** real window (e.g. `--since` yesterday) and confirm the summary shows plausible entries and **nothing is written** (check Toggl UI — no new rows).
- Then run once **without** `--dry-run` over that same short window; confirm the entries appear in Toggl **with the `reconciled` tag**.
- Run it a **second** time over the same window; confirm the summary reports everything skipped and **no duplicate** rows appear in Toggl.
- Confirm the API key never appears: `history | tail -50` shows no key; the `curl` used stdin, not argv.

If duplicates appear on the second run, the idempotency/coverage check is broken — fix before proceeding.

- [ ] **Step 4: Commit**

```bash
git add plugins/work/skills/reconcile/SKILL.md
git commit -m "feat(work): safe sink write, idempotency tag, export fallback, summary"
```

---

### Task 7: Config wiring in /work-setup + docs + version bump

Wires an optional `reconcile` config step into `/work-setup`, documents the new skill everywhere, and bumps `work` to 0.3.0 across the three synced places. Deliverable: `/work-setup` can configure reconcile; docs and marketplace list the skill; version is consistent.

**Files:**
- Modify: `plugins/work/skills/setup/SKILL.md` (add optional reconcile step)
- Modify: `plugins/work/skills/standup/SKILL.md` (add `/work-reconcile` row to the triad table)
- Modify: `plugins/work/CLAUDE.md` (skills table + config docs)
- Modify: `plugins/work/README.md` (describe the skill)
- Modify: `plugins/work/.claude-plugin/plugin.json` (version → 0.3.0)
- Modify: `.claude-plugin/marketplace.json` (work version → 0.3.0)

**Interfaces:**
- Consumes: nothing new.
- Produces: the `reconcile` config block written by `/work-setup`; consistent version 0.3.0.

- [ ] **Step 1: Add the reconcile step to /work-setup**

In `plugins/work/skills/setup/SKILL.md`, after the existing per-source Q&A, add an optional step that asks (via `AskUserQuestion`, in the configured language) whether to configure timesheet reconciliation, and if yes writes a `reconcile` block using the defaults from Global Constraints, letting the user override `sink.target` (toggl/clickup/both) and `default_window`. If the user skips, write nothing (the skill falls back to defaults at runtime). Keep the wording and structure parallel to the existing source steps.

- [ ] **Step 2: Add the triad row to standup**

In `plugins/work/skills/standup/SKILL.md`, find the table listing `/work-start`, `/work-status`, `/work-end`, `/work-standup` and add the row:

```markdown
| **`/work-reconcile`** | **What did I do but not log — and fill it in** | **Toggl/ClickUp write** | **back (write)** |
```
(match the existing column count/format of that specific table).

- [ ] **Step 3: Update CLAUDE.md and README**

In `plugins/work/CLAUDE.md`: add `/work-reconcile` to the skills table and document the `reconcile` config block (the keys from Global Constraints, one line each).

In `plugins/work/README.md`: add a short paragraph describing `/work-reconcile` — what it does, that it writes only missing time, and that it always asks before writing.

- [ ] **Step 4: Bump version in three synced places**

```bash
cd /Users/krato/IdeaProjects/github.com/kratocz/claude-plugins
# 1) plugin.json
python3 - <<'PY'
import json,io
p='plugins/work/.claude-plugin/plugin.json'
d=json.load(open(p)); d['version']='0.3.0'
json.dump(d,open(p,'w'),ensure_ascii=False,indent=2); open(p,'a').write('\n')
PY
# 2) skill frontmatter is already 0.3.0 (set in Task 1) — verify:
grep '^version:' plugins/work/skills/reconcile/SKILL.md
# 3) marketplace.json
python3 - <<'PY'
import json
p='.claude-plugin/marketplace.json'
d=json.load(open(p))
for e in d['plugins']:
    if e['name']=='work': e['version']='0.3.0'
json.dump(d,open(p,'w'),ensure_ascii=False,indent=2); open(p,'a').write('\n')
PY
```

- [ ] **Step 5: Verify consistency**

```bash
python3 - <<'PY'
import json
mkt={p['name']:p['version'] for p in json.load(open('.claude-plugin/marketplace.json'))['plugins']}
pj=json.load(open('plugins/work/.claude-plugin/plugin.json'))['version']
print('plugin.json', pj, '| marketplace', mkt['work'])
assert pj==mkt['work']=='0.3.0', 'version mismatch'
print('OK 0.3.0 everywhere')
PY
grep '^version:' plugins/work/skills/reconcile/SKILL.md
```
Expected: `OK 0.3.0 everywhere` and the skill frontmatter shows `version: 0.3.0`.

- [ ] **Step 6: Commit**

```bash
git add plugins/work/ .claude-plugin/marketplace.json
git commit -m "feat(work): wire reconcile into setup, docs, bump to 0.3.0"
```

---

### Task 8: Full end-to-end scenario pass + spec-coverage sign-off

A dedicated verification task (no new code) that runs the spec's 7-scenario checklist against the finished skill and confirms each spec requirement is met. Deliverable: a checklist in the PR description with each scenario marked pass, and any bugs found looped back to the owning task.

**Files:**
- None modified (verification only; fixes go to the relevant task's file).

- [ ] **Step 1: Run the 7 spec scenarios**

Execute each against the finished skill (use `--dry-run` except where a write is under test, and a short window for the write test):

1. `--dry-run` on a real past month → estimates and origin labels are sane.
2. Overnight session in that window → not counted as ~31h (spot-check its row).
3. Partially-logged day → PARTIAL proposes only the gap.
4. Fully-logged day → nothing proposed (COVERED, shown only in the summary count).
5. Commit with no session → `?` row, approval blocked until a time is entered.
6. Idempotency → run twice for real on a short window; second run writes nothing, no duplicates.
7. Missing MCP (e.g. disable/none for Calendar) → one warning, flow continues.

- [ ] **Step 2: Spec-coverage sign-off**

Open `docs/superpowers/specs/2026-07-07-work-reconcile-design.md` and tick each section against the skill: sources & roles, gap-capping, coverage diff, review/write flow, config, error-handling table. List any gap; if found, fix in the owning task's file and re-run the affected scenario.

- [ ] **Step 3: Final commit (only if fixes were made)**

```bash
git add -A
git commit -m "fix(work): address scenario findings in /work-reconcile"
```
