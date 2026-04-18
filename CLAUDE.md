# CLAUDE.md

## Project overview

`claude-plugins` is a Claude Code plugin marketplace. It catalogs plugins published by Petr Kratochvíl.

## Structure

```
claude-plugins/
├── .claude-plugin/
│   └── marketplace.json   ← marketplace catalog (name: "kratocz")
├── README.md
└── CLAUDE.md
```

## Adding a new plugin

Add an entry to `.claude-plugin/marketplace.json` under `plugins`:

```json
{
  "name": "my-new-plugin",
  "source": { "source": "github", "repo": "kratocz/my-new-plugin" },
  "description": "Short description",
  "version": "1.0.0",
  "added": "YYYY-MM-DD"
}
```

Each plugin lives in its own GitHub repository. This marketplace repo is just a catalog.

Also update `README.md`:
1. Prepend a row to the **Available plugins** table (newest first — top of the table).

## Updating plugin versions

When the user says "Update versions." (or similar), refresh the `version` field for every plugin in `.claude-plugin/marketplace.json` to match the latest upstream release.

For each plugin, fetch the latest tag:
```
gh api repos/<repo>/tags --jq '.[0].name'
```
If the repo has no tags, fall back to reading `.claude-plugin/plugin.json`:
```
gh api repos/<repo>/contents/.claude-plugin/plugin.json --jq '.content' | base64 -d
```
Strip the leading `v` from tags (e.g. `v1.4.0` → `1.4.0`) and update `marketplace.json`. README has no version numbers — no update needed there.

## Marketplace name

The marketplace `name` field is `kratocz` — this is the suffix used in install commands:
```
/plugin install plugin-name@kratocz
```
