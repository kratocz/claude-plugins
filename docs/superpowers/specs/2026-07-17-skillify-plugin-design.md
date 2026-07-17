# Design: `skillify` plugin — session → skill proposals

- **Date:** 2026-07-17
- **Status:** Approved (design phase)
- **Decision:** New standalone in-repo plugin `plugins/skillify/`; `retro` delegates
  Area E apply to it (retro 0.2.0 → 0.3.0)

## Purpose

A `/skillify` skill that analyzes the work done in a session (and, on demand, past
session transcripts) for repeatable workflows worth capturing as a skill, proposes
candidates interactively, and creates the approved ones. It is the focused,
on-demand counterpart to `/retro`'s Area E — runnable any time during work, not
just as an end-of-session retrospective.

Two kinds of findings (criteria shared with retro Area E):

- **New skill** — the session contains a repeated or clearly repeatable
  multi-prompt workflow (the user drove the same shape of work more than once, or
  said they do this often). A workflow the user iteratively corrected until it
  worked also qualifies — the corrected final form is what is worth capturing.
- **Improved skill** — a skill invoked this session misfired or needed manual
  correction → propose a concrete edit to its `SKILL.md`.

## Why a standalone plugin

Claude Code core, Superpowers, and the official skill-creator plugin have no
"analyze session → propose skills" command (verified 2026-07-16 against current
docs and repos). hookify implements exactly this mechanism but for hooks; `/retro`
covers it only as one of eight areas in a heavyweight end-of-session flow. A
small, focused plugin fills the gap, can run any time, and retro can delegate to
it — the kratocz marketplace favors small focused plugins.

## Invocation modes

| Invocation | Behavior |
|---|---|
| `/skillify` | Inline analysis of the current session: the main agent reviews its own conversation context — full fidelity including user corrections, no disk reads |
| `/skillify deep [N]` | Inline analysis PLUS deep scan: one subagent reads the last N (default 10) transcripts of past sessions of this project |
| `/skillify <description>` | Targeted mode: skip discovery, shape a candidate directly from the description. Also the entry point for retro delegation |

## Structure

```
plugins/skillify/
├── .claude-plugin/plugin.json    # name: skillify, version: 0.1.0
├── skills/
│   └── skillify/
│       └── SKILL.md              # single skill → /skillify
└── README.md
```

Skills-only plugin (house style, like retro): no commands, agents, or hooks.
`SKILL.md` is written in English with an instruction to respond in the language
the user has been using in the session. `allowed-tools`: Read, Write, Edit, Glob,
Grep, Bash, Agent, Task, AskUserQuestion, Skill — listing **both Agent and Task**
per the repo convention (the dispatch tool is named differently across Claude
Code versions; unknown names are ignored).

Marketplace integration per repo CLAUDE.md: entry in
`.claude-plugin/marketplace.json` (`"source": "./plugins/skillify"`, version
`0.1.0`, added `2026-07-17`) and a new top row in README's **Available plugins**
table.

## Skill flow

### Phase 0 — context

- Parse arguments → mode (default / deep N / targeted).
- Map the existing skill environment to avoid duplicate proposals: project
  skills (Glob `.claude/skills/*/SKILL.md`) and the skills visible in the
  available-skills system context (installed plugins).

### Phase 1 — analysis (read-only)

- **Inline:** review the current conversation for the two finding kinds.
- **Deep (deep mode only):** dispatch ONE subagent (Explore type) over the N
  most recently modified files in `~/.claude/projects/<project-slug>/*.jsonl`
  (filenames are session UUIDs without timestamps, so **file modification time,
  newest first** is the ordering key), excluding the currently running
  session's transcript — its session UUID is available in the environment
  (e.g. in the scratchpad directory path); if it cannot be identified, include
  it and rely on the merge step to dedupe overlap with the inline findings.
  Subagent instructions:
  - read primarily user messages and skill/tool invocations; grep-first
    strategy — transcript files can be huge;
  - ignore `<system-reminder>` blocks entirely;
  - look for workflow shapes recurring across sessions;
  - return ONLY a compact structured list — workflow, sessions seen in,
    ≤1-line evidence each — never transcript dumps.
- Merge and dedupe candidates; a cross-session recurrence is a stronger signal
  than a within-session one. Drop candidates already covered by an existing
  skill — mention the existing skill instead of proposing a duplicate.
- Each candidate records: proposed name, what it automates, trigger phrases,
  rough steps, placement recommendation, evidence.

### Phase 2 — interactive approval and creation

- Present numbered candidates; approve via AskUserQuestion (multiSelect,
  batches of ≤4 options). In targeted mode the passed description is the single
  candidate and this approval question is skipped — the caller (the user
  typing the description, or retro delegating an approved item) already chose
  to pursue it; Phase 2 starts at the placement decision.
- **New skill — placement** (recommendation stated, user chooses; rule shared
  with retro):
  - *Project-specific workflow* → scaffold `.claude/skills/<name>/SKILL.md`:
    frontmatter (`name`, `description` with trigger phrases) and a step-by-step
    body distilled from the session evidence. If `superpowers:writing-skills`
    is available, invoke it as quality guidance for the writing; otherwise use
    a built-in minimal template. No hard dependency on either.
  - *Generally useful workflow* → recommend a plugin in the user's marketplace.
    If the current working directory IS the marketplace repo, follow its
    CLAUDE.md "Adding a new plugin" procedure directly; otherwise print the
    instructions (and mention `plugin-dev:create-plugin` if installed).
- **Improved skill:** for marketplace-installed skills, locate the plugin's
  **source repo** — never edit `~/.claude/plugins/cache/...`; verify the cache
  copy matches the source before proposing the edit. Show the current text and
  the replacement as quotes; apply on approval; mention that the change reaches
  the cache only on reinstall / version bump.

### Phase 3 — summary

Report created / edited / skipped, one line each. If repo files changed, offer —
never auto-run — a git commit scoped to the touched paths.

## Retro integration (retro 0.2.0 → 0.3.0)

Mirrors the existing Area F → hookify pattern: **detection stays in retro**
(Area E analyzes the session as it does today — retro already has the
conversation in context), **apply delegates** — if the skillify plugin is
installed (its skill appears in the available-skills list), invoke
`skillify:skillify` with the candidate's description (targeted mode) instead of
retro's own scaffold logic; otherwise proceed as today. Placement, scaffolding,
and source-repo rules then live in one place. Minor bump, release `retro-v0.3.0`.

## Safety rules and edge cases

- No candidates → honest empty result; never invent findings.
- Deep scan with no or unreadable transcripts → report it and continue
  inline-only. The subagent reads at most N transcript files (the requested
  count, default 10) — never the whole directory.
- Re-run in the same session → re-check `.claude/skills/` and do not re-propose
  candidates already created or rejected earlier in the session.
- Never auto-commit. Never write outside the current project without explicit
  approval (marketplace-repo writes only when cwd is that repo, via its
  documented procedure).
- Interactive by default: nothing is created without the user approving the
  specific candidate.

## Verification

Manual, like retro: run `/skillify` on a live session with real history (the
implementation session of this very plugin is a good candidate), `/skillify deep`
on this project, and `/retro` with skillify installed to verify the delegation.
No automated tests — a skills-only plugin is prose.

## Release

Per repo convention (three-place version sync, per-plugin lightweight tags,
explicit release notes):

- `skillify-v0.1.0` — new plugin.
- `retro-v0.3.0` — Area E apply delegation (minor).
