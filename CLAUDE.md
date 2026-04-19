# CLAUDE.md

## Plugin overview

`session-log` is a Claude Code plugin that saves a structured markdown summary of each session via the `SessionEnd` hook. No configuration; no interactive setup.

## Structure

```
session-log/
├── .claude-plugin/
│   └── plugin.json           ← plugin manifest
├── hooks/
│   └── hooks.json            ← SessionEnd → scripts/log-session.sh
├── scripts/
│   ├── helpers.sh                ← helpers (extract_goal, extract_files_touched, …)
│   └── log-session.sh        ← hook script
├── skills/
│   └── log-where/
│       └── SKILL.md          ← /log-where skill
├── README.md
├── CLAUDE.md
├── LICENSE                   ← MIT
└── .gitignore
```

## Where logs are written

```
${CLAUDE_PLUGIN_DATA}/logs/<encoded-cwd>/<YYYY-MM-DD>_<session-id-short>.md
```

`${CLAUDE_PLUGIN_DATA}` is Claude Code's official plugin data directory (available since CC 2.1.78, 2026-03-17). It resolves to `~/.claude/plugins/data/<plugin>-<marketplace>/` — for this plugin installed as `session-log@kratocz` that's `~/.claude/plugins/data/session-log-kratocz/`. The marketplace suffix means two plugins named `session-log` from different marketplaces won't collide.

The env var is only documented as guaranteed in hook context. Skills and ad-hoc bash fall back to the computed path (`~/.claude/plugins/data/session-log-kratocz/`).

`<encoded-cwd>` follows the same encoding Claude Code uses for `~/.claude/projects/` — both `/` and `.` in the working directory are replaced with `-` (via `tr './' '--'`). So `/home/user/code/app` → `-home-user-code-app`, `/home/user/.claude/plugins` → `-home-user--claude-plugins`. This makes the logs dir key-compatible with the JSONL dir, and avoids collisions on `basename` alone.

The `session-id-short` is the first 8 chars of the session UUID — enough to disambiguate within a day and still link back to the full JSONL in `~/.claude/projects/<encoded-cwd>/<session_id>.jsonl`.

## Lifetime of data

Data persists across plugin **updates** automatically. On `/plugin uninstall` from the **last scope**, Claude Code wipes the data directory unless `--keep-data` is passed. Document this in user-facing README.

## Hook payload

The `SessionEnd` hook receives this JSON via stdin:

```json
{
  "session_id": "abc123…",
  "transcript_path": "/home/user/.claude/projects/<encoded>/<session>.jsonl",
  "cwd": "/home/user/code/my-app",
  "hook_event_name": "SessionEnd",
  "reason": "prompt_input_exit"
}
```

`scripts/log-session.sh` reads this, parses the JSONL transcript, and writes the summary. The hook runs `async: true` and must never crash loudly — all errors go to STDERR with `exit 0`.

## Summary format

Markdown with YAML frontmatter (see `README.md` for an example). Sections: Goal, Files touched, Git commits, Tool stats, Full transcript link.

## Adding a new section

1. Add an `extract_<thing>` helper to `scripts/helpers.sh` (parsing JSONL via `jq`).
2. Call it from `scripts/log-session.sh` and render a new markdown section.
3. Bump the version in `.claude-plugin/plugin.json`.

## Dependencies

`bash`, `jq`, `date`. No LLM calls — extraction is deterministic and offline.

## Testing the hook manually

```bash
echo '{"session_id":"abc12345","transcript_path":"/path/to/transcript.jsonl","cwd":"/path/to/cwd"}' | \
  bash scripts/log-session.sh
```

Check `~/.claude/plugins/session-log/logs/<basename(cwd)>/` for the output file.
