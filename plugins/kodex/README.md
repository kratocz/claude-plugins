# kodex

Thinking codex for AI agents — 15 working rules + a pre-delivery self-test,
injected into every Claude Code session as additional context via a `SessionStart`
hook. Four groups: **epistemics** (read intent and state first, label fact vs.
guess, verify cheaply verifiable claims, adversarially verify conclusions),
**decisions** (expected value over vibes, decision rules written before results,
escalate decisions rather than work), **output** (no theatre, recommendation +
falsification condition, disagreement as a service), and a **learning loop**
(externalize thinking, calibrate estimates per kind of work, learn at the
process level).

## Origin

Distilled in July 2026 from the working patterns of **Claude Fable 5** (Anthropic)
during real work on software projects — written as a handoff for weaker successor
models, then iterated and curated by a human. The core observation behind the whole
codex: even the strongest model's first pass is error-prone and self-serving;
the quality difference comes from *systematic distrust of the first draft* —
and that discipline, unlike model capacity, transfers fully through instructions.

## Install

```
/plugin marketplace add kratocz/claude-plugins
/plugin install kodex@kratocz
```

## How it works

A `SessionStart` hook prints the codex, and Claude Code adds it to the session
context — the agent then works under its rules in every session, in every project.
No commands, no configuration required.

The codex itself tells the agent to apply the rules proportionally
(process intensity ≈ cost of error × irreversibility), so trivial tasks don't
drown in ceremony.

## Language

Two equivalent versions ship with the plugin:

- [`kodex-en.md`](./kodex-en.md) — English (default)
- [`kodex-cs.md`](./kodex-cs.md) — Czech (the original; Czech is the canonical
  language of the codex, the English text is its maintained translation)

To switch the injected language, set the `KODEX_LANG` environment variable to
`cs` or `en` — e.g. in `~/.claude/settings.json`:

```json
{
  "env": {
    "KODEX_LANG": "cs"
  }
}
```

Unknown values fall back to English.

## Platform support

Linux 🟢 · macOS 🟢 · Windows 🟡 (the hook is a POSIX shell one-liner; untested
on Windows — expect it to work under Git Bash / WSL).

## Using the codex outside Claude Code

The rule files are plain Markdown — paste them into any `AGENTS.md` / `CLAUDE.md`
/ system prompt of your tool of choice. Keep this repo as the canonical version
if you fork or adapt it, so improvements have one home.

## License

The codex text (`kodex-cs.md`, `kodex-en.md`) is © 2026 Petr Kratochvíl, licensed
under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) — use, adapt, and
share with attribution and a link back. The plugin glue (hook, manifest) is trivial;
treat it as CC BY 4.0 as well.
