# project-init — Claude Code plugin

Bootstrap a new project with the standard baseline files in a single skill invocation.

## What it does

The skill `/project-init:init-project` walks through:

1. **Surveys** the current directory — is it a git repo? what files already exist?
2. **Detects the project type** (Node, Python, Go, Rust, PHP, JVM, Ruby, Elixir, Dart/Flutter, .NET, or generic) by looking for marker files.
3. **Creates or extends `.gitignore`** — always includes macOS junk (`.DS_Store`, `._*`) and JetBrains `/.idea/`, plus type-specific entries (e.g. `node_modules/`, `__pycache__/`, `/target/`).
4. **Creates `AGENTS.md`** — minimal template with placeholders for project description, setup, run/build/test, and conventions.
5. **Creates `CLAUDE.md`** — one-liner redirecting to `AGENTS.md` (single source of truth).
6. **Creates `README.md`** — name + one-line description, populated only from what's actually visible in the directory.
7. **`git init`** if not already a git repo, then commits the baseline.
8. **Offers a GitHub remote** — asks via `AskUserQuestion` for repo name and visibility (defaults to private), then runs `gh repo create … --source=. --push`.

Existing files are never overwritten — `.gitignore` is only appended to with missing entries, and `AGENTS.md` / `CLAUDE.md` / `README.md` are skipped if they already exist.

## Install

Via the [kratocz marketplace](https://github.com/kratocz/claude-plugins):

```
/plugin marketplace add kratocz/claude-plugins
/plugin install project-init@kratocz
```

## Requirements

- `git`
- `gh` CLI authenticated (`gh auth login`) — only needed for the GitHub repo creation step

## Usage

In a new or freshly inherited project directory:

```
/init-project
```

…or just tell Claude in natural language: "založ tomu projektu základní soubory a pushni to na GitHub".
