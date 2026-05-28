# Code Review — <short CR title>

- **PR / branch:** <link or branch name>
- **Author:** <name or @handle>
- **Reviewer:** <name or @handle>
- **Date:** <YYYY-MM-DD>
- **Round:** <N>

## Summary of changes

<2–4 sentences in the reviewer's own words, based on the actual diff — not a copy of the PR description.>

## Findings

> Severity codes — see `## Code review` in the plugin's `CLAUDE.md` for the full convention.
> `Cx` = critical (blocking), `Mx` = major (blocking), `mx` = minor (fix if easy), `nx` = nit (optional).

### Critical (blocking → request changes)

#### C1 — <short title>

- **Location:** `path/to/file.ext:42` (or `file.ext:42-58`)
- **Description:** <what's wrong and why it's critical>
- **Suggested fix:**
  ```<lang>
  <fix snippet the author can apply with one click>
  ```

### Major (blocking → request changes)

#### M1 — <short title>

- **Location:** `path/to/file.ext:NN`
- **Description:** <what's wrong>
- **Suggested fix:**
  ```<lang>
  <fix snippet>
  ```

### Minor (non-blocking; fix if easy)

#### m1 — <short title>

- **Location:** `path/to/file.ext:NN`
- **Description:** <what's wrong>
- **Suggested fix:**
  ```<lang>
  <fix snippet>
  ```

### Nits (optional)

#### n1 — <short title>

- **Location:** `path/to/file.ext:NN`
- **Description:** <what's wrong>
- **Suggested fix:** (optional)
  ```<lang>
  <fix snippet>
  ```

## Overall verdict

- **GitHub verdict:** Request changes / Approve (with comments)
- **Counts:** `<N> critical, <N> major, <N> minor, <N> nits`
- **Notes for the author:** <one short paragraph: thanks, praise, what must be fixed (Cx/Mx), what should be attempted if easy (mx), what is optional (nx)>
