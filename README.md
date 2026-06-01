# conventional-commit — Claude Code plugin

Generate a [Conventional Commits](https://www.conventionalcommits.org/) message from the staged diff and create the commit.

## What it does

The skill `/conventional-commit:conventional-commit` walks through:

1. **Checks the staged diff.** If nothing is staged, shows `git status` and asks how to proceed (stage all / stage by patch / cancel).
2. **Reads the diff** and picks the right Conventional Commits type — `feat`, `fix`, `chore`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `revert`.
3. **Drafts a subject line** (imperative, ≤72 chars).
4. **Asks for the scope** — proposes a sensible default based on changed paths (e.g. `auth` if all changes are in `src/auth/`), or `none` if the diff spans multiple areas.
5. **Drafts a body** when the diff is non-trivial (>1 file or >30 lines) — short 1–3 sentence explanation of *why*, not *what*.
6. **Shows the final message** and asks: commit / edit / cancel.
7. **Creates the commit** (no `--no-verify`).

Messages are in English (consistent with PR titles and code).

## Install

Via the [kratocz marketplace](https://github.com/kratocz/claude-plugins):

```
/plugin marketplace add kratocz/claude-plugins
/plugin install conventional-commit@kratocz
```

## Requirements

- `git`

## Usage

After staging some changes:

```
/conventional-commit
```

…or just say: "udělej commit", "commitni to", "commit staged changes".
