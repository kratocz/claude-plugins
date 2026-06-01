# CLAUDE.md

## Plugin overview

`session-tracker` is a Claude Code plugin for tracking work sessions in Toggl Track or Clockify.

## Structure

```
session-tracker/
├── .claude-plugin/
│   └── plugin.json        ← plugin manifest
├── skills/
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

## Adding a new backend

1. Add a section to `config.json` (e.g. `"harvest": { ... }`)
2. Add `backend: "harvest"` handling to each skill
3. Bump version in `plugin.json`

## Release workflow

Commit messages are the single source of truth for release content. Tags are lightweight pointers; GitHub Release notes are auto-generated from commits since the previous tag.

1. Bump `version` in `plugin.json` **and** in every skill's frontmatter (keep them in sync).
2. Commit the bump. Use a clear `feat:` / `fix:` / `chore:` subject and a bulleted body describing user-visible changes — this body is what ends up surfaced in the release notes and in `git log`.
3. Create a lightweight tag: `git tag vX.Y.Z` (no `-a`, no `-m` — the commit carries the message).
4. Push: `git push origin main && git push origin vX.Y.Z`.
5. Create the GitHub Release with auto-generated notes:
   ```bash
   gh release create vX.Y.Z --title "vX.Y.Z — <short summary>" --generate-notes
   ```
   `--generate-notes` populates the body from commits (and PRs, if any) since the previous tag. No manual copy-pasting from the commit message.

SemVer: patch for hardening/metadata, minor for new config fields or behavior, major for breaking changes (config schema changes that break existing configs).
