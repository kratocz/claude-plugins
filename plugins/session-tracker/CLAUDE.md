# CLAUDE.md

## Plugin overview

`session-tracker` is a Claude Code plugin for tracking work sessions in Toggl Track or Clockify.

## Structure

```
session-tracker/
├── .claude-plugin/
│   └── plugin.json        ← plugin manifest
├── skills/
│   ├── log-entry/
│   │   └── SKILL.md       ← /log-entry skill
│   ├── setup-tracker/
│   │   └── SKILL.md       ← /setup-tracker skill
│   ├── start/
│   │   └── SKILL.md       ← /start skill
│   └── stop/
│       └── SKILL.md       ← /stop skill
├── README.md
└── CLAUDE.md
```

## Config file

Skills read/write `~/.claude/plugins/session-tracker/config.json`:

```json
{
  "backend": "toggl",
  "billable": true,
  "language": "en",
  "toggl": {
    "api_key": "...",
    "workspace_id": 1234567,
    "default_project_id": null
  }
}
```

Top-level fields apply regardless of backend. Defaults when missing: `billable` → `true`, `language` → `"en"`. `language` influences Claude-generated text (prompts, confirmations, descriptions derived from a URL title); it is **not** sent to the tracker API.

## Skills

| Skill | Trigger | Description |
|-------|---------|-------------|
| `/setup-tracker` | First run / reconfigure | Interactive setup, writes config |
| `/start [desc]` | Begin tracking | Starts timer via API |
| `/stop` | End tracking | Stops running timer, reports duration |
| `/log-entry [window] [desc]` | Record past work | Creates a completed (retroactive) time entry — no live timer |

## Adding a new backend

1. Add a section to `config.json` (e.g. `"harvest": { ... }`)
2. Add `backend: "harvest"` handling to each skill
3. Bump version in `plugin.json`

## Release workflow

This plugin lives **in-repo** in the `claude-plugins` monorepo, so it follows the
monorepo release convention documented in the root `CLAUDE.md`
("Releasing an in-repo plugin") — **not** a per-repo one. Key points specific to
this plugin:

1. Bump `version` in **three places, kept in sync**: `plugin.json`, every skill's
   frontmatter (`version:` line), and this plugin's entry in the root
   `.claude-plugin/marketplace.json`.
2. Commit the bump with a scoped conventional subject
   (e.g. `feat(session-tracker): … (vX.Y.Z)`) and a bulleted body describing
   user-visible changes; push `main`.
3. Create a **per-plugin lightweight tag** and push it:
   ```bash
   git tag session-tracker-vX.Y.Z && git push origin session-tracker-vX.Y.Z
   ```
4. Create the GitHub Release with **explicit notes** — do **not** use
   `--generate-notes`, which in the monorepo would pull in commits of *other*
   plugins since the previous tag:
   ```bash
   gh release create session-tracker-vX.Y.Z \
     --title "session-tracker vX.Y.Z — <short summary>" \
     --notes "<bulleted user-visible changes>"
   ```

SemVer: patch for hardening/metadata, minor for new config fields or behavior, major for breaking changes (config schema changes that break existing configs).
