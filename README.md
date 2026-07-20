# claude-plugins

Claude Code plugin marketplace by [Petr Kratochvíl](https://krato.cz/).

## Add this marketplace

```
/plugin marketplace add kratocz/claude-plugins
```

## Available plugins

*Newest first — sorted by date added.*

| Plugin | Linux | macOS | Windows | Description | Added |
|---|:---:|:---:|:---:|---|---|
| [skillify](./plugins/skillify) | 🟢 | 🟢 | 🟢 | Analyze this session (and, on demand, past transcripts) for repeatable workflows worth capturing as a skill, propose candidates, and create the approved ones | 2026-07-17 |
| [kodex](./plugins/kodex) | 🟢 | 🟢 | 🟡 | Thinking codex for AI agents — 15 rules + pre-delivery self-test injected into every session (epistemics, decisions, output, learning loop) | 2026-07-10 |
| [dependency-diagrams](./plugins/dependency-diagrams) | 🟢 | 🟢 | 🟡 | Generate task-dependency diagrams (full graph, group overview, per-cluster details) from any tracker — ClickUp, GitHub, Jira, or a CSV/JSON export — as draw.io + SVG/PNG dated snapshots | 2026-07-10 |
| [retro](./plugins/retro) | 🟢 | 🟢 | 🟢 | Session retrospective — migrate memory facts to AGENTS.md, capture session learnings, audit docs freshness, propose skills/hooks/permission updates | 2026-06-10 |
| [claude-statusline-state](./plugins/claude-statusline-state) | 🟢 | 🟢 | 🔴 | Publish per-session Claude Code lifecycle state (idle/working/waiting) to a file, ready to render as an extra line in your statusline | 2026-06-09 |
| [work](./plugins/work) | 🟢 | 🟢 | 🟢 | Morning briefing across task trackers and code review queues — pulls Todoist/ClickUp/GitHub/Calendar into a single scored todo list | 2026-06-03 |
| [dockerize](./plugins/dockerize) | 🟢 | 🟢 | 🟢 | Add Docker to a project: multi-stage Dockerfile, .dockerignore, optional docker-compose.yml with detected services | 2026-06-01 |
| [launchpad-fix](./plugins/launchpad-fix) | 🔴 | 🟢 | 🔴 | Re-register macOS apps missing from Launchpad with Launch Services and reset the Dock | 2026-06-01 |
| [semver-release](./plugins/semver-release) | 🟢 | 🟢 | 🟢 | Cut a semver release from Conventional Commits: bump version, update CHANGELOG.md, tag, push, optional GitHub release | 2026-06-01 |
| [conventional-commit](./plugins/conventional-commit) | 🟢 | 🟢 | 🟢 | Create a Conventional Commits message from the staged diff (type, optional scope, subject, body for non-trivial diffs) | 2026-06-01 |
| [project-init](./plugins/project-init) | 🟢 | 🟢 | 🟢 | Bootstrap a new project: .gitignore, AGENTS.md, CLAUDE.md, README.md, initial commit, optional GitHub remote | 2026-05-30 |
| [code-review](./plugins/code-review) | 🟢 | 🟢 | 🟢 | Structured code review with severity codes (Cx/Mx/mx/nx), per-round findings files, and GitHub posting | 2026-05-30 |
| [tmux-hooks](./plugins/tmux-hooks) | 🟢 | 🟢 | 🔴 | Set tmux pane title to reflect Claude Code lifecycle state | 2026-05-16 |
| [mikrotik-audit](./plugins/mikrotik-audit) | 🟢 | 🟢 | 🔴 | Read-only security audit for Mikrotik RouterOS devices via SSH | 2026-04-20 |
| [session-log](./plugins/session-log) | 🟢 | 🟢 | 🔴 | Save a structured summary of each Claude Code session to a markdown file | 2026-04-19 |
| [session-tracker](./plugins/session-tracker) | 🟢 | 🟢 | 🟡 | Start and stop time tracking sessions in Toggl Track or Clockify | 2026-04-09 |
| [second-opinion](./plugins/second-opinion) | 🟢 | 🟢 | 🟡 | Get a second opinion from Gemini or GPT on any important topic or decision | 2026-04-04 |
| [desktop-notify](./plugins/desktop-notify) | 🟢 | 🟢 | 🔴 | Desktop notifications when Claude Code waits for your response or approval | 2026-03-23 |

*🟢 fully supported · 🟡 partial support or extra setup required · 🔴 not supported*

## Install a plugin

```
/plugin install skillify@kratocz
/plugin install kodex@kratocz
/plugin install dependency-diagrams@kratocz
/plugin install retro@kratocz
/plugin install claude-statusline-state@kratocz
/plugin install work@kratocz
/plugin install dockerize@kratocz
/plugin install launchpad-fix@kratocz
/plugin install semver-release@kratocz
/plugin install conventional-commit@kratocz
/plugin install project-init@kratocz
/plugin install code-review@kratocz
/plugin install tmux-hooks@kratocz
/plugin install mikrotik-audit@kratocz
/plugin install session-log@kratocz
/plugin install session-tracker@kratocz
/plugin install second-opinion@kratocz
/plugin install desktop-notify@kratocz
```
