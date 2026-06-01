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
| [dockerize](https://github.com/kratocz/dockerize) | 🟢 | 🟢 | 🟢 | Add Docker to a project: multi-stage Dockerfile, .dockerignore, optional docker-compose.yml with detected services | 2026-06-01 |
| [launchpad-fix](https://github.com/kratocz/launchpad-fix) | 🔴 | 🟢 | 🔴 | Re-register macOS apps missing from Launchpad with Launch Services and reset the Dock | 2026-06-01 |
| [semver-release](https://github.com/kratocz/semver-release) | 🟢 | 🟢 | 🟢 | Cut a semver release from Conventional Commits: bump version, update CHANGELOG.md, tag, push, optional GitHub release | 2026-06-01 |
| [conventional-commit](https://github.com/kratocz/conventional-commit) | 🟢 | 🟢 | 🟢 | Create a Conventional Commits message from the staged diff (type, optional scope, subject, body for non-trivial diffs) | 2026-06-01 |
| [project-init](https://github.com/kratocz/project-init) | 🟢 | 🟢 | 🟢 | Bootstrap a new project: .gitignore, AGENTS.md, CLAUDE.md, README.md, initial commit, optional GitHub remote | 2026-05-30 |
| [code-review](https://github.com/kratocz/code-review) | 🟢 | 🟢 | 🟢 | Structured code review with severity codes (Cx/Mx/mx/nx), per-round findings files, and GitHub posting | 2026-05-30 |
| [tmux-hooks](https://github.com/kratocz/tmux-hooks) | 🟢 | 🟢 | 🔴 | Set tmux pane title to reflect Claude Code lifecycle state | 2026-05-16 |
| [mikrotik-audit](https://github.com/kratocz/mikrotik-audit) | 🟢 | 🟢 | 🔴 | Read-only security audit for Mikrotik RouterOS devices via SSH | 2026-04-20 |
| [session-log](https://github.com/kratocz/session-log) | 🟢 | 🟢 | 🔴 | Save a structured summary of each Claude Code session to a markdown file | 2026-04-19 |
| [session-tracker](https://github.com/kratocz/session-tracker) | 🟢 | 🟢 | 🟡 | Start and stop time tracking sessions in Toggl Track or Clockify | 2026-04-09 |
| [second-opinion](https://github.com/kratocz/second-opinion) | 🟢 | 🟢 | 🟡 | Get a second opinion from Gemini or GPT on any important topic or decision | 2026-04-04 |
| [desktop-notify](https://github.com/kratocz/desktop-notify) | 🟢 | 🟢 | 🔴 | Desktop notifications when Claude Code waits for your response or approval | 2026-03-23 |

*🟢 fully supported · 🟡 partial support or extra setup required · 🔴 not supported*

## Install a plugin

```
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
