# Design: `retro` plugin — session retrospective

**Date:** 2026-06-10
**Status:** Approved (design phase)
**Decision:** New standalone in-repo plugin `plugins/retro/` (not part of `work`)

## Purpose

A `/retro` skill that runs a retrospective at the end of (or during) a Claude Code
session and turns session experience into durable improvements of the agent
environment: project `AGENTS.md`, persistent memory, project docs, skills, hooks,
and permission settings.

## Why a standalone plugin

The `work` plugin's domain is the daily work routine across external services
(Todoist, ClickUp, GitHub, Calendar). `retro`'s domain is agent-environment
hygiene — different concern, no shared config or dependencies. The kratocz
marketplace favors small, focused plugins. A later optional integration
(`work:end` offering to run `/retro`) is a possible follow-up, out of scope here.

## Structure

```
plugins/retro/
├── .claude-plugin/plugin.json    # name: retro, version: 0.1.0
├── skills/
│   └── retro/
│       └── SKILL.md              # single skill → /retro
└── README.md
```

Skills-only plugin: no hooks, no custom agents. Subagent work (docs audit) is
dispatched from SKILL.md instructions via the generic Agent tool (Explore type).

Marketplace integration per repo CLAUDE.md: entry in `.claude-plugin/marketplace.json`
(`"source": "./plugins/retro"`, version `0.1.0`, added `2026-06-10`) and a new
top row in the README **Available plugins** table.

## Skill flow

### Phase 0 — gather context

- Resolve the target knowledge file: `AGENTS.md` is the single source of truth
  (kratocz convention; `CLAUDE.md` is a one-line redirect). If only `CLAUDE.md`
  exists with real content, target it. If neither exists, offer to create
  `AGENTS.md` following the `project-init` template.
- Read `MEMORY.md` index and memory files from the project's memory directory
  (`~/.claude/projects/<project-slug>/memory/`).
- Map existing `.claude/skills/`, hookify rules, and `.claude/settings.json`.

### Phase 1 — analysis (7 areas, each yields candidate items)

| # | Area | Source / rule |
|---|------|---------------|
| A | Memory → AGENTS.md | memory files of type `project`/`feedback` relevant to the project; **never** personal (`type: user`) memories |
| B | Session → AGENTS.md | non-obvious learnings from the current conversation worth persisting for all agents |
| C | Project `*.md` audit | subagent (Explore) returns outdated claims as a compact list: file, line, claim, why outdated, suggested fix — never full file contents |
| D | Stale memory cleanup | memories contradicted by current repo state or by the session |
| E | Skills | repeated multi-prompt workflow → propose new skill; a skill that misfired during the session → propose a SKILL.md edit |
| F | Hooks | repeatedly corrected unwanted action → propose a hookify rule (delegate to `hookify:hookify` if installed, else write a plain hook) |
| G | Permission allowlist | commands repeatedly approved in this session → propose `.claude/settings.json` allowlist entries; mention `/fewer-permission-prompts` for a transcript-wide scan |

### Phase 2 — interactive apply

- Present items grouped by area; approve individually (AskUserQuestion with
  multiSelect where an area has multiple items).
- Approved items are applied immediately.
- Memory deletion happens **only after** the corresponding AGENTS.md write
  succeeded, and always includes removing the index line from `MEMORY.md`.

### Phase 3 — summary

Report what changed and what was skipped. Offer (never auto-run) a git commit
for repo changes (AGENTS.md, fixed docs).

## New-skill placement rule

Project-specific workflow → `.claude/skills/` in the project. Generally useful
workflow → offer creating a plugin in the kratocz marketplace (pointing to the
repo CLAUDE.md procedure). The skill always states its recommendation and asks.

## Safety rules and edge cases

- **AGENTS.md is committed and shared.** Never migrate personal data,
  credentials, tokens, or machine-local facts (paths outside the project, home
  network IPs). Such facts stay in memory. Borderline cases: ask.
- **Empty inputs:** missing/empty memory dir silently skips areas A and D; any
  area with no findings is skipped. Never invent items to have something to show.
- **Idempotence:** re-running `/retro` must not duplicate applied entries —
  before proposing an AGENTS.md write, check whether equivalent content exists.
- **No auto-commit.** Repo changes are offered for commit, never committed
  automatically.

## Verification

Manual verification on a live project: run `/retro` in a session with real
history (this repo after implementation is a good candidate — it will have
memory, docs, and approved commands) and check that each area produces sensible
items and that apply works. No automated tests — a skills-only plugin is prose,
not code.

## Out of scope

- `work:end` → `/retro` hand-off (possible follow-up)
- Transcript-wide (multi-session) analysis — `/retro` analyzes the current
  session plus current memory/docs state only
