# retro

A Claude Code plugin that runs a session retrospective: it turns what
happened in the current session into durable improvements of your agent
environment.

## Install

```
/plugin install retro@kratocz
```

## Usage

At the end of (or anytime during) a session:

```
/retro
```

The skill analyzes seven areas and proposes changes item by item — nothing is
applied without your approval:

| # | Area | What it proposes |
|---|------|------------------|
| A | Memory → AGENTS.md | moves project-relevant facts from Claude's per-project memory into the committed `AGENTS.md` |
| B | Session → AGENTS.md | records non-obvious learnings from the current conversation |
| C | Docs audit | outdated claims in the project's `*.md` files (checked by a subagent, reported as `file:line` with a suggested fix) |
| D | Memory cleanup | deletes or corrects memories contradicted by reality |
| E | Skills | new skills for repeated multi-prompt workflows; edits to skills that misfired |
| F | Hooks | hook rules for repeatedly corrected unwanted actions (delegates to hookify when installed) |
| G | Permissions | allowlist entries for commands you approved repeatedly |

## Conventions

- `AGENTS.md` is treated as the single source of truth (with `CLAUDE.md` as a
  redirect); if your project only has a `CLAUDE.md` with real content, that
  is used instead.
- Personal or machine-local facts never migrate into committed files.
- Memory files are deleted only after the corresponding `AGENTS.md` write
  succeeded.
- The skill never commits — it offers a commit at the end.
