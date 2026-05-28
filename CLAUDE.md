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

## Code review

Applies to `/review`, `/ultrareview`, and manual PR comments. **If a project's own conventions (`AGENTS.md`/`CLAUDE.md`) conflict with the rules below, follow the project's rules.**

The step-by-step procedure for *performing* a code review (CR title, timesheet, findings file, GitHub posting) lives in the `/ntit-common:code-review` skill — this section just captures the conventions.

- **Comment language:** English (consistent with PR titles, commits, and code)
- **Tone:** Constructive and specific. Reference lines as `path/to/file.ext:42`. Suggest, don't dictate.
- **Severity codes** — label every finding with `C1`, `C2`, `M1`, `m1`, `n1`, etc., numbered within its severity:
  - `Cx` — **critical**, blocking. Severe correctness/security issue, broken API contract.
  - `Mx` — **major**, blocking. Significant bug, missing essential tests, serious design issue.
  - `mx` — **minor**, non-blocking. Author should fix if easy.
  - `nx` — **nit**, optional.
- **Reviewer verdict:** any `Cx` or `Mx` → "Request changes". Otherwise → "Approve" (with comments).
- **Focus on:**
  - **Correctness** — does the diff do what the PR description claims? Edge cases? Error paths?
  - **Security** — committed secrets, injection, missing authn/authz, unsafe deserialization (see [Security and sensitive data](#security-and-sensitive-data))
  - **Tests** — appropriate coverage? For bug fixes, a regression test that fails without the fix?
  - **Maintainability** — naming, complexity, dead code, leaky abstractions
- **PR title and description:**
  - Suggesting a renamed PR title: mark as `nx` unless the current title is genuinely wrong
  - Suggesting an expanded/clearer PR description: mark as `nx` unless the description is factually misleading
- **Skip:** style nits a formatter/linter would catch (fix in CI tooling instead) and personal taste not codified in project conventions
- **Process:**
  - Authors re-read their own diff before merging or requesting review
  - Reviews and merges are done by the **tech lead** (who may also review and merge their own PRs). In practice, the user running the review (typically via the `/ntit-common:code-review` skill) acts as the reviewer.
  - All `Cx` and `Mx` findings resolved (or explicitly waived by the reviewer) before merge
  - CI must be green before merge

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
