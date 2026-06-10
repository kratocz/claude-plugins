---
name: retro
description: Session retrospective — turn this session's learnings into durable improvements. Migrates memory facts to AGENTS.md, captures session learnings, audits project *.md docs for staleness, cleans stale memories, proposes new or improved skills, hooks, and permission allowlist entries. Use when the user says "/retro", "retrospektiva", "udělej retro", or asks to consolidate what was learned in this session.
version: 0.1.0
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent, Task, AskUserQuestion, Skill
---

# Retro

Run a retrospective of the current session and turn its experience into durable
improvements of the agent environment: the project's `AGENTS.md`, persistent
memory, project docs, skills, hooks, and permission settings.

Respond in the language the user has been using in this session.

Hard rules, valid for the whole skill:

- **Interactive by default.** Nothing is changed without the user approving the
  specific item (Phase 2). Analysis (Phase 1) is read-only.
- **AGENTS.md is committed and shared.** Never migrate personal data,
  credentials, tokens, or machine-local facts (absolute paths outside the
  project, home network IPs, private hostnames) into repo files. When in doubt,
  ask.
- **Never invent findings.** An area with nothing to report is skipped
  silently. A short or trivial session may legitimately produce an empty
  retro — say so honestly.
- **Never commit automatically.** Offer a commit at the end; the user decides.

## Phase 0 — Gather context

1. **Resolve the target knowledge file** (where learnings get written):
   - If `AGENTS.md` exists in the project root → that's the target.
   - Else if `CLAUDE.md` exists and contains real content (more than a
     redirect like "See AGENTS.md") → target `CLAUDE.md`.
   - Else ask the user whether to create `AGENTS.md` (minimal skeleton:
     project overview, structure, commands, conventions). If declined, areas
     A and B run in report-only mode (findings shown, nothing written).

2. **Read memory.** Your file-based memory directory (path given in your
   system prompt, `.../projects/<project-slug>/memory/`): read `MEMORY.md`
   and every memory file it indexes. If the directory is missing or empty,
   areas A and D are skipped.

3. **Map the existing agent environment** (used to avoid duplicate proposals):
   - project skills: Glob `.claude/skills/*/SKILL.md`
   - hooks: the `hooks` key in `.claude/settings.json` and
     `.claude/settings.local.json`, plus any hookify rule files
     (Glob `.claude/hookify*` and `.claude/**/hookify*`)
   - permissions: `permissions.allow` in both settings files

## Phase 1 — Analysis (read-only)

Work through areas A–G. Collect candidate items into one numbered list; each
item records: area, one-line title, the exact proposed change (target file +
content), and a one-line rationale. Skip empty areas silently.

### A. Memory → AGENTS.md

For each memory file (excluding `MEMORY.md`): propose migration when **all**
of these hold:

- `metadata.type` is `project` or `feedback` (never `user`); if the field is
  missing, judge from content and ask when unsure whether it is personal,
- the fact is about this project and useful to anyone (human or agent)
  working in the repo — not just to you in this session,
- it contains nothing personal or machine-local,
- equivalent content is not already in the target file (check with Grep).

The proposed change is: add the fact to the appropriate section of the target
file (create the section if needed), then delete the memory file and its
`MEMORY.md` index line.

### B. Session → AGENTS.md

Review the current conversation for non-obvious, durable, project-relevant
learnings: commands that proved correct, conventions clarified by the user,
gotchas discovered while working. Exclude anything one-off, obvious from the
code, or already recorded (in the target file or in a memory proposed in A).

### C. Project docs audit (subagent)

Dispatch ONE subagent (type `Explore`) so doc contents do not fill this
context window. Instruct it to:

- list the project's `*.md` files (exclude `node_modules`, `vendor`, build
  output, and other third-party directories),
- check claims in them against the actual repo state (structure, commands,
  file paths, names),
- return ONLY a compact list of findings — `file:line — claim — why it is
  outdated — suggested fix` — plus a one-line "checked N files" summary,
- return nothing else (no file contents).

In large projects it should prioritize `README.md`, the target knowledge
file, and `docs/`.

### D. Stale memory cleanup

Memories contradicted by the current repo state or by what happened this
session → propose deletion or correction. A memory that merely duplicates the
target knowledge file is also stale → propose deletion.

### E. Skills — new and improved

- **New skill:** the session contains a repeated or clearly repeatable
  multi-prompt workflow (the user drove you through the same shape of work
  more than once, or said they do this often) → propose a skill that does it
  in one invocation. Placement rule: project-specific workflow →
  `.claude/skills/<name>/SKILL.md` in this project; generally useful
  workflow → suggest creating a plugin in the user's marketplace instead.
  State your recommendation, let the user choose.
- **Improved skill:** a skill invoked this session misfired or needed manual
  correction → propose a concrete edit to its `SKILL.md` (quote the current
  text and the replacement). For skills installed from a marketplace cache,
  propose the change as a follow-up task in the plugin's source repo instead
  of editing the cache.

### F. Hooks

The user had to correct or block the same unwanted action more than once this
session → propose a hook that prevents it. On apply: if the hookify plugin is
installed (its skills appear in your available-skills list), invoke
`hookify:hookify` with a description of the rule; otherwise propose the
`hooks` entry for `.claude/settings.json` yourself and apply it with Edit
(create the file with Write if it does not exist).

### G. Permission allowlist

Commands or tools the user approved repeatedly this session → propose
`permissions.allow` entries for the project's `.claude/settings.json` (or
`.claude/settings.local.json` if the user prefers not to commit them — ask
when applying). Mention that `/fewer-permission-prompts` (if available) does a
transcript-wide scan if the user wants more than this session's view.

## Phase 2 — Interactive apply

Present candidate items grouped by area, then approve and apply:

1. Show the full numbered list (titles + one-line rationale each).
2. Per area with items, use AskUserQuestion (`multiSelect: true`, max 4
   options per question — batch into several questions if an area has more).
   Each option label is the item title; the description states exactly what
   will change.
3. Apply each approved item immediately, in list order:
   - Writes to the target knowledge file go first; a memory file is deleted
     **only after** the corresponding write succeeded, and its index line is
     removed from `MEMORY.md` in the same step. Delete memory files with
     Bash `rm` on the exact path read in Phase 0 — never glob-delete.
   - Doc fixes (area C) are applied with Edit, one finding at a time.
   - New project skills are scaffolded as `.claude/skills/<name>/SKILL.md`
     with proper frontmatter (`name`, `description` with trigger phrases) and
     a step-by-step body distilled from what the session actually did.
4. If an apply step fails, report it, leave the item unapplied, and continue
   with the rest.

## Phase 3 — Summary

Report per area: applied / skipped / failed (one line each). Then:

- If repo files changed (target knowledge file, docs, project skills,
  settings): list them and offer — do not run — a commit, suggesting a
  message like `docs: apply retro session learnings`.
- Memory directory changes (deleted/updated memories) are outside the repo;
  list them separately so the user knows what moved.

## Edge cases

- **No target knowledge file and user declined creating one** → areas A and B
  report findings but apply nothing; say where the findings would have gone.
- **Memory directory missing or empty** → skip areas A and D without comment.
- **Trivial session** → an honest "nothing worth persisting from this
  session" is a valid result; do not pad.
- **Re-run in the same session** → before proposing, re-check the target file
  and settings: items applied earlier must not be proposed again.
