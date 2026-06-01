# second-opinion

A [Claude Code](https://claude.ai/claude-code) plugin that sends your current topic to Gemini and GPT for a second opinion — without leaving your Claude Code session.

Ask once, hear from all three.

## What it does

When you're deep in a technical discussion with Claude — choosing an architecture, picking a library, making a design decision — just run `/second-opinion`. The plugin assembles the relevant context from your conversation and sends it to Gemini and Codex. Their responses appear right in your session, labeled and ready to compare.

## Usage

```
/second-opinion
```
Infers the current topic from the conversation and asks both Gemini and GPT.

```
/second-opinion Should we use event sourcing here?
```
Uses your explicit question with context from the conversation.

```
/second-opinion --gemini
/second-opinion --gpt
```
Narrow down to a single model when you only need one perspective.

```
/second-opinion --gpt Is this approach thread-safe?
```
Explicit question, single model.

## Requirements

You need both CLIs installed, in your `$PATH`, and configured with your preferred credentials (API key, subscription, etc.):

| CLI | Install |
|---|---|
| `gemini` | [github.com/google-gemini/gemini-cli](https://github.com/google-gemini/gemini-cli) |
| `codex` | [github.com/openai/codex](https://github.com/openai/codex) |

The plugin does not manage authentication — that's up to you.

## Installation

```
/plugin marketplace add kratocz/claude-plugins
/plugin install second-opinion@kratocz
```

## How it works

`/second-opinion` is a [Claude Code skill](https://docs.anthropic.com/en/docs/claude-code/skills). When invoked:

1. Claude summarizes the relevant context from the current conversation into a self-contained prompt
2. The prompt is piped via stdin: `echo "$PROMPT" | gemini` and `echo "$PROMPT" | codex`
3. Responses are displayed inline, each under its own heading

The context assembly is handled by Claude itself — no need to copy-paste anything.

## Contributing

Issues and PRs are welcome at [github.com/kratocz/second-opinion](https://github.com/kratocz/second-opinion).

## License

MIT — © [Petr Kratochvíl](https://krato.cz/)
