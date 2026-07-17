# `skillify` Plugin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a new in-repo plugin `skillify` with a single `/skillify` skill that analyzes the current session (deep mode: past session transcripts via a subagent) for repeatable workflows worth capturing as a skill, proposes candidates interactively, and creates the approved ones — then wire `/retro`'s Area E to delegate its apply step to it.

**Architecture:** Skills-only plugin at `plugins/skillify/` following the repo's standard structure (`.claude-plugin/plugin.json`, `skills/skillify/SKILL.md`, `README.md`), registered in `.claude-plugin/marketplace.json` and the root `README.md`. All behavior lives in one SKILL.md; the deep-scan of past transcripts is delegated to an Explore subagent. Retro (0.2.0 → 0.3.0) gains a delegation lead-in in Area E that hands approved skill candidates to `skillify:skillify` when installed, mirroring the existing Area F → hookify pattern.

**Tech Stack:** Claude Code plugin (markdown skill + JSON manifests). No executable code; verification via `jq`, `grep`, `awk`, and the `plugin-dev:plugin-validator` agent.

**Spec:** `docs/superpowers/specs/2026-07-17-skillify-plugin-design.md`

## Global Constraints

- **Skills-only, house style.** No `commands/`, `agents/`, or `hooks/` dirs; the slash trigger is the skill name.
- **`allowed-tools` lists both `Agent` and `Task`** (dispatch tool differs across Claude Code versions; unknown names are ignored).
- **SKILL.md is written in English** with an explicit "respond in the language the user has been using" instruction.
- **New plugin registration is three-fold:** entry in `.claude-plugin/marketplace.json` (`"source": "./plugins/skillify"`), a new top row in the root `README.md` **Available plugins** table, and a new top line in the **Install a plugin** block. Newest first — skillify (`added: 2026-07-17`) sorts above `kodex` (2026-07-10).
- **Version sync in three places** when bumping retro: `plugins/retro/.claude-plugin/plugin.json`, the retro skill's frontmatter `version:`, and the retro entry in `marketplace.json` — all to `0.3.0`.
- **Never auto-commit** from within the skill; it offers a commit, the user decides.
- **Release** uses per-plugin lightweight tags and explicit release notes (never `--generate-notes` in this monorepo).

---

### Task 1: skillify plugin manifest

**Files:**
- Create: `plugins/skillify/.claude-plugin/plugin.json`

- [ ] **Step 1: Create the manifest**

Write `plugins/skillify/.claude-plugin/plugin.json` with exactly:

```json
{
  "name": "skillify",
  "version": "0.1.0",
  "description": "Analyze this session (and, on demand, past transcripts) for repeatable workflows worth capturing as a skill, propose candidates, and create the approved ones",
  "author": { "name": "Petr Kratochvíl", "url": "https://krato.cz/" }
}
```

- [ ] **Step 2: Verify it is valid JSON**

Run: `jq . plugins/skillify/.claude-plugin/plugin.json`
Expected: pretty-printed JSON, exit code 0.

- [ ] **Step 3: Commit**

```bash
git add plugins/skillify/.claude-plugin/plugin.json
git commit -m "feat(skillify): add plugin manifest"
```

---

### Task 2: The `/skillify` skill

**Files:**
- Create: `plugins/skillify/skills/skillify/SKILL.md`

- [ ] **Step 1: Create SKILL.md**

Write `plugins/skillify/skills/skillify/SKILL.md` with exactly this content:

````markdown
---
name: skillify
description: Analyze this session (and, on demand, past session transcripts) for repeatable workflows worth capturing as a skill, propose candidates, and create the approved ones. Use when the user says "/skillify", "skillify", "make a skill from this", "turn this into a skill", "co by z tohohle šlo udělat skill", "udělej z toho skill", or wants to capture a workflow as a reusable skill.
version: 0.1.0
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent, Task, AskUserQuestion, Skill
---

# Skillify

Analyze the work done in this session for repeatable workflows worth capturing
as a skill, propose candidates, and create the approved ones. The on-demand,
runnable-any-time counterpart to `/retro`'s skills area.

Respond in the language the user has been using in this session.

Hard rules, valid for the whole skill:

- **Interactive by default.** Nothing is created or edited without the user
  approving the specific candidate (Phase 2). Analysis (Phase 1) is read-only.
- **Never invent findings.** A session with no repeatable workflow legitimately
  produces an empty result — say so honestly, do not pad.
- **No duplicates.** Never propose a skill equivalent to one that already
  exists; mention the existing skill instead.
- **Never commit automatically.** Offer a commit at the end; the user decides.
- **Never write outside the current project** without explicit approval.

## Modes

Parse the invocation argument:

- **no argument** → *default*: analyze the current session inline.
- **`deep [N]`** → *deep*: inline analysis PLUS a subagent scan of the last N
  (default 10) past session transcripts of this project.
- **any other text** → *targeted*: treat the text as a description of one
  workflow to capture; skip discovery and go straight to shaping that single
  candidate (Phase 2, starting at the placement decision). This is also how
  `/retro` delegates an approved skill candidate.

## Phase 0 — Context

1. Parse the argument into mode (default / deep N / targeted description).
2. Map the existing skill environment to avoid duplicate proposals:
   - project skills: Glob `.claude/skills/*/SKILL.md`
   - installed-plugin skills: the skills listed in your available-skills
     system context.

## Phase 1 — Analysis (read-only)

Skip this phase entirely in targeted mode (the candidate is given).

Look for two kinds of findings:

- **New skill** — a repeated or clearly repeatable multi-prompt workflow: the
  user drove you through the same shape of work more than once, or said they do
  it often. A workflow the user iteratively corrected until it worked also
  counts — the corrected final form is what to capture.
- **Improved skill** — a skill invoked this session misfired or needed manual
  correction.

**Inline (all modes except targeted):** review the current conversation for
both kinds.

**Deep scan (deep mode only):** dispatch ONE subagent (type `Explore`) over the
project's past transcripts. First resolve the transcript directory and the
running session's own transcript:

- The scratchpad directory path in your system prompt has the form
  `.../<project-slug>/<session-uuid>/scratchpad`. Its second-to-last component
  is the running session's UUID; the component before that is the project slug.
- The transcript directory is `~/.claude/projects/<project-slug>/`; transcripts
  are its `*.jsonl` files. Filenames are session UUIDs with no embedded date.
- List newest-first by modification time: `ls -t ~/.claude/projects/<slug>/*.jsonl`.
- Exclude `<session-uuid>.jsonl` (the running session). If you cannot resolve
  the UUID, include it — the merge step dedupes the overlap with the inline
  findings.

Take at most N paths (newest first, default 10) and pass them to the subagent
with these instructions:

> Read the given Claude Code transcript files (JSONL). For each, focus on the
> user messages and the skill/tool invocations — grep first, these files can be
> huge. **Ignore `<system-reminder>` blocks entirely** — they are injected
> context, not the user's or the assistant's words. Identify workflow shapes
> that recur across sessions (the same kind of multi-step task driven more than
> once). Return ONLY a compact list: for each workflow, a one-line name, which
> sessions it appears in, and a ≤1-line piece of evidence. Return no transcript
> excerpts beyond those one-line evidences.

Merge the inline and deep findings. A workflow recurring across sessions is a
stronger signal than one seen once. Drop any candidate already covered by an
existing skill (from Phase 0) — mention the existing skill instead.

For each surviving candidate, record: proposed name, what it automates, trigger
phrases, rough steps, a placement recommendation, and the evidence.

## Phase 2 — Interactive approval and creation

**Approval (skip in targeted mode — the single candidate is already chosen):**
show the numbered candidates, then use AskUserQuestion (`multiSelect: true`,
max 4 options per question — batch into several questions if there are more).
Each option label is the candidate name; the description states what the skill
would do and where it would live.

For each approved **new skill**, decide placement (state your recommendation,
let the user choose):

- **Project-specific workflow** → scaffold `.claude/skills/<name>/SKILL.md` in
  this project. If `superpowers:writing-skills` is available, invoke it as
  guidance for writing a quality skill; otherwise write the file directly with:
  - frontmatter: `name`, and a `description` that is a one-line summary ending
    with the trigger phrases (the words a user would say to invoke it),
  - a body of concrete, step-by-step instructions distilled from what the
    session actually did — not a vague outline.
- **Generally useful workflow** → recommend creating a plugin in the user's
  marketplace. If the current working directory is that marketplace repo,
  follow its `CLAUDE.md` "Adding a new plugin" procedure. Otherwise print the
  steps (and mention `plugin-dev:create-plugin` if it is installed) — do not
  write outside the current project.

For each approved **improved skill**: quote the current `SKILL.md` text and the
replacement. For a skill installed from a marketplace cache, edit the plugin's
**source repo**, never the cache:

- the cache lives at `~/.claude/plugins/cache/<owner>/<plugin>/<version>/...`;
- find the working clone (e.g. under the user's projects directory) and confirm
  the source `SKILL.md` matches the cache copy before proposing the edit;
- after editing the source, note that the change reaches the cache only on
  reinstall / version bump.

Apply each approved item immediately, in list order. If an apply step fails,
report it, leave the item unapplied, and continue with the rest.

## Phase 3 — Summary

Report per candidate: created / edited / skipped (one line each). Then:

- If repo files changed (new project skills under `.claude/skills/`, or an
  edited source `SKILL.md`): list them and offer — do not run — a commit.
- If nothing was created, say so plainly.

## Edge cases

- **No candidates** → honest "nothing worth capturing as a skill from this
  session"; never invent one.
- **Deep scan, no or unreadable transcripts** → report it and continue with the
  inline findings only. Read at most N files (default 10), never the whole
  directory.
- **Equivalent skill already exists** → mention it, do not propose a duplicate.
- **Re-run in the same session** → re-check `.claude/skills/` and do not
  re-propose candidates already created or rejected earlier in the session.
````

- [ ] **Step 2: Verify frontmatter structure**

Run: `awk '/^---$/{c++} END{print c}' plugins/skillify/skills/skillify/SKILL.md`
Expected: `2` (exactly two `---` fences).

Run: `grep -c '^name: skillify$' plugins/skillify/skills/skillify/SKILL.md`
Expected: `1`

Run: `grep -c 'Agent, Task' plugins/skillify/skills/skillify/SKILL.md`
Expected: `1` (both dispatch names present in `allowed-tools`).

- [ ] **Step 3: Commit**

```bash
git add plugins/skillify/skills/skillify/SKILL.md
git commit -m "feat(skillify): add skillify skill"
```

---

### Task 3: skillify plugin README

**Files:**
- Create: `plugins/skillify/README.md`

- [ ] **Step 1: Create README.md**

Write `plugins/skillify/README.md` with exactly:

````markdown
# skillify

A Claude Code plugin that turns a repeatable workflow you just did into a
reusable skill. Runnable any time during a session — the on-demand counterpart
to `/retro`'s skills area.

## Install

```
/plugin install skillify@kratocz
```

## Usage

```
/skillify
```

| Invocation | What it does |
|---|---|
| `/skillify` | Analyzes the current session for repeatable workflows and proposes skills |
| `/skillify deep [N]` | Also scans the last N (default 10) past session transcripts of this project via a subagent |
| `/skillify <description>` | Targeted: shapes one skill from your description, skipping discovery |

Nothing is created without your approval. For each approved candidate the skill
decides placement — a project-specific workflow is scaffolded into
`.claude/skills/`, a generally useful one is recommended as a marketplace
plugin. It can also propose edits to an existing skill that misfired (editing
the plugin's source repo, never the installed cache).

## Conventions

- Never proposes a skill equivalent to one that already exists.
- A workflow recurring across sessions is a stronger signal than one seen once.
- Never writes outside the current project without approval, and never commits
  — it offers a commit at the end.
````

- [ ] **Step 2: Commit**

```bash
git add plugins/skillify/README.md
git commit -m "feat(skillify): add plugin README"
```

---

### Task 4: Marketplace and root README registration

**Files:**
- Modify: `.claude-plugin/marketplace.json` (insert as first element of the `plugins` array, right after the `"plugins": [` line)
- Modify: `README.md` (new first data row of the Available plugins table; new first line of the Install block)

- [ ] **Step 1: Add marketplace entry**

Insert as the FIRST element of the `plugins` array in `.claude-plugin/marketplace.json` (newest first — before the `kodex` entry):

```json
{
  "name": "skillify",
  "source": "./plugins/skillify",
  "description": "Analyze this session (and, on demand, past transcripts) for repeatable workflows worth capturing as a skill, propose candidates, and create the approved ones",
  "version": "0.1.0",
  "added": "2026-07-17"
},
```

- [ ] **Step 2: Verify marketplace JSON**

Run: `jq -r '.plugins[0].name' .claude-plugin/marketplace.json`
Expected: `skillify`

Run: `jq '.plugins | length' .claude-plugin/marketplace.json`
Expected: `18`

- [ ] **Step 3: Add root README table row**

In `README.md`, insert this row as the FIRST data row of the **Available plugins** table (directly under the `|---|:---:|:---:|:---:|---|---|` separator, above the `kodex` row):

```markdown
| [skillify](./plugins/skillify) | 🟢 | 🟢 | 🟢 | Analyze this session (and, on demand, past transcripts) for repeatable workflows worth capturing as a skill, propose candidates, and create the approved ones | 2026-07-17 |
```

- [ ] **Step 4: Add install command**

In `README.md`, section **Install a plugin**, add as the FIRST line inside the code block (above `/plugin install kodex@kratocz`):

```
/plugin install skillify@kratocz
```

- [ ] **Step 5: Verify README edits**

Run: `grep -n 'skillify' README.md`
Expected: exactly two hits — one table row and one install line, both above their `kodex` counterparts.

- [ ] **Step 6: Commit**

```bash
git add .claude-plugin/marketplace.json README.md
git commit -m "feat(marketplace): add skillify plugin"
```

---

### Task 5: Wire retro Area E to delegate to skillify (retro 0.3.0)

**Files:**
- Modify: `plugins/retro/skills/retro/SKILL.md` (Area E lead-in + frontmatter `version`)
- Modify: `plugins/retro/.claude-plugin/plugin.json` (`version`)
- Modify: `.claude-plugin/marketplace.json` (retro entry `version`)
- Modify: `plugins/retro/README.md` (Area E table row)

- [ ] **Step 1: Add the delegation lead-in to Area E**

In `plugins/retro/skills/retro/SKILL.md`, find:

```
### E. Skills — new and improved

- **New skill:** the session contains a repeated or clearly repeatable
```

Replace it with:

```
### E. Skills — new and improved

**On apply, delegate to skillify when installed.** If the `skillify` plugin is
available (its skill appears in your available-skills list), hand each approved
skill candidate to it — invoke `skillify:skillify` with a one-line description
of the candidate (its targeted mode); skillify then handles placement,
scaffolding, and the source-repo rules below. If skillify is not installed,
follow the guidance below yourself. Detection during this phase is unchanged
either way.

- **New skill:** the session contains a repeated or clearly repeatable
```

- [ ] **Step 2: Bump the skill frontmatter version**

In `plugins/retro/skills/retro/SKILL.md`, change the frontmatter line:

```
version: 0.2.0
```

to:

```
version: 0.3.0
```

- [ ] **Step 3: Bump plugin.json**

In `plugins/retro/.claude-plugin/plugin.json`, change `"version": "0.2.0"` to `"version": "0.3.0"`.

- [ ] **Step 4: Bump the marketplace entry**

In `.claude-plugin/marketplace.json`, in the `retro` entry, change `"version": "0.2.0"` to `"version": "0.3.0"`.

- [ ] **Step 5: Update the retro README Area E row**

In `plugins/retro/README.md`, find the row:

```markdown
| E | Skills | new skills for repeated multi-prompt workflows; edits to skills that misfired |
```

Replace it with:

```markdown
| E | Skills | new skills for repeated multi-prompt workflows; edits to skills that misfired (uses skillify when installed, otherwise scaffolds directly) |
```

- [ ] **Step 6: Verify the version is in sync across all three places**

Run: `grep -H '^version:' plugins/retro/skills/*/SKILL.md; jq -r '.version' plugins/retro/.claude-plugin/plugin.json; jq -r '.plugins[] | select(.name=="retro") | .version' .claude-plugin/marketplace.json`
Expected: all three report `0.3.0`.

Run: `grep -c 'skillify:skillify' plugins/retro/skills/retro/SKILL.md`
Expected: `1`

- [ ] **Step 7: Commit**

```bash
git add plugins/retro/skills/retro/SKILL.md plugins/retro/.claude-plugin/plugin.json .claude-plugin/marketplace.json plugins/retro/README.md
git commit -m "feat(retro): delegate Area E skill creation to skillify when installed (0.3.0)"
```

---

### Task 6: Validation

**Files:** none created — validation only.

- [ ] **Step 1: Run plugin validator on skillify**

Dispatch the `plugin-dev:plugin-validator` agent with the prompt:
"Validate the plugin at plugins/skillify/ in this repo (manifest, skill frontmatter, structure, marketplace entry in .claude-plugin/marketplace.json). Report any issues found."
Expected: no errors. Fix anything reported and amend the relevant commit.

- [ ] **Step 2: Cross-check spec coverage**

Re-read `docs/superpowers/specs/2026-07-17-skillify-plugin-design.md` and confirm each spec section maps to delivered content:
- Purpose / two finding kinds → Task 2 (Phase 1).
- Invocation modes (default / deep N / targeted) → Task 2 (Modes).
- Structure / skills-only / allowed-tools → Tasks 1–2.
- Skill flow Phases 0–3 → Task 2.
- Retro integration (delegate apply, 0.3.0) → Task 5.
- Safety rules and edge cases → Task 2 (Hard rules + Edge cases).
- Marketplace/README registration → Task 4.
- Release → Task 7.

Fix any gap found before proceeding.

- [ ] **Step 3: Live smoke test (after push, manual)**

After the changes are pushed and the marketplace is updated locally, in a real session:
- run `/skillify` and confirm it produces sensible candidates or an honest empty result;
- run `/skillify deep 5` on this project and confirm the subagent scan runs, respects the file cap, and excludes the running session;
- run `/retro` with skillify installed and confirm Area E delegates to `skillify:skillify` on apply.
This step is manual and happens outside this plan's session.

---

### Task 7: Release (user-driven ship step)

**Files:** none — tagging and GitHub releases only. Run when the user is ready to ship.

Per the repo `CLAUDE.md` "Releasing an in-repo plugin" convention: per-plugin lightweight tags, explicit release notes (never `--generate-notes` in this monorepo).

- [ ] **Step 1: Push main**

```bash
git push origin main
```

- [ ] **Step 2: Tag and release skillify**

```bash
git tag skillify-v0.1.0 && git push origin skillify-v0.1.0
gh release create skillify-v0.1.0 --title "skillify v0.1.0 — session → skill proposals" --notes "- New plugin: /skillify analyzes the current session for repeatable workflows worth capturing as a skill and creates the approved ones.
- deep mode (/skillify deep [N]) scans the last N past session transcripts via a subagent.
- targeted mode (/skillify <description>) shapes a single skill from a description; also the entry point for /retro delegation."
```

- [ ] **Step 3: Tag and release retro 0.3.0**

```bash
git tag retro-v0.3.0 && git push origin retro-v0.3.0
gh release create retro-v0.3.0 --title "retro v0.3.0 — Area E delegates to skillify" --notes "- Area E (Skills) now hands approved skill candidates to the skillify plugin when it is installed, for placement, scaffolding, and source-repo handling; falls back to retro's own logic otherwise."
```
