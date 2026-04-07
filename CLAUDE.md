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

## Marketplace name

The marketplace `name` field is `kratocz` — this is the suffix used in install commands:
```
/plugin install plugin-name@kratocz
```
