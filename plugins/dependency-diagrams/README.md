# dependency-diagrams

Generate task-dependency diagrams from any tracker — ClickUp, GitHub, Jira,
Todoist, or a CSV/JSON export — as draw.io + SVG + PNG dated snapshots.

## What it produces

| Diagram | Content |
|---|---|
| `<prefix>-graph` | Full dependency graph, tasks grouped by group/epic, transitively reduced |
| `<prefix>-overview` | One node per group, clustered by phase/milestone, edge labels = dependency counts |
| `<prefix>-<cluster>` | Per-phase detail: the phase's tasks + grey ghost nodes for upstream inputs |

Each as `.json` (layout model), `.drawio`, `.svg`, and `.png` (2× scale).
Status legend: green ✓ = done, blue ▸ = in flight (incl. review states),
white = open.

## How it works

The skill separates **fetching** (model-driven, per-source recipes for
ClickUp/GitHub/Jira/CSV — including the ClickUp gotcha that bulk task listing
omits dependencies) from **rendering** (deterministic Python scripts:
`gen_diagrams.py` normalized-model → graph JSONs, `autolayout.py` graph JSON →
draw.io XML via Graphviz).

Project-specific coordinates (board IDs, epic structure, output directory)
stay in the project's memory/AGENTS.md — the plugin itself is generic.

## Requirements

- Python 3 (stdlib only)
- Graphviz (`dot`)
- draw.io CLI (`drawio` or the desktop app) for SVG/PNG export — optional;
  without it you still get `.drawio` files

## Usage

Ask Claude Code e.g.:

> Generate task dependency diagrams from our ClickUp list.

> Regenerate the dependency diagram snapshot with today's state.

On first use in a project the skill asks for the source and grouping and
records them in project memory for next time.
