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
  - Reviews and merges are done by the **tech lead** (who may also review and merge their own PRs)
  - All `Cx` and `Mx` findings resolved (or explicitly waived by the reviewer) before merge
  - CI must be green before merge

## Performing a code review

When the user asks for a code review, follow this procedure:

1. **Identify the target.** A specific PR? A branch? Something else? If unclear, ask the user first.

2. **Check for prior review rounds.** Look at the target's history — existing review comments and any prior findings file in `docs.local/`.
   - No prior CR → proceed.
   - Prior CR exists → review only the new changes since (new commits, new discussion).
   - Prior CR exists and there are no new changes → tell the user and skip the CR; the author hasn't addressed earlier findings yet.

3. **Pick a CR title and start timesheet logging.**
   - Decide a short, descriptive title for this CR.
   - If the user tracks time (Toggl, Clockify, ClickUp time tracking, etc. — they may have specific timesheet instructions in their global or project `CLAUDE.md`), start a new timer/entry for this CR using that title.
   - If a timesheet session is already running, ask the user whether to stop it and start a new one for this CR, or leave the current one running.

4. **Produce findings.** Label each one with a severity code (`C1`, `C2`, `M1`, `m1`, `n1`, …). If a finding needs a new category (e.g. off-topic), propose it to the user with a suggested letter prefix.
   - Write the findings to a file in `docs.local/` at the project root; content in English.
   - The file starts with a header: metadata (author, reviewer, date, PR/branch reference) **plus a short summary of the changes — in your own words, based on what you actually found in the diff** (not a copy of the PR description).
   - If `docs.local/` doesn't exist, ask the user whether to create it and add it to the project `.gitignore`.

5. **Re-check severity.** Is each finding labelled at the right level (`Cx`/`Mx`/`mx`/`nx`)?

6. **Re-check for false positives.** Common. Remove the finding or downgrade its severity.

7. **Add line references** to each finding where it makes sense (`file:line` or `file:start-end`).

8. **Add a fix snippet** to each finding where it makes sense — a code change the author can apply with one click.

9. **Re-verify line numbers** against the actual file state; they often drift between earlier passes.

10. **Second verification pass:** for each finding, re-check severity, false-positive risk, line references, and suggested code.

11. **Third verification pass:** final check of everything to avoid wasting the author's time on inaccuracies.

12. **Summarise to the user** — e.g. `4 critical (C1,C2,C3,C4), 3 major (M1,M2,M3), 2 nits (n1,n2)`, mention the `docs.local/` file with the full CR, and wait for the user's go-ahead.

13. **After approval, post to GitHub:**
    - Each `Cx` and `Mx` finding → its own inline comment (or a standalone comment if inline isn't possible).
    - A summary comment with: an overview of all findings (including counts/lists for `mx` and `nx`), thanks to the author, a note of praise, and clear instructions — what **must** be fixed (`Cx`, `Mx`), what should be **attempted** if easy (`mx`), and what is **optional** (`nx`).
    - **All GitHub comments in English.**

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
