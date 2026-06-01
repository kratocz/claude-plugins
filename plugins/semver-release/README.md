# semver-release — Claude Code plugin

Cut a [SemVer](https://semver.org/) release driven by [Conventional Commits](https://www.conventionalcommits.org/): bump version, update `CHANGELOG.md`, commit, tag, push, optionally create a GitHub release.

## What it does

The skill `/semver-release` walks through:

1. **Finds the last tag** (`git describe --tags --abbrev=0`) and reads commits since.
2. **Proposes a version bump** by parsing Conventional Commits:
   - `BREAKING CHANGE` / `!:` → major
   - `feat:` → minor
   - `fix:` / `perf:` / `refactor:` → patch
   - For pre-1.0 (`0.x.y`), asks the user how to handle `feat:` (minor vs patch).
3. **Detects version files** to update: `package.json`, `pyproject.toml`, `Cargo.toml`, `composer.json`, `.claude-plugin/plugin.json`, `pubspec.yaml`, … (matches what `project-init` detects).
4. **Generates `CHANGELOG.md` entry** in [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format — groups commits into Added / Fixed / Changed / Removed.
5. **Checks CI status** of the current commit via `gh run list` and warns if any check is failing or pending.
6. **Commits** the version bump as `chore(release): vX.Y.Z` and tags it.
7. **Pushes** commit + tag.
8. **Asks before `gh release create`** — if yes, creates the GitHub release with the changelog entry as the release notes.

Every interactive step uses `AskUserQuestion` so the user can redirect — version bump kind, scope of files to update, whether to push, whether to publish the GitHub release.

## Install

Via the [kratocz marketplace](https://github.com/kratocz/claude-plugins):

```
/plugin marketplace add kratocz/claude-plugins
/plugin install semver-release@kratocz
```

## Requirements

- `git`
- `gh` CLI authenticated (only needed for the GitHub release step)
- A history of [Conventional Commits](https://www.conventionalcommits.org/) since the last tag (pairs naturally with the [`conventional-commit`](https://github.com/kratocz/conventional-commit) plugin)

## Usage

On the branch you want to release from:

```
/semver-release
```

…or just say: "vydej release", "cut a release", "tag a new version".
