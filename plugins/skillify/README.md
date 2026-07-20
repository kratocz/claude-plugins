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
