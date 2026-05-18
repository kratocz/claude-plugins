# NTIT Group – shared context for Claude Code

This file is loaded into memory whenever the `ntit-common` plugin is enabled. It contains company conventions that **cannot be derived from a specific project's source code**. Project-specific things belong in the repo's `AGENTS.md`/`CLAUDE.md`, not here.

## Communication

- Conversation language with the user: **match the user's language** (Czech with full diacritics, or English)
- Language of code, commit messages, PR titles and code review: **English**
- Code comments: English, unless the specific project says otherwise

## ClickUp

This plugin has the ClickUp MCP server (`mcp.clickup.com`) configured. Authentication uses OAuth on the first call — no API keys are shared.

- **Workspace:** `NTIT Group` (ID `9012339064`)
- **Bug lists, feature lists, chat channels and task naming conventions:** project-specific — they belong in the repo's `AGENTS.md`/`CLAUDE.md`, not here.

When the user mentions a ticket without context, search in ClickUp via `clickup_search` in the default workspace.

## Git / GitHub conventions

- **Org:** `NTITGroup` on GitHub
- **Default branch:** `main`
- **Commit style:** Conventional Commits (`feat:`, `fix:`, `ci:`, `docs:`, `refactor:`, `test:`, `chore:`) — see git log of existing repos
- **PR titles:** same format as commits, short and in English
- **Force push to `main`:** never
- **Skip hooks (`--no-verify`):** never without explicit user consent

## Security and sensitive data

- Passwords, API keys, OAuth tokens and `.env` files: **never** commit them or send them to external services (pastebin, gist, AI tools outside of Claude Code).
- Before committing, quickly check the diff for unintended secrets (typically `.env`, `credentials.json`, `*.pem`, hardcoded tokens in tests).
- If you find a secret in an existing commit, **don't just delete it from the working tree** — warn the user, the secret needs to be revoked and the history rewritten.

## Escalation

<!-- TODO: fill in contacts and procedure -->
- **Tech lead:** <!-- name + how to contact -->
- **Production incident:** <!-- procedure -->
- **Questions about ClickUp / project management:** <!-- contact -->

## .gitignore

In any new repo, consider adding lines for common macOS junk (many teammates work on macOS):

```
.DS_Store
._*
```

A global `~/.config/git/ignore` handles this for each developer individually, but a project-level `.gitignore` protects the team and external contributors.
