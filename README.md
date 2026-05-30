# code-review — Claude Code plugin

Structured code review workflow for Claude Code.

## What it does

The skill `/code-review:code-review` walks through a multi-step review:

1. **Auto-detects the target** (PR, branch) from the worktree directory name or current branch (e.g. a worktree named `cr-pr-27` → PR #27).
2. **Gathers inputs** — commits, PR description, existing review/discussion comments — and checks for prior CR rounds in `docs.local/code-reviews/`.
3. **Starts a timesheet entry** (via `session-tracker` skill, Toggl MCP, etc. if configured).
4. **Produces findings** labelled with severity codes — `Cx` (critical, blocking), `Mx` (major, blocking), `mx` (minor, fix-if-easy), `nx` (nit, optional) — and writes them to a per-round file in `docs.local/code-reviews/`.
5. **Verifies** through multiple passes (severity, false positives, line numbers, fix snippets).
6. **Freshness re-check** — if new commits/comments arrived mid-review, extends the review.
7. **Summarises to the user** and waits for go-ahead.
8. **Posts inline + summary comments** on GitHub, optionally including approve & merge when blockers are clear and CI is green.

Conventions (severity codes, focus areas, comment language, process) live in this plugin's `CLAUDE.md`.

## Install

Via the [kratocz marketplace](https://github.com/kratocz/claude-plugins):

```
/plugin marketplace add kratocz/claude-plugins
/plugin install code-review@kratocz
```

## History

Originally extracted from the `ntit-common` plugin in [`kratocz/ntit-claude-plugins`](https://github.com/kratocz/ntit-claude-plugins) and rewritten as a stand-alone plugin.
