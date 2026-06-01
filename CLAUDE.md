# CLAUDE.md

## Project overview

`claude-plugins` is a Claude Code plugin marketplace. It catalogs plugins published by Petr Kratochvíl.

## Structure

```
claude-plugins/
├── .claude-plugin/
│   └── marketplace.json   ← marketplace catalog (name: "kratocz")
├── plugins/                ← in-repo plugins (default for new plugins)
│   └── <plugin-name>/
│       ├── .claude-plugin/plugin.json
│       ├── skills/<skill>/SKILL.md
│       └── README.md
├── README.md
└── CLAUDE.md
```

The marketplace supports two source styles for plugins:

1. **In-repo** (default for new plugins) — plugin lives at `plugins/<name>/`. The marketplace entry uses an explicit relative path `"source": "./plugins/<name>"`.
2. **External GitHub repo** — for plugins that have an independent life (mature, broadly contributed). Entry uses `"source": { "source": "github", "repo": "kratocz/<name>" }`.

Migration from per-repo to in-repo is in progress; both styles coexist in `marketplace.json`.

## Adding a new plugin (in-repo, preferred)

1. Create `plugins/<plugin-name>/` with the standard structure:
   - `.claude-plugin/plugin.json` (name, version, description, author)
   - `skills/<skill-name>/SKILL.md`
   - `README.md`
2. Add an entry to `.claude-plugin/marketplace.json` under `plugins`:
   ```json
   {
     "name": "my-new-plugin",
     "source": "./plugins/my-new-plugin",
     "description": "Short description",
     "version": "1.0.0",
     "added": "YYYY-MM-DD"
   }
   ```
3. Prepend a row to README.md's **Available plugins** table (newest first).

## Adding a new plugin (external repo)

For plugins maintained in their own GitHub repo:

```json
{
  "name": "my-new-plugin",
  "source": { "source": "github", "repo": "kratocz/my-new-plugin" },
  "description": "Short description",
  "version": "1.0.0",
  "added": "YYYY-MM-DD"
}
```

The plugin then lives in `github.com/kratocz/my-new-plugin` with the same internal structure as in-repo plugins.

## Migrating an external plugin to in-repo

```
git subtree add --prefix=plugins/<name> git@github.com:kratocz/<name>.git main
```

Then switch the entry's `source` from the `github` object to the bare `"<name>"` string. Archive the old standalone repo (don't delete — preserve install URLs and history) with a redirect note in its README.

## Updating plugin versions

When the user says "Update versions." (or similar):
- **In-repo plugins:** read `version` from `plugins/<name>/.claude-plugin/plugin.json` and copy it to `marketplace.json`.
- **External plugins:** fetch the latest tag:
  ```
  gh api repos/<repo>/tags --jq '.[0].name'
  ```
  If the repo has no tags, fall back to reading `.claude-plugin/plugin.json`:
  ```
  gh api repos/<repo>/contents/.claude-plugin/plugin.json --jq '.content' | base64 -d
  ```
  Strip the leading `v` from tags (e.g. `v1.4.0` → `1.4.0`).

README has no version numbers — no update needed there.

## Marketplace name

The marketplace `name` field is `kratocz` — this is the suffix used in install commands:
```
/plugin install plugin-name@kratocz
```
