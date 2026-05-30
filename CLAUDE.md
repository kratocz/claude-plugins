# Code review plugin – shared context for Claude Code

This file is loaded into memory whenever the `code-review` plugin is enabled. It captures the **conventions** for code review; the step-by-step **procedure** for performing one lives in the `/code-review:code-review` skill.

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
  - **Security** — committed secrets, injection, missing authn/authz, unsafe deserialization.
  - **Tests** — appropriate coverage? For bug fixes, a regression test that fails without the fix?
  - **Maintainability** — naming, complexity, dead code, leaky abstractions
- **PR title and description:**
  - Suggesting a renamed PR title: mark as `nx` unless the current title is genuinely wrong
  - Suggesting an expanded/clearer PR description: mark as `nx` unless the description is factually misleading
- **Skip:** style nits a formatter/linter would catch (fix in CI tooling instead) and personal taste not codified in project conventions
- **Process:**
  - Authors re-read their own diff before merging or requesting review
  - The reviewer may merge after their own Approve, provided the repo's required approval count is met (otherwise submit only the Approve and wait for additional approvals)
  - All `Cx` and `Mx` findings resolved (or explicitly waived by the reviewer) before merge
  - CI must be green before merge
