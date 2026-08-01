# claude-plugins

Claude Code plugin marketplace by [Petr Kratochvíl](https://krato.cz/).

## 📦 Most of this repo moved → [kratocz/skills](https://github.com/kratocz/skills)

The skills that used to be distributed here as plugins — code-review, conventional-commit, dockerize, semver-release, init-project, mikrotik-audit, dependency-diagrams, second-opinion, skillify, retro, kodex, the `work-*` suite, and the `tracker-*` suite — now live in **[kratocz/skills](https://github.com/kratocz/skills)**: a portable [Agent Skills](https://agentskills.io/) collection that works in Claude Code, Codex, Antigravity, opencode, Copilot CLI, Gemini CLI, and any other agent supporting the standard. One command, no plugin marketplace needed:

```bash
npx skills add kratocz/skills
```

This repository keeps only the plugins that genuinely need Claude Code's plugin mechanism (lifecycle hooks, statusline integration).

## Add this marketplace

```
/plugin marketplace add kratocz/claude-plugins
```

## Available plugins

*Newest first — sorted by date added.*

| Plugin | Linux | macOS | Windows | Description | Added |
|---|:---:|:---:|:---:|---|---|
| [claude-statusline-state](./plugins/claude-statusline-state) | 🟢 | 🟢 | 🔴 | Publish per-session Claude Code lifecycle state (idle/working/waiting) to a file, ready to render as an extra line in your statusline | 2026-06-09 |
| [tmux-hooks](./plugins/tmux-hooks) | 🟢 | 🟢 | 🔴 | Set tmux pane title to reflect Claude Code lifecycle state | 2026-05-16 |
| [session-log](./plugins/session-log) | 🟢 | 🟢 | 🔴 | Save a structured summary of each Claude Code session to a markdown file | 2026-04-19 |
| [desktop-notify](./plugins/desktop-notify) | 🟢 | 🟢 | 🔴 | Desktop notifications when Claude Code waits for your response or approval | 2026-03-23 |

*🟢 fully supported · 🟡 partial support or extra setup required · 🔴 not supported*

## Install a plugin

```
/plugin install claude-statusline-state@kratocz
/plugin install tmux-hooks@kratocz
/plugin install session-log@kratocz
/plugin install desktop-notify@kratocz
```
