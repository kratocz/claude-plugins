# Work Plugin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a new `work` plugin with four skills (`/work-setup`, `/work-start`, `/work-status`, `/work-end`) that aggregates tasks, issues, PRs, and calendar events from MCP-configured sources (Todoist, ClickUp, GitHub, Google Calendar) into a scored, action-oriented briefing.

**Architecture:** Pure SKILL.md instructions (no runtime). Each skill is a markdown file that Claude executes by calling MCP tools, `Bash`, `Read`, `Write`, and `AskUserQuestion`. Config persists in `~/.claude/plugins/work/config.json`, with per-project overrides in memory files. Scoring uses an explicit weighted formula from the spec.

**Tech Stack:** Markdown (SKILL.md format), JSON (config + snapshot), MCP tools (Todoist, GitHub, ClickUp, Google Calendar), Bash (mkdir, date), `jq` (JSON manipulation in shell).

**Reference spec:** `docs/superpowers/specs/2026-06-03-work-plugin-design.md`

**Skill convention reference:** `plugins/session-tracker/skills/` (read these first if unfamiliar with the project — they show the SKILL.md pattern used in this monorepo).

---

## File Structure

This is the complete file inventory. Each file has one responsibility and is created or modified by exactly the tasks listed.

### Plugin metadata
- `plugins/work/.claude-plugin/plugin.json` — plugin manifest (name, version, description, author). Created in Task 1.
- `plugins/work/README.md` — user-facing install + usage docs. Created in Task 1, updated as skills are added.
- `plugins/work/CLAUDE.md` — internal notes for future Claude edits (config schema, skill table, release workflow). Created in Task 1.

### Skill files (one per slash command)
- `plugins/work/skills/setup/SKILL.md` — `/work-setup` skill. Created in Phase 1 (Tasks 3–8).
- `plugins/work/skills/start/SKILL.md` — `/work-start` skill. Created in Phase 2 (Tasks 9–16).
- `plugins/work/skills/status/SKILL.md` — `/work-status` skill. Created in Phase 3 (Tasks 17–20).
- `plugins/work/skills/end/SKILL.md` — `/work-end` skill. Created in Phase 4 (Tasks 21–24).

### Marketplace + repo docs
- `.claude-plugin/marketplace.json` — modified once in Task 25 (add `work` entry).
- `README.md` — modified once in Task 25 (prepend row to plugin table).

### Why this split

Each skill is a separate file because skills are independently invokable (slash commands). They share no code at runtime — the "shared" pieces (config schema, scoring formula) are documented in `CLAUDE.md` and **repeated inline** in each skill that needs them. This is intentional: SKILL.md files are prompts loaded individually, and a `start` skill that says "see CLAUDE.md for scoring" would force the user to load two files just to understand it.

`CLAUDE.md` is documentation for the plugin maintainer (future Claude editing the plugin). End users only read `README.md`.

---

## Testing strategy

This plugin has **no traditional unit tests** (no Python/Node code to test). Each skill is verified by:

1. **Structural test:** YAML frontmatter parses; required fields present; allowed-tools wildcard matches actual MCP prefixes available on the test machine.
2. **Dry-run test:** invoke the skill with a known config, verify it produces a well-formed output (snapshot of last-briefing.json conforms to schema).
3. **Integration test:** run end-to-end on the developer's real Todoist/GitHub data; eyeball the briefing for sanity.

Each phase ends with a manual verification step that the implementer must run before committing.

---

## Phase 0: Scaffolding (Tasks 1–2)

Setup the plugin skeleton. No skills yet, just the directory structure and metadata.

---

### Task 1: Create plugin skeleton (plugin.json, README, CLAUDE.md)

**Files:**
- Create: `plugins/work/.claude-plugin/plugin.json`
- Create: `plugins/work/README.md`
- Create: `plugins/work/CLAUDE.md`

- [ ] **Step 1: Create the directory structure**

Run:
```bash
mkdir -p /Users/krato/IdeaProjects/github.com/kratocz/claude-plugins/plugins/work/.claude-plugin
mkdir -p /Users/krato/IdeaProjects/github.com/kratocz/claude-plugins/plugins/work/skills
```

Expected: no output (directories created silently).

- [ ] **Step 2: Write plugin.json**

Write to `plugins/work/.claude-plugin/plugin.json`:

```json
{
  "name": "work",
  "version": "0.1.0",
  "description": "Morning briefing across task trackers and code review queues — pulls Todoist/ClickUp/GitHub/Calendar into a single scored todo list",
  "author": { "name": "Petr Kratochvíl", "url": "https://krato.cz/" }
}
```

- [ ] **Step 3: Write README.md**

Write to `plugins/work/README.md`:

````markdown
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
```

## Supported sources

- [Todoist](https://todoist.com/) — via Todoist MCP server
- [ClickUp](https://clickup.com/) — via ClickUp MCP server
- [GitHub](https://github.com/) — issues + PRs to review, via GitHub MCP server
- [Google Calendar](https://calendar.google.com/) — upcoming events, via Calendar MCP server

A source is used only if its MCP server is connected to your Claude Code session. Missing sources are skipped with a warning.

## Config

Stored at `~/.claude/plugins/work/config.json`. Persists across plugin upgrades. Re-run `/work-setup` to change settings.

Per-project overrides can be saved in `~/.claude/projects/<slug>/memory/work_config.md`.
````

- [ ] **Step 4: Write CLAUDE.md**

Write to `plugins/work/CLAUDE.md`:

````markdown
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
````

- [ ] **Step 5: Verify structure**

Run:
```bash
ls -la /Users/krato/IdeaProjects/github.com/kratocz/claude-plugins/plugins/work/
ls -la /Users/krato/IdeaProjects/github.com/kratocz/claude-plugins/plugins/work/.claude-plugin/
```

Expected: `.claude-plugin/`, `skills/`, `README.md`, `CLAUDE.md` in `work/`. `plugin.json` in `.claude-plugin/`.

- [ ] **Step 6: Commit**

```bash
cd /Users/krato/IdeaProjects/github.com/kratocz/claude-plugins
git add plugins/work/
git commit -m "$(cat <<'EOF'
feat(work): scaffold plugin skeleton

Add empty work plugin with plugin.json, README, and CLAUDE.md.
Skills will be added in subsequent commits.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: Add minimal marketplace entry (commented-out, for discoverability while in development)

This task is intentionally **skipped for now**. The marketplace entry goes in at the end (Task 25) when all four skills are working. Mark this task complete without doing anything — it's a placeholder to maintain task numbering consistency.

- [ ] **Step 1: No-op**

Skip. The marketplace entry is added in Task 25 after end-to-end verification.

---

## Phase 1: `/work-setup` (Tasks 3–8)

Build the interactive configuration skill. Without this, no other skill can run.

---

### Task 3: Create SKILL.md skeleton for setup

**Files:**
- Create: `plugins/work/skills/setup/SKILL.md`

- [ ] **Step 1: Write the frontmatter and section headers**

Write to `plugins/work/skills/setup/SKILL.md`:

```markdown
---
name: work-setup
description: Configure the work plugin — detect available MCP sources (Todoist, GitHub, ClickUp, Google Calendar) and write ~/.claude/plugins/work/config.json. Use when the user says "/work-setup", "configure work", or when /work-start fails because config is missing.
version: 0.1.0
allowed-tools: Read, Write, Bash, ToolSearch, AskUserQuestion
---

# Work Setup

Configure the work plugin: detect which MCP sources are available in this session, ask the user which to enable, and write the config file.

## Steps

1. **Load existing config** (edit mode vs. create mode)
2. **Detect available MCP sources** via ToolSearch
3. **Per-source Q&A** (enable, GitHub username if applicable)
4. **Scoring config** (weights, top_n)
5. **Language** (auto-detect from session-tracker config if present)
6. **Write global config**
7. **Optional per-project override**
8. **Confirm**
```

- [ ] **Step 2: Verify the file parses as valid frontmatter**

Run:
```bash
head -8 /Users/krato/IdeaProjects/github.com/kratocz/claude-plugins/plugins/work/skills/setup/SKILL.md
```

Expected output: lines `---`, frontmatter block, `---`, blank line, then `# Work Setup`.

- [ ] **Step 3: Commit (incremental)**

```bash
cd /Users/krato/IdeaProjects/github.com/kratocz/claude-plugins
git add plugins/work/skills/setup/SKILL.md
git commit -m "feat(work): add work-setup skill skeleton

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: Implement step 1 (load existing config) and step 2 (detect MCP sources)

**Files:**
- Modify: `plugins/work/skills/setup/SKILL.md`

- [ ] **Step 1: Replace step 1 and step 2 in SKILL.md with detailed instructions**

Find the "## Steps" section and replace it with this expanded version (keep step headers 3–8 as one-liners for now; we'll expand them in later tasks):

````markdown
## Steps

1. **Load existing config** (distinguishes edit vs. create mode):

   Try to read `~/.claude/plugins/work/config.json` with the Read tool.

   - If the file exists: parse it and remember it as `existing_config`. You're in **edit mode** — prefill defaults from existing values when asking questions.
   - If it doesn't exist: you're in **create mode** — use the defaults in this skill.

   Inform the user briefly in the configured language (default Czech, fallback English):
   - Edit mode: "Existující konfigurace nalezena, projdu ji s tebou znovu. Stiskni Enter na otázce pro ponechání aktuální hodnoty." / "Existing config found — I'll walk through it. Press Enter to keep current values."
   - Create mode: "Nová konfigurace. Projdu s tebou dostupné zdroje." / "Fresh setup. I'll walk you through available sources."

2. **Detect available MCP sources** via ToolSearch:

   For each known source, call ToolSearch with a representative tool name to verify the MCP server is connected in this session. Use these queries:

   | Source | ToolSearch query |
   |---|---|
   | todoist | `select:mcp__claude_ai_Todoist__find-tasks` |
   | github | `select:mcp__github__search_pull_requests` |
   | clickup | `select:mcp__plugin_ntit-common_clickup__clickup_filter_tasks` |
   | google_calendar | `select:mcp__claude_ai_Google_Calendar__list_events` |

   If the query returns a function definition, the source is **available**. If the query returns no match, the source is **unavailable**.

   Build a list `detected_sources` of available sources. If `detected_sources` is empty, tell the user "Žádný známý MCP server (Todoist/GitHub/ClickUp/Calendar) není v této session připojený. Nelze pokračovat se setup — přidej alespoň jeden MCP server v `~/.claude.json` a restartuj session." and stop.

3. **Per-source Q&A** — [expanded in Task 5]
4. **Scoring config** — [expanded in Task 6]
5. **Language** — [expanded in Task 6]
6. **Write global config** — [expanded in Task 7]
7. **Optional per-project override** — [expanded in Task 8]
8. **Confirm** — [expanded in Task 8]
````

- [ ] **Step 2: Verify the file still parses**

Run:
```bash
wc -l /Users/krato/IdeaProjects/github.com/kratocz/claude-plugins/plugins/work/skills/setup/SKILL.md
```

Expected: ~50–60 lines (frontmatter + expanded steps 1–2 + one-liners 3–8).

- [ ] **Step 3: Commit**

```bash
cd /Users/krato/IdeaProjects/github.com/kratocz/claude-plugins
git add plugins/work/skills/setup/SKILL.md
git commit -m "feat(work-setup): implement config load + MCP source detection

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 5: Implement step 3 (per-source Q&A)

**Files:**
- Modify: `plugins/work/skills/setup/SKILL.md`

- [ ] **Step 1: Replace the step 3 one-liner with detailed instructions**

Find `3. **Per-source Q&A** — [expanded in Task 5]` and replace it with:

````markdown
3. **Per-source Q&A** — for each source in `detected_sources`:

   Use AskUserQuestion to ask "Zapnout zdroj `<source_name>` ve work brieffingu?" (or English equivalent based on language setting). Options:
   - "Ano (Recommended)" / "Yes (Recommended)" — `enabled: true`
   - "Ne" / "No" — `enabled: false`

   In edit mode, mark the option matching the existing value as recommended.

   **GitHub-specific follow-up:** if user enables `github`, ask for their GitHub username (free-text). Pre-fill with `existing_config.sources.github.username` in edit mode, or with the output of `gh api user --jq .login 2>/dev/null` if `gh` CLI is available (best-effort, don't fail if it errors). Store as `sources.github.username`.

   **ClickUp-specific follow-up:** if user enables `clickup`, the plugin needs the user's member ID to filter `assignee=me`. Call `mcp__plugin_ntit-common_clickup__clickup_get_workspace_members` (no args) — it returns a list of members. If exactly one workspace member matches the user's name (heuristic: contains the GitHub username collected above, OR the user's email local-part), pick that ID automatically. Otherwise, list the members with AskUserQuestion (max 4 options — if more, list inline with numbers and ask via plain question) and ask the user to pick. Store as `sources.clickup.member_id`.

   **Default filter sets** for each source (used unless user later edits the JSON manually — no per-source filter UI in v1):

   - todoist: `{ "priorities": ["p1", "p2"], "scope": "today_and_overdue" }`
   - github: `{ "include": ["assigned_issues", "review_requested_prs", "my_open_prs"] }`
   - clickup: `{ "include": ["assigned_to_me"], "scope": "today_and_overdue" }`
   - google_calendar: `{ "window_hours": 12 }`

   Store the result for each source as an object like:
   ```json
   { "enabled": true, "mcp_prefix": "<from detection>", "username": "...", "filters": { ... } }
   ```

   (mcp_prefix is the prefix used during detection in step 2 — e.g. `mcp__claude_ai_Todoist__`.)
````

- [ ] **Step 2: Commit**

```bash
cd /Users/krato/IdeaProjects/github.com/kratocz/claude-plugins
git add plugins/work/skills/setup/SKILL.md
git commit -m "feat(work-setup): implement per-source Q&A with GitHub/ClickUp specifics

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 6: Implement step 4 (scoring config) and step 5 (language)

**Files:**
- Modify: `plugins/work/skills/setup/SKILL.md`

- [ ] **Step 1: Replace step 4 and step 5 one-liners**

Find `4. **Scoring config** — [expanded in Task 6]` and `5. **Language** — [expanded in Task 6]` and replace both with:

````markdown
4. **Scoring config**:

   Ask via AskUserQuestion: "Použít výchozí scoring váhy (priority=40, due=30, age=15, type=15)?" / "Use default scoring weights (priority=40, due=30, age=15, type=15)?"

   - "Ano (Recommended)" — store defaults
   - "Vlastní hodnoty" — prompt for each weight separately (priority, due_proximity, age, type_assignment). Each must be a non-negative integer. Validate that they sum to 100 (if not, tell the user the actual sum and re-ask). Store as `scoring.weights`.

   Then ask: "Kolik položek zobrazit v briefingu? (výchozí 8)" / "How many items to show in briefing? (default 8)" — free text, validate as integer 1–20. Store as `scoring.top_n`.

   In edit mode, prefill defaults with existing values.

5. **Language**:

   Look for an existing language preference:
   - Try Read on `~/.claude/plugins/session-tracker/config.json`. If it exists and has a `language` field, use that as the default.
   - Otherwise default to `cs`.

   Ask: "Jazyk pro výstup briefingu? (kód jako en, cs, de — výchozí: <detected_or_cs>)". Accept any 2-letter ISO 639-1 code. Store as top-level `language`.
````

- [ ] **Step 2: Commit**

```bash
cd /Users/krato/IdeaProjects/github.com/kratocz/claude-plugins
git add plugins/work/skills/setup/SKILL.md
git commit -m "feat(work-setup): implement scoring weights and language config

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 7: Implement step 6 (write global config)

**Files:**
- Modify: `plugins/work/skills/setup/SKILL.md`

- [ ] **Step 1: Replace step 6 one-liner**

Find `6. **Write global config** — [expanded in Task 7]` and replace with:

````markdown
6. **Write global config**:

   Ensure the config directory exists:
   ```bash
   mkdir -p ~/.claude/plugins/work
   ```

   Build the config object in memory:
   ```json
   {
     "language": "<from step 5>",
     "sources": {
       "todoist":         { "enabled": <bool>, "mcp_prefix": "mcp__claude_ai_Todoist__", "filters": { ... } },
       "github":          { "enabled": <bool>, "mcp_prefix": "mcp__github__", "username": "...", "filters": { ... } },
       "clickup":         { "enabled": <bool>, "mcp_prefix": "mcp__plugin_ntit-common_clickup__", "member_id": "...", "filters": { ... } },
       "google_calendar": { "enabled": <bool>, "mcp_prefix": "mcp__claude_ai_Google_Calendar__", "filters": { ... } }
     },
     "scoring": {
       "weights": { "priority": 40, "due_proximity": 30, "age": 15, "type_assignment": 15 },
       "top_n": 8
     }
   }
   ```

   **Important:** include ALL four sources in the JSON even if some are disabled or weren't detected in this session. Sources that weren't detected get `enabled: false` and the canonical `mcp_prefix` from the detection table (so the user can manually enable later when they add the MCP server). Sources that were detected but the user said "No" also get `enabled: false` but keep any collected metadata (username, member_id).

   Use the Write tool to write the JSON to `~/.claude/plugins/work/config.json` with 2-space indentation.
````

- [ ] **Step 2: Commit**

```bash
cd /Users/krato/IdeaProjects/github.com/kratocz/claude-plugins
git add plugins/work/skills/setup/SKILL.md
git commit -m "feat(work-setup): implement global config write step

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 8: Implement step 7 (per-project override) and step 8 (confirm)

**Files:**
- Modify: `plugins/work/skills/setup/SKILL.md`

- [ ] **Step 1: Replace step 7 and step 8 one-liners**

Find `7. **Optional per-project override** — [expanded in Task 8]` and `8. **Confirm** — [expanded in Task 8]` and replace both with:

````markdown
7. **Optional per-project override**:

   Detect the current project's slug:
   ```bash
   pwd
   ```

   The project memory dir follows the Claude Code convention: `~/.claude/projects/<slug>/memory/`, where `<slug>` is the absolute path of the current working directory with `/` replaced by `-` and a leading `-` (so `/Users/krato/IdeaProjects/foo` becomes `-Users-krato-IdeaProjects-foo`).

   Ask via AskUserQuestion: "Chceš uložit per-project override pro projekt `<basename>`?" Options:
   - "Ne, jen globální config (Recommended)" — skip
   - "Ano, uložit override soubor"

   If user picks "Ano":

   Compute the slug from `pwd`. Verify the memory dir exists:
   ```bash
   ls ~/.claude/projects/<slug>/memory/ 2>/dev/null || echo "MEMORY_DIR_MISSING"
   ```

   If `MEMORY_DIR_MISSING`, create it:
   ```bash
   mkdir -p ~/.claude/projects/<slug>/memory
   ```

   Ask the user (free text): "Co chceš v tomto projektu změnit oproti globálnímu configu? Napiš jednou větou (např. 'vypnout clickup, jen github repo X')." Use the answer as a hint for which fields to override.

   Then ask via AskUserQuestion for the specific override (this v1 supports only a small set):
   - "Vypnout některé zdroje v tomto projektu" — multi-select from `[todoist, github, clickup, google_calendar]`, the selected ones get `enabled: false` in the override.
   - "Pouze ze konkrétních GitHub repos" — free text, comma-separated owner/repo list. Adds `sources.github.repos` array.
   - "Hotovo — nic dalšího" — proceed to write.

   Loop until user picks "Hotovo".

   Build the override JSON (only the fields to override) and write to `~/.claude/projects/<slug>/memory/work_config.md`:

   ```markdown
   ---
   name: work-config-override
   description: Per-project work plugin overrides for <basename>
   metadata:
     type: project
   ---

   Per-project overrides for the work plugin in this project. The skill reads only the JSON block below.

   ```json
   { "sources": { "clickup": { "enabled": false } } }
   ```

   <user's one-sentence reason from above>
   ```

   Append a line to `~/.claude/projects/<slug>/memory/MEMORY.md` (create the file if missing):
   ```
   - [Work plugin override](work_config.md) — per-project source/scoring overrides
   ```

   If MEMORY.md already contains a line referencing `work_config.md`, don't add a duplicate.

8. **Confirm**:

   Print a summary in the configured language:
   ```
   ✅ Setup hotov.

   Global config: ~/.claude/plugins/work/config.json
   Povolené zdroje: <comma-separated list of enabled source names>
   Per-project override: <path or "není">

   Spusť /work-start pro ranní briefing.
   ```
````

- [ ] **Step 2: Manual verification — try the skill end-to-end**

This is the first integration test. Open a new Claude Code session (or reuse this one), type `/work-setup` (after the plugin is installed locally), and run through the full flow:

```bash
# In a separate terminal, verify the config file:
cat ~/.claude/plugins/work/config.json | jq .
```

Expected: well-formed JSON with all four sources, scoring weights summing to 100, `top_n` between 1–20, `language` set.

If you opted into a per-project override, also verify:
```bash
ls -la ~/.claude/projects/-Users-krato-IdeaProjects-github-com-kratocz-claude-plugins/memory/
cat ~/.claude/projects/-Users-krato-IdeaProjects-github-com-kratocz-claude-plugins/memory/work_config.md
```

Expected: `work_config.md` exists, contains the override JSON block, and `MEMORY.md` references it.

**If verification fails:** do NOT mark this task complete. Open the SKILL.md, identify which step Claude got wrong, and refine the instructions until the flow works.

- [ ] **Step 3: Commit**

```bash
cd /Users/krato/IdeaProjects/github.com/kratocz/claude-plugins
git add plugins/work/skills/setup/SKILL.md
git commit -m "feat(work-setup): implement per-project override and confirmation

Completes the /work-setup flow. Manually verified end-to-end.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Phase 2: `/work-start` (Tasks 9–16)

Build the morning briefing skill. Depends on Phase 1 (config must exist).

---

### Task 9: Create SKILL.md skeleton for start

**Files:**
- Create: `plugins/work/skills/start/SKILL.md`

- [ ] **Step 1: Write the frontmatter and section headers**

Write to `plugins/work/skills/start/SKILL.md`:

```markdown
---
name: work-start
description: Morning briefing — pull tasks/PRs from configured sources (Todoist, ClickUp, GitHub, Calendar), score them, and print top N with categories. Use when the user says "/work-start", "morning briefing", "co dneska řešit", "what's on my plate today".
argument-hint: [--fresh]
version: 0.1.0
allowed-tools: Read, Write, Bash, ToolSearch, mcp__claude_ai_Todoist__find-tasks, mcp__claude_ai_Todoist__find-tasks-by-date, mcp__github__search_issues, mcp__github__search_pull_requests, mcp__plugin_ntit-common_clickup__clickup_filter_tasks, mcp__claude_ai_Google_Calendar__list_events
---

# Work Start

Morning briefing across all configured task and code review sources.

## Steps

1. **Load effective config** (global + per-project merge)
2. **Verify enabled MCP sources** (skip and warn if unavailable)
3. **Fetch from each enabled source** (in parallel)
4. **Normalize items to common shape**
5. **Score and sort**
6. **Bucket items**
7. **Render briefing + recommendation**
8. **Write snapshot**
9. **Print warnings**
```

- [ ] **Step 2: Commit**

```bash
cd /Users/krato/IdeaProjects/github.com/kratocz/claude-plugins
git add plugins/work/skills/start/SKILL.md
git commit -m "feat(work): add work-start skill skeleton

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 10: Implement step 1 (load effective config)

**Files:**
- Modify: `plugins/work/skills/start/SKILL.md`

- [ ] **Step 1: Replace step 1 one-liner**

Find `1. **Load effective config** (global + per-project merge)` and replace with:

````markdown
1. **Load effective config**:

   a. Read global config: `~/.claude/plugins/work/config.json` with the Read tool.

   If the file doesn't exist, stop with this message in Czech (or English if user prefers): "Žádná konfigurace work pluginu. Spusť `/work-setup` nejdřív." Then return — do not proceed.

   b. Locate per-project override:
   ```bash
   pwd
   ```
   Build slug as in `/work-setup` (absolute path with `/` → `-`, leading `-`). Try to read `~/.claude/projects/<slug>/memory/work_config.md` with the Read tool.

   If the file exists:
   - Find the first fenced ` ```json ... ``` ` block in the file.
   - Parse the JSON. If parse fails, print warning "⚠️ Per-project override `work_config.md` má nevalidní JSON. Pokračuju s globálním configem." and skip override.
   - Otherwise, deep-merge the override onto the global config:
     - Objects: recursively merge keys. Override values replace global values.
     - Arrays: replace entirely (override array replaces global array).
     - Scalars: override replaces global.

   The merged result is `effective_config`. Use it for the rest of the steps.
````

- [ ] **Step 2: Commit**

```bash
cd /Users/krato/IdeaProjects/github.com/kratocz/claude-plugins
git add plugins/work/skills/start/SKILL.md
git commit -m "feat(work-start): implement config load with per-project override merge

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 11: Implement step 2 (verify MCP sources) and step 3 (fetch in parallel)

**Files:**
- Modify: `plugins/work/skills/start/SKILL.md`

- [ ] **Step 1: Replace step 2 and step 3 one-liners**

Find both and replace with:

````markdown
2. **Verify enabled MCP sources**:

   Initialize an empty list `warnings = []`.

   For each source in `effective_config.sources` where `enabled == true`:

   Use ToolSearch with `select:<a representative tool from the mcp_prefix>` to check availability. Use the same query table as `/work-setup` step 2:

   | Source | ToolSearch query |
   |---|---|
   | todoist | `select:mcp__claude_ai_Todoist__find-tasks` |
   | github | `select:mcp__github__search_pull_requests` |
   | clickup | `select:mcp__plugin_ntit-common_clickup__clickup_filter_tasks` |
   | google_calendar | `select:mcp__claude_ai_Google_Calendar__list_events` |

   If unavailable, mark the source as skipped, append to warnings:
   ```
   ⚠️ Source `<name>` je povolený v configu, ale MCP server není v této session. Přeskakuji. Spusť /work-setup pro aktualizaci, nebo zkontroluj ~/.claude.json.
   ```

   Continue with the remaining available sources.

3. **Fetch from each available source — IN PARALLEL**:

   Make ALL MCP fetch calls in a SINGLE message (multiple tool_use blocks in parallel). This is critical for speed.

   **Todoist** (if enabled):
   - Get today's date: `date +%Y-%m-%d`
   - Call `mcp__claude_ai_Todoist__find-tasks-by-date` with arguments `{ "dateFrom": "1900-01-01", "dateTo": "<today>" }` to get overdue + today's tasks. (Past date catches overdue; future date is exclusive.)
   - Call `mcp__claude_ai_Todoist__find-tasks` with arguments `{ "filter": "p1 | p2" }` to get all p1/p2 tasks regardless of due date.

   **GitHub** (if enabled):
   - Substitute `effective_config.sources.github.username` for `@me` in queries (GitHub MCP may not resolve `@me`).
   - Build base query — if `effective_config.sources.github.repos` is set (per-project override), AND-prefix each query with `repo:<owner/name>` for each repo in the list, joined with OR — e.g. `(repo:owner/a OR repo:owner/b)`. Otherwise no repo filter.
   - Call `mcp__github__search_issues` with `{ "q": "is:open is:issue assignee:<username> <repo_filter>" }`
   - Call `mcp__github__search_pull_requests` with `{ "q": "is:open review-requested:<username> <repo_filter>" }`
   - Call `mcp__github__search_pull_requests` with `{ "q": "is:open draft:false author:<username> <repo_filter>" }`

   **ClickUp** (if enabled):
   - Call `mcp__plugin_ntit-common_clickup__clickup_filter_tasks` with arguments that filter to the user's member_id (from `effective_config.sources.clickup.member_id`), open status, and due_date_lt = tomorrow midnight (covers overdue + today). Refer to the ClickUp MCP tool's exact schema for the argument shape.

   **Google Calendar** (if enabled):
   - Get current time and 12h-later time:
     ```bash
     date -u +%Y-%m-%dT%H:%M:%SZ
     date -u -v+12H +%Y-%m-%dT%H:%M:%SZ  # macOS; on Linux: date -u -d '+12 hours' +%Y-%m-%dT%H:%M:%SZ
     ```
   - Call `mcp__claude_ai_Google_Calendar__list_events` with `{ "timeMin": "<now>", "timeMax": "<now+window_hours>", "calendarId": "primary" }`.

   Collect all results into raw per-source response variables: `todoist_raw`, `github_raw`, `clickup_raw`, `calendar_raw`.

   If a call fails (returns error or empty array due to auth/network), append a warning and treat that source's contribution as empty:
   ```
   ⚠️ Fetch z `<source>` selhal: <error message>. Přeskakuji tento zdroj v dnešním briefingu.
   ```
````

- [ ] **Step 2: Commit**

```bash
cd /Users/krato/IdeaProjects/github.com/kratocz/claude-plugins
git add plugins/work/skills/start/SKILL.md
git commit -m "feat(work-start): implement source verification and parallel fetch

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 12: Implement step 4 (normalize items)

**Files:**
- Modify: `plugins/work/skills/start/SKILL.md`

- [ ] **Step 1: Replace step 4 one-liner**

Find `4. **Normalize items to common shape**` and replace with:

````markdown
4. **Normalize items to common shape**:

   Combine all raw responses into a single list `items`, each shaped as:

   ```json
   {
     "source": "todoist" | "github" | "clickup" | "google_calendar",
     "id": "<source-specific identifier>",
     "title": "<human-readable title>",
     "url": "<web URL or null>",
     "priority": "p1" | "p2" | "p3" | "p4" | null,
     "due": "<ISO 8601 date or datetime, or null>",
     "assigned_at": "<ISO 8601 datetime of when item entered queue, or null>",
     "type": "task" | "issue" | "pr_review" | "pr_mine" | "calendar_event",
     "raw": <original object, kept for debugging>
   }
   ```

   **Normalization rules per source:**

   **Todoist tasks** (from both `find-tasks-by-date` and `find-tasks`):
   - Deduplicate by task ID (a task may appear in both responses).
   - `source = "todoist"`, `type = "task"`.
   - `id = task.id`, `title = task.content`, `url = task.url` (if present), `due = task.due.date` (or null).
   - `priority`: Todoist `priority` is integer 1–4 where 4=p1 (highest) and 1=p4 (default). Map: `4 → "p1"`, `3 → "p2"`, `2 → "p3"`, `1 → "p4"`. If field missing, treat as `"p4"` (lowest).
   - `assigned_at`: use `task.added_at` or `task.created_at` (whichever Todoist returns).

   **GitHub items** (issues + PRs):
   - `source = "github"`, `id = "<owner>/<repo>#<number>"`, `title = item.title`, `url = item.html_url`.
   - `priority = null` (GitHub has no priority field).
   - `due = null` (GitHub issues don't have due dates by default).
   - `assigned_at`: for issues use `item.created_at` (best proxy for "in queue"); for PRs review-requested use `item.created_at` (or `requested_reviewers[].requested_at` if available).
   - `type`: from which query it came — `issue` from search_issues, `pr_review` from review-requested PR query, `pr_mine` from author query.

   **ClickUp tasks:**
   - `source = "clickup"`, `id = task.id`, `title = task.name`, `url = task.url`.
   - `priority`: ClickUp returns priority object with `priority` field ("1"=urgent, "2"=high, "3"=normal, "4"=low). Map: `"1" → "p1"`, `"2" → "p2"`, `"3" → "p3"`, `"4" → "p4"`. If null, treat as `"p4"`.
   - `due`: `task.due_date` (Unix millis → convert to ISO date).
   - `assigned_at`: `task.date_created` (Unix millis → ISO).
   - `type = "task"`.

   **Google Calendar events:**
   - `source = "google_calendar"`, `id = event.id`, `title = event.summary`, `url = event.htmlLink`.
   - `priority = null`, `due = event.start.dateTime` (or `event.start.date` for all-day).
   - `assigned_at`: `event.created`.
   - `type = "calendar_event"`.

   After normalization, you have a unified `items` list ready for scoring.
````

- [ ] **Step 2: Commit**

```bash
cd /Users/krato/IdeaProjects/github.com/kratocz/claude-plugins
git add plugins/work/skills/start/SKILL.md
git commit -m "feat(work-start): implement item normalization across sources

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 13: Implement step 5 (score and sort)

**Files:**
- Modify: `plugins/work/skills/start/SKILL.md`

- [ ] **Step 1: Replace step 5 one-liner**

Find `5. **Score and sort**` and replace with:

````markdown
5. **Score and sort**:

   For each item in `items`, compute four component scores (each 0–100) and combine using weights from `effective_config.scoring.weights`.

   **`priority_score`:**
   - `p1 → 100`, `p2 → 75`, `p3 → 50`, `p4 → 25`, `null → 10`
   - For items where `type == "pr_review"` and `priority == null`, override to `75` (PRs blocking colleagues default to p2 importance)

   **`due_proximity_score`:**
   - Compute today's date and the item's due date (date-only, ignore time-of-day for tasks; for calendar events use full datetime).
   - `due == null → 0`
   - `due < today (overdue) → 100`
   - `due == today → 90`
   - `due == tomorrow → 70`
   - `2 <= days_until_due <= 7 → linear interpolation from 60 (at +2 days) down to 20 (at +7 days). Formula: `60 - (days_until_due - 2) * 8` → `60, 52, 44, 36, 28, 20`.
   - `days_until_due > 7 → 10`

   **`age_score`:**
   - `age_days = (today - assigned_at) in whole days`
   - `age_score = min(100, age_days * 5)`
   - If `assigned_at == null`, `age_score = 0`

   **`type_assignment_score`:**
   - `type == "pr_review" → 90`
   - `type == "issue"` and assigned directly to user → `80`
   - `type == "task"` (Todoist or ClickUp) with assignment → `80`
   - `type == "task"` in user's project but no specific assignee → `40` (not applicable in v1 since we filter assignee=me at fetch; reserve for future)
   - `type == "calendar_event"`:
     - If event starts in `<= 2 hours` → `100`
     - Else if event starts in `<= 6 hours` → `70`
     - Else → `40`
   - `type == "pr_mine"` → `50` (your own PRs — relevant but not blocking others)

   **Combine:**
   ```
   weights = effective_config.scoring.weights  // e.g. {priority: 40, due_proximity: 30, age: 15, type_assignment: 15}
   total_weight = sum(weights.values())  // normally 100, but defensive

   score = (priority_score * weights.priority
          + due_proximity_score * weights.due_proximity
          + age_score * weights.age
          + type_assignment_score * weights.type_assignment) / total_weight
   ```

   Round score to integer.

   Sort `items` by score descending. Tie-break (in this order):
   1. Higher `priority_score`
   2. Shorter due (overdue first, then today, then nearest future)
   3. Older `age_days`
   4. Alphabetical title (case-insensitive)
````

- [ ] **Step 2: Commit**

```bash
cd /Users/krato/IdeaProjects/github.com/kratocz/claude-plugins
git add plugins/work/skills/start/SKILL.md
git commit -m "feat(work-start): implement scoring formula with tie-break rules

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 14: Implement step 6 (bucket) and step 7 (render)

**Files:**
- Modify: `plugins/work/skills/start/SKILL.md`

- [ ] **Step 1: Replace step 6 and step 7 one-liners**

Find both and replace with:

````markdown
6. **Bucket items**:

   Assign each item to exactly one bucket based on its data (NOT its score):

   - **🔥 OVERDUE** — `due` is set and `due < today`
   - **👀 WAITING ON REVIEW** — `type == "pr_review"` (regardless of due)
   - **📅 TODAY** — `due == today` OR (`due == null` AND `priority in [p1, p2]`)
   - **📆 UPCOMING** — `due` is in the next 7 days (tomorrow through +7)
   - **(uncategorized)** — anything else: low-priority items with no due date, calendar events more than 12h out, etc. Default: drop from briefing.

   Bucket assignment priority (if an item matches multiple, pick the first match in this order): OVERDUE > WAITING ON REVIEW > TODAY > UPCOMING.

   **Top N filter:** keep only the top `effective_config.scoring.top_n` items across all buckets. The score determines which items survive the filter; the bucket determines where they're displayed. Within a bucket, sort by score descending (tie-break rules from step 5).

   Skip empty buckets in the rendered output.

7. **Render briefing + recommendation**:

   Build a markdown briefing in the configured language. Use this template (Czech default; translate the labels and recommendation prose if `effective_config.language` is something else):

   ```markdown
   ## 📋 Briefing — <today's date as DD. MM. YYYY>

   ### 🔥 Overdue
   1. **<title>** — <source>, score <N>, due <DD.MM.YYYY> (X dní po termínu)
      <url>
   ...

   ### 👀 Čeká na tvůj review
   1. **<title>** — <source/repo>, score <N>, otevřeno <X dní>
      <url>
   ...

   ### 📅 Dnes
   ...

   ### 📆 Tento týden
   ...

   ---

   💡 **Začni s [item #1 overall]** — <one-sentence reason from the dominant scoring component>.

   <Warnings section if any>
   ```

   For the recommendation, identify the item with the highest score across all buckets. Determine which component contributed most to its score (the largest weighted component), and articulate that:
   - If priority_score dominates: "má prioritu <p1/p2>"
   - If due_proximity_score dominates: "je <po termínu / due dnes / due zítra>"
   - If age_score dominates: "leží v queue už <X> dní"
   - If type_assignment_score dominates: "je PR čekající na review / je za <X> hodin v kalendáři"

   Pick the single dominant reason; don't list all.
````

- [ ] **Step 2: Commit**

```bash
cd /Users/krato/IdeaProjects/github.com/kratocz/claude-plugins
git add plugins/work/skills/start/SKILL.md
git commit -m "feat(work-start): implement bucketing and briefing render

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 15: Implement step 8 (write snapshot) and step 9 (warnings)

**Files:**
- Modify: `plugins/work/skills/start/SKILL.md`

- [ ] **Step 1: Replace step 8 and step 9 one-liners**

Find both and replace with:

````markdown
8. **Write snapshot**:

   Compute `effective_config_hash`:
   ```bash
   echo -n '<effective_config as canonical JSON>' | shasum -a 256 | cut -d' ' -f1
   ```
   Prefix with `"sha256:"`.

   Build the snapshot:

   ```json
   {
     "schema_version": 1,
     "timestamp": "<UTC now as ISO 8601>",
     "effective_config_hash": "sha256:<hex>",
     "items": [
       {
         "source": "...",
         "id": "...",
         "title": "...",
         "url": "...",
         "score": <int>,
         "bucket": "OVERDUE" | "WAITING_ON_REVIEW" | "TODAY" | "UPCOMING",
         "status": "open"
       }
     ],
     "warnings": [...]
   }
   ```

   Only include the top_n items displayed in the briefing (not the full discarded set).

   Get UTC timestamp:
   ```bash
   date -u +%Y-%m-%dT%H:%M:%SZ
   ```

   Ensure dir exists:
   ```bash
   mkdir -p ~/.claude/plugins/work
   ```

   Write the snapshot with the Write tool to `~/.claude/plugins/work/last-briefing.json`.

9. **Print warnings**:

   If `warnings` is non-empty, after the briefing print:

   ```
   ---

   ⚠️ Upozornění:
   - <warning 1>
   - <warning 2>
   ```

   If `warnings` is empty, omit this section.
````

- [ ] **Step 2: Manual verification — try the skill end-to-end**

Open a new session. Run `/work-start`. Verify:

1. Briefing renders with the expected sections.
2. Snapshot file is written:
   ```bash
   cat ~/.claude/plugins/work/last-briefing.json | jq .
   ```
   Expected: valid JSON with `schema_version: 1`, `timestamp`, `effective_config_hash`, `items` array, `warnings` array.
3. Item count in snapshot matches the items shown in the briefing.
4. Sanity-check the recommendation matches the top-scored item.

If anything looks wrong, identify which step has the bug and refine the SKILL.md instructions.

- [ ] **Step 3: Commit**

```bash
cd /Users/krato/IdeaProjects/github.com/kratocz/claude-plugins
git add plugins/work/skills/start/SKILL.md
git commit -m "feat(work-start): implement snapshot write and warnings

Completes /work-start flow. Manually verified end-to-end.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 16: Handle `--fresh` argument and edge cases

**Files:**
- Modify: `plugins/work/skills/start/SKILL.md`

- [ ] **Step 1: Add an "Arguments" section before "## Steps" and an "Edge cases" section after**

After the `# Work Start` heading and before `## Steps`, insert:

````markdown
## Arguments

- `--fresh` (optional): if passed, treat any existing snapshot as stale and always re-fetch. (For v1 the skill always re-fetches, so this is informational; it's a hook for future caching.)
````

After step 9, append:

````markdown
## Edge cases

- **No items returned from any source**: render `🎉 Žádné overdue tasky, žádné PRs k review. Užij si volný čas.` Skip all bucket sections. Still write the snapshot (empty `items`) so `/work-status` has a baseline.
- **Config exists but all sources are `enabled: false`**: same message as no-items, plus warning "Žádný zdroj není povolený. Spusť /work-setup pro úpravu."
- **Snapshot already exists from earlier today**: overwrite it silently. (No "are you sure" prompt — `/work-start` is idempotent.)
- **All MCP sources fail**: print warnings, render no buckets, message "Briefing selhal — všechny zdroje nedostupné. Zkontroluj MCP servery."
````

- [ ] **Step 2: Commit**

```bash
cd /Users/krato/IdeaProjects/github.com/kratocz/claude-plugins
git add plugins/work/skills/start/SKILL.md
git commit -m "feat(work-start): document --fresh argument and edge cases

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Phase 3: `/work-status` (Tasks 17–20)

Build the mid-day diff skill. Depends on Phase 2 (snapshot must exist).

---

### Task 17: Create SKILL.md skeleton for status

**Files:**
- Create: `plugins/work/skills/status/SKILL.md`

- [ ] **Step 1: Write the frontmatter and section headers**

Write to `plugins/work/skills/status/SKILL.md`:

```markdown
---
name: work-status
description: Mid-day check — diff current state of volatile sources (GitHub PRs, Todoist completions) against the last /work-start snapshot. Use when the user says "/work-status", "what's new", "co se změnilo".
version: 0.1.0
allowed-tools: Read, Bash, ToolSearch, mcp__claude_ai_Todoist__find-completed-tasks, mcp__claude_ai_Todoist__find-tasks-by-date, mcp__github__search_issues, mcp__github__search_pull_requests
---

# Work Status

Lightweight diff: what closed, what's new, what's still open — since `/work-start`.

## Steps

1. **Read snapshot**
2. **Read effective config** (same as /work-start)
3. **Re-fetch volatile sources**
4. **Diff against snapshot**
5. **Render**
```

- [ ] **Step 2: Commit**

```bash
cd /Users/krato/IdeaProjects/github.com/kratocz/claude-plugins
git add plugins/work/skills/status/SKILL.md
git commit -m "feat(work): add work-status skill skeleton

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 18: Implement step 1 (read snapshot) and step 2 (read effective config)

**Files:**
- Modify: `plugins/work/skills/status/SKILL.md`

- [ ] **Step 1: Replace step 1 and step 2 one-liners**

Find both and replace with:

````markdown
1. **Read snapshot**:

   Try to read `~/.claude/plugins/work/last-briefing.json` with the Read tool.

   - If missing: stop with message "Žádný snapshot. Spusť /work-start nejdřív." Return.
   - If `schema_version` is not `1`: warn "Snapshot je z jiné verze pluginu. Pokračuju best-effort." Continue.
   - Compute snapshot age:
     ```bash
     date -u +%s  # current epoch
     date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "<snapshot.timestamp>" +%s  # macOS
     # On Linux: date -u -d "<snapshot.timestamp>" +%s
     ```
     `age_hours = (now - snapshot_epoch) / 3600`
   - If `age_hours > 12`: warn "Snapshot je starý <X> hodin. Doporučuji /work-start." Continue anyway.

2. **Read effective config** — use the same logic as `/work-start` step 1 (global config + per-project override merge). If global config is missing, stop with "Žádná konfigurace work pluginu. Spusť /work-setup." Return.

   Compare current `effective_config_hash` (compute same way as in /work-start step 8) against snapshot's `effective_config_hash`. If different, append a warning: "⚠️ Konfigurace se od snapshotu změnila — diff může být zavádějící. Pro čistý stav spusť /work-start."
````

- [ ] **Step 2: Commit**

```bash
cd /Users/krato/IdeaProjects/github.com/kratocz/claude-plugins
git add plugins/work/skills/status/SKILL.md
git commit -m "feat(work-status): implement snapshot and config read

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 19: Implement step 3 (re-fetch volatile sources) and step 4 (diff)

**Files:**
- Modify: `plugins/work/skills/status/SKILL.md`

- [ ] **Step 1: Replace step 3 and step 4 one-liners**

Find both and replace with:

````markdown
3. **Re-fetch volatile sources** (in parallel — single message with multiple MCP calls):

   Only sources that are `enabled` in `effective_config` AND in the volatile set (github, todoist). Skip calendar (stale events) and clickup (heavy re-fetch, defer to next /work-start).

   **GitHub** (if enabled and available — use ToolSearch to verify, same query as /work-start):
   - Use the same three queries as /work-start step 3 (search_issues + 2× search_pull_requests). Same `username` substitution and `repo` filter from override.

   **Todoist** (if enabled and available):
   - Get currently open tasks (for "new" and "still open" buckets):
     - Call `mcp__claude_ai_Todoist__find-tasks-by-date` with `{ "dateFrom": "1900-01-01", "dateTo": "<today>" }`.
     - Call `mcp__claude_ai_Todoist__find-tasks` with `{ "filter": "p1 | p2" }`.
   - Get tasks completed since snapshot timestamp:
     - Call `mcp__claude_ai_Todoist__find-completed-tasks` with `{ "since": "<snapshot.timestamp>" }` (or the equivalent argument shape per the MCP server's schema).

   Normalize all fetched items using the same normalization rules as `/work-start` step 4. Build `current_items` (open items now) and `completed_items` (Todoist completions since snapshot).

   For GitHub, also identify which snapshot items are now closed:
   - For each snapshot item with `source == "github"`, check if it appears in the current open results. If not, treat as closed.
   - **Caveat:** this is a heuristic. An item could also disappear because the user changed filters, removed assignment, etc. For v1 we accept this; in practice items in a morning snapshot rarely change assignment by mid-day. The next /work-start re-establishes ground truth.

4. **Diff snapshot vs. current**:

   - `closed`: snapshot items that are no longer open. (GitHub: not in current open results. Todoist: in `completed_items` OR not in current open results — Todoist completions appear in `completed_items` directly.)
   - `new`: current open items that don't appear in snapshot (matched by `id`).
   - `still_open`: snapshot items that are in current open results. Sort by `score` descending (use stored snapshot score; don't re-compute since we may be missing data from skipped sources).

   Sort `still_open` and pick the top 3 to display.
````

- [ ] **Step 2: Commit**

```bash
cd /Users/krato/IdeaProjects/github.com/kratocz/claude-plugins
git add plugins/work/skills/status/SKILL.md
git commit -m "feat(work-status): implement volatile fetch and diff logic

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 20: Implement step 5 (render) and edge cases

**Files:**
- Modify: `plugins/work/skills/status/SKILL.md`

- [ ] **Step 1: Replace step 5 one-liner and add edge cases**

Find step 5 and replace:

````markdown
5. **Render terse summary** in the configured language (Czech default):

   ```markdown
   ## 📊 Status — <X>h od /work-start

   ✅ **Dokončeno:** <N>
   - <title> (<source>)
   - ...

   🆕 **Nové od briefingu:** <N>
   - <title> (<source>) — <url>
   - ...

   🔥 **Stále otevřené (top 3 podle scoru):**
   1. <title> (<source>) — score <N>
   2. ...

   <Warnings section if any>
   ```

   If `closed`, `new`, and `still_open` are all empty: "Nic nového. Snapshot je aktuální." (No subsections.)
````

After step 5, append:

````markdown
## Edge cases

- **All volatile sources skipped (none enabled or all unavailable)**: print "Nelze re-fetchnout žádný zdroj — všechny volatile zdroje jsou neaktivní nebo nedostupné."
- **Snapshot is empty** (briefing had no items): print "Snapshot je prázdný (briefing nezachytil nic). Spusť /work-start znovu pro aktualizaci."
````

- [ ] **Step 2: Manual verification**

1. Run `/work-start` (must already work from Phase 2).
2. Wait ~5 minutes, optionally close one of the tasks/PRs in the briefing.
3. Run `/work-status`.

Expected: clean diff output. The closed item appears in ✅; if anything new arrived, it appears in 🆕; the rest in 🔥.

- [ ] **Step 3: Commit**

```bash
cd /Users/krato/IdeaProjects/github.com/kratocz/claude-plugins
git add plugins/work/skills/status/SKILL.md
git commit -m "feat(work-status): implement render and edge cases

Completes /work-status. Manually verified.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Phase 4: `/work-end` (Tasks 21–24)

Build the end-of-day summary skill. Depends on Phase 2 (snapshot must exist).

---

### Task 21: Create SKILL.md skeleton for end

**Files:**
- Create: `plugins/work/skills/end/SKILL.md`

- [ ] **Step 1: Write the frontmatter and section headers**

Write to `plugins/work/skills/end/SKILL.md`:

```markdown
---
name: work-end
description: End-of-day summary — what got done, what carries over, what's new since /work-start. Use when the user says "/work-end", "konec dne", "shrnutí dne", "wrap up".
version: 0.1.0
allowed-tools: Read, Write, Bash, ToolSearch, AskUserQuestion, mcp__claude_ai_Todoist__find-completed-tasks, mcp__claude_ai_Todoist__find-tasks, mcp__claude_ai_Todoist__find-tasks-by-date, mcp__github__search_issues, mcp__github__search_pull_requests, mcp__plugin_ntit-common_clickup__clickup_filter_tasks
---

# Work End

End-of-day retrospective: what closed, what carries over, what arrived during the day.

## Steps

1. **Read snapshot**
2. **Read effective config**
3. **Re-fetch all enabled sources**
4. **Compute completed / carry-over / new-unhandled**
5. **Render summary**
6. **Optionally save to session log**
```

- [ ] **Step 2: Commit**

```bash
cd /Users/krato/IdeaProjects/github.com/kratocz/claude-plugins
git add plugins/work/skills/end/SKILL.md
git commit -m "feat(work): add work-end skill skeleton

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 22: Implement step 1 (read snapshot) and step 2 (read config) and step 3 (re-fetch)

**Files:**
- Modify: `plugins/work/skills/end/SKILL.md`

- [ ] **Step 1: Replace step 1, step 2, and step 3 one-liners**

Find all three and replace:

````markdown
1. **Read snapshot**:

   Read `~/.claude/plugins/work/last-briefing.json` with the Read tool.

   - If missing: stop with "Žádný snapshot. Bez ranního /work-start nelze udělat end-of-day souhrn." Return.
   - Compute age:
     ```bash
     date -u +%s
     date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "<snapshot.timestamp>" +%s  # macOS
     ```
     If `age_hours > 24`: warn "Snapshot je z předchozího dne (před <X> hodinami). Souhrn může být zavádějící."

2. **Read effective config** — same as `/work-start` step 1. Stop if missing.

3. **Re-fetch all enabled sources**:

   Same as `/work-start` step 3 (parallel fetch of all enabled and available sources), BUT also include completed items for the "completed today" computation:

   - **Todoist** (in addition to open tasks): call `mcp__claude_ai_Todoist__find-completed-tasks` with `{ "since": "<midnight today UTC>" }`. Get midnight via:
     ```bash
     date -u -j -v0H -v0M -v0S +%Y-%m-%dT%H:%M:%SZ  # macOS, today UTC midnight
     # Linux: date -u -d 'today 00:00' +%Y-%m-%dT%H:%M:%SZ
     ```

   - **GitHub**: in addition to open queries, run:
     - `mcp__github__search_issues` with `{ "q": "is:closed is:issue assignee:<username> closed:>=<today UTC>" }`
     - `mcp__github__search_pull_requests` with `{ "q": "is:closed author:<username> closed:>=<today UTC>" }`

   - **ClickUp**: ClickUp `clickup_filter_tasks` can also filter by status — call once with `status=closed, date_updated_gt=<midnight epoch ms>`. (Refer to the MCP tool's schema for exact arg names.)

   - **Calendar**: skip (events don't have a "completed today" sense).

   Build:
   - `current_open` — normalized open items (same as /work-start)
   - `completed_today` — normalized completed items closed/completed today
````

- [ ] **Step 2: Commit**

```bash
cd /Users/krato/IdeaProjects/github.com/kratocz/claude-plugins
git add plugins/work/skills/end/SKILL.md
git commit -m "feat(work-end): implement snapshot/config read and full re-fetch

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 23: Implement step 4 (compute) and step 5 (render)

**Files:**
- Modify: `plugins/work/skills/end/SKILL.md`

- [ ] **Step 1: Replace step 4 and step 5 one-liners**

Find both and replace:

````markdown
4. **Compute completed / carry-over / new-unhandled**:

   - **`completed_total`** = `completed_today` (all items that finished today, regardless of whether they were in the morning briefing)
   - **`completed_from_briefing`** = subset of `completed_today` whose `id` matches a snapshot item
   - **`carry_over`** = snapshot items whose `id` is in `current_open` (still open at end of day)
   - **`new_unhandled`** = items in `current_open` whose `id` is NOT in snapshot AND NOT in `completed_today`

   Sort each list by score descending (re-score `carry_over` and `new_unhandled` using current data via /work-start scoring; for `completed_today` use the score they had in the snapshot if available, else 0).

5. **Render summary** in the configured language (Czech default):

   ```markdown
   ## 📊 Souhrn dne — <today's date>

   Doba od /work-start: **<X>h <Y>min**

   ### ✅ Dokončeno: <N> celkem (<M> z ranního briefingu)

   1. **<title>** — <source>
   ...

   ### 📝 Přechází na zítra: <N>

   1. **<title>** — <source>, score <N>
   ...

   ### ⚠️ Nové během dne, neřešeno: <N>

   1. **<title>** — <source>, score <N>, dorazilo <H>h zpět
   ...

   <Warnings if any>
   ```

   If `completed_total == 0` and `carry_over == 0` and `new_unhandled == 0`: render "Žádná aktivita dnes. Vše uzavřeno před snapshotem."
````

- [ ] **Step 2: Commit**

```bash
cd /Users/krato/IdeaProjects/github.com/kratocz/claude-plugins
git add plugins/work/skills/end/SKILL.md
git commit -m "feat(work-end): implement compute and render steps

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 24: Implement step 6 (save to session log) and edge cases

**Files:**
- Modify: `plugins/work/skills/end/SKILL.md`

- [ ] **Step 1: Replace step 6 one-liner and add edge cases**

Find step 6 and replace:

````markdown
6. **Optionally save to session log**:

   Check if the `session-log` plugin is installed by reading `~/.claude/plugins/session-log/config.json`. If it doesn't exist, skip this step silently.

   If it exists:
   - Read the config to find the session log directory (`session_log_dir` field, or default `~/Documents/claude-sessions/`).
   - Ask via AskUserQuestion: "Uložit dnešní souhrn do session logu?" Options:
     - "Ano (append k dnešnímu logu)"
     - "Ne, jen vypsat"
   - If "Ano":
     - Determine today's log file name (convention: `<dir>/YYYY-MM-DD.md`).
     - Use the Read tool to check if it exists. If yes, use the Write tool only if you can append (which Write doesn't support directly — use Bash `cat >> file`):
       ```bash
       printf '\n\n## work-end summary\n\n%s\n' '<rendered summary above>' >> '<path>'
       ```
     - If the file doesn't exist, use Write to create it with just the summary.

   Confirm: "Uloženo do <path>."
````

After step 6, append:

````markdown
## Edge cases

- **No sources fetched successfully**: render only "Žádný zdroj nedostupný. Souhrn dne nelze sestavit. Zkontroluj MCP servery." Skip lists.
- **All snapshot items still open, nothing completed today**: render with `completed_total = 0` section saying "(žádné položky dokončeny dnes)", and full `carry_over` list.
- **Snapshot from prior day**: render but with warning about age. Don't try to "extend" the snapshot range — be honest that the comparison baseline is stale.
````

- [ ] **Step 2: Manual verification**

1. Run `/work-start` (in the morning).
2. Complete one of the items during the day.
3. Run `/work-end` at end of day.

Expected: completed item appears in ✅, still-open items in 📝, anything new (e.g. a new PR review request) in ⚠️. Total time displayed correctly.

- [ ] **Step 3: Commit**

```bash
cd /Users/krato/IdeaProjects/github.com/kratocz/claude-plugins
git add plugins/work/skills/end/SKILL.md
git commit -m "feat(work-end): implement session log save and edge cases

Completes /work-end. Manually verified.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Phase 5: Marketplace listing (Task 25)

---

### Task 25: Add `work` to marketplace.json and README

**Files:**
- Modify: `.claude-plugin/marketplace.json` (prepend entry to `plugins` array)
- Modify: `README.md` (prepend row to plugin table)

- [ ] **Step 1: Add marketplace entry**

Open `.claude-plugin/marketplace.json` and prepend the following object to the `plugins` array (so it appears first):

```json
{
  "name": "work",
  "source": "./plugins/work",
  "description": "Morning briefing across task trackers and code review queues — pulls Todoist/ClickUp/GitHub/Calendar into a single scored todo list",
  "version": "0.1.0",
  "added": "2026-06-03"
}
```

- [ ] **Step 2: Update top-level README**

Open `README.md` at the repo root. Find the **Available plugins** table and prepend a new row immediately after the header row (so `work` appears first since it's newest):

```
| [work](plugins/work) | Morning briefing across task trackers and code review queues | 0.1.0 | 2026-06-03 |
```

(Verify the exact column structure by reading the existing table — adjust the row to match if columns differ.)

- [ ] **Step 3: Verify marketplace JSON is valid**

Run:
```bash
cd /Users/krato/IdeaProjects/github.com/kratocz/claude-plugins
jq . .claude-plugin/marketplace.json > /dev/null && echo "OK" || echo "INVALID JSON"
```

Expected: `OK`.

- [ ] **Step 4: Commit**

```bash
cd /Users/krato/IdeaProjects/github.com/kratocz/claude-plugins
git add .claude-plugin/marketplace.json README.md
git commit -m "$(cat <<'EOF'
feat(marketplace): add work plugin

Lists the new work plugin in marketplace catalog and README plugin table.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Done

All four skills implemented and verified end-to-end. Plugin is installable from the marketplace.

**Suggested follow-up (not in this plan):**
- Add `--fresh` argument actually doing something (current v1 is no-op).
- Add `gh` CLI fallback when GitHub MCP unavailable.
- Add JIRA source.
- Daily archive of snapshots for trend analysis.
- Single-instance lock to prevent parallel /work-start overwrites.
