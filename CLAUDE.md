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
1. Add a row to the **Available plugins** table (keep alphabetical order).
2. Prepend the plugin to the **Recently added** section (newest first); keep at most 3 entries — remove the oldest one if the list would exceed 3.

## Marketplace name

The marketplace `name` field is `kratocz` — this is the suffix used in install commands:
```
/plugin install plugin-name@kratocz
```
