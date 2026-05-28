---
name: code-review
description: Run an NTIT-style code review on a PR (or another target). Picks a CR title, starts timesheet logging, produces findings labelled C1/M1/m1/n1 with line references and fix snippets in `docs.local/`, runs verification passes, then posts inline + summary comments on GitHub. Use whenever the user asks you to review a PR, says "udělej CR", asks for a code review on a branch or diff, or otherwise wants structured review feedback in the NTIT convention.
---

# NTIT code review workflow

This skill executes a code review following NTIT conventions. The **conventions themselves** (severity codes, focus areas, comment language, tech-lead policy) live in the `## Code review` section of the plugin's `CLAUDE.md` — read that first; this skill is the **procedure** to follow.

When invoked, follow this procedure in order:

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
   - A template is bundled with this skill at `${CLAUDE_SKILL_DIR}/findings-template.md` — use it as a starting point.
   - If `docs.local/` doesn't exist, ask the user whether to create it and add it to the project `.gitignore`.

5. **Re-check severity.** Is each finding labelled at the right level (`Cx`/`Mx`/`mx`/`nx`)?

6. **Re-check for false positives.** Common. Remove the finding or downgrade its severity.

7. **Add line references** to each finding where it makes sense (`file:line` or `file:start-end`).

8. **Add a fix snippet** to each finding where it makes sense — a code change the author can apply with one click.

9. **Re-verify line numbers** against the actual file state; they often drift between earlier passes.

10. **Second verification pass:** for each finding, re-check severity, false-positive risk, line references, and suggested code.

11. **Third verification pass:** final check of everything to avoid wasting the author's time on inaccuracies.

12. **Summarise to the user** — e.g. `4 critical (C1,C2,C3,C4), 3 major (M1,M2,M3), 2 nits (n1,n2)`, mention the `docs.local/` file with the full CR, and wait for the user's go-ahead. **If there are no `Cx`/`Mx` blockers, also offer the "approve & merge" option** (see step 13).

13. **After approval, post to GitHub:**
    - Each `Cx` and `Mx` finding → its own inline comment (or a standalone comment if inline isn't possible).
    - A summary comment with: an overview of all findings (including counts/lists for `mx` and `nx`), thanks to the author, a note of praise, and clear instructions — what **must** be fixed (`Cx`, `Mx`), what should be **attempted** if easy (`mx`), and what is **optional** (`nx`).
    - **All GitHub comments in English.**
    - **Approve & merge:** if no `Cx`/`Mx` findings remain (no unresolved blockers) **and** the user pre-authorised it together with the go-ahead in step 12, after posting the comments also submit an **Approve** verdict and merge the PR (per the project's merge style).
