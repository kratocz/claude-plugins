# Code review plugin – shared context for Claude Code

This file is loaded into memory whenever the `code-review` plugin is enabled. It captures the **conventions** for code review; the step-by-step **procedure** for performing one lives in the `/code-review:code-review` skill.

## Communication

- Conversation language with the user: **match the user's language** (Czech with full diacritics, English, or whatever the user writes in)
- Language of code, commit messages, PR titles and code review: **English**
- Code comments: English, unless the specific project says otherwise

## Code review

Applies to `/review`, `/ultrareview`, and manual PR comments. **If a project's own conventions (`AGENTS.md`/`CLAUDE.md`) conflict with the rules below, follow the project's rules.**

The step-by-step procedure for *performing* a code review (CR title, timesheet, findings file, GitHub posting) lives in the `/code-review:code-review` skill — this section just captures the conventions.

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
  - **Security** — committed secrets, injection, missing authn/authz, unsafe deserialization (see [Security and sensitive data](#security-and-sensitive-data)).
  - **Tests** — appropriate coverage? For bug fixes, a regression test that fails without the fix?
  - **Maintainability** — naming, complexity, dead code, leaky abstractions
- **PR title and description:**
  - Suggesting a renamed PR title: mark as `nx` unless the current title is genuinely wrong
  - Suggesting an expanded/clearer PR description: mark as `nx` unless the description is factually misleading
- **Skip:** style nits a formatter/linter would catch (fix in CI tooling instead) and personal taste not codified in project conventions
- **Process:**
  - Authors re-read their own diff before merging or requesting review
  - Who reviews what is decided informally within the team; reviewers may also review and merge their own PRs
  - The reviewer may merge after their own Approve, provided the repo's required approval count is met (otherwise submit only the Approve and wait for additional approvals)
  - All `Cx` and `Mx` findings resolved (or explicitly waived by the reviewer) before merge
  - CI must be green before merge

## Git conventions

- **Commit style:** Conventional Commits (`feat:`, `fix:`, `ci:`, `docs:`, `refactor:`, `test:`, `chore:`) — see git log of existing repos
- **PR titles:** same format as commits, short and in English
- **Force push to `main` (or the repo's default branch):** never
- **Skip hooks (`--no-verify`):** never without explicit user consent

## Security and sensitive data

- Passwords, API keys, OAuth tokens and `.env` files: **never** commit them or send them to external services (pastebin, gist, AI tools outside of Claude Code).
- Before committing, quickly check the diff for unintended secrets (typically `.env`, `credentials.json`, `*.pem`, hardcoded tokens in tests).
- If you find a secret in an existing commit, **don't just delete it from the working tree** — warn the user, the secret needs to be revoked and the history rewritten.

## .gitignore

In any new repo, consider adding lines for common macOS junk (many teammates work on macOS):

```
.DS_Store
._*
```

A global `~/.config/git/ignore` handles this for each developer individually, but a project-level `.gitignore` protects the team and external contributors.
